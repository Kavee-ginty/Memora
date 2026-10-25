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
            showIndexBadge: true,
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Newton\'s Law'), findsOneWidget);
    });

    testWidgets(
      'renders clean 2x2 colored quiz buttons without badge by default',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildApp(
            const MemoraQuizGrid(
              options: <Widget>[
                MemoraQuizOption(text: 'Historic'),
                MemoraQuizOption(
                  text: 'Modern',
                  state: MemoraQuizOptionState.correct,
                ),
                MemoraQuizOption(text: 'Timeless'),
                MemoraQuizOption(
                  text: 'Traditional',
                  state: MemoraQuizOptionState.weakMemory,
                ),
              ],
            ),
          ),
        );

        expect(find.text('Historic'), findsOneWidget);
        expect(find.text('Modern'), findsOneWidget);
        expect(find.text('Timeless'), findsOneWidget);
        expect(find.text('Traditional'), findsOneWidget);
      },
    );

    testWidgets('renders MemoraTimerBadge and MemoraQuizActionButton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          Column(
            children: <Widget>[
              const MemoraTimerBadge(timeFormatted: '04:32'),
              MemoraQuizActionButton(label: 'Check Answer', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.text('04:32'), findsOneWidget);
      expect(find.text('Check Answer'), findsOneWidget);
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

  group('MemoraQuizGrid answer layout (UIX-017)', () {
    testWidgets(
      'renders 2 columns when every option fits on a single line at standard scale',
      (WidgetTester tester) async {
        // 400px width container
        await tester.pumpWidget(
          buildApp(
            const SizedBox(
              width: 400,
              child: MemoraQuizGrid(
                options: <Widget>[
                  MemoraQuizOption(text: 'Fast'),
                  MemoraQuizOption(text: 'Slow'),
                  MemoraQuizOption(text: 'Up'),
                  MemoraQuizOption(text: 'Down'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Two columns are formed
        expect(
          find.byKey(const ValueKey('MemoraQuizGridTwoColumns')),
          findsOneWidget,
          reason: 'Short options fitting on 1 line must render 2 columns',
        );
      },
    );

    testWidgets(
      'automatically switches to single column when an option exceeds single line width',
      (WidgetTester tester) async {
        // 400px width container with one long answer option
        await tester.pumpWidget(
          buildApp(
            const SizedBox(
              width: 400,
              child: MemoraQuizGrid(
                options: <Widget>[
                  MemoraQuizOption(text: 'Fast'),
                  MemoraQuizOption(
                    text: 'The total energy in an isolated system remains constant over time',
                  ),
                  MemoraQuizOption(text: 'Up'),
                  MemoraQuizOption(text: 'Down'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Single column layout
        expect(
          find.byKey(const ValueKey('MemoraQuizGridSingleColumn')),
          findsOneWidget,
          reason: 'Long option exceeding single line must switch to single column per UIX-017',
        );
      },
    );

    testWidgets('switches to single column at 200% text scale (UIX-017)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SizedBox(
                width: 360,
                child: MemoraQuizGrid(
                  options: <Widget>[
                    MemoraQuizOption(text: 'Historic'),
                    MemoraQuizOption(text: 'Modern'),
                    MemoraQuizOption(text: 'Timeless'),
                    MemoraQuizOption(text: 'Traditional'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('MemoraQuizGridSingleColumn')),
        findsOneWidget,
        reason: '200% text scale must switch to single column to prevent cramped wrapping',
      );
    });

    testWidgets('switches to single column at 320 px screen width (UIX-017)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 320px viewport with screen padding (16*2=32) and card padding (24*2=48)
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: MemoraQuizGrid(
                options: <Widget>[
                  MemoraQuizOption(text: 'Historic'),
                  MemoraQuizOption(text: 'Modern'),
                  MemoraQuizOption(text: 'Timeless'),
                  MemoraQuizOption(text: 'Traditional'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('MemoraQuizGridSingleColumn')),
        findsOneWidget,
        reason: '320px width must switch to single column per UIX-017',
      );
    });
  });
}
