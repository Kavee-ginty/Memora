import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/components/bottom_nav.dart';

/// Authenticated four-branch root application shell hosting Home, Learning,
/// Progress, and Profile with state preservation across tabs.
class RootShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RootShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MemoraBottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        reflowLabels: true,
        onTap: (index) {
          if (index == MemoraDestination.profile.index &&
              index == navigationShell.currentIndex) {
            return;
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
