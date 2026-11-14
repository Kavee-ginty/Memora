import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/ingestion/application/ingestion_flow_controller.dart';
import 'features/profile/application/profile_controller.dart';
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
    final accessibility = ref.watch(
      profileControllerProvider.select(
        (state) =>
            state.applied ?? state.confirmed?.preferences.fields.accessibility,
      ),
    );
    final baseTheme = MemoraTheme.light();
    final contrastTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      colorScheme: baseTheme.colorScheme.copyWith(
        onSurface: Colors.black,
        onSurfaceVariant: Colors.black,
        outline: Colors.black,
        outlineVariant: Colors.black,
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseTheme.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? Colors.black54
                : Colors.black,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.black,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.black
              : Colors.white,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.black),
      ),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        foregroundColor: Colors.black,
      ),
    );

    return MaterialApp.router(
      title: 'Memora',
      debugShowCheckedModeBanner: false,
      theme: accessibility?.highContrast == true ? contrastTheme : baseTheme,
      highContrastTheme: contrastTheme,
      themeAnimationDuration: accessibility?.reducedMotion == true
          ? Duration.zero
          : kThemeAnimationDuration,
      routerConfig: routerConfig,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations:
                media.disableAnimations ||
                (accessibility?.reducedMotion ?? false),
            highContrast:
                media.highContrast || (accessibility?.highContrast ?? false),
          ),
          child: child!,
        );
      },
    );
  }
}
