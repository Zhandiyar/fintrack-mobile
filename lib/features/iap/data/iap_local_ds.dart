import 'package:shared_preferences/shared_preferences.dart';
import '../domain/model/entitlement_status.dart';

class IapLocalDs {
  static const _key = 'iap_entitlement_v2'; // строка-статус
  final SharedPreferences sp;

  IapLocalDs(this.sp);

  EntitlementStatus getCached() {
    final s = sp.getString(_key);
    if (s != null) return EntitlementX.fromServer(s);
    // миграция со старой версии (если вдруг был bool)
    final old = sp.getBool('iap_entitlement') == true;
    return old ? EntitlementStatus.entitled : EntitlementStatus.none;
  }

  Future<void> save(EntitlementStatus s) async => sp.setString(_key, s.label);
}
