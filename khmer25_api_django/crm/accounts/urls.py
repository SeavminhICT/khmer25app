from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CategoryViewSet, ProductViewSet, UserViewSet, CartViewSet, OrderViewSet,
    OrderItemViewSet,  BannerViewSet,
    SupplierViewSet, register_user, login_user, get_user_info,
    telegram_webhook,
)

router = DefaultRouter()
router.register(r'products', ProductViewSet)

router.register(r'categories', CategoryViewSet)
router.register(r'users', UserViewSet)
router.register(r'carts', CartViewSet)
router.register(r'orders', OrderViewSet)
router.register(r'order-items', OrderItemViewSet)
router.register(r'banner', BannerViewSet, basename="banner")
router.register(r'suppliers', SupplierViewSet)                  


urlpatterns = [
    path("", include(router.urls)),
    # Auth endpoints reachable at /api/register and /api/login
    path("register/", register_user, name="register-user"),
    path("register", register_user, name="register-user-ns"),
    path("login/", login_user, name="login-user"),
    path("login", login_user, name="login-user-ns"),
    path("user/", get_user_info, name="get-user-info"),
    path("user", get_user_info, name="get-user-info-ns"),
    path("user/<int:pk>/", get_user_info, name="get-user-info-pk"),
    path("telegram/webhook", telegram_webhook, name="telegram-webhook"),
    path("telegram/webhook/", telegram_webhook, name="telegram-webhook-slash"),
]
