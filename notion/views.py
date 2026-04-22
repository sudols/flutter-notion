from django.contrib.auth.models import User
from django.conf import settings
from django.db import transaction
from django.db.models import Q
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from notion.models import Block, Page, PageShare, Workspace, WorkspaceMembership
from notion.permissions import (
    can_edit_page,
    can_edit_workspace,
    can_view_page,
)
from notion.serializers import (
    BlockSerializer,
    PageSerializer,
    ReorderBlocksSerializer,
    RegisterSerializer,
    ShareInputSerializer,
    UserSerializer,
    WorkspaceMemberInputSerializer,
    WorkspaceSerializer,
)


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        if User.objects.count() >= settings.MAX_DEMO_USERS:
            return Response(
                {'detail': f"Demo user limit reached ({settings.MAX_DEMO_USERS})."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        if not Workspace.objects.filter(owner=user).exists():
            workspace = Workspace.objects.create(name=f"{user.username}'s workspace", owner=user)
            WorkspaceMembership.objects.get_or_create(
                workspace=workspace,
                user=user,
                defaults={'role': WorkspaceMembership.ROLE_EDITOR},
            )

        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


class MeView(APIView):
    def get(self, request):
        return Response(UserSerializer(request.user).data, status=status.HTTP_200_OK)


class WorkspaceViewSet(viewsets.ModelViewSet):
    serializer_class = WorkspaceSerializer

    def get_queryset(self):
        user = self.request.user
        return Workspace.objects.filter(
            Q(owner=user) | Q(memberships__user=user)
        ).distinct()

    def perform_create(self, serializer):
        workspace = serializer.save(owner=self.request.user)
        WorkspaceMembership.objects.get_or_create(
            workspace=workspace,
            user=self.request.user,
            defaults={'role': WorkspaceMembership.ROLE_EDITOR},
        )

    def update(self, request, *args, **kwargs):
        workspace = self.get_object()
        if not can_edit_workspace(request.user, workspace):
            return Response({'detail': 'You cannot edit this workspace.'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        workspace = self.get_object()
        if not can_edit_workspace(request.user, workspace):
            return Response({'detail': 'You cannot edit this workspace.'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        workspace = self.get_object()
        if workspace.owner_id != request.user.id:
            return Response({'detail': 'Only owner can delete workspace.'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

    @action(detail=True, methods=['post'], url_path='share')
    def share(self, request, pk=None):
        workspace = self.get_object()
        if not can_edit_workspace(request.user, workspace):
            return Response({'detail': 'You cannot share this workspace.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = WorkspaceMemberInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            target_user = User.objects.get(id=serializer.validated_data['user_id'])
        except User.DoesNotExist:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        if workspace.owner_id == target_user.id:
            return Response({'detail': 'Owner already has full access.'}, status=status.HTTP_400_BAD_REQUEST)

        membership, _ = WorkspaceMembership.objects.update_or_create(
            workspace=workspace,
            user=target_user,
            defaults={'role': serializer.validated_data['role']},
        )

        return Response(
            {
                'workspace_id': workspace.id,
                'member_id': membership.user_id,
                'role': membership.role,
            },
            status=status.HTTP_200_OK,
        )


class PageViewSet(viewsets.ModelViewSet):
    serializer_class = PageSerializer

    def get_queryset(self):
        user = self.request.user
        query = Page.objects.filter(
            Q(owner=user)
            | Q(workspace__owner=user)
            | Q(workspace__memberships__user=user)
            | Q(shares__user=user)
        ).distinct()

        workspace_id = self.request.query_params.get('workspace')
        if workspace_id:
            query = query.filter(workspace_id=workspace_id)

        parent_id = self.request.query_params.get('parent')
        if parent_id is not None:
            if parent_id == 'null':
                query = query.filter(parent_page__isnull=True)
            else:
                query = query.filter(parent_page_id=parent_id)

        include_archived = self.request.query_params.get('include_archived') == 'true'
        if self.action == 'list' and not include_archived:
            query = query.filter(is_archived=False)

        search = self.request.query_params.get('search')
        if search:
            query = query.filter(Q(title__icontains=search) | Q(blocks__content__icontains=search)).distinct()

        return query

    def create(self, request, *args, **kwargs):
        workspace_id = request.data.get('workspace')
        if workspace_id is None:
            return Response({'detail': 'workspace is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            workspace = Workspace.objects.get(id=workspace_id)
        except Workspace.DoesNotExist:
            return Response({'detail': 'Workspace not found.'}, status=status.HTTP_404_NOT_FOUND)

        if not can_edit_workspace(request.user, workspace):
            return Response({'detail': 'You cannot create page in this workspace.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(owner=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def retrieve(self, request, *args, **kwargs):
        page = self.get_object()
        if not can_view_page(request.user, page):
            return Response({'detail': 'You cannot view this page.'}, status=status.HTTP_403_FORBIDDEN)
        return super().retrieve(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        page = self.get_object()
        if not can_edit_page(request.user, page):
            return Response({'detail': 'You cannot edit this page.'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        page = self.get_object()
        if not can_edit_page(request.user, page):
            return Response({'detail': 'You cannot edit this page.'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        page = self.get_object()
        if page.owner_id != request.user.id:
            return Response({'detail': 'Only owner can delete page.'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

    @action(detail=True, methods=['post'], url_path='archive')
    def archive(self, request, pk=None):
        page = self.get_object()
        if not can_edit_page(request.user, page):
            return Response({'detail': 'You cannot archive this page.'}, status=status.HTTP_403_FORBIDDEN)

        page.is_archived = True
        page.save(update_fields=['is_archived', 'updated_at'])
        return Response({'id': page.id, 'is_archived': True}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], url_path='restore')
    def restore(self, request, pk=None):
        page = self.get_object()
        if not can_edit_page(request.user, page):
            return Response({'detail': 'You cannot restore this page.'}, status=status.HTTP_403_FORBIDDEN)

        page.is_archived = False
        page.save(update_fields=['is_archived', 'updated_at'])
        return Response({'id': page.id, 'is_archived': False}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], url_path='share')
    def share(self, request, pk=None):
        page = self.get_object()
        if not can_edit_page(request.user, page):
            return Response({'detail': 'You cannot share this page.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = ShareInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            target_user = User.objects.get(id=serializer.validated_data['user_id'])
        except User.DoesNotExist:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        if page.owner_id == target_user.id:
            return Response({'detail': 'Owner already has full access.'}, status=status.HTTP_400_BAD_REQUEST)

        share, _ = PageShare.objects.update_or_create(
            page=page,
            user=target_user,
            defaults={'role': serializer.validated_data['role']},
        )

        return Response(
            {
                'page_id': page.id,
                'user_id': share.user_id,
                'role': share.role,
            },
            status=status.HTTP_200_OK,
        )


class BlockViewSet(viewsets.ModelViewSet):
    serializer_class = BlockSerializer

    def get_queryset(self):
        user = self.request.user
        query = Block.objects.filter(
            Q(page__owner=user)
            | Q(page__workspace__owner=user)
            | Q(page__workspace__memberships__user=user)
            | Q(page__shares__user=user)
        ).distinct()

        page_id = self.request.query_params.get('page')
        if page_id:
            query = query.filter(page_id=page_id)

        return query

    def create(self, request, *args, **kwargs):
        page_id = request.data.get('page')
        if page_id is None:
            return Response({'detail': 'page is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            page = Page.objects.get(id=page_id)
        except Page.DoesNotExist:
            return Response({'detail': 'Page not found.'}, status=status.HTTP_404_NOT_FOUND)

        if not can_edit_page(request.user, page):
            return Response({'detail': 'You cannot edit blocks for this page.'}, status=status.HTTP_403_FORBIDDEN)

        payload = request.data.copy()
        if payload.get('position') in (None, ''):
            max_position = page.blocks.order_by('-position').values_list('position', flat=True).first()
            payload['position'] = 0 if max_position is None else max_position + 1

        serializer = self.get_serializer(data=payload)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request, *args, **kwargs):
        block = self.get_object()
        if not can_edit_page(request.user, block.page):
            return Response({'detail': 'You cannot edit this block.'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        block = self.get_object()
        if not can_edit_page(request.user, block.page):
            return Response({'detail': 'You cannot edit this block.'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        block = self.get_object()
        if not can_edit_page(request.user, block.page):
            return Response({'detail': 'You cannot delete this block.'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

    @action(detail=False, methods=['post'], url_path='reorder')
    def reorder(self, request):
        serializer = ReorderBlocksSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        page_id = serializer.validated_data['page_id']
        ordered_ids = serializer.validated_data['ordered_block_ids']

        if len(ordered_ids) != len(set(ordered_ids)):
            return Response({'detail': 'ordered_block_ids has duplicate values.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            page = Page.objects.get(id=page_id)
        except Page.DoesNotExist:
            return Response({'detail': 'Page not found.'}, status=status.HTTP_404_NOT_FOUND)

        if not can_edit_page(request.user, page):
            return Response({'detail': 'You cannot reorder blocks for this page.'}, status=status.HTTP_403_FORBIDDEN)

        page_block_ids = list(page.blocks.values_list('id', flat=True))
        if set(page_block_ids) != set(ordered_ids):
            return Response(
                {'detail': 'ordered_block_ids must contain all and only blocks in the page.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        blocks_by_id = {block.id: block for block in page.blocks.all()}
        updated_blocks = []
        for position, block_id in enumerate(ordered_ids):
            block = blocks_by_id[block_id]
            block.position = position
            updated_blocks.append(block)

        with transaction.atomic():
            Block.objects.bulk_update(updated_blocks, ['position'])

        return Response(BlockSerializer(page.blocks.all(), many=True).data, status=status.HTTP_200_OK)
