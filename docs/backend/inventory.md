# Backend Technical Inventory

> Status: initial verified inventory. This document records what is present in the repository and identifies items that still need endpoint- and model-level verification.

## Runtime and framework

- Python backend using Django 5.2.x.
- Django REST Framework for the mobile/public API.
- Simple JWT with token blacklisting.
- SQLite is the base/local default; PostgreSQL is used for production deployments.
- Cloudinary-backed production media storage with local fallback.
- drf-spectacular for OpenAPI/Swagger.
- django-filter and CORS middleware are installed.

## Installed local applications

The active Django settings register these local applications:

| Application | Current responsibility |
|---|---|
| `apps.core` | shared pages, middleware, context processors and site-level behavior |
| `apps.accounts` | users, authentication, account profile and permissions |
| `apps.api` | REST serializers, views and API routing |
| `apps.directory` | locations, categories, businesses and favorites |
| `apps.products` | products and services attached to businesses |
| `apps.categories` | category administration and related domain helpers |
| `apps.reviews` | ratings and reviews |
| `apps.subscriptions` | plans, subscriptions and payment-related records |
| `apps.deals` | offers, discounts and claims |
| `apps.services` | supporting service-layer utilities |
| `apps.search` | search behavior and search-facing views |
| `apps.dashboard` | dashboard pages and reporting surfaces |
| `apps.notifications` | user/device notification records and delivery integration |

## Confirmed platform capabilities

The codebase contains support for:

- Arabic and English content.
- Governorate, city and district location hierarchy.
- Business profiles, contact details, coordinates, opening hours and galleries.
- Products and services.
- Deals and discounts.
- Favorites and reviews.
- JWT authentication and account flows.
- User notifications.
- Nearby search using latitude, longitude and radius.
- Durable production media storage.
- Admin and server-rendered Django pages in addition to the REST API.

## Configuration observations

- The default language is Arabic and the configured timezone is `Africa/Cairo`.
- The settings file still contains commented historical middleware configuration and informal comments; these should be cleaned only after behavior is verified.
- A development fallback secret exists in base settings. Production safety depends on the deployed environment overriding it.
- The repository currently combines API, server-rendered pages and administration in one Django project. This is acceptable for the current stage but boundaries must be documented before major expansion.

## Verification still required

The next pass must extract and verify:

1. Every model and its relationships.
2. Every public and authenticated endpoint.
3. Permissions and object ownership rules.
4. Pagination, filtering and ordering behavior.
5. Error response shapes.
6. File upload validation and limits.
7. Database indexes used by search and nearby queries.
8. Subscription/payment functionality versus models that are only scaffolded.
9. Notification delivery status versus stored inbox functionality.
10. Automated test coverage for each domain.

## Baseline rule

A capability is not marked production-ready merely because a model, serializer or screen exists. It must have a verified end-to-end flow, permission checks, error handling and automated or repeatable acceptance tests.
