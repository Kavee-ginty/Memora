import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/button.dart';
import '../../../design_system/components/mora.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../application/session_controller.dart';
import '../domain/bootstrap_state.dart';

/// Blocking screen displayed when an account is suspended or requires administrative recovery.
class AccountRecoveryScreen extends ConsumerWidget {
  const AccountRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);
    final status = sessionState.bootstrapData?.accountStatus;
    final pendingPrivacyRequests =
        sessionState.bootstrapData?.pendingPrivacyRequests ??
        const <PendingResourceSummaryDomain>[];
    final deletionRequest =
        status == AccountStatusDomain.deletionPending &&
            pendingPrivacyRequests.isNotEmpty
        ? pendingPrivacyRequests.first
        : null;

    final String title;
    final String description;

    if (status == AccountStatusDomain.suspended) {
      title = 'Account Suspended';
      description = 'Your student account has been temporarily suspended. Please contact support to resolve this issue.';
    } else if (status == AccountStatusDomain.deletionPending) {
      title = 'Account Deletion in Progress';
      description =
          'An account deletion request was received. You can review its '
          'status and cancel while the server still permits cancellation.';
    } else if (status == AccountStatusDomain.deleted) {
      title = 'Account Deletion in Progress';
      description = 'An account deletion request was received. You can sign out or contact support if this was made in error.';
    } else {
      title = 'Account Recovery Required';
      description = sessionState.failure?.message ?? 'Your account cannot be accessed at this time. Please contact support or sign in with another account.';
    }

    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
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
                  state: MoraState.sad,
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
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: MemoraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space32),
                if (deletionRequest != null) ...[
                  MemoraButton(
                    key: const Key('account_recovery_view_deletion'),
                    label: 'View deletion status',
                    onPressed: () => context.go(
                      AppRoutes.privacyDeletionStatusPath(deletionRequest.id),
                    ),
                  ),
                  const SizedBox(height: MemoraSpacing.space12),
                ],
                MemoraButton(
                  label: 'Sign Out',
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
        ),
      ),
    );
  }
}
