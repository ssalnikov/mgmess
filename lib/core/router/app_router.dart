import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/screens/auth/auth_screen.dart';
import '../../presentation/screens/channels/channels_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/mentions/mentions_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/notification_settings_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/user_profile_screen.dart';
import '../../presentation/screens/saved_messages/saved_messages_screen.dart';
import '../../presentation/screens/drafts/drafts_screen.dart';
import '../../presentation/screens/thread/thread_screen.dart';
import '../../presentation/screens/threads/threads_screen.dart';
import '../../presentation/widgets/bottom_nav_shell.dart';
import 'route_names.dart';

class AppRouter {
  final AuthBloc _authBloc;

  AppRouter({required AuthBloc authBloc}) : _authBloc = authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.channels,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: (context, state) {
      final authState = _authBloc.state;
      final isAuth = authState is AuthAuthenticated;
      final isAuthPage = state.matchedLocation == RouteNames.auth;

      if (!isAuth && !isAuthPage) return RouteNames.auth;
      if (isAuth && isAuthPage) return RouteNames.channels;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            BottomNavShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.channels,
            builder: (context, state) => const ChannelsScreen(),
          ),
          GoRoute(
            path: RouteNames.savedMessages,
            builder: (context, state) =>
                const SavedMessagesScreen(),
          ),
          GoRoute(
            path: RouteNames.mentions,
            builder: (context, state) => const MentionsScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.threads,
        builder: (context, state) => const ThreadsScreen(),
      ),
      GoRoute(
        path: RouteNames.drafts,
        builder: (context, state) => const DraftsScreen(),
      ),
      GoRoute(
        path: RouteNames.chat,
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          final extra = state.extra;
          String channelName = '';
          String? initialDraft;
          if (extra is String) {
            channelName = extra;
          } else if (extra is Map<String, dynamic>) {
            channelName = extra['channelName'] as String? ?? '';
            initialDraft = extra['draftMessage'] as String?;
          }
          return ChatScreen(
            channelId: channelId,
            channelName: channelName,
            initialDraft: initialDraft,
          );
        },
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.notificationSettings,
        builder: (context, state) =>
            const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.userProfile,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: RouteNames.thread,
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return ThreadScreen(postId: postId);
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
