import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:uuid/uuid.dart';

import '../../domain/model/entitlement_status.dart';
import '../../domain/repository/iap_repository.dart';
import '../../iap_ids.dart';
import '../iap_local_ds.dart';
import '../iap_remote_ds.dart';


class IapRepositoryImpl implements IapRepository {
  final InAppPurchase iap;
  final IapLocalDs local;
  final IapRemoteDs remote;

  IapRepositoryImpl({required this.iap, required this.local, required this.remote});

  @override
  Future<bool> isStoreAvailable() => iap.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProducts(Set<String> ids) {
    return iap.queryProductDetails(ids);
  }

  @override
  Future<void> startPurchase(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await iap.buyNonConsumable(purchaseParam: param); // для подписок ok
  }

  @override
  Future<bool> restore() async {
    if (Platform.isAndroid) {
      // На Android сами тянем историю и верифицируем на бэке.
      final android =
      iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      final res = await android.queryPastPurchases();
      final past = res.pastPurchases.whereType<GooglePlayPurchaseDetails>().toList();
      if (past.isEmpty) return false;

      // Оставим самую свежую запись на каждый productId
      final Map<String, GooglePlayPurchaseDetails> latestByProduct = {};
      for (final p in past) {
        final w = p.billingClientPurchase;
        // Берём только реально совершённые покупки
        if (w.purchaseState != PurchaseStateWrapper.purchased) continue;

        final prev = latestByProduct[p.productID];
        if (prev != null) {
          final prevTs = prev.billingClientPurchase.purchaseTime ?? 0;
          final currTs = w.purchaseTime ?? 0;
          if (currTs <= prevTs) continue;
        }
        latestByProduct[p.productID] = p;
      }
      if (latestByProduct.isEmpty) return false;

      bool anyVerified = false;
      for (final p in latestByProduct.values) {
        final token = p.verificationData.serverVerificationData;
        if (token.isEmpty) continue;

        final idemp = const Uuid().v4();
        final verified = await remote.verifyAndroid(
          purchaseToken: token,
          productId: p.productID,
          packageName: IapIds.packageName,
          idempotencyKey: idemp,
        );

        await local.save(verified);
        anyVerified = true;
      }
      return anyVerified;
    } else {
      // На iOS инициируем восстановление — результат придёт в purchaseStream.
      await iap.restorePurchases();
      return true; // инициировали процесс
    }
  }

  @override
  Future<EntitlementStatus> verifyAndroid({
    required String purchaseToken,
    required String productId,
    required String packageName,
    String? idempotencyKey,
  }) => remote.verifyAndroid(
    purchaseToken: purchaseToken,
    productId: productId,
    packageName: packageName,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<EntitlementStatus> getMyEntitlement() => remote.myEntitlements();

  @override
  Future<void> cacheEntitlement(EntitlementStatus s) => local.save(s);

  @override
  EntitlementStatus getCachedEntitlement() => local.getCached();
}
