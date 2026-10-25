import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

void main() {
  group('MemoraBanner, Dialog, BottomSheet and Toast', () {
    testWidgets('MemoraBanner displays icons and pairs with text', (
      WidgetTester tester,
    ) async {
      bool actionTapped = false;
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            body: Column(
              children: <Widget>[
                MemoraBanner(
                  variant: MemoraBannerVariant.offline,
                  title: 'Offline',
                  message: 'Working in offline mode',
                  actionLabel: 'Retry',
                  onAction: () {
                    actionTapped = true;
                  },
                  onDismiss: () {
                    dismissed = true;
                  },
                ),
                const MemoraBanner(
                  variant: MemoraBannerVariant.attention,
                  title: 'Weak memory found',
                  message: 'Review needed',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Working in offline mode'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(actionTapped, isTrue);

      await tester.tap(find.byTooltip('Dismiss'));
      expect(dismissed, isTrue);
    });

    testWidgets('MemoraDialog renders title, message and triggers actions', (
      WidgetTester tester,
    ) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showMemoraDialog<void>(
                      context: context,
                      title: 'Discard draft?',
                      message: 'Unsaved edits will be lost.',
                      primaryActionLabel: 'Discard',
                      secondaryActionLabel: 'Cancel',
                      isDestructive: true,
                      onPrimaryAction: () {
                        confirmed = true;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Discard draft?'), findsOneWidget);
      expect(find.text('Unsaved edits will be lost.'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('Discard draft?'), findsNothing);
    });

    testWidgets('MemoraBottomSheet renders title, close button and content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showMemoraBottomSheet<void>(
                      context: context,
                      title: 'Reef Details',
                      subtitle: 'Physics Reef',
                      child: const Text('Sheet Content Area'),
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Reef Details'), findsOneWidget);
      expect(find.text('Physics Reef'), findsOneWidget);
      expect(find.text('Sheet Content Area'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Reef Details'), findsNothing);
    });

    testWidgets('showMemoraToast shows floating toast message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showMemoraToast(context, 'Draft saved successfully');
                  },
                  child: const Text('Show Toast'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();

      expect(find.text('Draft saved successfully'), findsOneWidget);
    });
  });
}
