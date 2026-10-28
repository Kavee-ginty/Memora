import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/mora.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../auth/application/session_controller.dart';
import '../../../routing/app_routes.dart';

/// Interactive onboarding flow implementing UI/UX specs 9.2, 9.3, and 9.4.
class OnboardingScreen extends ConsumerStatefulWidget {
  final int step;

  const OnboardingScreen({super.key, this.step = 1});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.step.clamp(1, 3);
  }

  @override
  void didUpdateWidget(OnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step != oldWidget.step) {
      _currentStep = widget.step.clamp(1, 3);
    }
  }

  Future<void> _completeOnboarding(String destination) async {
    final storage = ref.read(appLocalStorageProvider);
    await storage.setOnboardingCompleted(true);
    if (!mounted) return;
    context.go(destination);
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      context.go(AppRoutes.onboardingStep(_currentStep));
    } else {
      _completeOnboarding(AppRoutes.createAccount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5F1FC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Mora Mascot Peeking
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: MemoraSpacing.space24),
                child: MoraPlacement(
                  state: _currentStep == 3
                      ? MoraState.celebrate
                      : MoraState.guide,
                  size: 90.0,
                  isDecorative: true,
                ),
              ),
            ),
            // Header bar inside screen container
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MemoraSpacing.gutterForWidth(
                  MediaQuery.sizeOf(context).width,
                ),
                vertical: MemoraSpacing.space8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: MemoraColors.textPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: MemoraColors.brandPrimary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: MemoraSpacing.space8),
                        const Flexible(
                          child: Text(
                            'memora',
                            style: TextStyle(
                              fontFamily: 'Exo',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: MemoraColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_currentStep of 3',
                    style: MemoraTypography.cardTitle.copyWith(
                      color: MemoraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: MemoraSpacing.space24,
                  vertical: MemoraSpacing.space12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildVisualCard(_currentStep),
                    const SizedBox(height: MemoraSpacing.space24),
                    _buildTextSection(_currentStep),
                    const SizedBox(height: MemoraSpacing.space16),
                    _buildNoteSection(_currentStep),
                    const SizedBox(height: MemoraSpacing.space24),
                    _buildPageIndicator(_currentStep),
                    const SizedBox(height: MemoraSpacing.space24),
                    _buildActions(_currentStep),
                    const SizedBox(height: MemoraSpacing.space16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualCard(int step) {
    return MemoraCard(
      variant: MemoraCardVariant.primary,
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        alignment: Alignment.center,
        child: step == 1
            ? const _ForgettingCurveVisual()
            : step == 2
            ? const _TimelyReturnVisual()
            : const _GrowReefVisual(),
      ),
    );
  }

  Widget _buildTextSection(int step) {
    final String title;
    final String body;

    switch (step) {
      case 1:
        title = 'New memories can fade.';
        body = 'That is normal. A quick review at the right time helps bring them back.';
        break;
      case 2:
        title = 'Come back before it fades.';
        body = 'Memora schedules short reviews when they can help most. Timing adapts as you learn.';
        break;
      case 3:
      default:
        title = 'Small reviews grow something lasting.';
        body = 'Protect memories to help each subject reef recover and thrive. What you earn stays yours.';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: MemoraTypography.pageTitle),
        ),
        const SizedBox(height: MemoraSpacing.space12),
        Text(
          body,
          style: MemoraTypography.body.copyWith(
            color: MemoraColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(int step) {
    final String note;
    switch (step) {
      case 1:
        note = 'Ebbinghaus explored this pattern. Your pace of forgetting can be different.';
        break;
      case 2:
        note = 'A starting point, not a deadline. Timing varies by learner and material.';
        break;
      case 3:
      default:
        note = 'Consistent practice gradually expands your reef sanctuary.';
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 18,
          color: MemoraColors.textSecondary,
        ),
        const SizedBox(width: MemoraSpacing.space8),
        Expanded(
          child: Text(
            note,
            style: MemoraTypography.metadata.copyWith(
              color: MemoraColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int activeStep) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index + 1 == activeStep;
        return AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0072B2) : const Color(0xFFB0D2F2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildActions(int step) {
    if (step < 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MemoraButton(label: 'Next', onPressed: _nextStep),
          const SizedBox(height: MemoraSpacing.space8),
          TextButton(
            onPressed: () => _completeOnboarding(AppRoutes.signIn),
            child: const Text(
              'Skip onboarding',
              style: TextStyle(
                fontFamily: 'Exo',
                fontWeight: FontWeight.w600,
                color: MemoraColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MemoraButton(
          label: 'Create account',
          onPressed: () => _completeOnboarding(AppRoutes.createAccount),
        ),
        const SizedBox(height: MemoraSpacing.space8),
        MemoraButton(
          label: 'I already have an account',
          variant: MemoraButtonVariant.secondary,
          onPressed: () => _completeOnboarding(AppRoutes.signIn),
        ),
      ],
    );
  }
}

// --- Visual Illustrations ---

class _ForgettingCurveVisual extends StatelessWidget {
  const _ForgettingCurveVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Easier to recall',
          style: TextStyle(fontSize: 12, color: MemoraColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          width: double.infinity,
          child: CustomPaint(
            painter: _CurvePainter(),
            child: const Center(
              child: Text(
                'Without a little\nrefresher...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0072B2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              'Learn',
              style: TextStyle(fontSize: 12, color: MemoraColors.textSecondary),
            ),
            Text(
              'Time passes →',
              style: TextStyle(fontSize: 12, color: MemoraColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Illustrative curve · not measured data',
          style: TextStyle(fontSize: 10, color: MemoraColors.textSecondary),
        ),
      ],
    );
  }
}

class _CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFD6E4F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Grid guide lines
    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width, size.height * 0.2),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      linePaint,
    );

    // Curve fill
    final fillPath = Path()
      ..moveTo(0, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.65,
        size.width,
        size.height * 0.88,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = const Color(0x80D4E9F9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Curve line
    final curvePath = Path()
      ..moveTo(0, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.65,
        size.width,
        size.height * 0.88,
      );

    final curvePaint = Paint()
      ..color = const Color(0xFF009EE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, curvePaint);

    // Dot at start
    final dotPaint = Paint()..color = const Color(0xFF009EE0);
    canvas.drawCircle(Offset(0, size.height * 0.1), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimelyReturnVisual extends StatelessWidget {
  const _TimelyReturnVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD3E7FA), width: 10),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 36, color: Color(0xFF0072B2)),
                const SizedBox(height: 4),
                Text(
                  'Review soon',
                  style: MemoraTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF009EE0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: MemoraSpacing.space16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: const [
            Icon(Icons.menu_book, size: 16, color: Color(0xFF0072B2)),
            Text(
              'Learn today',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Icon(
              Icons.arrow_forward,
              size: 14,
              color: MemoraColors.textSecondary,
            ),
            Icon(Icons.auto_awesome, size: 16, color: Color(0xFF0072B2)),
            Text(
              'Revisit soon',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _GrowReefVisual extends StatelessWidget {
  const _GrowReefVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCoralNode(
              'Initial',
              Icons.spa_outlined,
              const Color(0xFF8BA3B8),
            ),
            const Icon(
              Icons.arrow_forward,
              color: MemoraColors.textSecondary,
              size: 16,
            ),
            _buildCoralNode('Practicing', Icons.spa, const Color(0xFF009EE0)),
            const Icon(
              Icons.arrow_forward,
              color: MemoraColors.textSecondary,
              size: 16,
            ),
            _buildCoralNode(
              'Thriving Reef',
              Icons.wb_sunny,
              const Color(0xFF00BFA5),
            ),
          ],
        ),
        const SizedBox(height: MemoraSpacing.space16),
        const Text(
          'Continuous recovery with each mission',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0072B2),
          ),
        ),
      ],
    );
  }

  Widget _buildCoralNode(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
