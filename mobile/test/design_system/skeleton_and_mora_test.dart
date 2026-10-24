import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

void main() {
  group('MemoraSkeleton and Loading States', () {
    testWidgets('renders skeleton shapes with accessible semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(
            body: Column(
              children: <Widget>[
                MemoraSkeleton.card(height: 80),
                MemoraSkeleton.text(height: 16),
                MemoraSkeleton.circle(size: 40),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MemoraSkeleton), findsNWidgets(3));
      expect(find.bySemanticsLabel('Loading...'), findsNWidgets(3));
    });

    testWidgets('respects reduced motion when animations are disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: MemoraSkeleton.card(height: 80)),
          ),
        ),
      );

      // Verify widget builds without error under reduced motion
      expect(find.byType(MemoraSkeleton), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('MemoraLoadingTimeoutView shows recovery options after timeout (UIX-019)', (WidgetTester tester) async {
      bool retryClicked = false;
      bool leaveClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            body: MemoraLoadingTimeoutView(
              timeout: const Duration(milliseconds: 100),
              skeleton: const MemoraSkeleton.card(height: 100),
              onRetry: () {
                retryClicked = true;
              },
              onLeave: () {
                leaveClicked = true;
              },
            ),
          ),
        ),
      );

      // Initially shows skeleton
      expect(find.byType(MemoraSkeleton), findsOneWidget);
      expect(find.text('Loading your learning content...'), findsOneWidget);

      // Advance past timeout
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('This is taking longer than expected. You can wait, retry, or return Home.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryClicked, isTrue);

      await tester.tap(find.text('Leave'));
      expect(leaveClicked, isTrue);
    });
  });

  group('MoraPlacement', () {
    testWidgets('decorative Mora excludes semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(body: MoraPlacement(state: MoraState.guide, isDecorative: true)),
        ),
      );

      final Finder moraFinder = find.byType(MoraPlacement);
      expect(moraFinder, findsOneWidget);
      final SemanticsData data = tester.getSemantics(moraFinder).getSemanticsData();
      expect(data.label, isEmpty);
    });

    testWidgets('informative Mora includes semantics and speech bubble', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(
            body: MoraPlacement(
              state: MoraState.encourage,
              isDecorative: false,
              speechBubbleText: 'Great work! Keep going.',
            ),
          ),
        ),
      );

      expect(find.text('Great work! Keep going.'), findsOneWidget);
      final Finder moraFinder = find.byType(MoraPlacement);
      final SemanticsData data = tester.getSemantics(moraFinder).getSemanticsData();
      expect(data.label, 'Mora smiling encouragingly. Mora says: Great work! Keep going.');
    });
  });
}
