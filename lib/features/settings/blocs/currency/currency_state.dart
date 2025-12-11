import 'package:equatable/equatable.dart';

import '../../model/currency.dart';

class CurrencyState extends Equatable {
  final Currency currency;

  const CurrencyState({
    required this.currency,
  });

  CurrencyState copyWith({
    Currency? currency,
  }) {
    return CurrencyState(
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [currency];
}
//
// class CurrencyInitial extends CurrencyState {
//   const CurrencyInitial();
// }
//
// class CurrencyLoading extends CurrencyState {
//   const CurrencyLoading();
// }
//
// class CurrencyLoaded extends CurrencyState {
//   final Currency currency;
//   final String symbol;
//   final String code;
//   final double rate;
//
//   const CurrencyLoaded({
//     required this.currency,
//     required this.symbol,
//     required this.code,
//     required this.rate,
//   });
//
//   @override
//   List<Object?> get props => [currency, symbol, code, rate];
//
//   CurrencyLoaded copyWith({
//     Currency? currency,
//     String? symbol,
//     String? code,
//     double? rate,
//   }) {
//     return CurrencyLoaded(
//       currency: currency ?? this.currency,
//       symbol: symbol ?? this.symbol,
//       code: code ?? this.code,
//       rate: rate ?? this.rate,
//     );
//   }
// }
//
// class CurrencyError extends CurrencyState {
//   final String message;
//
//   const CurrencyError(this.message);
//
//   @override
//   List<Object?> get props => [message];
// }