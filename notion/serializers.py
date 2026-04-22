from django.contrib.auth.models import User
from rest_framework import serializers

from notion.models import Block, Page, PageShare, Workspace, WorkspaceMembership


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email')


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password')
        read_only_fields = ('id',)

    def create(self, validated_data):
        user = User(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
        )
        user.set_password(validated_data['password'])
        user.save()
        return user


class WorkspaceMembershipSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = WorkspaceMembership
        fields = ('id', 'user', 'role', 'created_at', 'updated_at')


class WorkspaceSerializer(serializers.ModelSerializer):
    owner = UserSerializer(read_only=True)
    memberships = WorkspaceMembershipSerializer(many=True, read_only=True)

    class Meta:
        model = Workspace
        fields = ('id', 'name', 'owner', 'memberships', 'created_at', 'updated_at')
        read_only_fields = ('id', 'owner', 'memberships', 'created_at', 'updated_at')


class BlockSerializer(serializers.ModelSerializer):
    def validate(self, attrs):
        if self.instance and 'page' in attrs and attrs['page'].id != self.instance.page_id:
            raise serializers.ValidationError('Moving a block to another page is not supported.')
        return attrs

    class Meta:
        model = Block
        fields = (
            'id',
            'page',
            'block_type',
            'content',
            'is_checked',
            'position',
            'created_at',
            'updated_at',
        )
        read_only_fields = ('id', 'created_at', 'updated_at')


class PageShareSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = PageShare
        fields = ('id', 'user', 'role', 'created_at', 'updated_at')


class PageSerializer(serializers.ModelSerializer):
    owner = UserSerializer(read_only=True)
    blocks = BlockSerializer(many=True, read_only=True)
    shares = PageShareSerializer(many=True, read_only=True)

    def validate(self, attrs):
        workspace = attrs.get('workspace') or getattr(self.instance, 'workspace', None)
        parent_page = attrs.get('parent_page')

        if self.instance and 'workspace' in attrs and attrs['workspace'].id != self.instance.workspace_id:
            raise serializers.ValidationError('Moving a page to another workspace is not supported.')

        if parent_page is None:
            return attrs

        if workspace and parent_page.workspace_id != workspace.id:
            raise serializers.ValidationError('Parent page must belong to the same workspace.')

        if self.instance and parent_page and parent_page.id == self.instance.id:
            raise serializers.ValidationError('A page cannot be parent of itself.')

        return attrs

    class Meta:
        model = Page
        fields = (
            'id',
            'title',
            'workspace',
            'owner',
            'parent_page',
            'is_archived',
            'blocks',
            'shares',
            'created_at',
            'updated_at',
        )
        read_only_fields = ('id', 'owner', 'blocks', 'shares', 'created_at', 'updated_at')


class ShareInputSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    role = serializers.ChoiceField(
        choices=[PageShare.ROLE_VIEWER, PageShare.ROLE_EDITOR],
        default=PageShare.ROLE_VIEWER,
    )


class WorkspaceMemberInputSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    role = serializers.ChoiceField(
        choices=[WorkspaceMembership.ROLE_VIEWER, WorkspaceMembership.ROLE_EDITOR],
        default=WorkspaceMembership.ROLE_VIEWER,
    )


class ReorderBlocksSerializer(serializers.Serializer):
    page_id = serializers.IntegerField()
    ordered_block_ids = serializers.ListField(
        child=serializers.IntegerField(),
        allow_empty=False,
    )
