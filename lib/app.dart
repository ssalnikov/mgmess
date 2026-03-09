import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/auth/biometric_service.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/l10n/l10n.dart';
import 'core/observability/analytics_service.dart';
import 'core/observability/crash_reporting.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/connectivity/connectivity_cubit.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/notification/notification_event.dart';
import 'presentation/blocs/locale/locale_cubit.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/blocs/user_status/user_status_cubit.dart';
import 'presentation/blocs/websocket/websocket_bloc.dart';
import 'presentation/blocs/websocket/websocket_event.dart';
import 'presentation/screens/auth/biometric_lock_screen.dart';
import 'presentation/screens/server/server_url_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late bool _serverReady;

  AuthBloc? _authBloc;
  WebSocketBloc? _wsBloc;
  ConnectivityCubit? _connectivityCubit;
  NotificationBloc? _notificationBloc;
  UserStatusCubit? _userStatusCubit;
  late ThemeCubit _themeCubit;
  late LocaleCubit _localeCubit;
  AppRouter? _appRouter;
  StreamSubscription? _wsEventSub;

  bool _biometricLocked = false;
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeCubit = AppConfig.isServerConfigured
        ? sl<ThemeCubit>()
        : ThemeCubit();
    _localeCubit = AppConfig.isServerConfigured
        ? sl<LocaleCubit>()
        : LocaleCubit();
    _serverReady = AppConfig.isServerConfigured;
    if (_serverReady) {
      _initBlocs();
      _checkBiometricOnLaunch();
    }
  }

  void _initBlocs() {
    _authBloc = sl<AuthBloc>();
    _wsBloc = sl<WebSocketBloc>();
    _connectivityCubit = sl<ConnectivityCubit>();
    _notificationBloc = sl<NotificationBloc>();
    _userStatusCubit = sl<UserStatusCubit>();
    _appRouter = AppRouter(authBloc: _authBloc!);
    _authBloc!.add(const AuthCheckSession());
  }

  Future<void> _checkBiometricOnLaunch() async {
    final bio = sl<BiometricService>();
    final enabled = await bio.isEnabled();
    final available = await bio.isAvailable();
    if (enabled && available) {
      setState(() => _biometricLocked = true);
    }
  }

  void _onServerConfigured() {
    _themeCubit.close();
    _localeCubit.close();
    setState(() {
      _serverReady = true;
      _themeCubit = sl<ThemeCubit>();
      _localeCubit = sl<LocaleCubit>();
      _initBlocs();
      _checkBiometricOnLaunch();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _checkBiometricOnResume();
    }
  }

  Future<void> _checkBiometricOnResume() async {
    if (!_serverReady) return;
    final bio = sl<BiometricService>();
    final enabled = await bio.isEnabled();
    final available = await bio.isAvailable();
    if (enabled && available) {
      setState(() => _biometricLocked = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsEventSub?.cancel();
    _authBloc?.close();
    _wsBloc?.close();
    _connectivityCubit?.close();
    _notificationBloc?.close();
    _userStatusCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_serverReady) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _themeCubit),
          BlocProvider.value(value: _localeCubit),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<LocaleCubit, LocaleState>(
              builder: (context, localeState) {
                return MaterialApp(
                  title: 'MGMess',
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: themeState.themeMode,
                  locale: localeState.locale,
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: ServerUrlScreen(onServerConfigured: _onServerConfigured),
                );
              },
            );
          },
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc!),
        BlocProvider.value(value: _wsBloc!),
        BlocProvider.value(value: _connectivityCubit!),
        BlocProvider.value(value: _notificationBloc!),
        BlocProvider.value(value: _userStatusCubit!),
        BlocProvider.value(value: _themeCubit),
        BlocProvider.value(value: _localeCubit),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _wsBloc!.add(const WebSocketConnect());
            _notificationBloc!.add(
              NotificationInit(userId: state.user.id),
            );
            _userStatusCubit!.subscribeToWs(_wsBloc!.wsEvents);
            _userStatusCubit!.setCustomStatusFromUser(state.user);
            _wsEventSub?.cancel();
            _wsEventSub = _wsBloc!.wsEvents.listen((wsEvent) {
              _notificationBloc!.add(
                NotificationWsEvent(wsEvent: wsEvent),
              );
            });
            // Observability: set user context
            CrashReporting.setUser(
              userId: state.user.id,
              username: state.user.username,
            );
            sl<AnalyticsService>().trackLogin(method: 'session');
          } else if (state is AuthUnauthenticated) {
            _wsBloc!.add(const WebSocketDisconnect());
            _wsEventSub?.cancel();
            _notificationBloc!.add(const NotificationLogout());
            CrashReporting.clearUser();
            sl<AnalyticsService>().trackLogout();
            try {
              AppBadgePlus.updateBadge(0);
            } catch (_) {}
          }
        },
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<LocaleCubit, LocaleState>(
              builder: (context, localeState) {
                return MaterialApp.router(
                  title: 'MGMess',
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: themeState.themeMode,
                  locale: localeState.locale,
                  routerConfig: _appRouter!.router,
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) {
                    if (_biometricLocked) {
                      return BiometricLockScreen(
                        onAuthenticated: () {
                          setState(() => _biometricLocked = false);
                        },
                      );
                    }
                    return child ?? const SizedBox.shrink();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
