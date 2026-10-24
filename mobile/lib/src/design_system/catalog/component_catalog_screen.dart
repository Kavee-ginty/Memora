import 'package:flutter/material.dart';

import '../components/app_header.dart';
import '../components/banner.dart';
import '../components/bottom_nav.dart';
import '../components/bottom_sheet.dart';
import '../components/button.dart';
import '../components/card.dart';
import '../components/dialog.dart';
import '../components/mora.dart';
import '../components/path.dart';
import '../components/quiz.dart';
import '../components/scaffold.dart';
import '../components/skeleton.dart';
import '../components/text_field.dart';
import '../components/toast.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class ComponentCatalogScreen extends StatefulWidget {
  const ComponentCatalogScreen({super.key});

  @override
  State<ComponentCatalogScreen> createState() => _ComponentCatalogScreenState();
}

class _ComponentCatalogScreenState extends State<ComponentCatalogScreen> {
  int _selectedNavIndex = 0;
  bool _isCardSelected = false;
  bool _obscurePassword = true;
  int _selectedQuizOption = 1;

  @override
  Widget build(BuildContext context) {
    return MemoraScaffold(
      appBar: const MemoraHeader.root(
        title: 'Component Catalog',
        streakDays: 7,
      ),
      bottomNavigationBar: MemoraBottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (int index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: MemoraSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSectionHeader('1. Buttons & Action Targets'),
            _buildButtonsSection(context),
            const SizedBox(height: MemoraSpacing.space24),

            _buildSectionHeader('2. Cards & Progress Surfaces'),
            _buildCardsSection(context),
            const SizedBox(height: MemoraSpacing.space24),

            _buildSectionHeader('3. Form Fields & Validation'),
            _buildFormFieldsSection(context),
            const SizedBox(height: MemoraSpacing.space24),

            _buildSectionHeader('4. Inline Banners'),
            _buildBannersSection(context),
            const SizedBox(height: MemoraSpacing.space24),

            _buildSectionHeader('5. Header Variants'),
            _buildHeadersSection(context),
            const SizedBox(height: MemoraSpacing.space24),

            _buildSectionHeader('6. Dialogs, Sheets & Toasts'),
            _buildOverlaysSection(context),
            const SizedBox(height: MemoraSpacing.space24),

            _buildSectionHeader('7. Skeletons & Loading States'),
            _buildSkeletonsSection(context),
            const SizedBox(height: MemoraSpacing.space24),

            _buildSectionHeader('8. Mora Mascot Placement'),
            _buildMoraSection(context),
            const SizedBox(height: MemoraSpacing.space24),

            _buildSectionHeader('9. Quiz & Retrieval Controls'),
            _buildQuizSection(context),
            const SizedBox(height: MemoraSpacing.space24),

            _buildSectionHeader('10. Learning Path & Map Nodes'),
            _buildPathSection(context),
            const SizedBox(height: MemoraSpacing.space32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MemoraSpacing.space12),
      child: Text(title, style: MemoraTypography.sectionTitle),
    );
  }

  Widget _buildButtonsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MemoraButton(
          label: 'Primary Action',
          onPressed: () => showMemoraToast(context, 'Primary clicked'),
        ),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraButton(
          label: 'Primary with Icon',
          icon: const Icon(Icons.play_arrow),
          onPressed: () {},
        ),
        const SizedBox(height: MemoraSpacing.space8),
        const MemoraButton(label: 'Primary Disabled', onPressed: null),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraButton(
          label: 'Primary Loading',
          isLoading: true,
          onPressed: () {},
        ),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraButton(
          label: 'Secondary Action',
          variant: MemoraButtonVariant.secondary,
          onPressed: () => showMemoraToast(context, 'Secondary clicked'),
        ),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraButton(
          label: 'Tertiary Action',
          variant: MemoraButtonVariant.tertiary,
          onPressed: () => showMemoraToast(context, 'Tertiary clicked'),
        ),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraButton(
          label: 'Destructive Action',
          variant: MemoraButtonVariant.destructive,
          icon: const Icon(Icons.delete_outline),
          onPressed: () => showMemoraToast(context, 'Destructive clicked'),
        ),
      ],
    );
  }

  Widget _buildCardsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const MemoraCard(
          variant: MemoraCardVariant.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Primary Surface Card', style: MemoraTypography.cardTitle),
              SizedBox(height: MemoraSpacing.space8),
              Text(
                '24px rounded geometry with ocean surface and subtle boundary cue.',
                style: MemoraTypography.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: MemoraSpacing.space12),
        const MemoraProgressCard(
          title: 'Everyday English',
          subtitle: 'Continue your journey',
          statusText: '6 of 10 lessons completed',
          progress: 0.60,
          metricText: '60%',
        ),
        const SizedBox(height: MemoraSpacing.space12),
        MemoraSelectableCard(
          title: 'Physics Mechanics Concept',
          subtitle: _isCardSelected ? 'Selected concept' : 'Tap to select',
          isSelected: _isCardSelected,
          progress: 0.75,
          onTap: () {
            setState(() {
              _isCardSelected = !_isCardSelected;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFormFieldsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const MemoraTextField(
          label: 'Email or Username',
          hintText: 'e.g. student@example.com',
          prefixIcon: Icon(Icons.person_outline),
        ),
        const SizedBox(height: MemoraSpacing.space12),
        MemoraTextField(
          label: 'Password',
          hintText: 'Enter your password',
          obscureText: _obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: Semantics(
            button: true,
            label: _obscurePassword ? 'Show password' : 'Hide password',
            child: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: MemoraColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: MemoraSpacing.space12),
        const MemoraTextField(
          label: 'Verified Input',
          initialValue: 'Albert Einstein',
          successText: 'Physics author identity verified',
        ),
        const SizedBox(height: MemoraSpacing.space12),
        const MemoraTextField(
          label: 'Error State Input',
          initialValue: 'invalid-email',
          errorText: 'Please enter a valid academic email address',
        ),
        const SizedBox(height: MemoraSpacing.space12),
        const MemoraTextField(
          label: 'Disabled Input',
          initialValue: 'Locked curriculum field',
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildBannersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const MemoraBanner(
          variant: MemoraBannerVariant.info,
          title: 'Daily Mission Ready',
          message: 'Your Physics Daily Mission is ready. About 5 minutes.',
        ),
        const MemoraBanner(
          variant: MemoraBannerVariant.attention,
          title: 'Weak Memory Found',
          message: 'A few concepts require review to keep your reef healthy.',
          actionLabel: 'Review now',
        ),
        const MemoraBanner(
          variant: MemoraBannerVariant.critical,
          title: 'Connection Interrupted',
          message:
              'Could not sync mission results. We will retry automatically.',
          actionLabel: 'Retry',
        ),
        const MemoraBanner(
          variant: MemoraBannerVariant.offline,
          title: 'Offline Mode Active',
          message: 'You can continue your active mission. Answers will sync once reconnected.',
        ),
        const MemoraBanner(
          variant: MemoraBannerVariant.positive,
          title: 'Streak Secured',
          message: 'Great work! Your 7-day streak has been recorded.',
        ),
      ],
    );
  }

  Widget _buildHeadersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('Detail Header Variant:', style: MemoraTypography.cardTitle),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraHeader.detail(
          title: 'Physics Learning Path',
          subtitle: 'Unit 1: Classical Mechanics',
          onBackPressed: () {},
        ),
        const SizedBox(height: MemoraSpacing.space16),
        const Text(
          'Mission Header Variant:',
          style: MemoraTypography.cardTitle,
        ),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraHeader.mission(
          missionProgressText: 'Memories protected 3 of 8',
          timerText: '04:32',
          onPauseMission: () {},
        ),
      ],
    );
  }

  Widget _buildOverlaysSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MemoraButton(
          label: 'Open Confirmation Dialog',
          variant: MemoraButtonVariant.secondary,
          onPressed: () {
            showMemoraDialog<bool>(
              context: context,
              title: 'Discard learning update?',
              message: 'Leaving now will lose your unsubmitted notes. You can save as draft instead.',
              primaryActionLabel: 'Discard',
              secondaryActionLabel: 'Keep editing',
              isDestructive: true,
              onPrimaryAction: () => Navigator.of(context).pop(true),
            );
          },
        ),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraButton(
          label: 'Open Contextual Bottom Sheet',
          variant: MemoraButtonVariant.secondary,
          onPressed: () {
            showMemoraBottomSheet<void>(
              context: context,
              title: 'Physics Reef Status',
              subtitle: 'Healthy - next review in 18 hours',
              action: MemoraButton(
                label: 'Start review mission',
                onPressed: () => Navigator.of(context).pop(),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Reef health represents memory maintenance. What you earn stays yours.',
                    style: MemoraTypography.body,
                  ),
                  SizedBox(height: MemoraSpacing.space16),
                  Text(
                    'Due memories: 4 concepts ready for care.',
                    style: MemoraTypography.bodyStrong,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraButton(
          label: 'Show Toast Notification',
          variant: MemoraButtonVariant.tertiary,
          onPressed: () {
            showMemoraToast(
              context,
              'Draft saved locally. Ready to sync.',
              icon: const Icon(Icons.check_circle_outline),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSkeletonsSection(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MemoraSkeleton.card(height: 100),
        SizedBox(height: MemoraSpacing.space8),
        MemoraSkeleton.text(height: 20),
        SizedBox(height: MemoraSpacing.space8),
        Row(
          children: <Widget>[
            MemoraSkeleton.circle(size: 48),
            SizedBox(width: MemoraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MemoraSkeleton.text(height: 16),
                  SizedBox(height: MemoraSpacing.space4),
                  MemoraSkeleton.text(height: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoraSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const MoraPlacement(
          state: MoraState.encourage,
          size: 72,
          isDecorative: false,
          speechBubbleText:
              'Protect today\'s memories to help your coral reef thrive!',
        ),
        const SizedBox(height: MemoraSpacing.space16),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              Column(
                children: <Widget>[
                  MoraPlacement(state: MoraState.guide, size: 56),
                  SizedBox(height: MemoraSpacing.space4),
                  Text('Guide', style: MemoraTypography.metadata),
                ],
              ),
              SizedBox(width: MemoraSpacing.space16),
              Column(
                children: <Widget>[
                  MoraPlacement(state: MoraState.encourage, size: 56),
                  SizedBox(height: MemoraSpacing.space4),
                  Text('Encourage', style: MemoraTypography.metadata),
                ],
              ),
              SizedBox(width: MemoraSpacing.space16),
              Column(
                children: <Widget>[
                  MoraPlacement(state: MoraState.celebrate, size: 56),
                  SizedBox(height: MemoraSpacing.space4),
                  Text('Celebrate', style: MemoraTypography.metadata),
                ],
              ),
              SizedBox(width: MemoraSpacing.space16),
              Column(
                children: <Widget>[
                  MoraPlacement(state: MoraState.think, size: 56),
                  SizedBox(height: MemoraSpacing.space4),
                  Text('Think', style: MemoraTypography.metadata),
                ],
              ),
              SizedBox(width: MemoraSpacing.space16),
              Column(
                children: <Widget>[
                  MoraPlacement(state: MoraState.rest, size: 56),
                  SizedBox(height: MemoraSpacing.space4),
                  Text('Rest', style: MemoraTypography.metadata),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const MemoraQuizProgressBar(
          totalQuestions: 8,
          currentQuestionIndex: 2,
          memoriesProtectedCount: 2,
        ),
        const SizedBox(height: MemoraSpacing.space16),
        MemoraQuizOption(
          indexLabel: 'A',
          text: 'F = G(m1 * m2) / r^2',
          state: _selectedQuizOption == 0
              ? MemoraQuizOptionState.selected
              : MemoraQuizOptionState.defaultState,
          onTap: () {
            setState(() {
              _selectedQuizOption = 0;
            });
          },
        ),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraQuizOption(
          indexLabel: 'B',
          text: 'F = m * a (Newton\'s 2nd Law)',
          state: _selectedQuizOption == 1
              ? MemoraQuizOptionState.selected
              : MemoraQuizOptionState.defaultState,
          onTap: () {
            setState(() {
              _selectedQuizOption = 1;
            });
          },
        ),
        const SizedBox(height: MemoraSpacing.space8),
        const MemoraQuizOption(
          indexLabel: 'C',
          text: 'E = m * c^2 (Verified Correct)',
          state: MemoraQuizOptionState.correct,
        ),
        const SizedBox(height: MemoraSpacing.space8),
        const MemoraQuizOption(
          indexLabel: 'D',
          text: 'P = V / I (Weak Memory State)',
          state: MemoraQuizOptionState.weakMemory,
        ),
        const SizedBox(height: MemoraSpacing.space16),
        MemoraFeedbackPanel(
          type: MemoraFeedbackType.recalled,
          headline: 'Memory protected',
          body: 'Great job! Newton\'s second law connects resultant force directly to mass and acceleration.',
          primaryActionLabel: 'Next memory',
          onPrimaryAction: () {},
          secondaryActionLabel: 'Explain',
          onSecondaryAction: () {},
        ),
        const SizedBox(height: MemoraSpacing.space12),
        MemoraFeedbackPanel(
          type: MemoraFeedbackType.weakMemory,
          headline: 'Weak memory found',
          body: 'Electrical power is P = V * I. Let\'s reinforce this concept with a quick repair.',
          primaryActionLabel: 'Try a repair question',
          onPrimaryAction: () {},
          secondaryActionLabel: 'Explain answer',
          onSecondaryAction: () {},
        ),
        const SizedBox(height: MemoraSpacing.space16),
        const MemoraConceptExplanationCard(
          conceptTitle: 'Newton\'s Gravitational Law',
          explanation: 'Every particle attracts every other particle with a force proportional to product of their masses and inversely proportional to square of distance.',
          sourceExcerpt: 'Physics GCE A/L Unit 3: Mechanics, Page 42',
        ),
      ],
    );
  }

  Widget _buildPathSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const MemoraPathMilestoneCard(
          unitNumber: 1,
          title: 'Measurement & Mechanics',
          conceptsCount: 14,
          progress: 0.72,
        ),
        const SizedBox(height: MemoraSpacing.space24),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MemoraPathNode(
                stepNumber: 1,
                title: 'Units & Dimensions',
                state: MemoraPathNodeState.completed,
              ),
              Padding(
                padding: EdgeInsets.only(top: 28),
                child: MemoraPathConnector(isCompleted: true, length: 24),
              ),
              MemoraPathNode(
                stepNumber: 2,
                title: 'Vectors & Forces',
                state: MemoraPathNodeState.current,
              ),
              Padding(
                padding: EdgeInsets.only(top: 28),
                child: MemoraPathConnector(isCompleted: false, length: 24),
              ),
              MemoraPathNode(
                stepNumber: 3,
                title: 'Circular Motion',
                state: MemoraPathNodeState.needsReview,
              ),
              Padding(
                padding: EdgeInsets.only(top: 28),
                child: MemoraPathConnector(isCompleted: false, length: 24),
              ),
              MemoraPathNode(
                stepNumber: 4,
                title: 'Gravitational Fields',
                state: MemoraPathNodeState.available,
              ),
              Padding(
                padding: EdgeInsets.only(top: 28),
                child: MemoraPathConnector(isCompleted: false, length: 24),
              ),
              MemoraPathNode(
                stepNumber: 5,
                title: 'Oscillations & Waves',
                state: MemoraPathNodeState.locked,
                lockReason: 'Complete Unit 1 first',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
