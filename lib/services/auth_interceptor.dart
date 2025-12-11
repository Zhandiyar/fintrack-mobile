import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/storage_service.dart';
import '../features/auth/blocs/auth_bloc.dart';
import '../features/auth/blocs/auth_event.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final GlobalKey<NavigatorState> navigatorKey;

  bool _isRefreshing = false;
  Future<bool>? _refreshFuture;

  AuthInterceptor(this.dio, this.navigatorKey);

  Future<bool> _refreshToken() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final resp = await dio.post(
        '/api/auth/refresh', // <-- ВАЖНО: с /api
        data: {'refreshToken': refreshToken},
      );

      final data = resp.data['data'];

      await SecureStorage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  void _forceLogout(ErrorInterceptorHandler handler, DioException err) async {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ctx.read<AuthBloc>().add(LogoutRequested());
    }
    handler.next(err);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Нас интересуют только 401
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Если refresh уже идёт — ждём его
    if (_isRefreshing) {
      final ok = await (_refreshFuture ?? Future.value(false));
      if (!ok) {
        return _forceLogout(handler, err);
      }

      final newAccess = await SecureStorage.getAccessToken();
      if (newAccess == null) {
        return _forceLogout(handler, err);
      }

      // Повторяем запрос
      try {
        final clone = await _retry(err.requestOptions, newAccess);
        return handler.resolve(clone);
      } catch (_) {
        return _forceLogout(handler, err);
      }
    }

    // Первый 401 — запускаем refresh
    _isRefreshing = true;
    _refreshFuture = _refreshToken();
    final refreshed = await _refreshFuture!;
    _isRefreshing = false;

    if (!refreshed) {
      return _forceLogout(handler, err);
    }

    final newAccess = await SecureStorage.getAccessToken();
    if (newAccess == null) {
      return _forceLogout(handler, err);
    }

    try {
      final clone = await _retry(err.requestOptions, newAccess);
      return handler.resolve(clone);
    } catch (_) {
      return _forceLogout(handler, err);
    }
  }

  Future<Response> _retry(RequestOptions req, String token) {
    final options = Options(
      method: req.method,
      headers: {
        ...req.headers,
        'Authorization': 'Bearer $token',
      },
      responseType: req.responseType,
      contentType: req.contentType,
      followRedirects: req.followRedirects,
      receiveDataWhenStatusError: req.receiveDataWhenStatusError,
      validateStatus: req.validateStatus,
      receiveTimeout: req.receiveTimeout,
      sendTimeout: req.sendTimeout,
    );

    return dio.request(
      req.path,
      data: req.data,
      queryParameters: req.queryParameters,
      options: options,
    );
  }
}
