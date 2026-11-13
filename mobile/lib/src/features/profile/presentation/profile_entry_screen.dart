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
import '../application/profile_controller.dart';

/// Account identity, settings destinations, and safe sign-out.
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
    final bootstrap = sessionState.bootstrapData;
    final profile = bootstrap?.profileSummary;
    final settings = ref.watch(profileControllerProvider);
    final name =
        settings.confirmed?.profile.fields.displayName ?? profile?.displayName;
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : sessionState.session?.email;
    final streak = profile?.streakDays ?? 0;
    final contrast = MediaQuery.highContrastOf(context);
    final titleStyle = MemoraTypography.cardTitle.copyWith(
      color: contrast ? Colors.black : null,
    );
    final metadataStyle = MemoraTypography.metadata.copyWith(
      color: contrast ? Colors.black : null,
    );

    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: const MemoraHeader.root(title: 'Profile', headingOnTitle: true),
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
              semanticLabel: 'Account identity',
              borderColor: contrast ? Colors.black : null,
              child: Padding(
                padding: const EdgeInsets.all(MemoraSpacing.space8),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFD4E9F9),
                        child: Text(
                          (name?.isNotEmpty == true)
                              ? name!.characters.first.toUpperCase()
                              : 'M',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: contrast
                                ? Colors.black
                                : const Color(0xFF0072B2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: MemoraSpacing.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name ?? 'Your account', style: titleStyle),
                          if (email != null && email.isNotEmpty)
                            Text(email, style: metadataStyle),
                          if (streak > 0)
                            Text(
                              'Streak: $streak days',
                              style: metadataStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: contrast
                                    ? Colors.black
                                    : const Color(0xFF0072B2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MemoraSpacing.space8),
            MemoraButton(
              label: 'Edit profile',
              onPressed: () => context.go(AppRoutes.editProfile),
            ),
            if (settings.cached) const Text('Showing your last saved profile.'),
            for (final subject in bootstrap?.subjects ?? [])
              ListTile(
                title: Text(subject.name),
                subtitle: const Text('Learning path'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.learning),
              ),
            ListTile(
              title: const Text('Accessibility and mission settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.profileAccessibility),
            ),
            ListTile(
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.profileNotifications),
            ),

            // Privacy entry owned by T21
            MemoraCard(
              key: const Key('profile_privacy_entry'),
              borderColor: contrast ? Colors.black : null,
              onTap: () => context.go(AppRoutes.privacy),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.shield_outlined,
                    color: contrast ? Colors.black : MemoraColors.brandBlue,
                    size: 24,
                  ),
                  const SizedBox(width: MemoraSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Privacy', style: titleStyle),
                        const SizedBox(height: MemoraSpacing.space4),
                        Text(
                          'Export your data or delete your account',
                          style: metadataStyle,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: contrast ? Colors.black : MemoraColors.textMuted,
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
