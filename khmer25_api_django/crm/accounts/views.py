import hashlib
import hmac
import json
import os
import secrets
from decimal import Decimal
from typing import Optional
from urllib.parse import urlencode, urlparse, parse_qsl, urlunparse, quote

import requests
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings
from django.contrib.auth.hashers import check_password
from django.db import transaction
from django.urls import reverse
from django.utils import timezone
from django.utils.html import escape
from django.views.decorators.csrf import csrf_exempt
from rest_framework import status, viewsets
from rest_framework.decorators import (
    action,
    api_view,
    authentication_classes,
    permission_classes,
    parser_classes,
)
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import (
    AllowAny,
    IsAuthenticated,
    IsAuthenticatedOrReadOnly,
)
from rest_framework.response import Response
from .models import (
    Category,
    Product,
    User,
    Cart,
    Order,
    OrderItem,
    Payment,
    Supplier,
    AuthToken,
    Banner,
    PaymentTransaction,
)
from .serializers import (
    CategorySerializer,
    ProductSerializer,
    UserSerializer,
    UserPublicSerializer,
    CartSerializer,
    OrderSerializer,
    OrderItemSerializer,
    SupplierSerializer,
    BannerSerializer,
    PaymentSerializer,
)
from .authentication import AuthTokenAuthentication

# Telegram configuration (provided by client)
TELEGRAM_BOT_TOKEN = "8342567023:AAE_GIwaUb5yEoHHlHRFdz0jzsNjc6ksClM"
TELEGRAM_CHAT_ID = "-1003393371435"


def _get_telegram_config():
    token = getattr(settings, "TELEGRAM_BOT_TOKEN", None) or TELEGRAM_BOT_TOKEN
    chat_id = getattr(settings, "TELEGRAM_CHAT_ID", None) or TELEGRAM_CHAT_ID
    return token, chat_id


def _format_amount(value: Decimal) -> str:
    return f"{Decimal(str(value)).quantize(Decimal('0.01'))}"

def _amount_matches(actual: Decimal, expected: Decimal) -> bool:
    try:
        return (actual - expected).copy_abs() <= Decimal("0.01")
    except Exception:
        return False

def _is_payway_success(status_text: str, data: dict) -> bool:
    if status_text in {"SUCCESS", "SUCCEEDED", "APPROVED", "PAID", "COMPLETED", "OK"}:
        return True
    status_code = str(
        data.get("status_code")
        or data.get("response_code")
        or data.get("result")
        or ""
    ).strip().upper()
    return status_code in {"0", "00", "000", "SUCCESS", "APPROVED", "OK"}

def _with_amount_url(url: str, amount: Decimal) -> str:
    if not url:
        return ""
    try:
        parsed = urlparse(url)
        params = dict(parse_qsl(parsed.query, keep_blank_values=True))
        params["amount"] = _format_amount(amount)
        return urlunparse(parsed._replace(query=urlencode(params)))
    except Exception:
        return url


def _compute_payway_hash(payload: dict, api_key: str) -> str:
    """
    PayWay HMAC signature: merchant_id + order_id + amount + currency hashed with API key.
    """
    base_string = f"{payload.get('merchant_id', '')}{payload.get('order_id', '')}{payload.get('amount', '')}{payload.get('currency', '')}"
    return hmac.new(api_key.encode("utf-8"), base_string.encode("utf-8"), hashlib.sha512).hexdigest()

def _normalize_payment_method(method: Optional[str]) -> Optional[str]:
    if not method:
        return None
    val = str(method).strip().upper()
    mapping = {
        "COD": "COD",
        "CASH_ON_DELIVERY": "COD",
        "ABA": "ABA_QR",
        "ABA_QR": "ABA_QR",
        "QR": "ABA_QR",
        "KHQR": "ABA_QR",
        "AC": "AC_QR",
        "AC_QR": "AC_QR",
        "ABA_PAYWAY": "ABA_PAYWAY",
    }
    return mapping.get(val)

def _get_qr_code_url(method: str, request=None) -> str:
    qr_map = getattr(settings, "PAYMENT_QR_CODE_URLS", {}) or {}
    method = (method or "").upper()
    url = qr_map.get(method)
    if not url:
        if method == "ABA_QR":
            url = getattr(settings, "ABA_QR_CODE_URL", "") or ""
        elif method == "AC_QR":
            url = getattr(settings, "AC_QR_CODE_URL", "") or ""
    if not url:
        return ""
    if request:
        try:
            return request.build_absolute_uri(url)
        except Exception:
            return url
    return url

def _build_qr_image_url(data: str) -> str:
    template = getattr(settings, "PAYMENT_QR_GENERATOR_URL", "") or ""
    if not template or "{data}" not in template:
        return ""
    return template.format(data=quote(data, safe=""))

def _validate_receipt_upload(upload):
    if not upload:
        return "Receipt file is required."
    max_mb = getattr(settings, "PAYMENT_RECEIPT_MAX_MB", 5)
    try:
        max_bytes = int(max_mb) * 1024 * 1024
    except Exception:
        max_bytes = 5 * 1024 * 1024
    if upload.size > max_bytes:
        return f"File too large. Max size is {max_mb} MB."
    allowed_exts = {".jpg", ".jpeg", ".png", ".pdf"}
    ext = os.path.splitext(upload.name)[1].lower()
    if ext not in allowed_exts:
        return "Unsupported file type. Use jpg, png, or pdf."
    # Some clients send a generic content type; extension check is primary.
    return None

def _broadcast_order_event(order: Order, event_type: str, extra: Optional[dict] = None):
    channel_layer = get_channel_layer()
    if not channel_layer:
        return
    payload = {
        "type": "order.event",
        "event": event_type,
        "order_id": order.id,
        "order_code": order.order_code,
        "order_status": order.order_status,
        "payment_status": order.payment_status,
        "payment_method": order.payment_method,
        "total_amount": str(order.total_amount),
        "created_at": timezone.localtime(order.created_at).isoformat(),
    }
    if extra:
        payload.update(extra)
    async_to_sync(channel_layer.group_send)("orders", payload)
    if order.user_id:
        async_to_sync(channel_layer.group_send)(f"user_{order.user_id}", payload)

def _get_order_by_identifier(identifier: Optional[str]) -> Optional[Order]:
    if not identifier:
        return None
    identifier = str(identifier).strip()
    order = Order.objects.filter(order_code=identifier).first()
    if order:
        return order
    try:
        return Order.objects.get(pk=int(identifier))
    except (ValueError, Order.DoesNotExist):
        return None


def _normalize_payload_dict(data) -> dict:
    """
    Convert DRF/Django request data to a plain dict for JSONField storage.
    """
    if isinstance(data, dict):
        return {k: data.get(k) for k in data.keys()}
    try:
        return dict(data)
    except Exception:
        return {}

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.select_related("category").all()
    serializer_class = ProductSerializer
    parser_classes = [MultiPartParser, FormParser]
    authentication_classes = [AuthTokenAuthentication]
    permission_classes = [IsAuthenticatedOrReadOnly]

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [AllowAny]

class CartViewSet(viewsets.ModelViewSet):
    queryset = Cart.objects.all()
    serializer_class = CartSerializer
    permission_classes = [AllowAny]      # <--- IMPORTANT


class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all().order_by("-created_at")
    serializer_class = OrderSerializer
    parser_classes = [MultiPartParser, FormParser]
    authentication_classes = [AuthTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in ("approve", "reject"):
            return [AllowAny()]
        return [IsAuthenticated()]

    def get_queryset(self):
        qs = super().get_queryset()
        user = getattr(self.request, "user", None)
        if not getattr(user, "is_authenticated", False):
            return qs.none()
        return qs.filter(user=user).order_by("-created_at")

    @action(detail=True, methods=["post"], url_path="approve", permission_classes=[AllowAny])
    def approve(self, request, pk=None):
        order = self.get_object()
        processed, msg = _apply_order_decision(order, "approve")
        status_code = status.HTTP_200_OK
        return Response(
            {
                "detail": msg,
                "order_status": order.order_status,
                "payment_status": order.payment_status,
                "processed": processed,
            },
            status=status_code,
        )

    @action(detail=True, methods=["post"], url_path="reject", permission_classes=[AllowAny])
    def reject(self, request, pk=None):
        order = self.get_object()
        processed, msg = _apply_order_decision(order, "reject")
        status_code = status.HTTP_200_OK
        return Response(
            {
                "detail": msg,
                "order_status": order.order_status,
                "payment_status": order.payment_status,
                "processed": processed,
            },
            status=status_code,
        )

    def create(self, request, *args, **kwargs):
        """
        Accepts multipart form-data with:
          - payload: JSON string containing order + items
          - receipt: optional image upload
        """
        try:
            payload_raw = request.data.get("payload")
            data = json.loads(payload_raw) if payload_raw else request.data
        except json.JSONDecodeError:
            return Response(
                {"detail": "Invalid JSON in payload."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        items = data.get("items") or []
        if not items:
            return Response(
                {"detail": "Order items are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        payment_method = self._normalize_payment_method(
            data.get("payment_method")
        )
        if not payment_method:
            return Response(
                {"detail": "Unsupported payment method."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # compute totals
        total = Decimal("0")
        product_items = []
        for item in items:
            try:
                qty = int(item.get("qty") or item.get("quantity") or 0)
                price = Decimal(str(item.get("price") or "0"))
            except Exception:
                return Response(
                    {"detail": f"Invalid price/quantity in item {item}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if qty <= 0:
                continue
            total += price * qty
            product_items.append((item, qty, price))

        if total <= 0:
            return Response(
                {"detail": "Order total must be greater than zero."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = getattr(request, "user", None)
        if not getattr(user, "is_authenticated", False):
            user = None

        # Status defaults based on payment method
        is_cod = payment_method == "COD"
        payment_status = "pending"  # represents unpaid/awaiting verification
        order_status = "confirmed" if is_cod else "pending"

        order = Order.objects.create(
            user=user,
            customer_name=data.get("name") or data.get("customer_name") or "",
            phone=data.get("phone") or "",
            address=data.get("address") or "",
            total_amount=total,
            payment_method=payment_method,
            payment_status=payment_status,
            order_status=order_status,
            note=data.get("note") or "",
        )

        for item, qty, price in product_items:
            product_id = item.get("id")
            try:
                product_obj = Product.objects.get(pk=int(product_id))
            except (TypeError, ValueError, Product.DoesNotExist):
                return Response(
                    {"detail": f"Product not found for item {item}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            OrderItem.objects.create(
                order=order,
                product=product_obj,
                product_name=item.get("title") or "",
                price=price,
                quantity=qty,
            )

        receipt_file = request.data.get("receipt")
        if receipt_file:
            Payment.objects.create(
                order=order,
                method=payment_method,
                amount=total,
                receipt_image=receipt_file,
                receipt_uploaded_at=timezone.now(),
                status="pending",
            )

        if payment_method == "COD":
            self._send_telegram_notification(order, request)

        _broadcast_order_event(order, "created")

        serializer = self.get_serializer(order)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def _normalize_payment_method(self, method: Optional[str]) -> Optional[str]:
        return _normalize_payment_method(method)

    def _send_telegram_notification(self, order: Order, request):
        """
        Push order details to Telegram chat with inline Approve/Reject buttons.
        """
        try:
            token, chat_id = _get_telegram_config()
            if not token or not chat_id:
                return

            receipt_file = None
            receipt_url = None
            payment = order.payments.first()
            if payment and payment.receipt_image:
                try:
                    # Prefer sending the binary to Telegram to avoid inaccessible hostnames
                    receipt_file = payment.receipt_image.path
                except Exception:
                    receipt_file = None
                if not receipt_file:
                    try:
                        receipt_url = request.build_absolute_uri(payment.receipt_image.url)
                    except Exception:
                        receipt_url = payment.receipt_image.url

            created_at = timezone.localtime(order.created_at).strftime("%Y-%m-%d %H:%M")
            title_prefix = "New COD Order" if order.payment_method == "COD" else "New PayByQR Order"
            lines = [
                f"🧾 {title_prefix} ({escape(order.payment_status).title()})",
                f"OrderCode: {escape(order.order_code)}",
                f"Name: {escape(order.customer_name)}",
                f"Phone: {escape(order.phone)}",
                f"Address: {escape(order.address)}",
                f"Payment: {escape(order.payment_method)}",
                f"Status: {escape(order.payment_status)}",
                f"Date: {created_at}",
            ]
            if order.note:
                lines.append(f"Note: {escape(order.note)}")

            lines.append("Items:")
            for item in order.items.all():
                lines.append(
                    f"- {escape(item.product_name)} — QTY {item.quantity} — ${item.price} — Subtotal ${item.subtotal or 0}"
                )

            lines.append(f"Total: ${order.total_amount}")
            if order.payment_method != "COD":
                payway_link = ""
                for item in order.items.select_related("product").all():
                    link = getattr(item.product, "payway_link", "") if item.product else ""
                    if link:
                        payway_link = _with_amount_url(
                            link, Decimal(str(order.total_amount))
                        )
                        break
                if payway_link:
                    lines.append(f"PayWay Link: {escape(payway_link)}")
            lines.append("✅ Receipt Image:" if (receipt_file or receipt_url) else "Receipt: (not provided)")

            text = "\n".join(lines)

            keyboard = None
            if order.payment_method != "COD" and order.payment_status == "pending":
                # Allow admins to resolve pending payments directly from Telegram
                keyboard = {
                    "inline_keyboard": [
                        [
                            {"text": "✅ Approve", "callback_data": f"approve:{order.id}"},
                            {"text": "❌ Reject", "callback_data": f"reject:{order.id}"},
                        ]
                    ]
                }

            base = f"https://api.telegram.org/bot{token}"
            payload = {
                "chat_id": chat_id,
                "parse_mode": "HTML",
            }
            if keyboard:
                payload["reply_markup"] = json.dumps(keyboard)
            if receipt_file:
                with open(receipt_file, "rb") as fh:
                    files = {"photo": fh}
                    payload.update({"caption": text})
                    requests.post(f"{base}/sendPhoto", data=payload, files=files, timeout=10)
            elif receipt_url:
                payload.update({"photo": receipt_url, "caption": text})
                requests.post(f"{base}/sendPhoto", data=payload, timeout=10)
            else:
                payload.update({"text": text})
                # If we have no keyboard (e.g. already paid), still send message
                if keyboard:
                    requests.post(f"{base}/sendMessage", data=payload, timeout=10)
                else:
                    requests.post(
                        f"{base}/sendMessage",
                        json=payload,
                        timeout=10,
                    )
        except Exception as exc:
            # Do not break order creation if Telegram fails
            print(f"[telegram] failed to send notification: {exc}")


def _send_telegram_receipt_upload(order: Order, payment: Payment, request):
    try:
        token, chat_id = _get_telegram_config()
        if not token or not chat_id:
            return
        receipt_file = None
        receipt_url = None
        if payment.receipt_image:
            try:
                receipt_file = payment.receipt_image.path
            except Exception:
                receipt_file = None
            try:
                receipt_url = request.build_absolute_uri(payment.receipt_image.url)
            except Exception:
                receipt_url = payment.receipt_image.url
        created_at = timezone.localtime(order.created_at).strftime("%Y-%m-%d %H:%M")
        status_map = {
            "pending": "⏳ Pending",
            "verified": "✅ Paid",
            "rejected": "❌ Rejected",
            "failed": "❌ Failed",
        }
        status_text = status_map.get(payment.status, payment.status)
        method_labels = {
            "COD": "Cash on Delivery (COD)",
            "ABA_QR": "ABA QR",
            "AC_QR": "AC QR",
            "ABA_PAYWAY": "ABA PayWay",
        }
        method_text = method_labels.get(payment.method, payment.method)
        lines = [
            "🧾 PAYMENT RECEIPT UPLOADED",
            "",
            f"Order Code: {order.order_code}",
            f"Date: {created_at}",
            "",
            "👤 Customer Information",
            f"Name: {order.customer_name or 'Guest'}",
            f"Phone: {order.phone or 'N/A'}",
            f"Address: {order.address or '-'}",
            "",
            "💳 Payment Details",
            f"Method: {method_text}",
            f"Status: {status_text}",
            "",
            "📦 Order Items",
        ]
        index = 1
        for item in order.items.all():
            lines.extend(
                [
                    f"{index}️⃣ {item.product_name}",
                    f"• Qty: {item.quantity}",
                    f"• Price: ${item.price}",
                    f"• Subtotal: ${item.subtotal or 0}",
                    "",
                ]
            )
            index += 1
        lines.extend(
            [
                "💰 Total Amount",
                f"🟢 ${order.total_amount}",
            ]
        )
        if order.note:
            lines.extend(["", "📝 Note", order.note])
        text = "\n".join(lines)
        base = f"https://api.telegram.org/bot{token}"
        if receipt_file:
            with open(receipt_file, "rb") as fh:
                files = {"photo": fh}
                payload = {"chat_id": chat_id, "caption": text}
                requests.post(
                    f"{base}/sendPhoto",
                    data=payload,
                    files=files,
                    timeout=10,
                )
        elif receipt_url:
            payload = {"chat_id": chat_id, "photo": receipt_url, "caption": text}
            requests.post(
                f"{base}/sendPhoto",
                data=payload,
                timeout=10,
            )
        else:
            requests.post(
                f"{base}/sendMessage",
                json={"chat_id": chat_id, "text": text},
                timeout=10,
            )
    except Exception as exc:
        print(f"[telegram] receipt upload notify failed: {exc}")

class OrderItemViewSet(viewsets.ModelViewSet):
    queryset = OrderItem.objects.all()
    serializer_class = OrderItemSerializer







class BannerViewSet(viewsets.ModelViewSet):
    queryset = Banner.objects.all()
    serializer_class = BannerSerializer
    parser_classes = [MultiPartParser, FormParser]





class SupplierViewSet(viewsets.ModelViewSet):
    queryset = Supplier.objects.all()
    serializer_class = SupplierSerializer


@api_view(["POST"])
@authentication_classes([AuthTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_payway_payment(request):
    """
    Admin-triggered endpoint to generate an ABA PayWay payment link for an order.
    """
    merchant_id = getattr(settings, "PAYWAY_MERCHANT_ID", "") or ""
    api_key = getattr(settings, "PAYWAY_API_KEY", "") or ""
    if not merchant_id or not api_key:
        return Response(
            {"detail": "PayWay merchant_id/api_key are not configured."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    data = request.data
    order_ref = data.get("order_id") or data.get("order_code")
    if not order_ref:
        return Response(
            {"detail": "order_id (or order_code) is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    order = _get_order_by_identifier(order_ref)
    if not order:
        return Response({"detail": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

    try:
        amount_raw = data.get("amount", order.total_amount)
        amount = Decimal(str(amount_raw)).quantize(Decimal("0.01"))
    except Exception:
        return Response(
            {"detail": "Invalid amount supplied."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if amount <= 0:
        return Response(
            {"detail": "Amount must be greater than zero."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    expected_amount = Decimal(str(order.total_amount)).quantize(Decimal("0.01"))
    if amount != expected_amount:
        return Response(
            {
                "detail": "Amount does not match order total.",
                "expected_total": str(expected_amount),
            },
            status=status.HTTP_400_BAD_REQUEST,
        )

    currency = (data.get("currency") or getattr(settings, "PAYWAY_CURRENCY", "USD") or "USD").upper()
    callback_url = getattr(settings, "PAYWAY_CALLBACK_URL", "") or request.build_absolute_uri(
        reverse("payway-callback")
    )
    return_url = getattr(settings, "PAYWAY_RETURN_URL", "") or request.build_absolute_uri("/")

    payload = {
        "merchant_id": merchant_id,
        "order_id": order.order_code or str(order.pk),
        "amount": _format_amount(amount),
        "currency": currency,
        "return_url": return_url,
        "callback_url": callback_url,
    }
    payload["hash"] = _compute_payway_hash(payload, api_key)

    checkout_base = getattr(settings, "PAYWAY_CHECKOUT_URL", "") or getattr(
        settings, "PAYWAY_BASE_URL", "https://link.payway.com.kh"
    )
    separator = "&" if "?" in checkout_base else "?"
    checkout_url = f"{checkout_base.rstrip('/')}{separator}{urlencode(payload)}"

    with transaction.atomic():
        payment, _ = Payment.objects.get_or_create(
            order=order,
            method="ABA_PAYWAY",
            defaults={
                "amount": amount,
                "currency": currency,
                "status": "pending",
                "provider": "ABA_PAYWAY",
            },
        )
        payment.amount = amount
        payment.currency = currency
        payment.provider = "ABA_PAYWAY"
        payment.status = payment.status or "pending"
        payment.hash_value = payload["hash"]
        payment.hash_valid = True
        payment.raw_payload = payload
        payment.transaction_id = None
        payment.save()

        PaymentTransaction.objects.create(
            provider="ABA_PAYWAY",
            order=order,
            payment=payment,
            transaction_id=None,
            order_reference=payload["order_id"],
            amount=amount,
            currency=currency,
            status="INITIATED",
            hash_value=payload["hash"],
            hash_valid=True,
            raw_payload=payload,
            processed=False,
        )

        if order.payment_method != "ABA_PAYWAY":
            order.payment_method = "ABA_PAYWAY"
            order.save(update_fields=["payment_method", "updated_at"])

    return Response(
        {
            "order_id": order.order_code,
            "payment_url": checkout_url,
            "payload": payload,
        },
        status=status.HTTP_201_CREATED,
    )


@api_view(["POST"])
@authentication_classes([AuthTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_qr_payment(request):
    data = request.data or {}
    order_ref = data.get("order_id") or data.get("order_code")
    if not order_ref:
        return Response(
            {"detail": "order_id (or order_code) is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    order = _get_order_by_identifier(order_ref)
    if not order:
        return Response({"detail": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

    user = getattr(request, "user", None)
    if order.user and user and getattr(user, "is_authenticated", False):
        if order.user.id != user.id:
            return Response({"detail": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

    payment_method = _normalize_payment_method(
        data.get("payment_method") or data.get("method") or order.payment_method or "ABA_QR"
    )
    if payment_method not in ("ABA_QR", "AC_QR"):
        return Response(
            {"detail": "Unsupported QR payment method."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        amount_raw = data.get("amount", order.total_amount)
        amount = Decimal(str(amount_raw)).quantize(Decimal("0.01"))
    except Exception:
        return Response(
            {"detail": "Invalid amount supplied."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    expected_amount = Decimal(str(order.total_amount)).quantize(Decimal("0.01"))
    if amount != expected_amount:
        return Response(
            {
                "detail": "Amount does not match order total.",
                "expected_total": str(expected_amount),
            },
            status=status.HTTP_400_BAD_REQUEST,
        )

    with transaction.atomic():
        payment, _ = Payment.objects.get_or_create(
            order=order,
            method=payment_method,
            defaults={
                "amount": amount,
                "currency": "USD",
                "status": "pending",
                "provider": "QR_MANUAL",
            },
        )
        payment.amount = amount
        payment.currency = getattr(payment, "currency", "USD") or "USD"
        payment.provider = "QR_MANUAL"
        if payment.status not in ("verified", "failed", "rejected"):
            payment.status = "pending"
        payment.save()

        if order.payment_method != payment_method:
            order.payment_method = payment_method
        if order.payment_status != "pending":
            order.payment_status = "pending"
        order.save(update_fields=["payment_method", "payment_status", "updated_at"])

    payload = PaymentSerializer(payment, context={"request": request}).data
    sample_link = getattr(settings, "PAYWAY_SAMPLE_LINK", "") or ""
    payway_link = _with_amount_url(sample_link, amount)
    qr_code_url = _get_qr_code_url(payment_method, request=request)
    if payway_link:
        qr_code_url = _build_qr_image_url(payway_link) or qr_code_url
    payload["qr_code_url"] = qr_code_url
    payload["payway_link"] = payway_link
    return Response(payload, status=status.HTTP_201_CREATED)


@api_view(["POST"])
@authentication_classes([AuthTokenAuthentication])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def upload_qr_receipt(request):
    payment_id = request.data.get("payment_id")
    if not payment_id:
        return Response(
            {"detail": "payment_id is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    payment = Payment.objects.select_related("order", "order__user").filter(pk=payment_id).first()
    if not payment:
        return Response({"detail": "Payment not found."}, status=status.HTTP_404_NOT_FOUND)

    user = getattr(request, "user", None)
    if payment.order and payment.order.user and user and getattr(user, "is_authenticated", False):
        if payment.order.user.id != user.id:
            return Response({"detail": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

    receipt_file = request.data.get("file") or request.data.get("receipt")
    error = _validate_receipt_upload(receipt_file)
    if error:
        return Response({"detail": error}, status=status.HTTP_400_BAD_REQUEST)

    payment.receipt_image = receipt_file
    payment.receipt_uploaded_at = timezone.now()
    if payment.status in ("rejected", "failed"):
        payment.status = "pending"
    payment.save(update_fields=["receipt_image", "receipt_uploaded_at", "status", "updated_at"])

    order = payment.order
    if order and order.payment_status != "paid":
        order.payment_status = "pending"
        order.save(update_fields=["payment_status", "updated_at"])

    if order:
        _send_telegram_receipt_upload(order, payment, request)
        _broadcast_order_event(
            order,
            "receipt_uploaded",
            extra={"payment_id": payment.id},
        )

    payload = PaymentSerializer(payment, context={"request": request}).data
    return Response(payload, status=status.HTTP_200_OK)


@api_view(["GET"])
@authentication_classes([AuthTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_qr_payment(request, payment_id: int):
    payment = Payment.objects.select_related("order", "order__user").filter(pk=payment_id).first()
    if not payment:
        return Response({"detail": "Payment not found."}, status=status.HTTP_404_NOT_FOUND)

    user = getattr(request, "user", None)
    if payment.order and payment.order.user and user and getattr(user, "is_authenticated", False):
        if payment.order.user.id != user.id:
            return Response({"detail": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

    payload = PaymentSerializer(payment, context={"request": request}).data
    return Response(payload, status=status.HTTP_200_OK)


@csrf_exempt
@api_view(["POST"])
@permission_classes([AllowAny])
def payway_callback(request):
    """
    PayWay webhook: validates hash, amount, and status; prevents duplicates.
    """
    if not request.is_secure() and not settings.DEBUG:
        return Response(
            {"detail": "Webhook must be served over HTTPS."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    data = request.data or {}
    if not data:
        try:
            data = json.loads(request.body.decode("utf-8"))
        except Exception:
            data = {}

    order_ref = data.get("order_id") or data.get("order_code")
    tx_id = str(
        data.get("transaction_id")
        or data.get("tran_id")
        or data.get("trans_id")
        or ""
    ).strip()
    status_text = str(
        data.get("status")
        or data.get("status_code")
        or data.get("response_code")
        or data.get("result")
        or ""
    ).upper()
    provided_hash = data.get("hash") or data.get("signature") or ""
    currency = (data.get("currency") or getattr(settings, "PAYWAY_CURRENCY", "USD") or "USD").upper()

    if not order_ref or not tx_id:
        return Response(
            {"detail": "order_id and transaction_id are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    order = _get_order_by_identifier(order_ref)
    if not order:
        return Response({"detail": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

    try:
        amount = Decimal(str(data.get("amount"))).quantize(Decimal("0.01"))
    except Exception:
        return Response({"detail": "Invalid amount."}, status=status.HTTP_400_BAD_REQUEST)

    expected_amount = Decimal(str(order.total_amount)).quantize(Decimal("0.01"))
    amount_valid = _amount_matches(amount, expected_amount)

    merchant_id = data.get("merchant_id") or getattr(settings, "PAYWAY_MERCHANT_ID", "")
    api_key = getattr(settings, "PAYWAY_API_KEY", "")
    if not merchant_id or not api_key:
        return Response(
            {"detail": "PayWay credentials are not configured on the server."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    hash_payload = {
        "merchant_id": merchant_id,
        "order_id": order_ref,
        "amount": _format_amount(amount),
        "currency": currency,
    }
    expected_hash = _compute_payway_hash(hash_payload, api_key)
    hash_valid = bool(provided_hash) and bool(expected_hash) and hmac.compare_digest(
        provided_hash, expected_hash
    )

    raw_payload = _normalize_payload_dict(data)
    tx = PaymentTransaction.objects.filter(
        provider="ABA_PAYWAY", transaction_id=tx_id
    ).first()

    if tx and tx.processed:
        return Response(
            {"detail": "Transaction already processed.", "transaction_id": tx_id},
            status=status.HTTP_200_OK,
        )

    if not tx:
        tx = PaymentTransaction(
            provider="ABA_PAYWAY",
            order=order,
            order_reference=order_ref,
            transaction_id=tx_id,
        )

    tx.amount = amount
    tx.currency = currency
    tx.status = status_text or tx.status or "UNKNOWN"
    tx.hash_value = provided_hash or tx.hash_value
    tx.hash_valid = hash_valid
    tx.raw_payload = raw_payload
    tx.processed = tx.processed or False
    tx.save()

    payment = Payment.objects.filter(order=order, method="ABA_PAYWAY").first()
    if not payment:
        payment = Payment(
            order=order,
            method="ABA_PAYWAY",
            amount=amount,
            currency=currency,
            provider="ABA_PAYWAY",
        )

    payment.amount = amount
    payment.currency = currency
    payment.provider = "ABA_PAYWAY"
    payment.transaction_id = tx_id
    payment.hash_value = provided_hash or expected_hash or ""
    payment.hash_valid = hash_valid
    payment.raw_payload = raw_payload

    if _is_payway_success(status_text, data) and amount_valid and hash_valid:
        with transaction.atomic():
            payment.status = "verified"
            payment.paid_at = timezone.now()
            payment.save()

            order.payment_status = "paid"
            if order.order_status == "pending":
                order.order_status = "confirmed"
            order.payment_method = "ABA_PAYWAY"
            order.save(update_fields=["payment_status", "order_status", "payment_method", "updated_at"])

            tx.payment = payment
            tx.processed = True
            tx.processed_at = timezone.now()
            tx.save()

        _send_telegram_payment_update(order, payment, tx)
        return Response(
            {"detail": "Payment verified", "transaction_id": tx_id},
            status=status.HTTP_200_OK,
        )

    payment.status = "failed" if status_text else "rejected"
    payment.save()
    tx.payment = payment
    tx.save(update_fields=["payment"])

    return Response(
        {
            "detail": "Callback logged",
            "status": status_text or "UNKNOWN",
            "hash_valid": hash_valid,
            "amount_valid": amount_valid,
        },
        status=status.HTTP_200_OK,
    )


def _send_telegram_payment_update(order: Order, payment: Payment, tx: PaymentTransaction):
    """
    Notify Telegram when a payment is confirmed.
    """
    token, chat_id = _get_telegram_config()
    if not token or not chat_id:
        return

    paid_time = timezone.localtime(payment.paid_at or timezone.now()).strftime("%Y-%m-%d %H:%M")
    lines = [
        "💳 ABA PayWay Payment",
        f"Order: {order.order_code}",
        f"Amount: {payment.currency} {payment.amount}",
        f"Transaction ID: {tx.transaction_id}",
        f"Status: {payment.status}",
        f"Paid at: {paid_time}",
    ]
    text = "\n".join(lines)
    try:
        base = f"https://api.telegram.org/bot{token}"
        requests.post(
            f"{base}/sendMessage",
            json={"chat_id": chat_id, "text": text},
            timeout=10,
        )
    except Exception as exc:
        print(f"[telegram] failed to send payment update: {exc}")


def _apply_order_decision(order: Order, action: str):
    """
    Shared helper to approve/reject an order + payment.
    Returns (processed: bool, message: str).
    """
    action = action.lower()
    # Prevent double-processing
    if order.payment_status in ("paid", "failed") or order.order_status in ("cancelled", "completed"):
        return False, f"Order {order.order_code} already processed."

    if action == "approve":
        order.order_status = "confirmed"
        order.payment_status = "paid"
        msg = f"✅ Order {order.order_code} approved."
    elif action == "reject":
        order.order_status = "pending" if order.payment_method != "COD" else "cancelled"
        order.payment_status = "failed"
        msg = f"❌ Order {order.order_code} rejected."
    else:
        return False, "Unsupported action."

    order.save(update_fields=["order_status", "payment_status"])

    for payment in order.payments.all():
        if action == "approve":
            payment.status = "verified"
            payment.paid_at = timezone.now()
        elif action == "reject":
            payment.status = "rejected"
            payment.paid_at = None
        payment.save(update_fields=["status", "paid_at"])

    _broadcast_order_event(order, f"status_{action}")
    return True, msg

@csrf_exempt
@api_view(["POST"])
def telegram_webhook(request):
    """
    Handle Telegram callback buttons Approve/Reject.
    """
    try:
        update = json.loads(request.body.decode("utf-8"))
    except Exception:
        return Response(status=status.HTTP_400_BAD_REQUEST)

    callback = update.get("callback_query") or {}
    data = callback.get("data") or ""
    if not data:
        return Response(status=status.HTTP_200_OK)

    if not (data.startswith("approve:") or data.startswith("reject:")):
        return Response(status=status.HTTP_200_OK)

    action, raw_id = data.split(":", 1)
    order = None
    try:
        order = Order.objects.get(pk=int(raw_id))
    except (ValueError, Order.DoesNotExist):
        order = Order.objects.filter(order_code=raw_id).first()
    if not order:
        return Response(status=status.HTTP_200_OK)

    processed, status_text = _apply_order_decision(order, action)

    token, default_chat_id = _get_telegram_config()
    if not token:
        return Response(status=status.HTTP_200_OK)

    base = f"https://api.telegram.org/bot{token}"
    msg = callback.get("message", {})
    chat_id = msg.get("chat", {}).get("id") or default_chat_id
    message_id = msg.get("message_id")

    try:
        # Acknowledge button press
        requests.post(
            f"{base}/answerCallbackQuery",
            json={
              "callback_query_id": callback.get("id"),
              "text": status_text,
              "show_alert": False,
            },
            timeout=10,
        )
        # Remove inline buttons to prevent duplicate actions
        if message_id:
            requests.post(
                f"{base}/editMessageReplyMarkup",
                json={
                    "chat_id": chat_id,
                    "message_id": message_id,
                    "reply_markup": {"inline_keyboard": []},
                },
                timeout=10,
            )
        # Notify the chat
        requests.post(
            f"{base}/sendMessage",
            json={
              "chat_id": chat_id,
              "text": status_text,
            },
            timeout=10,
        )
    except Exception as exc:
        print(f"[telegram] callback handling failed: {exc}")

    return Response(status=status.HTTP_200_OK)


@api_view(["POST"])
def register_user(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        token = issue_token(user)
        return Response(
            {
                "message": "User created successfully",
                "user": UserPublicSerializer(user).data,
                "token": token.key,
            },
            status=status.HTTP_201_CREATED,
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["POST"])
def login_user(request):
    phone = request.data.get("phone")
    password = request.data.get("password")

    if not phone or not password:
        return Response(
            {"detail": "Phone and password are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        user = User.objects.get(phone=phone)
    except User.DoesNotExist:
        return Response(
            {"detail": "Invalid phone or password."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not check_password(password, user.password):
        return Response(
            {"detail": "Invalid phone or password."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    token = issue_token(user, replace_existing=True)
    return Response(
        {
            "message": "Login successful",
            "user": UserPublicSerializer(user).data,
            "token": token.key,
        },
        status=status.HTTP_200_OK,
    )


@api_view(["GET"])
def get_user_info(request, pk=None):
    """
    Fetch a user by id or phone.
    Accepts:
    - query params: ?id=<user_id> or ?phone=<phone_number>
    - URL path: /api/user/<id>/
    """
    user_id = request.query_params.get("id") or pk
    phone = request.query_params.get("phone")

    if not user_id and not phone:
        return Response(
            {"detail": "Provide 'id' or 'phone' to fetch user info."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        if user_id:
            user = User.objects.get(pk=user_id)
        else:
            user = User.objects.get(phone=phone)
    except User.DoesNotExist:
        return Response(
            {"detail": "User not found."},
            status=status.HTTP_404_NOT_FOUND,
        )

    return Response(UserPublicSerializer(user).data, status=status.HTTP_200_OK)


def issue_token(user, replace_existing=False):
    """
    Create a new token for the given user.
    If replace_existing=True, old tokens are removed first.
    """
    if replace_existing:
        AuthToken.objects.filter(user=user).delete()
    token = AuthToken.objects.create(user=user, key=secrets.token_hex(20))
    return token
