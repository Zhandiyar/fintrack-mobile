import 'package:dio/dio.dart';
import '../../../services/api_client.dart';
import '../domain/model/entitlement_status.dart';

class IapRemoteDs {
  final ApiClient _apiClient; // твой ApiClient.dio (с baseUrl)
  final bool mock; // TODO: switch mock=false на проде

  // 👇 текущее "серверное" состояние в режиме mock
  EntitlementStatus _mockServerEntitlement = EntitlementStatus.none;

  IapRemoteDs(this._apiClient, {this.mock = false});

  static const _verifyPath = '/api/subscription/google/verify';
  static const _mePath = '/api/subscription/entitlements/me';

  EntitlementStatus _parseEntitlement(dynamic data) {
    if (data is Map) {
      final raw = data['status'] ?? data['entitlement'];
      if (raw != null) return EntitlementX.fromServer(raw.toString());
      if (data['entitled'] == true) return EntitlementStatus.entitled;
    }
    return EntitlementStatus.none;
  }

  /// Проверка чека на бэкенде
  Future<EntitlementStatus> verifyAndroid({
    required String purchaseToken,
    required String productId,
    required String packageName,
    String? idempotencyKey,
  }) async {
    if (mock) {
      // эмулируем успешную верификацию на бэкенде
      await Future.delayed(const Duration(milliseconds: 250));
      _mockServerEntitlement = EntitlementStatus.entitled;
      return _mockServerEntitlement;
    }
    try {
      final resp = await _apiClient.dio.post(
        _verifyPath,
        data: {
          'purchaseToken': purchaseToken,
          'productId': productId,
          'packageName': packageName,
        },
        options: Options(headers: {
          if (idempotencyKey != null) 'X-Idempotency-Key': idempotencyKey,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );
      return _parseEntitlement(resp.data);
    } catch (e) {
      _rethrowHuman(e);
    }
  }

  /// Текущие права пользователя
  Future<EntitlementStatus> myEntitlements() async {
    if (mock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return _mockServerEntitlement; // ← возвращаем текущее mock состояние
    }
    try {
      final resp = await _apiClient.dio.get(
        _mePath,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return _parseEntitlement(resp.data);
    } catch (e) {
      _rethrowHuman(e);
    }
  }

  // === DEV helper (по желанию) ===
  Future<void> setMockState(EntitlementStatus s) async {
    if (mock) _mockServerEntitlement = s;
  }

  Never _rethrowHuman(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      // Бросаем читаемую ошибку — её поймает _humanizeError в блоке
      throw Exception('DioException $code ${body ?? ''}'.trim());
    }
    throw Exception(e.toString());
  }
}
