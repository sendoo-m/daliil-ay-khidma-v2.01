from rest_framework.throttling import AnonRateThrottle, ScopedRateThrottle


class LoginRateThrottle(AnonRateThrottle):
    scope = 'login'


class RegistrationRateThrottle(AnonRateThrottle):
    scope = 'registration'


class PasswordResetRateThrottle(AnonRateThrottle):
    scope = 'password_reset'


class BusinessInteractionRateThrottle(ScopedRateThrottle):
    """Apply a dedicated limit to public business counter events."""

    scope = 'business_interaction'
