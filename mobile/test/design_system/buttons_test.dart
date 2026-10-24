import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

void main() {
  group('MemoraButton', () {
    testWidgets('renders primary button with minimum 48px touch target', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            body: Center(
              child: MemoraButton(
                label: 'Start Mission',
                onPressed: () {
                  pressed = true;
                },
              ),
            ),
          ),
        ),
      );

      final Finder buttonFinder = find.byType(MemoraButton);
      expect(buttonFinder, findsOneWidget);
      expect(find.text('Start Mission'), findsOneWidget);

      final Size buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));

      await tester.tap(buttonFinder);
      expect(pressed, isTrue);
    });

    testWidgets('renders all button variants', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            body: Column(
              children: <Widget>[
                MemoraButton(label: 'Primary', variant: MemoraButtonVariant.primary, onPressed: () {}),
                MemoraButton(label: 'Secondary', variant: MemoraButtonVariant.secondary, onPressed: () {}),
                MemoraButton(label: 'Tertiary', variant: MemoraButtonVariant.tertiary, onPressed: () {}),
                MemoraButton(label: 'Destructive', variant: MemoraButtonVariant.destructive, onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Tertiary'), findsOneWidget);
      expect(find.text('Destructive'), findsOneWidget);
    });

    testWidgets('disabled button does not trigger callback and has disabled semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(body: MemoraButton(label: 'Disabled Action', onPressed: null)),
        ),
      );

      final Finder buttonFinder = find.byType(MemoraButton);
      await tester.tap(buttonFinder);
      await tester.pump();

      final SemanticsData data = tester.getSemantics(buttonFinder).getSemanticsData();
      expect(data.label, 'Disabled Action');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('loading button shows progress indicator and retains accessible label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            body: MemoraButton(label: 'Saving Draft', isLoading: true, onPressed: () {}),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saving Draft'), findsOneWidget);

      final Finder buttonFinder = find.byType(MemoraButton);
      final SemanticsData data = tester.getSemantics(buttonFinder).getSemanticsData();
      expect(data.label, 'Saving Draft, loading');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('adapts to 200% text scale without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SizedBox(
                width: 320,
                child: MemoraButton(
                  label: 'Very Long Action Label Designed For Accessibility Scaling Testing',
                  onPressed: null,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
