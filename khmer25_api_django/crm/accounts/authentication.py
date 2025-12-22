from rest_framework.authentication import BaseAuthentication
from rest_framework import exceptions
from .models import AuthToken


class AuthTokenAuthentication(BaseAuthentication):
    """
    Simple token authentication using our AuthToken model.
    Expect header: Authorization: Token <token>
    """

    def authenticate(self, request):
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            return None

        # Accept "Token <key>", "Bearer <key>", or bare "<key>"
        auth_value = auth_header.strip()
        if " " in auth_value:
            keyword, key = auth_value.split(" ", 1)
            if keyword.lower() not in ("token", "bearer"):
                # Unrecognized scheme: ignore so other auth classes (or unauthenticated) can proceed
                return None
        else:
            key = auth_value

        if not key:
            raise exceptions.AuthenticationFailed("Missing token.")

        try:
            token = AuthToken.objects.select_related("user").get(key=key)
        except AuthToken.DoesNotExist:
            raise exceptions.AuthenticationFailed("Invalid token.")

        return (token.user, token)
