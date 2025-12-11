import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/currency/currency_bloc.dart';

class CurrencyFormatter {
  static final _numberFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '',
    decimalDigits: 2,
  );

  static String format(double amount, BuildContext context) {
    try {
      final currency = context.read<CurrencyBloc>().state.currency;
      return '${currency.symbol} ${_formatNumber(amount)}';
    } catch (e) {
      return '₸ ${_formatNumber(amount)}';
    }
  }

  static String formatWithoutSymbol(double amount) {
    return _formatNumber(amount);
  }

  static String _formatNumber(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
    }
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  static String formatWithCurrency(double amount, BuildContext context) {
    try {
      final currency = context.read<CurrencyBloc>().state.currency;
      return '${currency.symbol} ${_formatNumber(amount)} ${currency.code}';
    } catch (e) {
      return '₸ ${_formatNumber(amount)} KZT';
    }
  }

  static String formatCompact(double amount, BuildContext context) {
    try {
      final currency = context.read<CurrencyBloc>().state.currency;
      
      if (amount < 1000) {
        return '${currency.symbol} ${_formatNumber(amount)} ${currency.code}';
      }

      final compactFormat = NumberFormat.compactCurrency(
        locale: 'ru_RU',
        symbol: currency.symbol,
        decimalDigits: 1,
      );
      return '${compactFormat.format(amount)} ${currency.code}';
    } catch (e) {
      return '₸ ${_formatNumber(amount)} KZT';
    }
  }

  static String formatDetailed(double amount, BuildContext context) {
    try {
      final currency = context.read<CurrencyBloc>().state.currency;
      return '${currency.symbol} ${_numberFormat.format(amount)}';
    } catch (e) {
      return '₸ ${_numberFormat.format(amount)}';
    }
  }
} 