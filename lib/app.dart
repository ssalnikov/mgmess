import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/connectivity/connectivity_cubit.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/notification/notification_event.dart';
import 'presentation/blocs/websocket/websocket_bloc.dart';
import 'presentation/blocs/websocket/websocket_event.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;
  late final WebSocketBloc _wsBloc;
  late final ConnectivityCubit _connectivityCubit;
  late final NotificationBloc _notificationBloc;
  late final AppRouter _appRouter;
  StreamSubscription? _wsEventSub;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    _wsBloc = sl<WebSocketBloc>();
    _connectivityCubit = sl<ConnectivityCubit>();
    _notificationBloc = sl<NotificationBloc>();
    _appRouter = AppRouter(authBloc: _authBloc);

    // Check if user has active session
    _authBloc.add(const AuthCheckSession());
  }

  @override
  void dispose() {
    _wsEventSub?.cancel();
    _authBloc.close();
    _wsBloc.close();
    _connectivityCubit.close();
    _notificationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _wsBloc),
        BlocProvider.value(value: _connectivityCubit),
        BlocProvider.value(value: _notificationBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _wsBloc.add(const WebSocketConnect());
            _notificationBloc.add(
              NotificationInit(userId: state.user.id),
            );
            _wsEventSub?.cancel();
            _wsEventSub = _wsBloc.wsEvents.listen((wsEvent) {
              _notificationBloc.add(
                NotificationWsEvent(wsEvent: wsEvent),
              );
            });
          } else if (state is AuthUnauthenticated) {
            _wsBloc.add(const WebSocketDisconnect());
            _wsEventSub?.cancel();
            _notificationBloc.add(const NotificationLogout());
          }
        },
        child: MaterialApp.router(
          title: 'MGMess',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: _appRouter.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
