import 'package:in_app_purchase/in_app_purchase.dart';

import '../model/entitlement_status.dart';

abstract class IapRepository {
  Future<bool> isStoreAvailable();
  Future<ProductDetailsResponse> queryProducts(Set<String> ids);
  Future<void> startPurchase(ProductDetails product);
  Future<bool> restore();

  Future<EntitlementStatus> verifyAndroid({
    required String purchaseToken,
    required String productId,
    required String packageName,
    String? idempotencyKey, // для логов/контроля (опц.)
  });

  Future<EntitlementStatus> getMyEntitlement();

  Future<void> cacheEntitlement(EntitlementStatus s);
  EntitlementStatus getCachedEntitlement();
}
