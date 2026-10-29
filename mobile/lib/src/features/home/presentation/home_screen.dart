import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/app_header.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/mora.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/bootstrap_state.dart';
import '../../../routing/app_routes.dart';

/// Bootstrap-backed authoritative Home screen matching UI/UX spec Section 9.7.
///
/// Only renders data confirmed by server bootstrap; does not synthesize
/// unearned XP, arbitrary mission counts, fake streaks, or reef health.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);
    final bootstrap = sessionState.bootstrapData;
    final streakDays = bootstrap?.profileSummary.streakDays ?? 0;
    final activeMission = bootstrap?.activeMission;
    final hasSubjects = bootstrap?.hasSubjects ?? false;
    final pendingUpdates = bootstrap?.pendingUpdates ?? const [];

    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: MemoraHeader.root(
        title: 'Memora',
        streakDays: streakDays,
        onProfilePressed: () => context.go(AppRoutes.profile),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(sessionControllerProvider.notifier).retryBootstrap(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space16,
            vertical: MemoraSpacing.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Pending work notification banner if any
              if (pendingUpdates.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(MemoraSpacing.space12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F1FC),
                    borderRadius: MemoraRadii.compactCard,
                    border: Border.all(color: const Color(0xFFB0D2F2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync,
                        color: Color(0xFF0072B2),
                        size: 20,
                      ),
                      const SizedBox(width: MemoraSpacing.space8),
                      Expanded(
                        child: Text(
                          '${pendingUpdates.length} learning update(s) currently processing.',
                          style: MemoraTypography.metadata.copyWith(
                            color: const Color(0xFF102A43),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
              ],

              // Daily Mission Hero Card
              if (activeMission != null) ...[
                _buildActiveMissionHero(context, activeMission),
              ] else if (!hasSubjects) ...[
                _buildSetupHero(context),
              ] else ...[
                _buildReadyHero(context, bootstrap!),
              ],

              const SizedBox(height: MemoraSpacing.space24),

              // Subject exploration section
              if (hasSubjects) ...[
                Semantics(
                  header: true,
                  child: const Text(
                    'Your subjects',
                    style: MemoraTypography.sectionTitle,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space12),
                ...bootstrap!.subjects.map((subject) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: MemoraSpacing.space8,
                    ),
                    child: MemoraCard(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE5F1FC),
                          child: Icon(Icons.school, color: Color(0xFF0072B2)),
                        ),
                        title: Text(
                          subject.name,
                          style: MemoraTypography.cardTitle,
                        ),
                        subtitle: Text(
                          'Code: ${subject.code} · ${subject.curriculumEditionCode}',
                          style: MemoraTypography.metadata,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(AppRoutes.learning),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveMissionHero(
    BuildContext context,
    ActiveMissionSummaryDomain activeMission,
  ) {
    return MemoraCard(
      variant: MemoraCardVariant.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF0072B2), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Daily Mission in Progress',
                    style: TextStyle(
                      fontFamily: 'Exo',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF0072B2),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F1FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activeMission.status.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Exo',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Color(0xFF0072B2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoraSpacing.space12),
          Text(
            'Mission for ${activeMission.missionDate}',
            style: MemoraTypography.sectionTitle,
          ),
          const SizedBox(height: MemoraSpacing.space8),
          Text(
            'Keep your retention strong with today\'s review session.',
            style: MemoraTypography.body.copyWith(
              color: MemoraColors.textSecondary,
            ),
          ),
          const SizedBox(height: MemoraSpacing.space24),
          MemoraButton(
            label: 'Continue Daily Mission',
            onPressed: () {
              context.push(
                AppRoutes.featureUnavailable,
                extra: 'Mission execution will be available in task T14.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSetupHero(BuildContext context) {
    return MemoraCard(
      variant: MemoraCardVariant.primary,
      child: Column(
        children: [
          const MoraPlacement(
            state: MoraState.encourage,
            size: 80,
            speechBubbleText: 'Welcome to Memora!',
          ),
          const SizedBox(height: MemoraSpacing.space16),
          const Text(
            'Ready to start learning',
            textAlign: TextAlign.center,
            style: MemoraTypography.cardTitle,
          ),
          const SizedBox(height: MemoraSpacing.space8),
          const Text(
            'No learning material yet. Add notes or a PDF to build your first Physics learning path.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: MemoraColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: MemoraSpacing.space24),
          MemoraButton(
            label: 'Add Learning Material',
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push(
                AppRoutes.featureUnavailable,
                extra: 'Material ingestion will be available in task T10.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadyHero(BuildContext context, dynamic bootstrap) {
    return MemoraCard(
      variant: MemoraCardVariant.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Focus',
            style: TextStyle(
              fontFamily: 'Exo',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF0072B2),
            ),
          ),
          const SizedBox(height: MemoraSpacing.space8),
          const Text(
            'Keep your memories fresh',
            style: MemoraTypography.sectionTitle,
          ),
          const SizedBox(height: MemoraSpacing.space8),
          const Text(
            'Explore your active subjects or add learning materials to schedule new retrieval practice.',
            style: TextStyle(
              fontSize: 14,
              color: MemoraColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: MemoraSpacing.space24),
          MemoraButton(
            label: 'Add Learning Material',
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push(
                AppRoutes.featureUnavailable,
                extra: 'Material ingestion will be available in task T10.',
              );
            },
          ),
        ],
      ),
    );
  }
}
