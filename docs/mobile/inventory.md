# Flutter Application Inventory

> Baseline snapshot of the user-facing Flutter application. This records the architecture visible in the repository; it is not yet a device-by-device acceptance report.

## Application location

The Flutter client is located at:

```text
mobile/dalil_app/
```

The current package version is `0.1.0+1`.

## Core stack

- Flutter and Dart 3.x
- Riverpod for dependency injection and state management
- Dio for HTTP networking
- Flutter Secure Storage for tokens
- Firebase Core and Firebase Messaging
- App Links for deep-link handling
- Geolocator for device location
- MapLibre GL with OpenFreeMap map styles
- URL Launcher for external contact and direction actions
- Flutter localization generation

## Application layers

The current source follows a feature-oriented structure:

```text
lib/
├── app/
├── core/
└── features/
```

Shared providers connect repositories and infrastructure through Riverpod. The confirmed provider graph includes:

- token storage
- API client
- authentication repository and controller
- password-reset repository
- home repository
- business/directory repository
- catalogue repository
- application-configuration repository
- profile repository
- review repository
- notification repository
- device-registration repository
- push-notification service
- device-location service

## Confirmed feature areas

Based on repository code and merged development history, the application contains implementations for:

- guest/public home browsing
- registration and login
- password-reset flow
- business search and filtering
- product and service catalogue
- business details
- product/service details
- nearby search and maps
- external contact and directions
- deals and deal claiming
- favorites
- ratings and reviews
- profile management
- notification inbox and device registration
- remote application configuration

Each item remains subject to an end-to-end verification pass against the deployed API.

## Map implementation

The nearby screen uses MapLibre GL and an OpenFreeMap style URL. Business coordinates are parsed from API responses and displayed as interactive map circles. The screen also provides navigation to business details and opens external OpenStreetMap directions.

This confirms that Google Maps is not the current map implementation.

## Build and CI behavior

The Flutter workflow currently:

- installs Java 21
- installs stable Flutter
- generates Android, iOS, and Web platform projects during CI
- configures Firebase and deep links through scripts
- runs package resolution and localization generation
- formats source and tests
- runs `flutter analyze`
- runs `flutter test`
- builds a Web preview against the live Render API
- builds an Android debug APK
- builds iOS without signing
- deploys Web output to GitHub Pages after master pushes

## Technical risks to verify

1. Native platform folders are generated during CI, which may hide platform-specific configuration drift.
2. The provider file centralizes many dependencies and may become difficult to maintain as the admin application grows.
3. Feature completeness has mostly been inferred from code and commit history rather than a formal acceptance suite.
4. The live Render API can cold-start, so UI loading and retry states must be verified consistently.
5. Web, Android, and iOS may differ in secure storage, location, Firebase, deep-link, and map behavior.
6. Arabic localization exists, but full Arabic/English parity still needs a screen-by-screen audit.

## Verification backlog

- Record every screen and navigation route.
- Map every repository method to its API endpoint.
- Run guest and authenticated user journeys on Web and Android.
- Verify iOS platform configuration and permissions.
- Audit loading, empty, offline, unauthorized, and server-error states.
- Confirm token refresh behavior during concurrent requests.
- Confirm push-token lifecycle: register, refresh, logout, and deletion.
- Add widget tests for core journeys and repository contract tests.
