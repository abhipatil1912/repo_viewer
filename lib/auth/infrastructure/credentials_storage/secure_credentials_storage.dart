import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/oauth2.dart';

import 'credentials_storage.dart';

class SecureCredentialsStorage implements CredentialsStorage {
  final FlutterSecureStorage _storage;
  static const _key = "oauth2_credentials";
  Credentials? _cashedCredential;

  SecureCredentialsStorage(this._storage);

  @override
  Future<Credentials?> read() async {
    if (_cashedCredential != null) return _cashedCredential;
    final json = await _storage.read(key: _key);
    if (json == null) return null;
    try {
      return _cashedCredential = Credentials.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Credentials credentials) {
    _cashedCredential = credentials;
    return _storage.write(key: _key, value: credentials.toJson());
  }

  @override
  Future<void> clear() {
    _cashedCredential = null;
    return _storage.delete(key: _key);
  }
}
