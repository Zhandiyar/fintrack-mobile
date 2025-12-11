import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class PurchaseEvent extends Equatable {
  const PurchaseEvent();
  @override
  List<Object?> get props => [];
}

class PurchaseInit extends PurchaseEvent {}

class PurchaseRefreshProducts extends PurchaseEvent {}

class PurchaseBuy extends PurchaseEvent {
  final ProductDetails product;
  const PurchaseBuy(this.product);
  @override
  List<Object?> get props => [product.id];
}

class PurchaseRestore extends PurchaseEvent {}

class PurchaseRefreshEntitlement extends PurchaseEvent {}

class PurchaseStreamUpdate extends PurchaseEvent {
  final List<PurchaseDetails> updates;
  const PurchaseStreamUpdate(this.updates);
  @override
  List<Object?> get props => [updates];
}
