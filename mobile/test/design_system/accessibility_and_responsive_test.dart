import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

void main() {
  group('Accessibility and Responsive Acceptance Tests (T03)', () {
    testWidgets('Component catalog renders cleanly at 320 px width without horizontal overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(theme: MemoraTheme.light(), home: const ComponentCatalogScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull, reason: 'Must not throw overflow exceptions at 320 px');
      expect(find.text('Component Catalog'), findsOneWidget);
    });

    testWidgets('Component catalog renders cleanly at 200% text scale without overflow or clipping', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: ComponentCatalogScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull, reason: 'Must not throw text clipping or overflow at 200% scale');
      expect(find.text('Component Catalog'), findsOneWidget);
    });

    testWidgets('All interactive buttons and navigation targets meet minimum 48x48 px touch target (UIX-030)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(theme: MemoraTheme.light(), home: const ComponentCatalogScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check BottomNavigationBar items
      for (final String label in <String>['Home', 'Learning', 'Progress', 'Profile']) {
        final Finder targetFinder = find.widgetWithText(InkWell, label);
        expect(targetFinder, findsOneWidget);
        final Size size = tester.getSize(targetFinder);
        expect(
          size.width,
          greaterThanOrEqualTo(MemoraSpacing.minTouchTarget),
          reason: '$label nav item width must be >= 48px',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(MemoraSpacing.minTouchTarget),
          reason: '$label nav item height must be >= 48px',
        );
      }

      // Check primary button
      final Finder primaryButton = find.widgetWithText(MemoraButton, 'Primary Action');
      expect(primaryButton, findsOneWidget);
      final Size primarySize = tester.getSize(primaryButton);
      expect(primarySize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));

      // Check secondary button
      final Finder secondaryButton = find.widgetWithText(MemoraButton, 'Secondary Action');
      expect(secondaryButton, findsOneWidget);
      final Size secondarySize = tester.getSize(secondaryButton);
      expect(secondarySize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));

      // Check tertiary button
      final Finder tertiaryButton = find.widgetWithText(MemoraButton, 'Tertiary Action');
      expect(tertiaryButton, findsOneWidget);
      final Size tertiarySize = tester.getSize(tertiaryButton);
      expect(tertiarySize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));

      // Check destructive button
      final Finder destructiveButton = find.widgetWithText(MemoraButton, 'Destructive Action');
      expect(destructiveButton, findsOneWidget);
      final Size destructiveSize = tester.getSize(destructiveButton);
      expect(destructiveSize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));
    });

    testWidgets('Component catalog functions under reduced-motion mode (UIX-023)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const MediaQuery(data: MediaQueryData(disableAnimations: true), child: ComponentCatalogScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.byType(ComponentCatalogScreen), findsOneWidget);
    });
  });
}
