import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeBloc(this._prefs) : super(const ThemeState()) {
    on<ThemeChanged>(_onThemeChanged);
    _loadTheme();
  }

  void _loadTheme() {
    final String? themeModeString = _prefs.getString(_themeKey);
    if (themeModeString != null) {
      final ThemeMode themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeString,
      );
      add(ThemeChanged(themeMode));
    }
  }

  Future<void> _onThemeChanged(
    ThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    await _prefs.setString(_themeKey, event.themeMode.toString());
    emit(state.copyWith(themeMode: event.themeMode));
  }
} 