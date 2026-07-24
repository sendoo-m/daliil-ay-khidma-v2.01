# API Permission Matrix

> Status: stabilization audit draft

This document records the effective permission boundaries observed in the current Django REST Framework implementation. It describes code behavior, not yet production-verified behavior.

## Roles

- **Guest**: unauthenticated visitor.
- **User**: authenticated normal account.
- **Business owner**: authenticated account accepted by `IsBusinessOwner`.
- **Staff**: authenticated account with `is_staff=True`.

## Public directory

| Resource / action | Guest | User | Business owner | Staff | Notes |
| --- | --- | --- | --- | --- | --- |
| Governorates, cities, districts, categories: list/retrieve | Allow | Allow | Allow | Allow | Read-only ViewSets. |
| Businesses: list/retrieve/search/filter/nearby | Allow | Allow | Allow | Allow | Only active and verified businesses are returned. |
| Businesses: `increment_view` | Allow | Allow | Allow | Allow | Public POST; requires throttling and abuse review. |
| Businesses: `increment_click` | Allow | Allow | Allow | Allow | Public POST; requires throttling and abuse review. |
| Favorites: list/create/delete/toggle | Deny | Own records | Own records | Own records | Queryset is scoped to `request.user`. |

## Authentication and profile

| Resource / action | Guest | User | Business owner | Staff |
| --- | --- | --- | --- | --- |
| Login, token refresh, registration, password-reset request/confirm | Allow | Allow | Allow | Allow |
| Profile read/update, password change, logout | Deny | Own account | Own account | Own account |

The function-level permission decorators and serializer write fields still need endpoint-by-endpoint validation tests.

## Business-owner API

| Resource / action | Guest | User | Business owner | Staff | Effective ownership scope |
| --- | --- | --- | --- | --- | --- |
| Dashboard statistics | Deny | Conditional deny | Allow | Allow by permission class | Statistics are filtered by `request.user`; staff do not receive global data. |
| Businesses CRUD | Deny | Conditional deny | Allow | Allow by permission class | Queryset contains only businesses owned by `request.user`. |
| Business images list/create/delete | Deny | Conditional deny | Allow | Allow by permission class | Parent business is obtained from owner-scoped queryset. |
| Nested products CRUD/images | Deny | Conditional deny | Allow | Allow by permission class | Queryset and creation validate `business__owner=request.user`. |
| Nested deals CRUD | Deny | Conditional deny | Allow | Allow by permission class | Queryset and creation validate `business__owner=request.user`. |
| Nested reviews read | Deny | Conditional deny | Allow | Allow by permission class | Read-only and filtered by business owner. |

`IsBusinessOwner` allows an account when it is staff, has `is_business_owner`, or already owns a business. This creates an onboarding question: a normal authenticated user with no business cannot create their first business through this API unless another flag is set first.

## Administrative API

| Resource / action | Guest | User | Business owner | Staff | Notes |
| --- | --- | --- | --- | --- | --- |
| Dashboard statistics and analytics | Deny | Deny | Deny unless staff | Allow | Staff-only permission. |
| Users full CRUD | Deny | Deny | Deny unless staff | Allow | Sensitive fields require serializer audit. |
| Toggle user active / make staff | Deny | Deny | Deny unless staff | Allow | Any staff account can promote another account to staff. |
| Businesses, categories, products, deals, reviews full CRUD | Deny | Deny | Deny unless staff | Allow | No distinction between moderator and super-admin roles. |
| Verify/feature businesses and approve/reject reviews | Deny | Deny | Deny unless staff | Allow | Staff-only moderation actions. |

## Confirmed controls

- Public business data is read-only and filtered to active, verified records.
- Favorite records are scoped to the authenticated user.
- Business-owner querysets filter by `request.user` ownership.
- Nested product and deal creation validates ownership of the parent business.
- Administrative ViewSets consistently use `IsAdminUser`.

## Risks requiring tests or changes

1. Public counter mutation endpoints can be called anonymously and repeatedly.
2. Every staff account currently receives broad administrative powers, including staff promotion.
3. Business-owner onboarding may block creation of the first business.
4. Object-level permission tests are not documented for all update/delete actions.
5. Serializer write-field exposure must be reviewed, especially users, businesses, reviews, deals, and ownership fields.
6. API v1 and API v2 coexist; permission differences between them must be tested before v1 retirement.

## Required automated scenarios

- Guest cannot access favorites, profile, owner, or admin resources.
- User A cannot retrieve, update, or delete User B's favorites.
- Owner A cannot access businesses, products, images, deals, or reviews belonging to Owner B.
- A normal user cannot access admin endpoints.
- A staff user can access intended moderation endpoints.
- Staff promotion is restricted to the intended highest administrative role after roles are formalized.
- Public counter endpoints are throttled and reject invalid targets.
- A newly registered intended owner can complete the first-business onboarding flow.
