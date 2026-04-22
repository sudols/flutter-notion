from notion.models import PageShare, WorkspaceMembership


def get_workspace_role(user, workspace):
    if workspace.owner_id == user.id:
        return WorkspaceMembership.ROLE_EDITOR

    membership = WorkspaceMembership.objects.filter(workspace=workspace, user=user).first()
    if not membership:
        return None
    return membership.role


def can_view_workspace(user, workspace):
    return get_workspace_role(user, workspace) is not None


def can_edit_workspace(user, workspace):
    role = get_workspace_role(user, workspace)
    return role == WorkspaceMembership.ROLE_EDITOR


def get_page_role(user, page):
    if page.owner_id == user.id:
        return PageShare.ROLE_EDITOR

    roles = []
    workspace_role = get_workspace_role(user, page.workspace)
    if workspace_role:
        roles.append(workspace_role)

    share = PageShare.objects.filter(page=page, user=user).first()
    if share:
        roles.append(share.role)

    if not roles:
        return None

    if PageShare.ROLE_EDITOR in roles:
        return PageShare.ROLE_EDITOR
    return PageShare.ROLE_VIEWER


def can_view_page(user, page):
    return get_page_role(user, page) is not None


def can_edit_page(user, page):
    role = get_page_role(user, page)
    return role == PageShare.ROLE_EDITOR
