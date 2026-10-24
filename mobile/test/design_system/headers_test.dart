import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

void main() {
  group('MemoraHeader', () {
    testWidgets('Root header renders brand, menu affordance, and streak badge', (WidgetTester tester) async {
      bool menuPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            appBar: MemoraHeader.root(
              title: 'Memora',
              streakDays: 7,
              onMenuPressed: () {
                menuPressed = true;
              },
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Memora'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);

      final Finder menuFinder = find.widgetWithText(InkWell, 'Menu');
      final Size menuSize = tester.getSize(menuFinder);
      expect(menuSize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));
      expect(menuSize.width, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));

      await tester.tap(menuFinder);
      expect(menuPressed, isTrue);
    });

    testWidgets('Detail header renders Back button with accessible label and min 48x48 target', (
      WidgetTester tester,
    ) async {
      bool backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            appBar: MemoraHeader.detail(
              title: 'Physics Mechanics',
              subtitle: 'Unit 1: Kinematics',
              onBackPressed: () {
                backPressed = true;
              },
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Physics Mechanics'), findsOneWidget);
      expect(find.text('Unit 1: Kinematics'), findsOneWidget);

      final Finder backFinder = find.byTooltip('Go back');
      expect(backFinder, findsOneWidget);

      final Size backSize = tester.getSize(backFinder);
      expect(backSize.width, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));
      expect(backSize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));

      await tester.tap(backFinder);
      expect(backPressed, isTrue);
    });

    testWidgets('Mission header renders Pause/exit with accessible label and progress text', (
      WidgetTester tester,
    ) async {
      bool pausePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            appBar: MemoraHeader.mission(
              missionProgressText: 'Memories protected 3 of 8',
              timerText: '04:32',
              onPauseMission: () {
                pausePressed = true;
              },
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Memories protected 3 of 8'), findsOneWidget);
      expect(find.text('04:32'), findsOneWidget);

      final Finder pauseFinder = find.byTooltip('Pause and exit');
      expect(pauseFinder, findsOneWidget);

      final Size pauseSize = tester.getSize(pauseFinder);
      expect(pauseSize.width, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));
      expect(pauseSize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));

      await tester.tap(pauseFinder);
      expect(pausePressed, isTrue);
    });
  });
}
