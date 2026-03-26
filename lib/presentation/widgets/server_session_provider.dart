import 'package:flutter/widgets.dart';

import '../../core/di/server_session.dart';

/// Provides the current [ServerSession] down the widget tree.
///
/// Placed above the per-server BLoC providers in [App] so that any
/// descendant can access the active session via [ServerSessionProvider.of]
/// or the [ServerSessionContext] extension.
class ServerSessionProvider extends InheritedWidget {
  final ServerSession session;

  const ServerSessionProvider({
    super.key,
    required this.session,
    required super.child,
  });

  static ServerSession of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ServerSessionProvider>();
    assert(provider != null, 'No ServerSessionProvider found in context');
    return provider!.session;
  }

  @override
  bool updateShouldNotify(ServerSessionProvider oldWidget) =>
      session != oldWidget.session;
}

/// Convenience extension for accessing the active [ServerSession] via context.
///
/// Use in `build` methods and callbacks where `BuildContext` is available.
/// For `initState` or field initializers, use [currentSession] from injection.dart.
extension ServerSessionContext on BuildContext {
  ServerSession get serverSession => ServerSessionProvider.of(this);
}
