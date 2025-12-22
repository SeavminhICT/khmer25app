from django.urls import path
from . import ui_views

urlpatterns = [
    path("", ui_views.dashboard_view, name="admin-dashboard"),
    path("login/", ui_views.login_view, name="admin-login"),
    path("logout/", ui_views.logout_view, name="admin-logout"),
    path("dashboard/", ui_views.dashboard_view, name="admin-dashboard-alt"),
    path("dashbord/", ui_views.dashboard_view, name="admin-dashboard-legacy"),
    path("products/", ui_views.products_list_view, name="admin-products-list"),
    path("products/new/", ui_views.products_form_view, name="admin-products-new"),
    path("products/<int:product_id>/edit/", ui_views.products_edit_view, name="admin-products-edit"),
    path("products/<int:product_id>/delete/", ui_views.products_delete_view, name="admin-products-delete"),
    path("products/<int:product_id>/", ui_views.products_detail_view, name="admin-products-detail"),
    path("categories/", ui_views.categories_list_view, name="admin-categories"),
    path("categories/<int:category_id>/delete/", ui_views.categories_delete_view, name="admin-categories-delete"),
    path("orders/", ui_views.orders_list_view, name="admin-orders-list"),
    path("orders/<int:order_id>/", ui_views.orders_detail_view, name="admin-orders-detail"),
    path("customers/", ui_views.customers_list_view, name="admin-customers-list"),
    path("customers/<int:customer_id>/", ui_views.customers_detail_view, name="admin-customers-detail"),
    path("users/", ui_views.users_roles_view, name="admin-users-roles"),
    path("banners/", ui_views.banners_list_view, name="admin-banners-list"),
    path("banners/new/", ui_views.banners_form_view, name="admin-banners-new"),
    path("banners/<int:banner_id>/edit/", ui_views.banners_form_view, name="admin-banners-edit"),
    path("banners/<int:banner_id>/delete/", ui_views.banners_delete_view, name="admin-banners-delete"),
    path("reports/sales/", ui_views.sales_report_view, name="admin-sales-report"),
    path("settings/", ui_views.settings_view, name="admin-settings"),
    path("profile/", ui_views.profile_view, name="admin-profile"),
]
