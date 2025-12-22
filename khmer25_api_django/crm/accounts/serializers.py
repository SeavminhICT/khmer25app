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

    class Meta:
        model = Product
        fields = [
            "id",
            "name",
            "price",
            "currency",
            "quantity",
            "supplier_id",
            "product_date",
            "image",
            "image_url",
            "category",
        ]

    def get_image_url(self, obj):
        request = self.context.get("request")

        if obj.image and hasattr(obj.image, 'url'):
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url  # Fallback (absolute path not required)

        return None


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
    class Meta:
        model = OrderItem
        fields = "__all__"

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    class Meta:
        model = Order
        fields = "__all__"













class BannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Banner
        fields = ["id", "image"]




class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = "__all__"
