import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:uuid/uuid.dart';
import '../model/entitlement_status.dart';
import '../../iap_ids.dart';
import '../repository/iap_repository.dart';

class Purchase {
  final IapRepository repo;
  Purchase(this.repo);

  Future<void> start(ProductDetails p) => repo.startPurchase(p);

  /// Handle purchase update: verify with backend and cache.
  Future<EntitlementStatus?> handle(PurchaseDetails pd) async {
    if (pd.status == PurchaseStatus.purchased || pd.status == PurchaseStatus.restored) {
      final token = pd.verificationData.serverVerificationData; // purchaseToken
      final idemp = const Uuid().v4();
      final status = await repo.verifyAndroid(
        purchaseToken: token,
        productId: pd.productID,
        packageName: IapIds.packageName,
        idempotencyKey: idemp,
      );
      await repo.cacheEntitlement(status);
      return status;
    }
    return null;
  }
}
