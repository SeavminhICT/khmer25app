from pathlib import Path

from django.conf import settings
from django.core.files import File
from django.core.files.storage import default_storage
from django.core.management.base import BaseCommand

from accounts.models import Banner, Category, Product


class Command(BaseCommand):
    help = "Audit and fix missing media files for categories, products, and banners."

    def add_arguments(self, parser):
        parser.add_argument(
            "--copy-bundled",
            action="store_true",
            help="Copy bundled media from BASE_DIR/media into MEDIA_ROOT.",
        )
        parser.add_argument(
            "--report",
            action="store_true",
            help="Report missing media files referenced by the database.",
        )
        parser.add_argument(
            "--clear-missing",
            action="store_true",
            help="Clear image fields that reference missing files.",
        )

    def handle(self, *args, **options):
        copy_bundled = options["copy_bundled"]
        report = options["report"]
        clear_missing = options["clear_missing"]

        if not (copy_bundled or report or clear_missing):
            copy_bundled = report = clear_missing = True

        bundled_root = Path(settings.BASE_DIR) / "media"

        if copy_bundled:
            self._copy_bundled_media(bundled_root)

        missing = {}
        if report or clear_missing:
            missing = self._find_missing_media()
            if report:
                self._print_missing(missing)

        if clear_missing and missing:
            self._clear_missing(missing)

        self.stdout.write(self.style.SUCCESS("Media fix completed."))

    def _copy_bundled_media(self, bundled_root: Path) -> None:
        if not bundled_root.exists():
            self.stdout.write(f"No bundled media found at {bundled_root}")
            return

        copied = 0
        for folder in ("categories", "products", "banners"):
            source_dir = bundled_root / folder
            if not source_dir.exists():
                continue
            for source_path in source_dir.rglob("*"):
                if not source_path.is_file():
                    continue
                rel_path = f"{folder}/{source_path.name}"
                if default_storage.exists(rel_path):
                    continue
                with source_path.open("rb") as handle:
                    default_storage.save(rel_path, File(handle))
                copied += 1

        self.stdout.write(f"Copied {copied} bundled media files.")

    def _find_missing_media(self):
        missing = {"categories": [], "products": [], "banners": []}

        for category in Category.objects.all():
            if self._is_missing(category.image):
                missing["categories"].append((category.id, category.image.name))

        for product in Product.objects.all():
            if self._is_missing(product.image):
                missing["products"].append((product.id, product.image.name))

        for banner in Banner.objects.all():
            if self._is_missing(banner.image):
                missing["banners"].append((banner.id, banner.image.name))

        return missing

    def _is_missing(self, field) -> bool:
        if not field or not getattr(field, "name", ""):
            return False
        return not default_storage.exists(field.name)

    def _print_missing(self, missing):
        for label, items in missing.items():
            if not items:
                self.stdout.write(f"{label}: no missing files.")
                continue
            self.stdout.write(f"{label}: {len(items)} missing files.")
            for item_id, name in items:
                self.stdout.write(f"  - {item_id}: {name}")

    def _clear_missing(self, missing):
        if missing["categories"]:
            ids = [item_id for item_id, _ in missing["categories"]]
            Category.objects.filter(id__in=ids).update(image=None)
        if missing["products"]:
            ids = [item_id for item_id, _ in missing["products"]]
            Product.objects.filter(id__in=ids).update(image=None)
        if missing["banners"]:
            ids = [item_id for item_id, _ in missing["banners"]]
            Banner.objects.filter(id__in=ids).update(image="")
