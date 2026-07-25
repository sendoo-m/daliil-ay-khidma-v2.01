# Flutter Web network bootstrap failure

## Symptom

The GitHub Pages client rendered correctly, but Home, Search, Deals, Favorites, and Profile all failed before any request appeared in the browser Network panel.

## Root cause

Every Dio request passed through the authentication interceptor, which awaited Flutter Secure Storage before forwarding the request. A storage exception on Web therefore aborted even public API requests before the browser could send them.

## Required behavior

- Public API requests must continue without an Authorization header when secure storage is unavailable.
- Token reads and cleanup must not crash the networking layer.
- Authenticated sessions should continue to use stored tokens whenever storage is available.
