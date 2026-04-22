from django.db import models
from django.contrib.auth.models import User


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class Workspace(TimeStampedModel):
    name = models.CharField(max_length=150)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='owned_workspaces')
    members = models.ManyToManyField(User, through='WorkspaceMembership', related_name='workspaces')

    def __str__(self):
        return f'{self.name} ({self.owner.username})'


class WorkspaceMembership(TimeStampedModel):
    ROLE_VIEWER = 'viewer'
    ROLE_EDITOR = 'editor'
    ROLE_CHOICES = [
        (ROLE_VIEWER, 'Viewer'),
        (ROLE_EDITOR, 'Editor'),
    ]

    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE, related_name='memberships')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_memberships')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=ROLE_EDITOR)

    class Meta:
        unique_together = ('workspace', 'user')

    def __str__(self):
        return f'{self.user.username} in {self.workspace.name} ({self.role})'


class Page(TimeStampedModel):
    title = models.CharField(max_length=255)
    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE, related_name='pages')
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='pages')
    parent_page = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='children',
    )
    is_archived = models.BooleanField(default=False)

    class Meta:
        ordering = ['title', 'id']

    def __str__(self):
        return self.title


class PageShare(TimeStampedModel):
    ROLE_VIEWER = 'viewer'
    ROLE_EDITOR = 'editor'
    ROLE_CHOICES = [
        (ROLE_VIEWER, 'Viewer'),
        (ROLE_EDITOR, 'Editor'),
    ]

    page = models.ForeignKey(Page, on_delete=models.CASCADE, related_name='shares')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='shared_pages')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=ROLE_VIEWER)

    class Meta:
        unique_together = ('page', 'user')

    def __str__(self):
        return f'{self.page.title} -> {self.user.username} ({self.role})'


class Block(TimeStampedModel):
    TYPE_TEXT = 'text'
    TYPE_HEADING = 'heading'
    TYPE_TODO = 'todo'
    TYPE_BULLET = 'bullet'
    TYPE_CHOICES = [
        (TYPE_TEXT, 'Text'),
        (TYPE_HEADING, 'Heading'),
        (TYPE_TODO, 'Todo'),
        (TYPE_BULLET, 'Bullet'),
    ]

    page = models.ForeignKey(Page, on_delete=models.CASCADE, related_name='blocks')
    block_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default=TYPE_TEXT)
    content = models.TextField(blank=True)
    is_checked = models.BooleanField(default=False)
    position = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['position', 'id']

    def __str__(self):
        return f'{self.page.title} [{self.block_type}] #{self.position}'
