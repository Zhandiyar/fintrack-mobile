part of 'purchase_bloc.dart';

enum BusyAction { none, buy, restore, refreshEnt, products }

class PurchaseState extends Equatable {
  final EntitlementStatus status;        // право (backend)
  final List<ProductDetails> products;   // товары из стора
  final bool isBusy;                     // индикатор процесса
  final BusyAction busyAction;
  final String? lastError;               // ошибка UI/snackbar
  final bool storeAvailable;             // доступность биллинга

  const PurchaseState({
    required this.status,
    required this.products,
    required this.isBusy,
    required this.busyAction,
    required this.lastError,
    required this.storeAvailable,
  });

  factory PurchaseState.initial() => const PurchaseState(
    status: EntitlementStatus.none,
    products: <ProductDetails>[],
    isBusy: false,
    busyAction: BusyAction.none,
    lastError: null,
    storeAvailable: true,
  );

  PurchaseState copyWith({
    EntitlementStatus? status,
    List<ProductDetails>? products,
    bool? isBusy,
    BusyAction? busyAction,
    String? lastError,
    bool? storeAvailable,
  }) {
    return PurchaseState(
      status: status ?? this.status,
      products: products ?? this.products,
      isBusy: isBusy ?? this.isBusy,
      busyAction: busyAction ?? this.busyAction,
      lastError: lastError,
      storeAvailable: storeAvailable ?? this.storeAvailable,
    );
  }

  @override
  List<Object?> get props => [status, products, isBusy, busyAction, lastError, storeAvailable];
}
