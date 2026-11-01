import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/button.dart';
import '../../../design_system/components/mora.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../application/session_controller.dart';
import '../domain/app_session_state.dart';

/// Splash screen displaying brand recognition during startup and initialization.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final phase = ref.read(sessionControllerProvider).phase;
        if (phase == AppSessionPhase.unknown) {
          ref.read(sessionControllerProvider.notifier).initialize();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final isFailure = sessionState.phase == AppSessionPhase.failure;

    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: MemoraSpacing.space24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const MoraPlacement(
                  state: MoraState.guide,
                  size: 160.0,
                  isDecorative: true,
                ),
                const SizedBox(height: MemoraSpacing.space24),
                Semantics(
                  header: true,
                  child: const Text(
                    'Memora',
                    style: MemoraTypography.display,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isFailure) ...[
                  const SizedBox(height: MemoraSpacing.space24),
                  Container(
                    padding: const EdgeInsets.all(MemoraSpacing.space16),
                    decoration: BoxDecoration(
                      color: MemoraColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MemoraColors.borderDefault),
                    ),
                    child: Column(
                      children: [
                        Text(
                          sessionState.failure?.message ??
                              'Unable to connect to Memora. Please try again.',
                          textAlign: TextAlign.center,
                          style: MemoraTypography.body,
                        ),
                        const SizedBox(height: MemoraSpacing.space16),
                        MemoraButton(
                          label: 'Retry Connection',
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            ref
                                .read(sessionControllerProvider.notifier)
                                .retryBootstrap();
                          },
                        ),
                        const SizedBox(height: MemoraSpacing.space8),
                        MemoraButton(
                          label: 'Sign In Again',
                          variant: MemoraButtonVariant.secondary,
                          onPressed: () {
                            ref
                                .read(sessionControllerProvider.notifier)
                                .signOut(force: true);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
