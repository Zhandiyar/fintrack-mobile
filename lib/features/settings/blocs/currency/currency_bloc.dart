import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../model/currency.dart';
import 'currency_event.dart';
import 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  static const String _currencyKey = 'currency_code';
  final SharedPreferences _prefs;

  CurrencyBloc(this._prefs) : super(CurrencyState(currency: Currency.defaultCurrency)) {
    on<CurrencyChanged>(_onCurrencyChanged);
    _loadCurrency();
  }

  void _loadCurrency() {
    try {
      final String? currencyCode = _prefs.getString(_currencyKey);
      if (currencyCode != null) {
        final Currency currency = Currency.getCurrencyByCode(currencyCode);
        if (kDebugMode) {
          print('Загружена сохраненная валюта: ${currency.code}');
        }
        add(CurrencyChanged(currency));
      } else {
        if (kDebugMode) {
          print('Используется валюта по умолчанию: ${Currency.defaultCurrency.code}');
        }
        add(CurrencyChanged(Currency.defaultCurrency));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка при загрузке валюты: $e');
      }
      add(CurrencyChanged(Currency.defaultCurrency));
    }
  }

  Future<void> _onCurrencyChanged(
    CurrencyChanged event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      await _prefs.setString(_currencyKey, event.currency.code);
      if (kDebugMode) {
        print('Валюта изменена на: ${event.currency.code}');
      }
      emit(state.copyWith(currency: event.currency));
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка при сохранении валюты: $e');
      }
    }
  }
} 