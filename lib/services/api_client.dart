import 'package:dio/dio.dart';
import 'package:fintrack/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'auth_interceptor.dart';
class ApiClient {
  final Dio dio;
  final GlobalKey<NavigatorState> navigatorKey;

  ApiClient({required this.navigatorKey})
      : dio = Dio(BaseOptions(
    baseUrl: "https://api.fin-track.pro",
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )) {
    dio.interceptors.add(AuthInterceptor(dio, navigatorKey));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await SecureStorage.getAccessToken();
          if (access != null) {
            options.headers["Authorization"] = "Bearer $access";
          }
          options.headers["Content-Type"] = "application/json";
          handler.next(options);
        },
      ),
    );
  }
}
