import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';

/// Interactive Quiz Screen matching the exact visual mockup in docs/screens/quiz.png
/// and user-provided screenshots.
///
/// Features:
/// - Top header with Mora teacher mascot and 7-day streak
/// - Timer badge (04:32 Time remaining)
/// - 2x2 grid of solid colored answer buttons (#86BBE7 default, #1FE46B correct, #ED8F91 weak memory)
/// - Skip/Explain text links
/// - Full-width action button (Check Answer -> Next)
/// - Memora bottom navigation bar
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? _selectedIndex;
  bool _hasChecked = false;
  int _navIndex = 1; // Learning tab active

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = _selectedIndex == 1; // "Modern" is index 1

    return Scaffold(
      backgroundColor: MemoraColors.surfaceOcean, // #DDEEFF
      bottomNavigationBar: MemoraBottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (int index) {
          if (index == 0) {
            context.go('/');
          } else {
            setState(() {
              _navIndex = index;
            });
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space16,
            vertical: MemoraSpacing.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Top Bar: Memora logo, Menu, Mora teacher mascot, 7 days streak
              _buildTopHeader(),

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

                    // Timer Badge Row (Right-aligned)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: MemoraTimerBadge(
                        timeFormatted: '04:32',
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

                    // Skip or Explain text link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          if (_hasChecked) {
                            // Show explain
                          } else {
                            _onNext();
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8FA3B5),
                        ),
                        child: Text(
                          _hasChecked ? 'Explain' : 'skip',
                          style: MemoraTypography.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8FA3B5),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: MemoraSpacing.space8),

                    // Primary Action Button (Check Answer -> Next)
                    if (!_hasChecked)
                      MemoraQuizActionButton(
                        label: 'Check Answer',
                        variant: MemoraQuizActionVariant.checkAnswer,
                        onPressed: _selectedIndex != null
                            ? _onCheckAnswer
                            : null,
                      )
                    else
                      MemoraQuizActionButton(
                        label: 'Next →',
                        variant: isCorrect
                            ? MemoraQuizActionVariant.nextCorrect
                            : MemoraQuizActionVariant.nextWeakMemory,
                        onPressed: _onNext,
                      ),
                  ],
                ),
              ),

              if (_hasChecked) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space16),
                if (isCorrect)
                  const MemoraFeedbackPanel(
                    type: MemoraFeedbackType.recalled,
                    headline: 'Memory protected!',
                    body: '"Modern" refers to the present and is the direct antonym of "ancient".',
                    primaryActionLabel: 'Continue',
                    onPrimaryAction: _noop,
                  )
                else
                  const MemoraFeedbackPanel(
                    type: MemoraFeedbackType.weakMemory,
                    headline: 'Weak memory found',
                    body: 'The opposite of "ancient" is "modern". Let\'s reinforce this concept!',
                    primaryActionLabel: 'Review Explanation',
                    onPrimaryAction: _noop,
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
        return MemoraQuizOptionState.selected;
      }
      return MemoraQuizOptionState.defaultState;
    }

    // Checked state
    if (index == 1) {
      return MemoraQuizOptionState.correct; // "Modern" is correct
    }
    if (_selectedIndex == index) {
      return MemoraQuizOptionState.weakMemory; // Wrong selection
    }
    return MemoraQuizOptionState.defaultState;
  }

  Widget _buildTopHeader() {
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
                // Memora Logo & Menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: MemoraColors.brandPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: MemoraSpacing.space8),
                        Text(
                          'Memora',
                          style: MemoraTypography.cardTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: <Widget>[
                        Icon(Icons.menu, size: 14, color: Color(0xFF00AFFF)),
                        SizedBox(width: 4),
                        Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MemoraColors.textPrimary,
                          ),
                        ),
                      ],
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

  static void _noop() {}
}
