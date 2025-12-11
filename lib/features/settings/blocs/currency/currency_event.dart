import 'package:equatable/equatable.dart';

import '../../model/currency.dart';

abstract class CurrencyEvent extends Equatable {
  const CurrencyEvent();

  @override
  List<Object?> get props => [];
}

class CurrencyChanged extends CurrencyEvent {
  final Currency currency;

  const CurrencyChanged(this.currency);

  @override
  List<Object?> get props => [currency];
} 