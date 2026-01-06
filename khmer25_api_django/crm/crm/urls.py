"""
URL configuration for crm project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
import os

from django.contrib import admin
from django.http import HttpResponse, HttpResponseForbidden
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static


def media_debug(request):
    token = os.getenv("MEDIA_DEBUG_TOKEN", "")
    if token and request.GET.get("token") != token:
        return HttpResponseForbidden("forbidden")
    lines = [
        f"MEDIA_ROOT={settings.MEDIA_ROOT}",
        f"MEDIA_URL={settings.MEDIA_URL}",
        f"SERVE_MEDIA={settings.SERVE_MEDIA}",
    ]
    try:
        os.makedirs(settings.MEDIA_ROOT, exist_ok=True)
    except OSError as exc:
        lines.append(f"mkdir_error={exc!r}")
    test_path = os.path.join(settings.MEDIA_ROOT, "railway_media_test.txt")
    try:
        with open(test_path, "w", encoding="utf-8") as handle:
            handle.write("ok")
        lines.append("write=ok")
    except OSError as exc:
        lines.append(f"write_error={exc!r}")
    try:
        entries = os.listdir(settings.MEDIA_ROOT)
        lines.append("entries=" + ", ".join(entries[:50]))
    except OSError as exc:
        lines.append(f"list_error={exc!r}")
    return HttpResponse("\n".join(lines))

urlpatterns = [
    # Simple health check for platform probes (e.g., Railway).
    path("", lambda request: HttpResponse("ok"), name="health"),
    path("__media_check/", media_debug, name="media_debug"),
    path('dj-admin/', admin.site.urls),
    path('admin/', include('accounts.ui_urls')),
    path('api/', include('accounts.urls')),
]

if settings.DEBUG or settings.SERVE_MEDIA:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
