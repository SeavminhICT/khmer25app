from django.db import migrations, models
import django.core.validators


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0016_product_tag"),
    ]

    operations = [
        migrations.AddField(
            model_name="payment",
            name="receipt_uploaded_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AlterField(
            model_name="payment",
            name="receipt_image",
            field=models.FileField(
                blank=True,
                null=True,
                upload_to="payments/",
                validators=[django.core.validators.FileExtensionValidator(["jpg", "jpeg", "png", "pdf"])],
            ),
        ),
    ]
