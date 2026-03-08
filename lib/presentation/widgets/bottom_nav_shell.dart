import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/router/route_names.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;

  const BottomNavShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RouteNames.savedMessages)) return 1;
    if (location.startsWith(RouteNames.mentions)) return 2;
    if (location.startsWith(RouteNames.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.channels);
            case 1:
              context.go(RouteNames.savedMessages);
            case 2:
              context.go(RouteNames.mentions);
            case 3:
              context.go(RouteNames.profile);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: context.l10n.channels,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_border),
            activeIcon: const Icon(Icons.bookmark),
            label: context.l10n.saved,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.alternate_email),
            activeIcon: const Icon(Icons.alternate_email),
            label: context.l10n.mentions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: context.l10n.profile,
          ),
        ],
      ),
    );
  }
}
