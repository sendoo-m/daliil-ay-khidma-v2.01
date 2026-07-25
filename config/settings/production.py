"""
Production settings for daliil-ay-khidma project.
"""
from .base import *
from decouple import config

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split(',')

# Database - PostgreSQL for production
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
    }
}

# Serve collected static files (including Django admin CSS) from Render.
# WhiteNoise must run directly after Django's SecurityMiddleware.
MIDDLEWARE.insert(1, 'whitenoise.middleware.WhiteNoiseMiddleware')

STORAGES = {
    # Keep production bootable until CLOUDINARY_URL is added to Render.
    # Once present, every new ImageField/FileField upload is stored permanently.
    'default': {
        'BACKEND': (
            'apps.core.storage.BoundedMediaCloudinaryStorage'
            if config('CLOUDINARY_URL', default='')
            else 'django.core.files.storage.FileSystemStorage'
        ),
    },
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage',
    },
}

# Keep admin uploads below Gunicorn's request deadline if Cloudinary is slow.
CLOUDINARY_UPLOAD_TIMEOUT = config(
    'CLOUDINARY_UPLOAD_TIMEOUT',
    default=8,
    cast=int,
)

REST_FRAMEWORK['DEFAULT_THROTTLE_CLASSES'] = [
    *REST_FRAMEWORK['DEFAULT_THROTTLE_CLASSES'],
    'apps.api.throttles.BusinessInteractionRateThrottle',
]
REST_FRAMEWORK['DEFAULT_THROTTLE_RATES']['business_interaction'] = '30/minute'

# Log unhandled request errors to Render's stdout without enabling DEBUG.
# Django includes the exception traceback, but does not log request bodies here.
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'render': {
            'format': '{levelname} {asctime} {name}: {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'render',
        },
    },
    'loggers': {
        'django.request': {
            'handlers': ['console'],
            'level': 'ERROR',
            'propagate': False,
        },
        'django.server': {
            'handlers': ['console'],
            'level': 'ERROR',
            'propagate': False,
        },
    },
}

# Security settings
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = config('SECURE_HSTS_SECONDS', default=31536000, cast=int)
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_REFERRER_POLICY = 'same-origin'
CSRF_COOKIE_HTTPONLY = True

# Email settings for production
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = True
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL', default='noreply@daliilaykhidma.com')
