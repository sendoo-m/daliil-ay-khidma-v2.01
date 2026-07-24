# Django Model Audit Plan

The repository contains multiple domain applications, but the baseline must not treat an installed application as proof that every model and workflow is production-ready.

## Installed local applications

- `core`
- `accounts`
- `api`
- `directory`
- `products`
- `categories`
- `reviews`
- `subscriptions`
- `deals`
- `services`
- `search`
- `dashboard`
- `notifications`

## Audit method

For every concrete model, record:

1. owning Django application;
2. table purpose;
3. primary relationships;
4. ownership boundary;
5. lifecycle/status fields;
6. soft-delete or archival behavior;
7. indexes and uniqueness constraints;
8. uploaded files and validation;
9. serializer exposure;
10. administration and business-owner access;
11. existing tests;
12. migration risks.

## High-risk relationship groups

The first pass should prioritize:

- user ↔ business ownership;
- location hierarchy ↔ business;
- category hierarchy ↔ business/product;
- business ↔ product/service;
- business/product ↔ deal;
- user ↔ favorite;
- user/business ↔ review and owner response;
- subscription plan ↔ subscription ↔ business/user;
- device token ↔ user;
- notification ↔ recipient and read state.

## Required invariants

The audit must confirm or add tests for these rules:

- a business owner can mutate only owned businesses and nested resources;
- duplicate favorites are prevented;
- review ownership is enforced;
- rating aggregates remain consistent after create/update/delete;
- location parent relationships are valid;
- expired deals cannot be claimed;
- duplicate or over-limit deal claims are prevented;
- device tokens do not remain incorrectly assigned after logout/account changes;
- subscription state cannot grant features after expiry;
- file/image fields reject unsupported or excessive uploads.

## Deliverable

The detailed model inventory will be generated during the stabilization audit and will include a relationship diagram after the concrete model definitions and migrations are checked. This file intentionally avoids inventing fields that have not yet been verified from source.
