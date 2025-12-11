import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:fintrack/features/transaction/repository/transaction_repository.dart';
import 'package:fintrack/services/navigation.dart';
import 'package:fintrack/services/storage_service.dart';
import 'package:fintrack/ui/scaffolds/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/blocs/auth_bloc.dart';
import 'features/auth/blocs/auth_event.dart';
import 'features/auth/blocs/auth_state.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/settings/blocs/currency/currency_bloc.dart';
import 'features/settings/blocs/settings_bloc.dart';
import 'features/ai/blocs/ai_analyze_bloc.dart';
import 'features/ai/repository/ai_analyze_repository.dart';
import 'features/ai/screens/ai_deep_analyze_screen.dart';
import 'features/ai/screens/ai_quick_analyze_screen.dart';
import 'features/analytics/blocs/analytics_bloc.dart';
import 'features/analytics/repository/analytics_repository.dart';
import 'features/analytics/screens/reports_screen.dart';
import 'features/category/blocs/category_bloc.dart';
import 'features/category/repository/category_repository.dart';
import 'features/dashboard/blocs/dashboard_bloc.dart';
import 'features/dashboard/repository/dashboard_repository.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/iap/data/iap_local_ds.dart';
import 'features/iap/data/iap_remote_ds.dart';
import 'features/iap/data/repositories/iap_repository_impl.dart';
import 'features/iap/domain/repository/iap_repository.dart';
import 'features/iap/presentation/bloc/purchase_bloc.dart';
import 'features/iap/presentation/bloc/purchase_event.dart';
import 'features/iap/presentation/pages/paywall_page.dart';
import 'features/settings/blocs/theme/theme_bloc.dart';
import 'features/settings/blocs/theme/theme_state.dart';
import 'features/settings/repository/settings_repository.dart';
import 'features/transaction/blocs/transaction_bloc.dart';
import 'features/transaction/blocs/transaction_event.dart';
import 'features/transaction/screens/transaction_list_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);

  final prefs = await SharedPreferences.getInstance();
  final token = await SecureStorage.getAccessToken();

  final appLinks = AppLinks();
  final initialLink = await appLinks.getInitialAppLink();

  runApp(FinTrackApp(
    prefs: prefs,
    isAuthenticated: token != null,
    initialLink: initialLink,
    appLinks: appLinks,
  ));
}

class FinTrackApp extends StatefulWidget {
  final SharedPreferences prefs;
  final bool isAuthenticated;
  final Uri? initialLink;
  final AppLinks appLinks;

  const FinTrackApp({
    Key? key,
    required this.prefs,
    required this.isAuthenticated,
    required this.initialLink,
    required this.appLinks,
  }) : super(key: key);

  @override
  State<FinTrackApp> createState() => _FinTrackAppState();
}

class _FinTrackAppState extends State<FinTrackApp> {
  late final ApiClient apiClient;
  Uri? _pendingLink;

  @override
  void initState() {
    super.initState();

    apiClient = ApiClient(navigatorKey: navigatorKey);
    _pendingLink = widget.initialLink;

    /// Stream deep links
    widget.appLinks.uriLinkStream.listen((uri) {
      if (uri != null) _safeHandleDeepLink(uri);
    });

    /// Initial deep link (delayed for Android stability)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_pendingLink != null) {
        _safeHandleDeepLink(_pendingLink!);
        _pendingLink = null;
      }
    });
  }

  /// Safe handler with Navigator readiness check
  void _safeHandleDeepLink(Uri uri) {
    debugPrint("🔥 Deep link received: $uri");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState == null) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _safeHandleDeepLink(uri);
        });
        return;
      }
      _handleDeepLink(uri);
    });
  }

  /// Main deep link logic
  void _handleDeepLink(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return;

    final last = segments.last;

    if (last == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        navigatorKey.currentState?.pushNamed(
          '/reset-password',
          arguments: token,
        );
      }
    }
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => apiClient),
        Provider<TransactionRepository>(
            create: (_) => TransactionRepository(apiClient)),
        Provider<CategoryRepository>(
            create: (_) => CategoryRepository(apiClient)),
        Provider<DashboardRepository>(
            create: (_) => DashboardRepository(apiClient)),
        Provider<SettingsRepository>(
            create: (_) => SettingsRepository(apiClient)),
        Provider<AnalyticsRepository>(
            create: (_) => AnalyticsRepository(apiClient)),
        Provider<AuthRepository>(create: (_) => AuthRepository(apiClient)),
        Provider<AiAnalyzeRepository>(
            create: (_) => AiAnalyzeRepository(apiClient)),
        Provider<IapRemoteDs>(
          create: (ctx) => IapRemoteDs(apiClient, mock: false),
        ),
        Provider<IapRepository>(
          create: (ctx) => IapRepositoryImpl(
            iap: InAppPurchase.instance,
            local: IapLocalDs(widget.prefs),
            remote: ctx.read<IapRemoteDs>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (context) =>
              AuthBloc(authRepository: context.read<AuthRepository>())
                ..add(AppStarted())),
          BlocProvider(
              create: (context) =>
              TransactionBloc(context.read<TransactionRepository>())
                ..add(LoadTransactions())),
          BlocProvider(
              create: (context) =>
                  CategoryBloc(context.read<CategoryRepository>())),
          BlocProvider(
              create: (context) => DashboardBloc(context.read<DashboardRepository>())),
          BlocProvider(
              create: (context) =>
                  SettingsBloc(context.read<SettingsRepository>())),
          BlocProvider(
              create: (context) =>
                  AnalyticsBloc(context.read<AnalyticsRepository>())),
          BlocProvider(
            create: (context) =>
                AiAnalyzeBloc(context.read<AiAnalyzeRepository>()),
          ),
          BlocProvider(create: (_) => ThemeBloc(widget.prefs)),
          BlocProvider(create: (_) => CurrencyBloc(widget.prefs)),
          BlocProvider(
            create: (ctx) => PurchaseBloc(
              repo: ctx.read<IapRepository>(),
              iap: InAppPurchase.instance,
            )..add(PurchaseInit()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (_, s) => s is AuthLoggedOut,
          listener: (_, __) =>
              navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false),
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                title: 'FinTrack',
                theme: ThemeData(
                    colorSchemeSeed: Colors.deepPurple, brightness: Brightness.light),
                darkTheme: ThemeData(
                    colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark),
                themeMode: themeState.themeMode,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('ru')],
                locale: const Locale('ru'),
                initialRoute: '/loading',
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case '/ai-quick-analyze':
                      final args = settings.arguments as Map<String, dynamic>;
                      return MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (_) =>
                              AiAnalyzeBloc(context.read<AiAnalyzeRepository>()),
                          child: AiQuickAnalyzeScreen(
                            year: args['year'],
                            month: args['month'],
                            currency: args['currency'],
                          ),
                        ),
                      );
                    case '/ai-deep-analyze':
                      final args = settings.arguments as Map<String, dynamic>;
                      return MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (_) =>
                              AiAnalyzeBloc(context.read<AiAnalyzeRepository>()),
                          child: AiDeepAnalyzeScreen(
                            year: args['year'],
                            month: args['month'],
                            currency: args['currency'],
                          ),
                        ),
                      );
                    default:
                      return null;
                  }
                },
                routes: {
                  '/': (_) => LoadingScreen(isAuthenticated: widget.isAuthenticated),
                  '/loading': (_) =>
                      LoadingScreen(isAuthenticated: widget.isAuthenticated),
                  '/login': (context) => LoginScreen(),
                  '/register': (context) => RegisterScreen(),
                  '/forgot-password': (context) => ForgotPasswordScreen(),
                  '/reset-password': (context) => ResetPasswordScreen(),
                  '/transactions': (context) => TransactionListScreen(),
                  '/reports': (context) => ReportsScreen(),
                  '/dashboard': (context) => DashboardScreen(),
                  '/main': (context) => const MainScaffold(),
                  '/paywall': (_) => const PaywallPage(),
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  final bool isAuthenticated;

  const LoadingScreen({Key? key, required this.isAuthenticated}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = widget.isAuthenticated ? '/main' : '/login';
      Navigator.of(context).pushReplacementNamed(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}