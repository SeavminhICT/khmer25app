from .models import User, Banner
from django.contrib.auth.hashers import make_password
from rest_framework import serializers
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
    class Meta:
        model = Category
        fields = "__all__"
        

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
            "address",
            "items",
        ]













class BannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Banner
        fields = ["id", "image"]




class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = "__all__"
