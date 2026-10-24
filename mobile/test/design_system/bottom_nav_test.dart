import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

void main() {
  group('MemoraBottomNavigationBar', () {
    testWidgets('renders all 4 destinations with visible labels and min 48x48 touch targets', (
      WidgetTester tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              theme: MemoraTheme.light(),
              home: Scaffold(
                bottomNavigationBar: MemoraBottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (int index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                ),
                body: const SizedBox(),
              ),
            );
          },
        ),
      );

      // Verify all 4 destination labels are visible
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify touch targets >= 48x48
      final Finder homeFinder = find.widgetWithText(InkWell, 'Home');
      final Size homeSize = tester.getSize(homeFinder);
      expect(homeSize.width, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));
      expect(homeSize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));

      // Verify tap changes selected destination
      await tester.tap(find.text('Learning'));
      await tester.pump();
      expect(selectedIndex, 1);

      await tester.tap(find.text('Progress'));
      await tester.pump();
      expect(selectedIndex, 2);

      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(selectedIndex, 3);
    });

    testWidgets('accessible semantics announce tab and position', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            bottomNavigationBar: MemoraBottomNavigationBar(
              currentIndex: 1, // Learning
              onTap: (_) {},
            ),
            body: const SizedBox(),
          ),
        ),
      );

      final Finder learningFinder = find.widgetWithText(InkWell, 'Learning');
      final SemanticsData learningData = tester.getSemantics(learningFinder).getSemanticsData();
      expect(learningData.label, 'Learning tab, 2 of 4');
      expect(learningData.flagsCollection.isSelected, Tristate.isTrue);
      expect(learningData.flagsCollection.isButton, isTrue);

      final Finder homeFinder = find.widgetWithText(InkWell, 'Home');
      final SemanticsData homeData = tester.getSemantics(homeFinder).getSemanticsData();
      expect(homeData.label, 'Home tab, 1 of 4');
      expect(homeData.flagsCollection.isSelected, isNot(Tristate.isTrue));
      expect(homeData.flagsCollection.isButton, isTrue);
    });
  });
}
