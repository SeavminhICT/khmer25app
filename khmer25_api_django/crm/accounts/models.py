from decimal import Decimal
from django.db import models
from django.core.validators import FileExtensionValidator
from django.utils import timezone

# Category
class Category(models.Model):
    title_en = models.CharField(max_length=100)
    title_kh = models.CharField(max_length=100)
    image = models.ImageField(upload_to='categories/', blank=True, null=True)
    sub_count = models.IntegerField(default=0)

    def __str__(self):
        return self.title_en


# Product
class Product(models.Model):
    CURRENCY_CHOICES = [
        ("USD", "USD"),
        ("KHR", "KHR"),
    ]
    TAG_CHOICES = [
        ("", "None"),
        ("hot", "Hot"),
        ("discount", "Discount"),
    ]
    category = models.ForeignKey(Category, related_name='products', on_delete=models.CASCADE)
    name = models.CharField(max_length=200)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default="USD")
    quantity = models.PositiveIntegerField()
    tag = models.CharField(max_length=20, choices=TAG_CHOICES, blank=True, default="")
    image = models.ImageField(upload_to='products/', blank=True, null=True)
    payway_link = models.URLField(blank=True, null=True)
    supplier_id = models.IntegerField(blank=True, null=True)
    product_date = models.DateField(auto_now_add=True)
    def __str__(self):
        return self.name

# models.py


class User(models.Model):
    username = models.CharField(max_length=100)
    password = models.CharField(max_length=128)  # hashed password stored here
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True)
    avatar = models.ImageField(upload_to="avatars/", blank=True, null=True)



    def __str__(self):
        return self.username

    @property
    def is_authenticated(self):
        return True


class AdminProfile(models.Model):
    full_name = models.CharField(max_length=120)
    email = models.EmailField()
    phone = models.CharField(max_length=20, blank=True)
    role = models.CharField(max_length=40, default="Admin")
    avatar = models.ImageField(upload_to="avatars/", blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.full_name


# Cart
class Cart(models.Model):
    user = models.ForeignKey(User, related_name='carts', on_delete=models.CASCADE)
    product = models.ForeignKey(Product, related_name='carts', on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)

class Order(models.Model):
    PAYMENT_METHOD_CHOICES = [
        ("COD", "Cash on Delivery"),
        ("ABA_QR", "ABA QR"),
        ("AC_QR", "AC QR"),
        ("ABA_PAYWAY", "ABA PayWay"),
    ]
    PAYMENT_STATUS_CHOICES = [
        ("pending", "Pending"),
        ("paid", "Paid"),
        ("failed", "Failed"),
    ]
    ORDER_STATUS_CHOICES = [
        ("pending", "Pending"),
        ("confirmed", "Confirmed"),
        ("shipping", "Shipping"),
        ("completed", "Completed"),
        ("cancelled", "Cancelled"),
    ]

    user = models.ForeignKey(
        User, related_name='orders', on_delete=models.SET_NULL, null=True, blank=True
    )
    order_code = models.CharField(max_length=50, unique=True, blank=True)
    customer_name = models.CharField(max_length=100)
    phone = models.CharField(max_length=20)
    address = models.TextField()
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES)
    payment_status = models.CharField(
        max_length=20, choices=PAYMENT_STATUS_CHOICES, default="pending"
    )
    order_status = models.CharField(
        max_length=20, choices=ORDER_STATUS_CHOICES, default="pending"
    )
    note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        is_new = self.pk is None
        super().save(*args, **kwargs)
        # Generate a human-readable order code after we have a primary key
        if is_new and not self.order_code:
            from django.utils import timezone

            self.order_code = f"ORD-{timezone.now().year}-{self.pk:04d}"
            super().save(update_fields=["order_code"])


class OrderItem(models.Model):
    order = models.ForeignKey(Order, related_name='items', on_delete=models.CASCADE)
    product = models.ForeignKey(Product, related_name='order_items', on_delete=models.CASCADE)
    product_name = models.CharField(max_length=150, blank=True)
    price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    quantity = models.PositiveIntegerField(default=1)
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    def save(self, *args, **kwargs):
        # Default snapshot fields from the linked product if they were not provided
        if self.product and not self.product_name:
            self.product_name = self.product.name
        if self.product and self.price is None:
            self.price = self.product.price
        if self.price is None:
            raise ValueError("Price is required for order items.")
        self.subtotal = (self.price or Decimal("0")) * self.quantity
        super().save(*args, **kwargs)


class Payment(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("verified", "Verified"),
        ("rejected", "Rejected"),
        ("failed", "Failed"),
    ]

    METHOD_CHOICES = [
        ("COD", "Cash on Delivery"),
        ("ABA_QR", "ABA QR"),
        ("AC_QR", "AC QR"),
        ("ABA_PAYWAY", "ABA PayWay"),
    ]

    order = models.ForeignKey(Order, related_name='payments', on_delete=models.CASCADE)
    method = models.CharField(max_length=20, choices=METHOD_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    receipt_image = models.FileField(
        upload_to="payments/",
        blank=True,
        null=True,
        validators=[FileExtensionValidator(["jpg", "jpeg", "png", "pdf"])],
    )
    receipt_uploaded_at = models.DateTimeField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    paid_at = models.DateTimeField(blank=True, null=True)
    currency = models.CharField(max_length=3, default="USD")
    provider = models.CharField(max_length=40, default="ABA_PAYWAY")
    transaction_id = models.CharField(max_length=128, blank=True, null=True)
    hash_value = models.CharField(max_length=512, blank=True)
    hash_valid = models.BooleanField(default=False)
    raw_payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)


class PaymentTransaction(models.Model):
    """
    Audit log for inbound/outbound PayWay messages to prevent duplicate processing.
    """
    provider = models.CharField(max_length=40, default="ABA_PAYWAY")
    order = models.ForeignKey(Order, related_name="payment_transactions", on_delete=models.CASCADE)
    payment = models.ForeignKey(Payment, related_name="transactions", on_delete=models.SET_NULL, blank=True, null=True)
    transaction_id = models.CharField(max_length=128, blank=True, null=True)
    order_reference = models.CharField(max_length=128)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default="USD")
    status = models.CharField(max_length=40)
    hash_value = models.CharField(max_length=512, blank=True)
    hash_valid = models.BooleanField(default=False)
    raw_payload = models.JSONField(default=dict, blank=True)
    processed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    processed_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        indexes = [
            models.Index(fields=["provider", "transaction_id"]),
            models.Index(fields=["order_reference"]),
        ]
        ordering = ["-created_at"]





    






class Banner(models.Model):
    image = models.ImageField(upload_to="banners/")

    def __str__(self):
        return f"Banner {self.pk}"
    




    
class Supplier(models.Model):
    contact_title = models.CharField(max_length=255)
    phone_number = models.CharField(max_length=50)
    supplier_address = models.TextField()
    supplier_email = models.EmailField()
    supplier_website = models.URLField(blank=True, null=True)
    supplier_social = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return self.contact_title
    
    
class SocialMedia(models.Model):
    name = models.CharField(max_length=255)
    url = models.URLField()
    icon = models.URLField()

    def __str__(self):
        return self.name

class FooterType(models.Model):
    footer_type_name = models.CharField(max_length=255)

    def __str__(self):
        return self.footer_type_name


class Footer(models.Model):
    footer_detail = models.TextField()
    footer_type = models.ForeignKey(FooterType, on_delete=models.CASCADE)

    def __str__(self):
        return f"Footer - {self.footer_type.footer_type_name}"



class AuthToken(models.Model):
    """
    Simple token tied to our custom User model for API auth.
    """
    key = models.CharField(max_length=40, unique=True)
    user = models.ForeignKey(User, related_name="tokens", on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Token for {self.user.username}"
