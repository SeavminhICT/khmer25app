from urllib.parse import parse_qs

from channels.generic.websocket import AsyncJsonWebsocketConsumer


class OrderEventConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        await self.channel_layer.group_add("orders", self.channel_name)
        query = parse_qs(self.scope.get("query_string", b"").decode())
        user_id = (query.get("user_id") or [None])[0]
        if user_id:
            await self.channel_layer.group_add(f"user_{user_id}", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard("orders", self.channel_name)
        query = parse_qs(self.scope.get("query_string", b"").decode())
        user_id = (query.get("user_id") or [None])[0]
        if user_id:
            await self.channel_layer.group_discard(f"user_{user_id}", self.channel_name)

    async def order_event(self, event):
        await self.send_json(event)
