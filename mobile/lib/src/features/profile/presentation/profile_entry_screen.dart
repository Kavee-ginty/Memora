import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/app_header.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/dialog.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../../auth/application/session_controller.dart';

/// Minimal Profile host rendering authenticated profile summary and safe sign-out.
class ProfileEntryScreen extends ConsumerWidget {
  const ProfileEntryScreen({super.key});

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    final sessionController = ref.read(sessionControllerProvider.notifier);
    final hasUnsynced = sessionController.requiresSignOutConfirmation;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return MemoraDialog(
          title: 'Sign Out',
          message: hasUnsynced
              ? 'You have uncommitted or pending operations that will be discarded upon sign-out. Are you sure you wish to sign out?'
              : 'Are you sure you want to sign out of Memora?',
          isDestructive: true,
          primaryActionLabel: 'Sign Out',
          onPrimaryAction: () {
            Navigator.of(dialogContext).pop();
            sessionController.signOut(force: true);
          },
          secondaryActionLabel: 'Cancel',
          onSecondaryAction: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);
    final profile = sessionState.bootstrapData?.profileSummary;

    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: const MemoraHeader.root(title: 'Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: MemoraSpacing.space16,
          vertical: MemoraSpacing.space16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Profile Card
            MemoraCard(
              child: Padding(
                padding: const EdgeInsets.all(MemoraSpacing.space8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFD4E9F9),
                      child: Text(
                        (profile?.displayName.isNotEmpty == true)
                            ? profile!.displayName[0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0072B2),
                        ),
                      ),
                    ),
                    const SizedBox(width: MemoraSpacing.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              profile?.displayName ?? 'Student',
                              style: MemoraTypography.cardTitle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.email ?? '',
                            style: MemoraTypography.metadata,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Streak: ${profile?.streakDays ?? 0} days',
                            style: MemoraTypography.metadata.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0072B2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MemoraSpacing.space24),

            // Privacy entry owned by T21
            MemoraCard(
              key: const Key('profile_privacy_entry'),
              onTap: () => context.go(AppRoutes.privacy),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.shield_outlined,
                    color: MemoraColors.brandBlue,
                    size: 24,
                  ),
                  const SizedBox(width: MemoraSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Privacy', style: MemoraTypography.cardTitle),
                        const SizedBox(height: MemoraSpacing.space4),
                        Text(
                          'Export your data or delete your account',
                          style: MemoraTypography.metadata,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: MemoraColors.textMuted,
                  ),
                ],
              ),
            ),

            const SizedBox(height: MemoraSpacing.space32),

            // Sign out button
            MemoraButton(
              label: 'Sign Out',
              variant: MemoraButtonVariant.destructive,
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmSignOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
