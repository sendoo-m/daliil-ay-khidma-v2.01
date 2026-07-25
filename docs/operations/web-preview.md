# Web preview deployment

The Flutter Web preview is published at:

- https://sendoo-m.github.io/daliil-ay-khidma-v2.01/

The production API must allow the page origin, not the full repository path:

- CORS origin: `https://sendoo-m.github.io`
- CSRF trusted origin: `https://sendoo-m.github.io`

The Render service reads optional comma-separated `CORS_ALLOWED_ORIGINS` and `CSRF_TRUSTED_ORIGINS` environment variables. Both settings default to the GitHub Pages origin so the public preview remains usable without additional environment configuration.
