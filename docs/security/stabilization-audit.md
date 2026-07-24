# Stabilization Security Audit

## Scope

Initial static review of Django REST Framework permissions and queryset ownership boundaries. This is not a penetration test and does not replace automated authorization tests.

## Findings

### High priority: staff privilege boundary is too broad

`IsAdminUser` accepts every authenticated `is_staff` account. The administrative API exposes user CRUD, business/product/deal/review CRUD, moderation actions, and an action that can promote another account to staff.

**Required decision:** define whether `staff` means full platform administrator. If not, introduce explicit roles/permissions and reserve user promotion and destructive actions for super-admins.

### High priority: anonymous mutable analytics counters

Public business `increment_view` and `increment_click` actions accept anonymous POST requests. Without rate limiting or deduplication, counters can be inflated cheaply and cannot be treated as reliable analytics.

**Required change:** add throttling and a measurement policy, or move counting behind server-side event collection.

### Medium priority: first-business onboarding ambiguity

`IsBusinessOwner` permits staff, users with `is_business_owner`, or users who already own at least one business. A newly registered normal user with no business may be unable to create the first business unless another workflow sets the flag.

**Required decision:** document and test the owner-application/onboarding path.

### Medium priority: authorization tests are incomplete or not centrally documented

Querysets are generally owner-scoped, which is a good control, but cross-owner update/delete tests are required for businesses, nested products, images, deals, reviews, favorites, profile operations, and administrative actions.

### Medium priority: duplicated legacy code remains commented in production modules

Large commented historical implementations remain in API view modules. This increases review cost, hides active logic, and can lead to accidental restoration of obsolete permission behavior.

**Required change:** remove dead commented implementations after confirming Git history preserves them.

## Positive controls observed

- Public business listing is read-only and returns active, verified records.
- Favorites are filtered to the current user.
- Owner business, product, deal, image, and review querysets validate ownership.
- Nested product/deal creation validates the parent business owner.
- Admin ViewSets consistently declare a staff-only permission class.

## Exit criteria

- A role and permission policy is documented.
- Cross-account and cross-owner API tests pass.
- Anonymous mutation endpoints have an explicit anti-abuse policy.
- First-business onboarding has a tested workflow.
- Obsolete commented implementations are removed.
