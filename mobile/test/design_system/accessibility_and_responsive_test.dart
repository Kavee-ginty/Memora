import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';
import 'package:memora_mobile/src/features/quiz/presentation/quiz_screen.dart';

void main() {
  group('Accessibility and Responsive Acceptance Tests (T03)', () {
    testWidgets(
      'Component catalog renders cleanly at 320 px width without horizontal overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320 * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: const ComponentCatalogScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          tester.takeException(),
          isNull,
          reason: 'Must not throw overflow exceptions at 320 px',
        );
        expect(find.text('Component Catalog'), findsOneWidget);
      },
    );

    testWidgets(
      'Component catalog renders cleanly at 200% text scale without overflow or clipping',
      (WidgetTester tester) async {
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

        expect(
          tester.takeException(),
          isNull,
          reason: 'Must not throw text clipping or overflow at 200% scale',
        );
        expect(find.text('Component Catalog'), findsOneWidget);
      },
    );

    testWidgets(
      'Component catalog and QuizScreen render cleanly at combined 320 px width AND 200% text scale',
      (WidgetTester tester) async {
        final void Function(FlutterErrorDetails)? oldOnError =
            FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.exception is FlutterError) {
            final FlutterError fe = details.exception as FlutterError;
            for (final DiagnosticsNode node in fe.diagnostics) {
              if (node.value is RenderFlex) {
                // ignore: avoid_print
                print(
                  'RENDERFLEX_CREATOR: ${(node.value as RenderFlex).debugCreator}',
                );
              }
            }
          }
          oldOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = oldOnError;
        });

        tester.view.physicalSize = const Size(320 * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Test Component Catalog
        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 800),
                textScaler: TextScaler.linear(2.0),
              ),
              child: ComponentCatalogScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          tester.takeException(),
          isNull,
          reason:
              'Catalog must not overflow at combined 320px + 200% text scale',
        );
        expect(find.text('Component Catalog'), findsOneWidget);

        // 2. Test QuizScreen with single column adaptation (UIX-017)
        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 800),
                textScaler: TextScaler.linear(2.0),
              ),
              child: QuizScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          tester.takeException(),
          isNull,
          reason: 'QuizScreen must not overflow at combined 320px + 200% text scale',
        );
        // At combined 320px and 200% text scale, UIX-017 requires single-column answers
        expect(
          find.byKey(const ValueKey('MemoraQuizGridSingleColumn')),
          findsOneWidget,
          reason:
              'Quiz answers must adapt to 1 column at 320px with 200% scale',
        );
        expect(find.text('Historic'), findsOneWidget);
        expect(find.text('Modern'), findsOneWidget);
        expect(find.text('Timeless'), findsOneWidget);
        expect(find.text('Traditional'), findsOneWidget);
      },
    );

    testWidgets(
      'All interactive buttons and navigation targets meet minimum 48x48 px touch target (UIX-030)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: const ComponentCatalogScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Check BottomNavigationBar items
        for (final String label in <String>[
          'Home',
          'Learning',
          'Progress',
          'Profile',
        ]) {
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
        final Finder primaryButton = find.widgetWithText(
          MemoraButton,
          'Primary Action',
        );
        expect(primaryButton, findsOneWidget);
        final Size primarySize = tester.getSize(primaryButton);
        expect(
          primarySize.height,
          greaterThanOrEqualTo(MemoraSpacing.minTouchTarget),
        );

        // Check secondary button
        final Finder secondaryButton = find.widgetWithText(
          MemoraButton,
          'Secondary Action',
        );
        expect(secondaryButton, findsOneWidget);
        final Size secondarySize = tester.getSize(secondaryButton);
        expect(
          secondarySize.height,
          greaterThanOrEqualTo(MemoraSpacing.minTouchTarget),
        );

        // Check tertiary button
        final Finder tertiaryButton = find.widgetWithText(
          MemoraButton,
          'Tertiary Action',
        );
        expect(tertiaryButton, findsOneWidget);
        final Size tertiarySize = tester.getSize(tertiaryButton);
        expect(
          tertiarySize.height,
          greaterThanOrEqualTo(MemoraSpacing.minTouchTarget),
        );

        // Check destructive button
        final Finder destructiveButton = find.widgetWithText(
          MemoraButton,
          'Destructive Action',
        );
        expect(destructiveButton, findsOneWidget);
        final Size destructiveSize = tester.getSize(destructiveButton);
        expect(
          destructiveSize.height,
          greaterThanOrEqualTo(MemoraSpacing.minTouchTarget),
        );
      },
    );

    testWidgets(
      'Reduced-motion mode actively disables skeleton animation and controllers (UIX-023)',
      (WidgetTester tester) async {
        // Standard motion: AnimatedBuilder is active
        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: const Scaffold(
              body: MemoraSkeleton.card(width: 200, height: 100),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(MemoraSkeleton),
            matching: find.byType(AnimatedBuilder),
          ),
          findsOneWidget,
          reason: 'AnimatedBuilder must be present in standard motion mode',
        );

        // Reduced motion: animation is stopped, controller disposed, AnimatedBuilder absent
        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: MemoraSkeleton.card(width: 200, height: 100),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(MemoraSkeleton),
            matching: find.byType(AnimatedBuilder),
          ),
          findsNothing,
          reason: 'AnimatedBuilder must be absent when animations are disabled',
        );

        // Pump ticker without throwing exception
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Visible keyboard focus ring and activation via Enter and Space keys',
      (WidgetTester tester) async {
        int enterPressCount = 0;
        int spacePressCount = 0;
        final FocusNode button1Focus = FocusNode();
        final FocusNode button2Focus = FocusNode();

        addTearDown(() {
          button1Focus.dispose();
          button2Focus.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  MemoraButton(
                    label: 'Button 1',
                    focusNode: button1Focus,
                    onPressed: () => enterPressCount++,
                  ),
                  MemoraButton(
                    label: 'Button 2',
                    focusNode: button2Focus,
                    onPressed: () => spacePressCount++,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Request focus on Button 1
        button1Focus.requestFocus();
        await tester.pumpAndSettle();
        expect(button1Focus.hasFocus, isTrue);
        expect(button2Focus.hasFocus, isFalse);

        // Verify visible focus border on Button 1 (MemoraColors.focus, width 2.0)
        final Container container1 = tester.widget<Container>(
          find
              .descendant(
                of: find.widgetWithText(MemoraButton, 'Button 1'),
                matching: find.byKey(
                  const ValueKey('MemoraButtonFocusContainer'),
                ),
              )
              .first,
        );
        final BoxDecoration? decoration1 =
            container1.decoration as BoxDecoration?;
        expect(decoration1, isNotNull);
        expect(decoration1!.border?.top.color, MemoraColors.focus);
        expect(decoration1.border?.top.width, 2.0);

        // 2. Activate Button 1 via Enter key
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(enterPressCount, 1);

        // 3. Shift focus to Button 2
        button2Focus.requestFocus();
        await tester.pumpAndSettle();
        expect(button1Focus.hasFocus, isFalse);
        expect(button2Focus.hasFocus, isTrue);

        // Verify visible focus border on Button 2
        final Container container2 = tester.widget<Container>(
          find
              .descendant(
                of: find.widgetWithText(MemoraButton, 'Button 2'),
                matching: find.byKey(
                  const ValueKey('MemoraButtonFocusContainer'),
                ),
              )
              .first,
        );
        final BoxDecoration? decoration2 =
            container2.decoration as BoxDecoration?;
        expect(decoration2, isNotNull);
        expect(decoration2!.border?.top.color, MemoraColors.focus);
        expect(decoration2.border?.top.width, 2.0);

        // 4. Activate Button 2 via Space key
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(spacePressCount, 1);
      },
    );

    testWidgets(
      'Dialog manages focus and restores focus to triggering control upon dismiss',
      (WidgetTester tester) async {
        final FocusNode triggerFocusNode = FocusNode();
        addTearDown(triggerFocusNode.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) {
                  return MemoraButton(
                    label: 'Open Dialog',
                    focusNode: triggerFocusNode,
                    onPressed: () {
                      showMemoraDialog<void>(
                        context: context,
                        title: 'Confirm Action',
                        message: 'Are you sure you want to proceed?',
                        primaryActionLabel: 'Confirm',
                        onPrimaryAction: () => Navigator.of(context).pop(),
                        secondaryActionLabel: 'Cancel',
                        onSecondaryAction: () => Navigator.of(context).pop(),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial focus on trigger button
        triggerFocusNode.requestFocus();
        await tester.pump();
        expect(triggerFocusNode.hasFocus, isTrue);

        // 2. Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Action'), findsOneWidget);
        expect(triggerFocusNode.hasPrimaryFocus, isFalse);

        // 3. Dismiss dialog via Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Action'), findsNothing);
        // Focus restored to the triggering button
        expect(triggerFocusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      'BottomSheet manages focus and restores focus to triggering control upon dismiss',
      (WidgetTester tester) async {
        final FocusNode triggerFocusNode = FocusNode();
        addTearDown(triggerFocusNode.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: MemoraTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) {
                  return MemoraButton(
                    label: 'Open Sheet',
                    focusNode: triggerFocusNode,
                    onPressed: () {
                      showMemoraBottomSheet<void>(
                        context: context,
                        title: 'Sheet Details',
                        child: const Text('Sheet body content'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial focus on trigger button
        triggerFocusNode.requestFocus();
        await tester.pump();
        expect(triggerFocusNode.hasFocus, isTrue);

        // 2. Open bottom sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Sheet Details'), findsOneWidget);
        expect(triggerFocusNode.hasPrimaryFocus, isFalse);

        // 3. Dismiss bottom sheet via Close button
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();

        expect(find.text('Sheet Details'), findsNothing);
        // Focus restored to the triggering button
        expect(triggerFocusNode.hasFocus, isTrue);
      },
    );
  });
}
