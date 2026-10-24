import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';
import 'package:memora_mobile/src/features/quiz/presentation/quiz_screen.dart';

void main() {
  testWidgets('QuizScreen renders 2x2 solid colored buttons matching mockup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: MemoraTheme.light(), home: const QuizScreen()),
    );

    // 1. Verify Header Elements
    expect(find.text('Memora'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);

    // 2. Verify Timer Badge & Question
    expect(find.text('04:32'), findsOneWidget);
    expect(find.text('Time remaining'), findsOneWidget);
    expect(
      find.text('Which word means the opposite of “ancient”?'),
      findsOneWidget,
    );

    // 3. Verify the 4 Solid Colored Buttons in 2x2 Grid
    expect(find.text('Historic'), findsOneWidget);
    expect(find.text('Modern'), findsOneWidget);
    expect(find.text('Timeless'), findsOneWidget);
    expect(find.text('Traditional'), findsOneWidget);

    // 4. Verify Skip and Check Answer CTA
    expect(find.text('skip'), findsOneWidget);
    expect(find.text('Check Answer'), findsOneWidget);

    // 5. Select option 'Modern' and check answer
    await tester.ensureVisible(find.text('Modern'));
    await tester.tap(find.text('Modern'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Check Answer'));
    await tester.tap(find.text('Check Answer'));
    await tester.pumpAndSettle();

    // Verify State Transition
    expect(find.text('Next →'), findsOneWidget);
    expect(find.text('Explain'), findsOneWidget);
    expect(find.text('Memory protected!'), findsOneWidget);
  });
}
