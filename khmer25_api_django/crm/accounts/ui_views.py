from dataclasses import dataclass
from datetime import datetime, time, timedelta
from functools import wraps
import csv
import io
import re

from django.core.paginator import Paginator
from django.db.models import Count, Sum
from django.db.models import Q
from django.http import HttpResponse, JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils import timezone

from .models import AdminProfile, Banner, Category, Order, OrderItem, Product, User

PAYWAY_SAMPLE_LINK = "https://link.payway.com.kh/aba?id=BC9C1637D99A&dynamic=true&source_caller=sdk&pid=af_app_invites&link_action=abaqr&shortlink=qom57m9s&created_from_app=true&acc=007253721&af_siteid=968860649&userid=BC9C1637D99A&code=099743&c=abaqr&af_referrer_uid=1695695806092-3948219"

ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "123"


def _is_admin_authenticated(request):
    return request.session.get("admin_user") == ADMIN_USERNAME


def require_admin(view_func):
    @wraps(view_func)
    def _wrapped(request, *args, **kwargs):
        if not _is_admin_authenticated(request):
            return redirect("admin-login")
        return view_func(request, *args, **kwargs)

    return _wrapped


@dataclass
class ParsedOrder:
    order_id: str
    customer_name: str
    customer_phone: str
    timestamp: datetime
    total_amount: float
    receipt_url: str
    items: list


TELEGRAM_MESSAGES = [
    (
        "Order ID: ORD-2025-0001 | Customer: Dara Sok (+85512345678) | "
        "Time: 2025-03-08 09:42 | Total: $58.20 | "
        "Img receipt QR: https://via.placeholder.com/160 | "
        "Items: 2x Khmer Cola, 1x Rice Crackers"
    ),
    (
        "Order ID: ORD-2025-0002 | Customer: Lina Vann (+85598765432) | "
        "Time: 2025-03-08 11:15 | Total: $120.00 | "
        "Img receipt QR: https://via.placeholder.com/160 | "
        "Items: 1x Herbal Tea, 3x Khmer Cola"
    ),
    (
        "Order ID: ORD-2025-0003 | Customer: Chan Dara (+85511223344) | "
        "Time: 2025-03-07 18:30 | Total: $32.50 | "
        "Img receipt QR: https://via.placeholder.com/160 | "
        "Items: 2x Banana Chips"
    ),
]


def _parse_telegram_message(message):
    order_match = re.search(r"Order ID:\s*([^|]+)", message)
    customer_match = re.search(r"Customer:\s*([^()]+)\(([^)]+)\)", message)
    time_match = re.search(r"Time:\s*([^|]+)", message)
    total_match = re.search(r"Total:\s*\$?([0-9]+(?:\.[0-9]+)?)", message)
    receipt_match = re.search(r"Img\\s*res(?:eipt|cpt)\\s*QR:\s*([^|]+)", message, re.IGNORECASE)
    items_match = re.search(r"Items:\s*(.+)$", message)

    if not (order_match and customer_match and time_match and total_match):
        return None

    raw_time = time_match.group(1).strip()
    parsed_time = None
    for fmt in ("%Y-%m-%d %H:%M", "%Y-%m-%d %H:%M:%S"):
        try:
            parsed_time = datetime.strptime(raw_time, fmt)
            break
        except ValueError:
            continue
    if not parsed_time:
        return None

    local_tz = timezone.get_current_timezone()
    parsed_time = timezone.make_aware(parsed_time, local_tz)

    items = []
    if items_match:
        items = [item.strip() for item in items_match.group(1).split(",") if item.strip()]

    return ParsedOrder(
        order_id=order_match.group(1).strip(),
        customer_name=customer_match.group(1).strip(),
        customer_phone=customer_match.group(2).strip(),
        timestamp=parsed_time,
        total_amount=float(total_match.group(1)),
        receipt_url=receipt_match.group(1).strip() if receipt_match else "",
        items=items,
    )


def _load_sales_orders():
    orders = []
    for message in TELEGRAM_MESSAGES:
        parsed = _parse_telegram_message(message)
        if parsed:
            orders.append(parsed)
    return orders


def login_view(request):
    if _is_admin_authenticated(request):
        return redirect("admin-dashboard")
    error = ""
    if request.method == "POST":
        username = request.POST.get("username", "").strip()
        password = request.POST.get("password", "")
        if username == ADMIN_USERNAME and password == ADMIN_PASSWORD:
            request.session["admin_user"] = ADMIN_USERNAME
            return redirect("admin-dashboard")
        error = "Invalid username or password."
    return render(request, "pages/login.html", {"error": error})


def logout_view(request):
    request.session.flush()
    return redirect("admin-login")


@require_admin
def dashboard_view(request):
    total_sales = (
        Order.objects.aggregate(total=Sum("total_amount")).get("total") or 0
    )
    context = {
        "total_sales": f"{total_sales:,.2f}",
        "total_orders": Order.objects.count(),
        "total_customers": User.objects.count(),
        "total_products": Product.objects.count(),
        "recent_orders": Order.objects.select_related("user")
        .order_by("-created_at")[:5],
    }
    return render(request, "pages/dashboard.html", context)


@require_admin
def products_list_view(request):
    qs = Product.objects.select_related("category").order_by("-id")
    query = request.GET.get("q", "").strip()
    category_id = request.GET.get("category")
    if query:
        qs = qs.filter(name__icontains=query)
    if category_id:
        qs = qs.filter(category_id=category_id)
    paginator = Paginator(qs, 10)
    page_param = request.GET.get("page") or "1"
    try:
        page_obj = paginator.page(page_param)
    except Exception:
        page_obj = paginator.page(1)
    context = {
        "page_obj": page_obj,
        "categories": Category.objects.all().order_by("title_en"),
        "query": query,
        "selected_category": category_id or "",
        "prev_page": page_obj.previous_page_number() if page_obj.has_previous() else None,
        "next_page": page_obj.next_page_number() if page_obj.has_next() else None,
    }
    return render(request, "pages/products/list.html", context)


@require_admin
def products_form_view(request):
    categories = Category.objects.all().order_by("title_en")
    if request.method == "POST":
        name = request.POST.get("name", "").strip()
        category_id = request.POST.get("category")
        price = request.POST.get("price") or "0"
        currency = request.POST.get("currency") or "USD"
        quantity = request.POST.get("quantity") or "0"
        tag = request.POST.get("tag", "").strip()
        payway_link = request.POST.get("payway_link", "").strip() or PAYWAY_SAMPLE_LINK
        image = request.FILES.get("image")
        if name and category_id:
            product = Product.objects.create(
                name=name,
                category_id=category_id,
                price=price,
                currency=currency,
                quantity=quantity,
                tag=tag,
                payway_link=payway_link,
                image=image,
            )
            return redirect(f"{reverse('admin-products-detail', kwargs={'product_id': product.id})}?status=created")
    return render(
        request,
        "pages/products/form.html",
        {"categories": categories},
    )


@require_admin
def products_edit_view(request, product_id):
    product = get_object_or_404(Product, pk=product_id)
    categories = Category.objects.all().order_by("title_en")
    if request.method == "POST":
        product.name = request.POST.get("name", "").strip()
        product.category_id = request.POST.get("category") or product.category_id
        product.price = request.POST.get("price") or product.price
        product.currency = request.POST.get("currency") or product.currency
        product.quantity = request.POST.get("quantity") or product.quantity
        product.tag = request.POST.get("tag", "").strip()
        product.payway_link = request.POST.get("payway_link", "").strip() or PAYWAY_SAMPLE_LINK
        image = request.FILES.get("image")
        if image:
            product.image = image
        product.save()
        return redirect(f"{reverse('admin-products-detail', kwargs={'product_id': product.id})}?status=updated")
    return render(
        request,
        "pages/products/form.html",
        {"categories": categories, "product": product, "is_edit": True},
    )


@require_admin
def products_delete_view(request, product_id):
    if request.method == "POST":
        Product.objects.filter(pk=product_id).delete()
        return redirect(f"{reverse('admin-products-list')}?status=deleted")
    return redirect("admin-products-list")


@require_admin
def products_detail_view(request, product_id):
    product = get_object_or_404(Product.objects.select_related("category"), pk=product_id)
    stock_history = (
        OrderItem.objects.filter(product=product)
        .select_related("order")
        .order_by("-id")[:10]
    )
    context = {
        "product": product,
        "stock_history": stock_history,
    }
    return render(request, "pages/products/detail.html", context)


@require_admin
def categories_list_view(request):
    if request.method == "POST":
        name_en = request.POST.get("title_en", "").strip()
        name_kh = request.POST.get("title_kh", "").strip()
        image = request.FILES.get("image")
        category_id = request.POST.get("category_id")
        if name_en and name_kh:
            if category_id:
                Category.objects.filter(pk=category_id).update(
                    title_en=name_en,
                    title_kh=name_kh,
                )
                if image:
                    category = Category.objects.get(pk=category_id)
                    category.image = image
                    category.save()
                return redirect(f"{reverse('admin-categories')}?status=updated")
            Category.objects.create(title_en=name_en, title_kh=name_kh, image=image)
            return redirect(f"{reverse('admin-categories')}?status=created")
    return render(
        request,
        "pages/categories/list.html",
        {"categories": Category.objects.all().order_by("title_en")},
    )


@require_admin
def categories_delete_view(request, category_id):
    if request.method == "POST":
        Category.objects.filter(pk=category_id).delete()
        return redirect(f"{reverse('admin-categories')}?status=deleted")
    return redirect("admin-categories")


@require_admin
def orders_list_view(request):
    qs = Order.objects.select_related("user").order_by("-created_at")
    status_filter = request.GET.get("status")
    if status_filter:
        qs = qs.filter(order_status=status_filter)
    context = {
        "orders": qs[:50],
        "status_filter": status_filter or "",
    }
    return render(request, "pages/orders/list.html", context)


@require_admin
def orders_detail_view(request, order_id):
    order = get_object_or_404(Order.objects.select_related("user"), pk=order_id)
    if request.method == "POST":
        if request.POST.get("action") == "mark_delivered":
            order.order_status = "completed"
            order.payment_status = "paid"
            order.save(update_fields=["order_status", "payment_status"])
            if request.headers.get("x-requested-with") == "XMLHttpRequest":
                return JsonResponse({"status": "ok"})
            return redirect(f"{reverse('admin-orders-detail', kwargs={'order_id': order.id})}?status=delivered")
    items = OrderItem.objects.filter(order=order).select_related("product")
    subtotal = sum((item.subtotal or 0) for item in items)
    context = {
        "order": order,
        "items": items,
        "subtotal": subtotal,
        "payments": order.payments.all(),
    }
    return render(request, "pages/orders/detail.html", context)


@require_admin
def customers_list_view(request):
    customers = (
        User.objects.annotate(
            orders_count=Count("orders"),
            total_spend=Sum("orders__total_amount"),
        )
        .order_by("-orders_count", "username")
    )
    return render(request, "pages/customers/list.html", {"customers": customers})


@require_admin
def customers_detail_view(request, customer_id):
    customer = get_object_or_404(User, pk=customer_id)
    orders = Order.objects.filter(user=customer).order_by("-created_at")
    stats = orders.aggregate(total_spend=Sum("total_amount"))
    total_spend = stats.get("total_spend") or 0
    avg_order = total_spend / orders.count() if orders.count() else 0
    context = {
        "customer": customer,
        "orders": orders,
        "total_spend": total_spend,
        "avg_order": avg_order,
    }
    return render(request, "pages/customers/detail.html", context)


@require_admin
def users_roles_view(request):
    return render(request, "pages/users/list.html")


@require_admin
def settings_view(request):
    return render(request, "pages/settings.html")


@require_admin
def profile_view(request):
    profile = AdminProfile.objects.first()
    if not profile:
        profile = AdminProfile.objects.create(
            full_name="Yon Chandaneth",
            email="admin@khmer25.com",
            phone="",
            role="Admin",
        )
    if request.method == "POST":
        profile.full_name = request.POST.get("full_name", "").strip() or profile.full_name
        profile.email = request.POST.get("email", "").strip() or profile.email
        profile.phone = request.POST.get("phone", "").strip()
        avatar = request.FILES.get("avatar")
        if avatar:
            profile.avatar = avatar
        profile.save()
        return redirect(f"{reverse('admin-profile')}?status=updated")
    return render(request, "pages/profile/index.html", {"profile": profile})


@require_admin
def sales_report_view(request):
    local_now = timezone.localtime()
    preset = request.GET.get("preset", "today")
    start_date = request.GET.get("start")
    end_date = request.GET.get("end")
    query = request.GET.get("q", "").strip()
    time_slot = request.GET.get("time_slot", "all").strip().lower()

    if preset == "last7":
        start = local_now.date() - timedelta(days=6)
        end = local_now.date()
    elif preset == "month":
        start = local_now.date().replace(day=1)
        end = local_now.date()
    elif preset == "custom" and start_date and end_date:
        start = datetime.strptime(start_date, "%Y-%m-%d").date()
        end = datetime.strptime(end_date, "%Y-%m-%d").date()
    else:
        start = local_now.date()
        end = local_now.date()
        preset = "today"

    tz = timezone.get_current_timezone()
    start_dt = timezone.make_aware(datetime.combine(start, time.min), tz)
    end_dt = timezone.make_aware(datetime.combine(end, time.max), tz)

    orders_qs = (
        Order.objects.select_related("user")
        .prefetch_related("items", "payments")
        .filter(created_at__range=(start_dt, end_dt))
    )

    if query:
        orders_qs = orders_qs.filter(
            Q(order_code__icontains=query) | Q(phone__icontains=query)
        )

    orders_qs = list(orders_qs.order_by("-created_at"))

    if time_slot != "all":
        def _match_slot(dt):
            local_dt = timezone.localtime(dt)
            hour = local_dt.hour
            if time_slot == "morning":
                return 6 <= hour < 12
            if time_slot == "afternoon":
                return 12 <= hour < 18
            if time_slot == "evening":
                return 18 <= hour < 24
            return True

        orders_qs = [order for order in orders_qs if _match_slot(order.created_at)]

    orders = []
    for order in orders_qs:
        items = list(order.items.all())
        receipt = order.payments.first()
        orders.append(
            {
                "order_id": order.order_code or str(order.id),
                "customer_name": order.customer_name or "Guest",
                "customer_phone": order.phone,
                "timestamp": order.created_at,
                "total_amount": float(order.total_amount),
                "receipt_url": receipt.receipt_image.url if receipt and receipt.receipt_image else "",
                "items": [
                    f"{item.quantity}x {item.product_name or item.product.name}"
                    for item in items
                ],
            }
        )

    total_revenue = (
        Order.objects.aggregate(total=Sum("total_amount")).get("total") or 0
    )
    total_orders = Order.objects.count()
    aov = (total_revenue / total_orders) if total_orders else 0
    todays_count = Order.objects.filter(
        created_at__date=local_now.date()
    ).count()

    if request.GET.get("export") == "csv":
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(
            [
                "Order ID",
                "Customer Name",
                "Customer Phone",
                "Date Time",
                "Total Amount",
                "Receipt URL",
                "Items",
            ]
        )
        for order in orders:
            writer.writerow(
                [
                    order["order_id"],
                    order["customer_name"],
                    order["customer_phone"],
                    timezone.localtime(order["timestamp"]).strftime("%Y-%m-%d %H:%M"),
                    f"{order['total_amount']:.2f}",
                    order["receipt_url"],
                    "; ".join(order["items"]),
                ]
            )
        response = HttpResponse(output.getvalue(), content_type="text/csv")
        response["Content-Disposition"] = "attachment; filename=sales_report.csv"
        return response

    context = {
        "orders": orders,
        "preset": preset,
        "start_date": start.strftime("%Y-%m-%d"),
        "end_date": end.strftime("%Y-%m-%d"),
        "query": query,
        "time_slot": time_slot,
        "todays_count": todays_count,
        "total_orders": total_orders,
        "total_revenue": total_revenue,
        "aov": aov,
    }
    return render(request, "pages/sales/report.html", context)


@require_admin
def banners_list_view(request):
    banners = Banner.objects.all().order_by("-id")
    return render(request, "pages/banners/list.html", {"banners": banners})


@require_admin
def banners_form_view(request, banner_id=None):
    banner = None
    if banner_id:
        banner = get_object_or_404(Banner, pk=banner_id)
    if request.method == "POST":
        image = request.FILES.get("image")
        if banner and image:
            banner.image = image
            banner.save()
            return redirect(f"{reverse('admin-banners-list')}?status=updated")
        if not banner and image:
            Banner.objects.create(image=image)
            return redirect(f"{reverse('admin-banners-list')}?status=created")
    return render(request, "pages/banners/form.html", {"banner": banner})


@require_admin
def banners_delete_view(request, banner_id):
    banner = get_object_or_404(Banner, pk=banner_id)
    if request.method == "POST":
        banner.delete()
        return redirect(f"{reverse('admin-banners-list')}?status=deleted")
    return redirect("admin-banners-list")
