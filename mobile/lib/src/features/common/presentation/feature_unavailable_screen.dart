import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/button.dart';
import '../../../design_system/components/mora.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';

/// Screen displayed when an authorized route or action belongs to a future task.
class FeatureUnavailableScreen extends StatelessWidget {
  final String? featureName;
  final String? message;

  const FeatureUnavailableScreen({super.key, this.featureName, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MemoraColors.textPrimary),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: MemoraSpacing.space24,
              vertical: MemoraSpacing.space32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MoraPlacement(
                  state: MoraState.think,
                  size: 110,
                  isDecorative: true,
                ),
                const SizedBox(height: MemoraSpacing.space24),
                Semantics(
                  header: true,
                  child: Text(
                    featureName ?? 'Feature Coming Soon',
                    textAlign: TextAlign.center,
                    style: MemoraTypography.pageTitle,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                Text(
                  message ?? 'This feature is scheduled in an upcoming development milestone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: MemoraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space32),
                MemoraButton(
                  label: 'Return to Home',
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
