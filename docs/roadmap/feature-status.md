# Feature Status Matrix

> Status is evidence-based. `Implemented` means code and routes exist; it does not automatically mean production-ready. `Needs verification` means an end-to-end acceptance test is still required.

| Area | Current evidence | Baseline status | Next verification |
|---|---|---|---|
| Public home | Flutter home repository and v2 `home/` endpoint | Implemented; needs verification | Load live data as guest on Web and Android |
| Registration/login | JWT auth routes, auth repository/controller, UI work | Implemented; needs verification | Register, login, refresh, logout, invalid credentials |
| Password reset | Request/confirm routes and Flutter repository | Implemented; needs verification | Deep link, expiry, invalid token, changed password login |
| Business directory | Public businesses resource and Flutter repository | Implemented; needs verification | Pagination, detail loading, image URLs, filters |
| Locations | Governorates, cities, districts resources | Implemented; needs verification | Cascading filtering and incomplete location data |
| Search and filters | Repository history and directory API | Implemented; needs verification | Arabic/English terms, empty results, ordering, distance |
| Nearby map | Geolocation, MapLibre, coordinates, directions | Implemented; needs verification | Permission states, map loading, missing coordinates |
| Products/services | Public products resource and catalogue UI | Implemented; needs verification | Business catalogue, detail, price and image parsing |
| Favorites | Favorites resource and Flutter flows | Implemented; needs verification | Guest gating, add/remove, refresh, duplicate requests |
| Reviews | Public reviews resource and Flutter repository/UI | Implemented; needs verification | Ownership, edit/delete, moderation, average refresh |
| Deals | Deals and deal-claims resources | Implemented; needs verification | Validity, authentication, repeat claim, expired deals |
| Profile | Profile read/update/password routes | Implemented; needs verification | Validation, persistence, unauthorized and session expiry |
| Notifications | Devices, notifications, app config, send endpoint | Implemented; needs verification | Token registration, inbox state, logout cleanup, delivery |
| Business-owner API | Dashboard and nested business resources | Implemented API surface; unverified | Object ownership and CRUD acceptance tests |
| Admin API | Dashboard/users/businesses/categories/products/deals/reviews | Implemented API surface; unverified | Role enforcement, moderation and destructive actions |
| Admin Flutter app | Product requirement only | Not established | Decide separate package vs role-based application |
| Subscriptions | Plans and subscriptions resources exist | Partial/uncertain | Billing model, payment provider, lifecycle and enforcement |
| Payments | No production payment readiness confirmed | Not verified | Product decision and provider integration plan |
| Bilingual parity | Django/Flutter localization foundations exist | Partial/uncertain | Screen and response-field parity audit |
| Production media | Cloudinary support exists with local fallback | Implemented; needs verification | Upload persistence, transformations, invalid files, URLs |
| API documentation | Schema, Swagger and ReDoc routes exist | Implemented; needs verification | Compare generated contract with serializers and Flutter |
| Automated backend tests | pytest tooling and historical tests exist | Partial/uncertain | Inventory tests, run suite, record coverage and failures |
| Automated Flutter tests | CI runs `flutter test` | Partial/uncertain | Inventory tests and map them to critical journeys |
| Web preview | GitHub Pages workflow exists | Implemented; needs verification | Open current deployment and complete smoke test |
| Android build | CI builds debug APK | Implemented; needs verification | Install current artifact and run acceptance checklist |
| iOS build | CI builds without signing | Build-only | Verify native configuration and signed-device testing |

## Baseline priorities produced by this matrix

1. Verify critical guest journey: home → search → business → product/service → map/contact.
2. Verify critical account journey: register/login → favorite → review → profile → logout.
3. Audit object-level permissions for business-owner and administrator APIs.
4. Establish a single authoritative API contract and reduce v1/v2 ambiguity.
5. Decide the administration application architecture only after API permission verification.
6. Treat subscriptions and payments as later product work until the core directory is stable.

## Definition of baseline complete

The baseline phase can close when:

- each critical journey has a reproducible acceptance checklist;
- API permissions and ownership are tested;
- current CI is green and documented;
- known failures are converted into prioritized issues;
- documentation describes actual behavior rather than intended behavior;
- the team can name the exact first stabilization sprint without further discovery.
