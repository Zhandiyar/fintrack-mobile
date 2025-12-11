import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

class SecureStorage {
  static const _access = "access_token";
  static const _refresh = "refresh_token";
  static const _guest = "is_guest";

  static const _storage = FlutterSecureStorage();

  // --- SAVE TOKENS ---
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _access, value: accessToken);
    await _storage.write(key: _refresh, value: refreshToken);

    bool isGuest = false;
    try {
      final payload = Jwt.parseJwt(accessToken);
      final roles = (payload['roles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      isGuest = roles.contains("ROLE_GUEST");
    } catch (e) {
      // можно залогировать, но не падать
    }

    await _storage.write(key: _guest, value: isGuest ? 'true' : 'false');
  }

  // --- READ ---
  static Future<String?> getAccessToken() => _storage.read(key: _access);
  static Future<String?> getRefreshToken() => _storage.read(key: _refresh);

  static Future<void> setGuest(bool value) async {
    await _storage.write(key: _guest, value: value ? 'true' : 'false');
  }
  static Future<bool> isGuest() async {
    final v = await _storage.read(key: _guest);
    return v == "true";
  }

  // --- CLEAR ---
  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
