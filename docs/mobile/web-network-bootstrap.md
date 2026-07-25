# Flutter Web network bootstrap

The Web client must not abort public API requests when browser secure storage is unavailable. Every Dio request passes through the authentication interceptor, so token reads must degrade to a guest request instead of throwing before the browser sends the request.
