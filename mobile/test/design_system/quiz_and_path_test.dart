import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      theme: MemoraTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MemoraQuizOption tests', () {
    testWidgets('renders option label and text', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          const MemoraQuizOption(
            indexLabel: 'A',
            text: 'Newton\'s Law',
            state: MemoraQuizOptionState.defaultState,
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Newton\'s Law'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when selected', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildApp(
          MemoraQuizOption(
            indexLabel: 'B',
            text: 'Centripetal Force',
            state: MemoraQuizOptionState.defaultState,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(MemoraQuizOption));
      expect(tapped, isTrue);
    });

    testWidgets('does not trigger onTap when disabled', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildApp(
          MemoraQuizOption(
            indexLabel: 'C',
            text: 'Disabled Option',
            state: MemoraQuizOptionState.disabled,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(MemoraQuizOption));
      expect(tapped, isFalse);
    });

    testWidgets('exposes accessible semantics for correct and weak states', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          const Column(
            children: <Widget>[
              MemoraQuizOption(
                indexLabel: 'A',
                text: 'Correct choice',
                state: MemoraQuizOptionState.correct,
              ),
              MemoraQuizOption(
                indexLabel: 'B',
                text: 'Weak memory choice',
                state: MemoraQuizOptionState.weakMemory,
              ),
            ],
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Correct choice')).label,
        contains('Option A, Correct choice, correct, memory protected'),
      );
      expect(
        tester.getSemantics(find.text('Weak memory choice')).label,
        contains('Option B, Weak memory choice, weak memory'),
      );
    });
  });

  group('MemoraFeedbackPanel tests', () {
    testWidgets('renders recalled feedback panel with actions', (
      WidgetTester tester,
    ) async {
      bool primaryClicked = false;
      bool secondaryClicked = false;

      await tester.pumpWidget(
        buildApp(
          MemoraFeedbackPanel(
            type: MemoraFeedbackType.recalled,
            headline: 'Memory protected',
            body: 'Concept successfully reinforced.',
            primaryActionLabel: 'Next memory',
            onPrimaryAction: () {
              primaryClicked = true;
            },
            secondaryActionLabel: 'Explain answer',
            onSecondaryAction: () {
              secondaryClicked = true;
            },
          ),
        ),
      );

      expect(find.text('Memory protected'), findsOneWidget);
      expect(find.text('Concept successfully reinforced.'), findsOneWidget);

      await tester.tap(find.text('Next memory'));
      expect(primaryClicked, isTrue);

      await tester.tap(find.text('Explain answer'));
      expect(secondaryClicked, isTrue);
    });

    testWidgets('renders weak memory feedback panel', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          MemoraFeedbackPanel(
            type: MemoraFeedbackType.weakMemory,
            headline: 'Weak memory found',
            body: 'Let\'s repair this together.',
            primaryActionLabel: 'Try a repair question',
            onPrimaryAction: () {},
          ),
        ),
      );

      expect(find.text('Weak memory found'), findsOneWidget);
      expect(find.text('Let\'s repair this together.'), findsOneWidget);
      expect(find.text('Try a repair question'), findsOneWidget);
    });
  });

  group('MemoraPathNode & Map tests', () {
    testWidgets('renders completed, current, and locked states', (
      WidgetTester tester,
    ) async {
      bool currentTapped = false;

      await tester.pumpWidget(
        buildApp(
          Row(
            children: <Widget>[
              const MemoraPathNode(
                title: 'Vectors',
                state: MemoraPathNodeState.completed,
              ),
              MemoraPathNode(
                title: 'Circular Motion',
                state: MemoraPathNodeState.current,
                onTap: () {
                  currentTapped = true;
                },
              ),
              const MemoraPathNode(
                title: 'Gravitation',
                state: MemoraPathNodeState.locked,
                lockReason: 'Complete circular motion first',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Vectors'), findsOneWidget);
      expect(find.text('Circular Motion'), findsOneWidget);
      expect(find.text('Gravitation'), findsOneWidget);

      await tester.tap(find.text('Circular Motion'));
      expect(currentTapped, isTrue);

      // Verify touch target is at least 48x48 px
      final Size nodeSize = tester.getSize(find.byType(Stack).first);
      expect(nodeSize.width, greaterThanOrEqualTo(48.0));
      expect(nodeSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('MemoraPathMilestoneCard renders unit details and progress', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          const MemoraPathMilestoneCard(
            unitNumber: 2,
            title: 'Mechanics & Dynamics',
            conceptsCount: 16,
            progress: 0.5,
          ),
        ),
      );

      expect(find.text('U2'), findsOneWidget);
      expect(find.text('Mechanics & Dynamics'), findsOneWidget);
      expect(find.text('16 concepts • 50% complete'), findsOneWidget);
    });
  });
}
