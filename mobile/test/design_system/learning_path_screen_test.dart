import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';
import 'package:memora_mobile/src/features/learning/presentation/learning_path_screen.dart';

void main() {
  testWidgets(
    'LearningPathScreen renders full Everyday English learning path',
    (WidgetTester tester) async {
      bool started = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            body: LearningPathScreen(
              onStartMission: () {
                started = true;
              },
            ),
          ),
        ),
      );

      // 1. Verify Top Header Card
      expect(find.text('Everyday English'), findsOneWidget);
      expect(find.text('6 of 10 Quizzes completed'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);

      // 2. Verify Milestone Pill
      expect(find.text('Quiz 1–4 completed'), findsOneWidget);

      // 3. Verify Nodes
      expect(find.text('5 · Daily routines'), findsOneWidget);
      expect(find.text('Ready for real life'), findsOneWidget);

      expect(find.text('6 · At the shops'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // 4. Verify Active Mission with Mora & Start Quiz
      expect(find.text('At the café'), findsOneWidget);
      expect(find.text('Lesson 7 · 5 min · +20 XP'), findsOneWidget);
      expect(find.text('You\'re making waves!'), findsOneWidget);
      expect(find.text('YOU ARE HERE'), findsOneWidget);
      expect(find.text('Start Quiz'), findsOneWidget);

      // 5. Verify Locked Node & Reward
      expect(find.text('8 · Getting around'), findsOneWidget);
      expect(find.text('Complete Quiz 7'), findsOneWidget);
      expect(find.text('+50 XP reward'), findsOneWidget);
      expect(find.text('Finish Quiz 8 to unlock'), findsOneWidget);

      // Tap Start Quiz
      await tester.ensureVisible(find.text('Start Quiz'));
      await tester.tap(find.text('Start Quiz'));
      await tester.pumpAndSettle();
      expect(started, isTrue);
    },
  );
}
