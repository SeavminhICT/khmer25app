from .models import User, Banner
from django.contrib.auth.hashers import make_password
from rest_framework import serializers
from django.utils import timezone
from .models import (
    Category,
    Product,
    User,
    Cart,
    Order,
    OrderItem,
    Payment,
    Supplier,
)
from rest_framework.permissions import AllowAny


class CategorySerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = [
            "id",
            "title_en",
            "title_kh",
            "image",
            "image_url",
            "sub_count",
        ]

    def get_image_url(self, obj):
        request = self.context.get("request")
        if obj.image and hasattr(obj.image, "url"):
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None
        

class ProductSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    category_name = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            "id",
            "name",
            "price",
            "currency",
            "quantity",
            "tag",
            "supplier_id",
            "product_date",
            "image",
            "image_url",
            "payway_link",
            "category",
            "category_name",
        ]

    def get_image_url(self, obj):
        request = self.context.get("request")

        if obj.image and hasattr(obj.image, 'url'):
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url  # Fallback (absolute path not required)

        return None

    def get_category_name(self, obj):
        category = getattr(obj, "category", None)
        if not category:
            return ""
        name = (getattr(category, "title_en", "") or "").strip()
        if name:
            return name
        return (getattr(category, "title_kh", "") or "").strip()


class UserSerializer(serializers.ModelSerializer):
    avatar_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = User
        fields = ["id", "username", "password", "email", "phone", "avatar", "avatar_url"]
        extra_kwargs = {
            "password": {"write_only": True},
            "username": {"required": True},
            "email": {"required": True},
            "phone": {"required": True},
            "avatar": {"required": False, "allow_null": True},
        }

    # Auto-hash password before saving
    def create(self, validated_data):
        validated_data['password'] = make_password(validated_data['password'])
        return super().create(validated_data)

    def update(self, instance, validated_data):
        if "password" in validated_data:
            validated_data["password"] = make_password(validated_data["password"])
        return super().update(instance, validated_data)

    def validate_phone(self, value):
        # Prevent multiple accounts sharing the same phone number
        qs = User.objects.filter(phone=value)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError("Phone already registered.")
        return value

    def get_avatar_url(self, obj):
        request = self.context.get("request")
        if obj.avatar:
            if request:
                return request.build_absolute_uri(obj.avatar.url)
            return obj.avatar.url
        return None


class UserPublicSerializer(serializers.ModelSerializer):
    avatar_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = User
        fields = ["id", "username", "email", "phone", "avatar_url"]

    def get_avatar_url(self, obj):
        request = self.context.get("request")
        if obj.avatar:
            if request:
                return request.build_absolute_uri(obj.avatar.url)
            return obj.avatar.url
        return None

class CartSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cart
        fields = "__all__"


class OrderItemSerializer(serializers.ModelSerializer):
    product_image = serializers.SerializerMethodField()

    class Meta:
        model = OrderItem
        fields = [
            "id",
            "product_id",
            "product_name",
            "product_image",
            "price",
            "quantity",
            "subtotal",
        ]

    def get_product_image(self, obj):
        product = obj.product
        if not product or not product.image:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(product.image.url)
        return product.image.url

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    created_at = serializers.SerializerMethodField()
    receipt_url = serializers.SerializerMethodField()
    class Meta:
        model = Order
        fields = [
            "id",
            "order_code",
            "created_at",
            "total_amount",
            "order_status",
            "payment_status",
            "payment_method",
            "receipt_url",
            "address",
            "customer_name",
            "phone",
            "note",
            "items",
        ]

    def get_created_at(self, obj):
        try:
            return timezone.localtime(obj.created_at).isoformat()
        except Exception:
            return obj.created_at.isoformat() if obj.created_at else None

    def get_receipt_url(self, obj):
        payment = obj.payments.filter(receipt_image__isnull=False).first()
        if not payment or not payment.receipt_image:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(payment.receipt_image.url)
        return payment.receipt_image.url


class PaymentSerializer(serializers.ModelSerializer):
    payment_id = serializers.IntegerField(source="id", read_only=True)
    order_id = serializers.IntegerField(read_only=True)
    user_id = serializers.SerializerMethodField()
    payment_amount = serializers.DecimalField(
        source="amount", max_digits=12, decimal_places=2, read_only=True
    )
    payment_status = serializers.SerializerMethodField()
    receipt_upload = serializers.SerializerMethodField()
    uploaded_at = serializers.DateTimeField(source="receipt_uploaded_at", read_only=True)

    class Meta:
        model = Payment
        fields = [
            "payment_id",
            "user_id",
            "payment_amount",
            "payment_status",
            "receipt_upload",
            "uploaded_at",
            "method",
            "currency",
            "status",
            "order_id",
            "created_at",
            "updated_at",
        ]

    def get_user_id(self, obj):
        if obj.order and obj.order.user:
            return obj.order.user.id
        return None

    def get_payment_status(self, obj):
        mapping = {
            "pending": "Processing",
            "verified": "Paid",
            "rejected": "Failed",
            "failed": "Failed",
        }
        return mapping.get(obj.status, obj.status)

    def get_receipt_upload(self, obj):
        if not obj.receipt_image:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(obj.receipt_image.url)
        return obj.receipt_image.url












class BannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Banner
        fields = ["id", "image"]




class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = "__all__"
