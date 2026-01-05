from pathlib import Path
from decimal import Decimal

from django.conf import settings
from django.core.files import File
from django.core.management.base import BaseCommand
from django.db import transaction

from accounts.models import Banner, Category, Product


class Command(BaseCommand):
    help = "Seed sample categories, products, and banners."

    def add_arguments(self, parser):
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Delete existing categories, products, and banners before seeding.",
        )

    def handle(self, *args, **options):
        reset = options["reset"]
        source_media = Path(settings.BASE_DIR) / "media"

        if reset:
            self.stdout.write("Deleting existing banners, products, and categories...")
            Banner.objects.all().delete()
            Product.objects.all().delete()
            Category.objects.all().delete()

        categories = [
            {"title": "Books", "image": "Books.png"},
            {"title": "Clothing", "image": "Clothing.png"},
            {"title": "Electronics", "image": "Electronics.png"},
            {"title": "Food & Drinks", "image": "Food__Drinks.png"},
            {"title": "Health", "image": "Health.png"},
        ]

        product_images = [
            "Headphones.jpg",
            "Jeans.avif",
            "T-Shirt.avif",
            "Coffee.jpeg",
            "photo_2025-02-11_18-41-40.jpg",
            "photo_2025-08-16_00-10-56.jpg",
            "tk_photo_2025_09-2025_2025-09-korean-noodles_korean-noodles-020.jpeg",
            "EXPS_TOHD24_167133_SarahTramonte_6.jpg",
            "iPhone_17_Pro_Max_Cosmic_Orange_PDP_Image_Position_1_Cosmic_Orange_Color__SEA-EN.avif",
            "1766983014134.jpg",
            "download_1.jpg",
            "download_3.jpg",
            "download_5.jpg",
            "download_8.jpg",
            "download_9.jpg",
            "images_1.jpg",
            "images_2.jpg",
            "img_1.png",
            "strawberry.webp",
            "paer.webp",
            "1-1.jpg",
            "11.jpg",
            "15.jpg",
            "4.png",
            "5.jpg",
        ]

        banner_images = ["b1.png", "b2.png", "Instagram_.png"]

        with transaction.atomic():
            created_categories = []
            for entry in categories:
                category = Category(
                    title_en=entry["title"],
                    title_kh=entry["title"],
                    sub_count=0,
                )
                self._attach_image(
                    category,
                    "image",
                    source_media / "categories" / entry["image"],
                )
                category.save()
                created_categories.append(category)

            self._seed_products(created_categories, product_images, source_media)
            self._seed_banners(banner_images, source_media)

        self.stdout.write(self.style.SUCCESS("Seed data created."))

    def _attach_image(self, instance, field_name, source_path):
        if not source_path.exists():
            self.stdout.write(f"Missing image: {source_path}")
            return
        with source_path.open("rb") as handle:
            getattr(instance, field_name).save(
                source_path.name,
                File(handle),
                save=False,
            )

    def _seed_products(self, categories, images, source_media):
        if not categories:
            return
        per_category = 5
        price_base = Decimal("2.50")
        image_iter = iter(images)

        for category in categories:
            for index in range(1, per_category + 1):
                try:
                    image_name = next(image_iter)
                except StopIteration:
                    image_iter = iter(images)
                    image_name = next(image_iter)

                product = Product(
                    category=category,
                    name=f"{category.title_en} Item {index}",
                    price=price_base + Decimal(index),
                    currency="USD",
                    quantity=10 * index,
                    tag="hot" if index % 2 == 0 else "",
                )
                self._attach_image(
                    product,
                    "image",
                    source_media / "products" / image_name,
                )
                product.save()

    def _seed_banners(self, images, source_media):
        for image_name in images:
            banner = Banner()
            self._attach_image(
                banner,
                "image",
                source_media / "banners" / image_name,
            )
            banner.save()
