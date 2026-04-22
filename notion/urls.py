from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from notion.views import BlockViewSet, MeView, PageViewSet, RegisterView, WorkspaceViewSet

router = DefaultRouter()
router.register('workspaces', WorkspaceViewSet, basename='workspace')
router.register('pages', PageViewSet, basename='page')
router.register('blocks', BlockViewSet, basename='block')

urlpatterns = [
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/me/', MeView.as_view(), name='me'),
    path('', include(router.urls)),
]
