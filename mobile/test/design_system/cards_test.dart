import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

void main() {
  group('MemoraCard and Variations', () {
    testWidgets('MemoraCard primary variant renders with 24px radius', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(
            body: MemoraCard(
              variant: MemoraCardVariant.primary,
              child: Text('Primary Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Primary Card Content'), findsOneWidget);
      final Container container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MemoraCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, MemoraRadii.primaryCard);
    });

    testWidgets('MemoraCard compact variant renders with 16px radius', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(
            body: MemoraCard(
              variant: MemoraCardVariant.compact,
              child: Text('Compact Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Compact Card Content'), findsOneWidget);
      final Container container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MemoraCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, MemoraRadii.compactCard);
    });

    testWidgets(
      'MemoraProgressCard renders title, status, percentage, and accessible value',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: const Scaffold(
              body: MemoraProgressCard(
                title: 'Everyday English',
                statusText: '6 of 10 lessons completed',
                progress: 0.60,
                metricText: '60%',
              ),
            ),
          ),
        );

        expect(find.text('Everyday English'), findsOneWidget);
        expect(find.text('6 of 10 lessons completed'), findsOneWidget);
        expect(find.text('60%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        final Finder progressFinder = find.byType(MemoraProgressCard);
        final SemanticsData data = tester
            .getSemantics(progressFinder)
            .getSemanticsData();
        expect(
          data.label,
          'Everyday English. 6 of 10 lessons completed. 60% complete.',
        );
        expect(data.value, '60%');
      },
    );

    testWidgets(
      'MemoraSelectableCard toggles selection and updates semantics',
      (WidgetTester tester) async {
        bool selected = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MaterialApp(
                theme: MemoraTheme.light(),
                home: Scaffold(
                  body: MemoraSelectableCard(
                    title: 'Mechanics Concept',
                    isSelected: selected,
                    onTap: () {
                      setState(() {
                        selected = !selected;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        );

        final Finder cardFinder = find.byType(MemoraSelectableCard);
        expect(find.text('Mechanics Concept'), findsOneWidget);

        SemanticsData data = tester.getSemantics(cardFinder).getSemanticsData();
        expect(data.label, 'Mechanics Concept');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isSelected, isNot(Tristate.isTrue));

        await tester.tap(cardFinder);
        await tester.pump();

        expect(selected, isTrue);
        data = tester.getSemantics(cardFinder).getSemanticsData();
        expect(data.label, 'Mechanics Concept');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isSelected, Tristate.isTrue);
      },
    );
  });
}
