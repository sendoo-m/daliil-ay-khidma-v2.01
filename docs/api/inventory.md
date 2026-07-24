# API Inventory

> Baseline snapshot of the API surface currently wired into the project. This document describes registered routes only; behavior, permissions, pagination, validation, and response contracts still require endpoint-level verification.

## API entry points

The root URL configuration exposes three API families:

- `/api/v1/` — legacy API surface.
- `/api/v2/` — current mobile/admin API surface.
- `/api/dashboard/` — dashboard-specific API routes.

The project should treat `/api/v2/` as the primary contract for new Flutter work unless a feature audit proves otherwise.

## Authentication and account routes

Registered under `/api/v2/auth/`:

- `login/`
- `refresh/`
- `register/`
- `profile/`
- `profile/update/`
- `change-password/`
- `logout/`
- `password-reset/`
- `password-reset/confirm/`

Authentication uses JWT with token refresh and blacklist support. The audit must still verify token rotation, logout invalidation, password-reset expiry, and error response consistency.

## Public catalogue routes

Router resources registered under `/api/v2/`:

- `governorates`
- `cities`
- `districts`
- `categories`
- `businesses`
- `favorites`
- `products`
- `deals`
- `deal-claims`
- `reviews`
- `subscriptions`
- `subscription-plans`
- `devices`
- `notifications`

Additional public/mobile endpoints:

- `home/`
- `app-config/`

## Administration routes

Registered resources:

- `admin/dashboard`
- `admin/users`
- `admin/businesses`
- `admin/categories`
- `admin/products`
- `admin/deals`
- `admin/reviews`
- `admin/notifications/send/`

These endpoints prove that an administrative API surface exists. They do not prove that the future administration application is complete or that all role boundaries are correct.

## Business-owner routes

Registered resources:

- `business-owner/dashboard`
- `business-owner/businesses`
- nested `business-owner/businesses/{business}/products`
- nested `business-owner/businesses/{business}/deals`
- nested `business-owner/businesses/{business}/reviews`

The next permission audit must verify that business owners cannot access or mutate another owner's resources by changing identifiers.

## API documentation

The v2 API exposes:

- `schema/`
- `docs/` (Swagger UI)
- `redoc/`

The generated schema must be compared against actual serializers and Flutter parsing models before it is considered authoritative.

## Confirmed architectural observations

1. API v1 and v2 coexist, creating a risk of duplicated behavior and unclear ownership.
2. Public, administrator, and business-owner endpoints share the same API application.
3. Nested routers are used for business-owned resources.
4. Notifications and device registration are part of the v2 contract.
5. Subscription resources are exposed even though payment and billing readiness has not yet been validated.

## Verification backlog

- Build an endpoint/method/permission matrix from every ViewSet.
- Document pagination, filter, search, and ordering parameters.
- Record representative success and error payloads.
- Verify object-level permissions for admin and business-owner resources.
- Confirm image URL behavior in local and production environments.
- Compare v1 and v2 and define a deprecation plan.
- Validate OpenAPI completeness and serializer field accuracy.
- Add contract tests for endpoints consumed by Flutter.
