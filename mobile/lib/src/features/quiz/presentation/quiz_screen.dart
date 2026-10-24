import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';

/// Interactive Quiz Screen matching docs/screens/quiz.png and UI/UX Specification.
///
/// Complies with:
/// - UIX-008: Root bottom navigation is strictly hidden during active quizzes.
/// - UIX-030: Minimum 48x48 px touch targets across all interactive controls.
/// - UIX-001 & UIX-005: Canonical primary CTA styling preserved post-feedback.
/// - UIX-004: Supportive, non-punitive weak memory repair pathway with source explanation.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? _selectedIndex;
  bool _hasChecked = false;
  bool _showExplanation = false;

  // Active countdown timer (starts at 04:32 = 272 seconds)
  int _remainingSeconds = 272;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onOptionTap(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCheckAnswer() {
    if (_selectedIndex == null) return;
    setState(() {
      _hasChecked = true;
    });
  }

  void _onNext() {
    setState(() {
      _selectedIndex = null;
      _hasChecked = false;
      _showExplanation = false;
    });
  }

  void _onRetry() {
    setState(() {
      _selectedIndex = null;
      _hasChecked = false;
    });
  }

  void _toggleExplanation() {
    setState(() {
      _showExplanation = !_showExplanation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = _selectedIndex == 1; // "Modern" is index 1

    return Scaffold(
      backgroundColor: MemoraColors.surfaceOcean, // #DDEEFF
      // Root bottom navigation is intentionally omitted during active missions (UIX-008)
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space16,
            vertical: MemoraSpacing.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Top Bar: Memora logo, Menu affordance, Mora teacher mascot, 7 days streak
              _buildTopHeader(context),

              const SizedBox(height: MemoraSpacing.space8),

              // Main Quiz Card Container
              Container(
                padding: const EdgeInsets.all(MemoraSpacing.space24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.0),
                  border: Border.all(color: const Color(0xFFCCE2F6)),
                  boxShadow: MemoraElevations.cardShadows,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Thin Top Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        MemoraRadii.pillValue,
                      ),
                      child: const LinearProgressIndicator(
                        value: 0.75,
                        minHeight: 6,
                        backgroundColor: Color(0xFFD6E9FA),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF00C7FF),
                        ),
                      ),
                    ),

                    const SizedBox(height: MemoraSpacing.space16),

                    // Timer Badge Row (Right-aligned with active countdown)
                    Align(
                      alignment: Alignment.centerRight,
                      child: MemoraTimerBadge(
                        remainingSeconds: _remainingSeconds,
                        label: 'Time remaining',
                      ),
                    ),

                    const SizedBox(height: MemoraSpacing.space24),

                    // Question Prompt
                    Text(
                      'Which word means the opposite of “ancient”?',
                      textAlign: TextAlign.center,
                      style: MemoraTypography.cardTitle.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: MemoraColors.textPrimary,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: MemoraSpacing.space32),

                    // 2x2 Grid of Solid Colored Buttons
                    MemoraQuizGrid(
                      options: <Widget>[
                        MemoraQuizOption(
                          text: 'Historic',
                          state: _getOptionState(0),
                          onTap: () => _onOptionTap(0),
                        ),
                        MemoraQuizOption(
                          text: 'Modern',
                          state: _getOptionState(1),
                          onTap: () => _onOptionTap(1),
                        ),
                        MemoraQuizOption(
                          text: 'Timeless',
                          state: _getOptionState(2),
                          onTap: () => _onOptionTap(2),
                        ),
                        MemoraQuizOption(
                          text: 'Traditional',
                          state: _getOptionState(3),
                          onTap: () => _onOptionTap(3),
                        ),
                      ],
                    ),

                    const SizedBox(height: MemoraSpacing.space16),

                    // Skip or Explain text link with 48px touch target
                    Center(
                      child: TextButton(
                        onPressed: _hasChecked ? _toggleExplanation : _onNext,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(
                            MemoraSpacing.minTouchTarget,
                            MemoraSpacing.minTouchTarget,
                          ),
                          foregroundColor: const Color(0xFF566B7D),
                        ),
                        child: Text(
                          _hasChecked ? 'Explain answer' : 'skip',
                          style: MemoraTypography.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF566B7D),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: MemoraSpacing.space8),

                    // Primary Action Button (Canonical cyan action preserved per UIX-001)
                    MemoraQuizActionButton(
                      label: _hasChecked ? 'Next →' : 'Check Answer',
                      variant: MemoraQuizActionVariant.nextPrimary,
                      onPressed: _hasChecked
                          ? _onNext
                          : (_selectedIndex != null ? _onCheckAnswer : null),
                    ),
                  ],
                ),
              ),

              // Feedback Panel (shown after checking answer)
              if (_hasChecked) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space16),
                if (isCorrect)
                  MemoraFeedbackPanel(
                    type: MemoraFeedbackType.recalled,
                    headline: 'Memory protected!',
                    body: '"Modern" refers to the present and is the direct antonym of "ancient".',
                    primaryActionLabel: 'Next memory',
                    onPrimaryAction: _onNext,
                    secondaryActionLabel: 'Explain',
                    onSecondaryAction: _toggleExplanation,
                  )
                else
                  MemoraFeedbackPanel(
                    type: MemoraFeedbackType.weakMemory,
                    headline: 'Weak memory found',
                    body: 'The opposite of "ancient" is "modern". Let\'s reinforce this concept!',
                    primaryActionLabel: 'Try a repair question',
                    onPrimaryAction: _onRetry,
                    secondaryActionLabel: 'Explain answer',
                    onSecondaryAction: _toggleExplanation,
                  ),
              ],

              // Concept Explanation Card (toggled via Explain controls)
              if (_showExplanation) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space16),
                MemoraConceptExplanationCard(
                  conceptTitle: 'Antonyms & Etymology',
                  explanation: 'Ancient designates times long past in human history. Modern designates the present era or contemporary times.',
                  sourceExcerpt: 'English Vocabulary Mastery, Unit 4: Antonyms',
                  onContinue: _onNext,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  MemoraQuizOptionState _getOptionState(int index) {
    if (!_hasChecked) {
      if (_selectedIndex == index) {
        return MemoraQuizOptionState
            .selected; // Distinct selected tint, not correct
      }
      return MemoraQuizOptionState.defaultState;
    }

    // Evaluated state
    if (index == 1) {
      return MemoraQuizOptionState.correct; // "Modern" is correct
    }
    if (_selectedIndex == index) {
      return MemoraQuizOptionState.weakMemory; // Wrong selection
    }
    return MemoraQuizOptionState.defaultState;
  }

  Widget _buildTopHeader(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: <Widget>[
          // Header Card
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(
              horizontal: MemoraSpacing.space16,
              vertical: MemoraSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F0FD),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFFCCE2F6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // Memora Logo & Exit / Menu
                Row(
                  children: <Widget>[
                    Semantics(
                      button: true,
                      label: 'Exit quiz session',
                      child: InkWell(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        borderRadius: BorderRadius.circular(24.0),
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: MemoraSpacing.minTouchTarget,
                            minHeight: MemoraSpacing.minTouchTarget,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: MemoraColors.brandPrimary,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: MemoraColors.brandPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: MemoraSpacing.space8),
                    Text(
                      'Memora',
                      style: MemoraTypography.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Streak Flame
                const Row(
                  children: <Widget>[
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFF4A7DFF),
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '7 days',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: MemoraColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mora Mascot in Teacher Glasses Poking Above Card
          Positioned(
            top: -10,
            child: Image.asset(
              'assets/mascot/teaching.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
