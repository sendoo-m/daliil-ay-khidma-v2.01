import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class TokenPair {
  const TokenPair({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

final class TokenStore {
  TokenStore(this._storage);

  static const _accessKey = 'auth.access_token';
  static const _refreshKey = 'auth.refresh_token';
  final FlutterSecureStorage _storage;

  Future<String?> readAccess() => _safeRead(_accessKey);
  Future<String?> readRefresh() => _safeRead(_refreshKey);

  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // Secure storage can be unavailable in some Web browser contexts.
      // Public API requests must still continue as guest requests.
      return null;
    }
  }

  Future<void> save(TokenPair tokens) async {
    try {
      await Future.wait([
        _storage.write(key: _accessKey, value: tokens.access),
        _storage.write(key: _refreshKey, value: tokens.refresh),
      ]);
    } catch (_) {
      // Do not let a browser storage failure crash the networking layer.
    }
  }

  Future<void> clear() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
      ]);
    } catch (_) {
      // An unavailable store is equivalent to having no persisted session.
    }
  }

  Future<bool> get hasSession async => (await readRefresh()) != null;
}
