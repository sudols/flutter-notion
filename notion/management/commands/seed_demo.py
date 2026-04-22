from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from notion.models import Block, Page, PageShare, Workspace, WorkspaceMembership


class Command(BaseCommand):
    help = 'Seed a two-user demo dataset for the Notion clone backend.'

    def handle(self, *args, **options):
        Block.objects.all().delete()
        PageShare.objects.all().delete()
        Page.objects.all().delete()
        WorkspaceMembership.objects.all().delete()
        Workspace.objects.all().delete()
        User.objects.exclude(is_superuser=True).delete()

        alice = User.objects.create_user(username='alice', email='alice@example.com', password='password123')
        bob = User.objects.create_user(username='bob', email='bob@example.com', password='password123')

        workspace = Workspace.objects.create(name='Semester Demo Workspace', owner=alice)
        WorkspaceMembership.objects.create(
            workspace=workspace,
            user=alice,
            role=WorkspaceMembership.ROLE_EDITOR,
        )
        WorkspaceMembership.objects.create(
            workspace=workspace,
            user=bob,
            role=WorkspaceMembership.ROLE_VIEWER,
        )

        root_page = Page.objects.create(
            title='Capstone Home',
            workspace=workspace,
            owner=alice,
        )
        sprint_page = Page.objects.create(
            title='Sprint Tasks',
            workspace=workspace,
            owner=alice,
            parent_page=root_page,
        )
        shared_page = Page.objects.create(
            title='Shared Notes',
            workspace=workspace,
            owner=alice,
        )

        PageShare.objects.create(page=shared_page, user=bob, role=PageShare.ROLE_EDITOR)

        Block.objects.create(page=root_page, block_type=Block.TYPE_HEADING, content='Notion Clone MVP', position=0)
        Block.objects.create(page=root_page, block_type=Block.TYPE_TEXT, content='Demo-ready backend progress', position=1)
        Block.objects.create(page=sprint_page, block_type=Block.TYPE_TODO, content='Finish API tests', is_checked=False, position=0)
        Block.objects.create(page=sprint_page, block_type=Block.TYPE_BULLET, content='Record demo video', position=1)
        Block.objects.create(page=shared_page, block_type=Block.TYPE_TEXT, content='Bob can edit this page', position=0)

        self.stdout.write(self.style.SUCCESS('Demo data seeded.'))
        self.stdout.write('Users: alice/password123, bob/password123')
