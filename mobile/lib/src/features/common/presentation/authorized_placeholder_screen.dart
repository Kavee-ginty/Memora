import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/button.dart';
import '../../../design_system/components/mora.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';

/// Honest placeholder for a canonical detail route whose full feature UI is
/// owned by a later task.
///
/// It identifies the authorized destination and offers one stable Back action.
/// It never fabricates lesson, mission, reward or reef data.
class AuthorizedPlaceholderScreen extends StatelessWidget {
  const AuthorizedPlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
    required this.backLabel,
    required this.backPath,
  });

  final String title;
  final String message;
  final String backLabel;
  final String backPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: MemoraColors.surfaceSoft,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MemoraColors.textPrimary),
          tooltip: 'Back',
          onPressed: () => _back(context),
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
              children: <Widget>[
                const MoraPlacement(
                  state: MoraState.guide,
                  size: 110,
                  isDecorative: true,
                ),
                const SizedBox(height: MemoraSpacing.space24),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: MemoraTypography.pageTitle,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: MemoraTypography.body.copyWith(
                    color: MemoraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space32),
                MemoraButton(label: backLabel, onPressed: () => _back(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(backPath);
    }
  }
}

/// Generic not-found destination used for malformed identifiers and
/// wrong-owner resources. Copy is identical for both cases.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: MemoraColors.surfaceSoft,
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
              children: <Widget>[
                const MoraPlacement(
                  state: MoraState.think,
                  size: 110,
                  isDecorative: true,
                ),
                const SizedBox(height: MemoraSpacing.space24),
                Semantics(
                  header: true,
                  child: Text(
                    'We could not find that page',
                    textAlign: TextAlign.center,
                    style: MemoraTypography.pageTitle,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                Text(
                  'The requested item may have moved or is no longer available.',
                  textAlign: TextAlign.center,
                  style: MemoraTypography.body.copyWith(
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
