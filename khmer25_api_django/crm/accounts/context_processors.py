from .models import Order


def admin_notifications(request):
    try:
        new_orders = Order.objects.filter(order_status="pending").count()
    except Exception:
        new_orders = 0
    return {"new_orders_count": new_orders}
