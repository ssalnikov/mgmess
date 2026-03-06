import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/connectivity/connectivity_cubit.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/notification/notification_event.dart';
import 'presentation/blocs/user_status/user_status_cubit.dart';
import 'presentation/blocs/websocket/websocket_bloc.dart';
import 'presentation/blocs/websocket/websocket_event.dart';
import 'presentation/screens/server/server_url_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late bool _serverReady;

  AuthBloc? _authBloc;
  WebSocketBloc? _wsBloc;
  ConnectivityCubit? _connectivityCubit;
  NotificationBloc? _notificationBloc;
  UserStatusCubit? _userStatusCubit;
  AppRouter? _appRouter;
  StreamSubscription? _wsEventSub;

  @override
  void initState() {
    super.initState();
    _serverReady = AppConfig.isServerConfigured;
    if (_serverReady) {
      _initBlocs();
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

  void _onServerConfigured() {
    setState(() {
      _serverReady = true;
      _initBlocs();
    });
  }

  @override
  void dispose() {
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
      return MaterialApp(
        title: 'MGMess',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: ServerUrlScreen(onServerConfigured: _onServerConfigured),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc!),
        BlocProvider.value(value: _wsBloc!),
        BlocProvider.value(value: _connectivityCubit!),
        BlocProvider.value(value: _notificationBloc!),
        BlocProvider.value(value: _userStatusCubit!),
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
          } else if (state is AuthUnauthenticated) {
            _wsBloc!.add(const WebSocketDisconnect());
            _wsEventSub?.cancel();
            _notificationBloc!.add(const NotificationLogout());
            try {
              AppBadgePlus.updateBadge(0);
            } catch (_) {}

          }
        },
        child: MaterialApp.router(
          title: 'MGMess',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: _appRouter!.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
