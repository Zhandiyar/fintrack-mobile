import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:uuid/uuid.dart';

import '../../domain/model/entitlement_status.dart';
import '../../domain/repository/iap_repository.dart';
import '../../iap_ids.dart';
import 'purchase_event.dart';

part 'purchase_state.dart';

class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  final IapRepository repo;
  final InAppPurchase iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  static const String _androidPackage = IapIds.packageName;

  PurchaseBloc({required this.repo, required this.iap})
      : super(PurchaseState.initial()) {
    on<PurchaseInit>(_onInit);
    on<PurchaseRefreshProducts>(_onRefreshProducts);
    on<PurchaseBuy>(_onBuy);
    on<PurchaseRestore>(_onRestore);
    on<PurchaseRefreshEntitlement>(_onRefreshEntitlement);
    on<PurchaseStreamUpdate>(_onStreamUpdate);
  }

  String _humanizeError(Object err) {
    final msg = err.toString();

    // Google Play Billing codes often look like: BillingResponse.itemAlreadyOwned
    if (msg.contains('itemAlreadyOwned') ||
        msg.contains('ITEM_ALREADY_OWNED')) {
      return 'Подписка уже оформлена в Google. Нажмите «Проверить статус».';
    }
    if (msg.contains('itemUnavailable')) {
      return 'Тариф недоступен для этой сборки/страны аккаунта Google.';
    }
    if (msg.contains('userCancelled') || msg.contains('canceled')) {
      return 'Покупка отменена.';
    }

    if (msg.contains('DioException') || msg.contains('SocketException')) {
      return 'Нет сети или сервер недоступен. Проверьте интернет.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'Нужно войти в аккаунт, чтобы проверить подписку.';
    }
    if (msg.contains('notFoundIDs')) {
      return 'Товары не найдены в Google Play для этой сборки.';
    }
    return 'Что-то пошло не так. Попробуйте ещё раз.';
  }

  Future<void> _onInit(PurchaseInit e, Emitter<PurchaseState> emit) async {
    final cached = repo.getCachedEntitlement();
    final available = await repo.isStoreAvailable();
    emit(state.copyWith(status: cached, storeAvailable: available));

    add(PurchaseRefreshProducts());

    // 1) слушаем поток заранее
    _sub ??= iap.purchaseStream.listen(
      (updates) => add(PurchaseStreamUpdate(updates)),
      onError: (e, st) => debugPrint('purchaseStream error: $e\n$st'),
    );

    // 2) Android force-sync активных подписок (если оформили в Play)
    await _androidForceSync(emit);

    // 3) на всякий — restore (не вредит)
    try {
      await repo.restore();
    } catch (_) {}

    // 4) источник истины — бэк
    try {
      final remote = await repo.getMyEntitlement();
      await repo.cacheEntitlement(remote);
      emit(state.copyWith(status: remote));
    } catch (err, st) {
      debugPrint('getMyEntitlement error: $err\n$st');
      emit(state.copyWith(
        lastError: _humanizeError(err),
      ));
    }
  }

  Future<void> _onRefreshProducts(
      PurchaseRefreshProducts e, Emitter<PurchaseState> emit) async {
    emit(state.copyWith(
        isBusy: true, busyAction: BusyAction.products, lastError: null));
    try {
      final ids = {IapIds.monthly, IapIds.yearly};
      final resp = await repo.queryProducts(ids);
      if (resp.notFoundIDs.isNotEmpty) {
        debugPrint('IAP notFoundIDs: ${resp.notFoundIDs}');
        emit(state.copyWith(
          isBusy: false,
          busyAction: BusyAction.none,
          products: resp.productDetails,
          lastError: 'Товары не найдены: ${resp.notFoundIDs.join(', ')}',
        ));
      } else {
        emit(state.copyWith(
          products: resp.productDetails,
          isBusy: false,
          busyAction: BusyAction.none,
          lastError: null,
        ));
      }
    } catch (err, st) {
      debugPrint('queryProducts error: $err\n$st');
      emit(state.copyWith(
          isBusy: false,
          busyAction: BusyAction.none,
          lastError: _humanizeError(err)));
    }
  }

  Future<void> _onBuy(PurchaseBuy e, Emitter<PurchaseState> emit) async {
    if (state.isBusy) return;
    emit(state.copyWith(
        isBusy: true, busyAction: BusyAction.buy, lastError: null));
    try {
      await repo.startPurchase(e.product);
      // дальше придёт purchaseStream → там снимем busy
    } catch (err, st) {
      debugPrint('startPurchase error: $err\n$st');
      emit(state.copyWith(
        isBusy: false,
        busyAction: BusyAction.none,
        lastError: _humanizeError(err),
      ));
    }
  }

  Future<void> _onRestore(
      PurchaseRestore e, Emitter<PurchaseState> emit) async {
    if (state.isBusy) return;
    emit(state.copyWith(
        isBusy: true, busyAction: BusyAction.restore, lastError: null));
    try {
      final changed = await repo.restore();
      // если restore ничего не нашёл — подскажем пользователю
      if (changed == false) {
        emit(state.copyWith(
          isBusy: false,
          busyAction: BusyAction.none,
          lastError: 'Активные покупки на этом устройстве не найдены.',
        ));
      } else {
        emit(state.copyWith(
          isBusy: false,
          busyAction: BusyAction.none,
          lastError: null,
        ));
      }
    } catch (err, st) {
      debugPrint('restore error: $err\n$st');
      emit(state.copyWith(
        isBusy: false,
        busyAction: BusyAction.none,
        lastError: _humanizeError(err),
      ));
    }
  }

  Future<void> _onRefreshEntitlement(
      PurchaseRefreshEntitlement e, Emitter<PurchaseState> emit) async {
    if (state.isBusy) return;
    emit(state.copyWith(
        isBusy: true, busyAction: BusyAction.refreshEnt, lastError: null));
    try {
      await _androidForceSync(emit);
      final remote = await repo.getMyEntitlement();
      await repo.cacheEntitlement(remote);
      emit(state.copyWith(
          status: remote, isBusy: false, busyAction: BusyAction.none));

      if (!remote.isUnlocked) {
        emit(state.copyWith(
          lastError:
              'Активная подписка в Google не найдена для этого аккаунта/сборки.',
        ));
      }
    } catch (err, st) {
      debugPrint('refresh entitlement error: $err\n$st');
      emit(state.copyWith(
        isBusy: false,
        busyAction: BusyAction.none,
        lastError: _humanizeError(err),
      ));
    }
  }

  Future<void> _onStreamUpdate(
      PurchaseStreamUpdate e, Emitter<PurchaseState> emit) async {
    for (final p in e.updates) {
      switch (p.status) {
        case PurchaseStatus.pending:
          emit(state.copyWith(isBusy: true)); // busyAction оставляем прежним
          break;

        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) {
            try {
              await InAppPurchase.instance.completePurchase(p);
            } catch (_) {}
          }
          emit(state.copyWith(
            isBusy: false,
            busyAction: BusyAction.none,
            lastError: 'Покупка отменена.',
          ));
          break;

        case PurchaseStatus.error:
          final msg = p.error?.message ?? '';
          final alreadyOwned = msg.contains('ITEM_ALREADY_OWNED') ||
              msg.contains('already owned') ||
              msg.contains('already purchased');

          if (alreadyOwned) {
            emit(state.copyWith(
              isBusy: true,
              busyAction: BusyAction.refreshEnt,
              lastError: 'Подписка уже активна в Google. Синхронизируем…',
            ));
            try {
              await _androidForceSync(emit);
              final remote = await repo.getMyEntitlement();
              await repo.cacheEntitlement(remote);
              emit(state.copyWith(
                status: remote,
                isBusy: false,
                busyAction: BusyAction.none,
                lastError: null,
              ));
            } catch (e, st) {
              debugPrint('alreadyOwned sync error: $e\n$st');
              emit(state.copyWith(
                isBusy: false,
                busyAction: BusyAction.none,
                lastError:
                    'Подписка уже активна. Нажмите «Проверить статус» или «Восстановить покупки».',
              ));
            }
            break;
          }

          emit(state.copyWith(
            isBusy: false,
            busyAction: BusyAction.none,
            lastError: p.error?.message ?? 'Ошибка покупки',
          ));
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final token = p.verificationData.serverVerificationData;
            final productId = p.productID;
            final idemp = const Uuid().v4();
            final verified = await repo.verifyAndroid(
              purchaseToken: token,
              productId: productId,
              packageName: _androidPackage,
              idempotencyKey: idemp,
            );
            await repo.cacheEntitlement(verified);
            emit(state.copyWith(
              status: verified,
              isBusy: false,
              busyAction: BusyAction.none,
              lastError: null,
            ));
          } catch (err, st) {
            debugPrint('verify error: $err\n$st');
            emit(state.copyWith(
              isBusy: false,
              busyAction: BusyAction.none,
              lastError: 'Не удалось подтвердить покупку',
            ));
          } finally {
            if (p.pendingCompletePurchase) {
              try {
                await InAppPurchase.instance.completePurchase(p);
              } catch (err) {
                debugPrint('completePurchase error: $err');
              }
            }
          }
          break;
      }
    }
  }

  Future<void> _androidForceSync(Emitter<PurchaseState> emit) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final android =
          iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      // История на устройстве (включая отменённые/истёкшие)
      final res = await android.queryPastPurchases();
      final past = res.pastPurchases;
      if (past.isEmpty) return;

      // Фильтруем: берём только действительно купленные/автопродляемые
      // и оставляем самую свежую запись на каждый productId.
      final Map<String, GooglePlayPurchaseDetails> latestByProduct = {};

      for (final p in past) {
        // На Android это GooglePlayPurchaseDetails
        if (p is GooglePlayPurchaseDetails) {
          final w = p.billingClientPurchase; // GooglePlayPurchaseWrapper
          // Только успешные покупки
          if (w.purchaseState != PurchaseStateWrapper.purchased) continue;
          // (опц.) если хочешь тащить только активные подписки (автопродление):
          // if (w.isAutoRenewing != true) continue;

          // Берём самую свежую по времени
          final prev = latestByProduct[p.productID];
          if (prev != null) {
            final prevTime = prev.billingClientPurchase.purchaseTime ?? 0;
            final currTime = w.purchaseTime ?? 0;
            if (currTime <= prevTime) continue;
          }
          latestByProduct[p.productID] = p;
        }
      }

      if (latestByProduct.isEmpty) {
        // нет активных покупок на устройстве
        return;
      }

      // Верифицируем только уникальные и свежие
      for (final p in latestByProduct.values) {
        final token = p.verificationData.serverVerificationData;
        if (token.isEmpty) continue; // safety
        final idemp = const Uuid().v4();
        final verified = await repo.verifyAndroid(
          purchaseToken: token,
          productId: p.productID,
          packageName: _androidPackage,
          idempotencyKey: idemp,
        );
        await repo.cacheEntitlement(verified);
        emit(state.copyWith(status: verified));
      }
    } catch (e, st) {
      debugPrint('androidForceSync error: $e\n$st');
      // UX не ломаем — просто лог.
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
