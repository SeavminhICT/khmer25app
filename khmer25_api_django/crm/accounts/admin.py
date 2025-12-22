from decimal import Decimal
import requests
from django.contrib import admin
from django import forms
from .models import (
    Category,
    Product,
    User,
    Cart,
    Order,
    OrderItem,
    Supplier,
    Banner,
)
from .views import TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID

# Register models
admin.site.register(Category)
admin.site.register(User)
admin.site.register(Cart)
admin.site.register(Supplier)
admin.site.register(Banner)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    search_fields = ("name",)


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    search_fields = ("order_code", "customer_name", "phone")
    list_display = (
        "order_code",
        "customer_name",
        "total_amount",
        "order_status",
        "payment_status",
        "created_at",
    )
    actions = ("mark_confirmed", "mark_shipping", "mark_completed", "mark_cancelled")

    def _notify_status(self, order: Order, status_text: str):
        try:
            msg = f"Order {order.order_code} updated: {status_text}"
            base = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"
            requests.post(
                f"{base}/sendMessage",
                json={"chat_id": TELEGRAM_CHAT_ID, "text": msg},
                timeout=10,
            )
        except Exception:
            pass

    def _bulk_update(self, request, queryset, order_status, payment_status=None, label="updated"):
        payment_status = payment_status or "pending"
        count = 0
        for order in queryset:
            order.order_status = order_status
            order.payment_status = payment_status
            order.save(update_fields=["order_status", "payment_status"])
            self._notify_status(order, f"{order_status} / {payment_status}")
            count += 1
        self.message_user(request, f"{count} orders {label}.")

    def mark_confirmed(self, request, queryset):
        self._bulk_update(request, queryset, "confirmed", "paid", label="confirmed")

    def mark_shipping(self, request, queryset):
        self._bulk_update(request, queryset, "shipping", payment_status="paid", label="marked as shipping")

    def mark_completed(self, request, queryset):
        self._bulk_update(request, queryset, "completed", payment_status="paid", label="marked as completed")

    def mark_cancelled(self, request, queryset):
        self._bulk_update(request, queryset, "cancelled", payment_status="failed", label="cancelled")

    mark_confirmed.short_description = "Confirm & mark paid"
    mark_shipping.short_description = "Mark as shipping"
    mark_completed.short_description = "Mark as delivered/completed"
    mark_cancelled.short_description = "Cancel & mark failed"


class OrderItemAdminForm(forms.ModelForm):
    """
    Prefills snapshot fields from the selected product so staff do not
    have to type the price or name manually when adding order items.
    """

    class Meta:
        model = OrderItem
        fields = "__all__"

    def clean(self):
        cleaned = super().clean()
        product = cleaned.get("product")

        if product:
            # If price or product_name are empty, copy from the product
            if not cleaned.get("product_name"):
                cleaned["product_name"] = product.name
            price = cleaned.get("price")
            if price in (None, ""):
                cleaned["price"] = product.price

        return cleaned

    def save(self, commit=True):
        instance: OrderItem = super().save(commit=False)

        if instance.product:
            if not instance.product_name:
                instance.product_name = instance.product.name
            if instance.price is None:
                instance.price = instance.product.price
            instance.subtotal = (instance.price or Decimal("0")) * instance.quantity

        if commit:
            instance.save()
        return instance


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    form = OrderItemAdminForm
    list_display = ("id", "order", "product_name", "price", "quantity", "subtotal")
    autocomplete_fields = ("order", "product")
    list_filter = ("order",)
    search_fields = ("product__name", "order__order_code", "order__customer_name")
