import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/ingestion/application/ingestion_flow_controller.dart';
import 'features/notifications/application/push_registration_controller.dart';
import 'routing/app_router.dart';
import 'theme/memora_theme.dart';

/// Root application widget configuring routing and design tokens.
class MemoraApp extends StatelessWidget {
  final GoRouter? router;

  const MemoraApp({super.key, this.router});

  @override
  Widget build(BuildContext context) {
    // Provide a fallback ProviderScope if the app is pumped in a test without one
    try {
      ProviderScope.containerOf(context);
      return _MemoraAppContent(router: router);
    } catch (_) {
      return ProviderScope(child: _MemoraAppContent(router: router));
    }
  }
}

class _MemoraAppContent extends ConsumerWidget {
  final GoRouter? router;

  const _MemoraAppContent({this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerConfig = router ?? ref.watch(appRouterProvider);

    // Clears protected ingestion drafts and operation keys when the signed-in
    // account changes or signs out (D8). Kept alive for the app's lifetime.
    ref.watch(ingestionSessionCleanupProvider);

    // Push token registration orchestrator (T19): listens to session
    // transitions for the app's lifetime. Failures never block use.
    ref.watch(pushRegistrationControllerProvider);

    return MaterialApp.router(
      title: 'Memora',
      debugShowCheckedModeBanner: false,
      theme: MemoraTheme.light(),
      routerConfig: routerConfig,
    );
  }
}
