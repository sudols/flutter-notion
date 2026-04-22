from django.contrib.auth.models import User
from rest_framework import status
from rest_framework.test import APIClient, APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from notion.models import Block, Page, Workspace, WorkspaceMembership


def authorize(client, user):
    access_token = RefreshToken.for_user(user).access_token
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')


class AuthAndRegistrationTests(APITestCase):
    def test_registration_creates_default_workspace(self):
        payload = {
            'username': 'alice',
            'email': 'alice@example.com',
            'password': 'password123',
        }

        response = self.client.post('/api/auth/register/', payload, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(User.objects.count(), 1)

        user = User.objects.get(username='alice')
        workspace = Workspace.objects.get(owner=user)
        membership = WorkspaceMembership.objects.get(workspace=workspace, user=user)

        self.assertEqual(workspace.name, "alice's workspace")
        self.assertEqual(membership.role, WorkspaceMembership.ROLE_EDITOR)

    def test_registration_is_limited_to_two_demo_users(self):
        for username in ['alice', 'bob']:
            response = self.client.post(
                '/api/auth/register/',
                {
                    'username': username,
                    'email': f'{username}@example.com',
                    'password': 'password123',
                },
                format='json',
            )
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        third_user_response = self.client.post(
            '/api/auth/register/',
            {
                'username': 'charlie',
                'email': 'charlie@example.com',
                'password': 'password123',
            },
            format='json',
        )

        self.assertEqual(third_user_response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Demo user limit reached', third_user_response.data['detail'])


class PageAndBlockFlowTests(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.alice = User.objects.create_user(username='alice', password='password123')
        self.bob = User.objects.create_user(username='bob', password='password123')
        self.workspace = Workspace.objects.create(name='Demo', owner=self.alice)
        WorkspaceMembership.objects.create(
            workspace=self.workspace,
            user=self.alice,
            role=WorkspaceMembership.ROLE_EDITOR,
        )

    def test_page_archive_search_and_block_reorder(self):
        authorize(self.client, self.alice)

        page_response = self.client.post(
            '/api/pages/',
            {'title': 'Project Notes', 'workspace': self.workspace.id},
            format='json',
        )
        self.assertEqual(page_response.status_code, status.HTTP_201_CREATED)
        page_id = page_response.data['id']

        block_a = self.client.post(
            '/api/blocks/',
            {'page': page_id, 'block_type': 'text', 'content': 'first line'},
            format='json',
        )
        block_b = self.client.post(
            '/api/blocks/',
            {'page': page_id, 'block_type': 'text', 'content': 'second line'},
            format='json',
        )
        self.assertEqual(block_a.status_code, status.HTTP_201_CREATED)
        self.assertEqual(block_b.status_code, status.HTTP_201_CREATED)
        self.assertEqual(block_a.data['position'], 0)
        self.assertEqual(block_b.data['position'], 1)

        reorder_response = self.client.post(
            '/api/blocks/reorder/',
            {
                'page_id': page_id,
                'ordered_block_ids': [block_b.data['id'], block_a.data['id']],
            },
            format='json',
        )
        self.assertEqual(reorder_response.status_code, status.HTTP_200_OK)
        self.assertEqual(reorder_response.data[0]['id'], block_b.data['id'])
        self.assertEqual(reorder_response.data[0]['position'], 0)

        archive_response = self.client.post(f'/api/pages/{page_id}/archive/', format='json')
        self.assertEqual(archive_response.status_code, status.HTTP_200_OK)

        active_list = self.client.get('/api/pages/')
        self.assertEqual(active_list.status_code, status.HTTP_200_OK)
        self.assertEqual(len(active_list.data), 0)

        archived_list = self.client.get('/api/pages/?include_archived=true')
        self.assertEqual(archived_list.status_code, status.HTTP_200_OK)
        self.assertEqual(len(archived_list.data), 1)

        restore_response = self.client.post(f'/api/pages/{page_id}/restore/', format='json')
        self.assertEqual(restore_response.status_code, status.HTTP_200_OK)

        search_response = self.client.get('/api/pages/?search=second')
        self.assertEqual(search_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(search_response.data), 1)

    def test_viewer_cannot_edit_until_page_is_shared_as_editor(self):
        authorize(self.client, self.alice)
        page_response = self.client.post(
            '/api/pages/',
            {'title': 'Shared Doc', 'workspace': self.workspace.id},
            format='json',
        )
        page_id = page_response.data['id']

        share_as_viewer = self.client.post(
            f'/api/pages/{page_id}/share/',
            {'user_id': self.bob.id, 'role': 'viewer'},
            format='json',
        )
        self.assertEqual(share_as_viewer.status_code, status.HTTP_200_OK)

        authorize(self.client, self.bob)
        denied_update = self.client.patch(
            f'/api/pages/{page_id}/',
            {'title': 'Bob Edit Attempt'},
            format='json',
        )
        self.assertEqual(denied_update.status_code, status.HTTP_403_FORBIDDEN)

        authorize(self.client, self.alice)
        share_as_editor = self.client.post(
            f'/api/pages/{page_id}/share/',
            {'user_id': self.bob.id, 'role': 'editor'},
            format='json',
        )
        self.assertEqual(share_as_editor.status_code, status.HTTP_200_OK)

        authorize(self.client, self.bob)
        allowed_update = self.client.patch(
            f'/api/pages/{page_id}/',
            {'title': 'Bob Final Edit'},
            format='json',
        )
        self.assertEqual(allowed_update.status_code, status.HTTP_200_OK)

        page = Page.objects.get(id=page_id)
        self.assertEqual(page.title, 'Bob Final Edit')
