from django.urls import path

from .consumers import OrderEventConsumer

websocket_urlpatterns = [
    path("ws/orders/", OrderEventConsumer.as_asgi()),
]
