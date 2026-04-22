from django.contrib import admin

from notion.models import Block, Page, PageShare, Workspace, WorkspaceMembership


@admin.register(Workspace)
class WorkspaceAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'owner', 'created_at', 'updated_at')
    search_fields = ('name', 'owner__username')


@admin.register(WorkspaceMembership)
class WorkspaceMembershipAdmin(admin.ModelAdmin):
    list_display = ('id', 'workspace', 'user', 'role', 'created_at')
    list_filter = ('role',)
    search_fields = ('workspace__name', 'user__username')


@admin.register(Page)
class PageAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'workspace', 'owner', 'parent_page', 'is_archived', 'created_at')
    list_filter = ('is_archived',)
    search_fields = ('title', 'workspace__name', 'owner__username')


@admin.register(PageShare)
class PageShareAdmin(admin.ModelAdmin):
    list_display = ('id', 'page', 'user', 'role', 'created_at')
    list_filter = ('role',)
    search_fields = ('page__title', 'user__username')


@admin.register(Block)
class BlockAdmin(admin.ModelAdmin):
    list_display = ('id', 'page', 'block_type', 'position', 'is_checked', 'created_at')
    list_filter = ('block_type', 'is_checked')
    search_fields = ('page__title', 'content')
