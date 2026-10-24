import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

void main() {
  group('MemoraTextField', () {
    testWidgets('renders persistent label, hint, and min 48px height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(
            body: MemoraTextField(label: 'Username', hintText: 'Enter your username'),
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Enter your username'), findsOneWidget);

      final Finder fieldFinder = find.byType(TextFormField);
      expect(fieldFinder, findsOneWidget);

      final Size fieldSize = tester.getSize(fieldFinder);
      expect(fieldSize.height, greaterThanOrEqualTo(MemoraSpacing.minTouchTarget));
    });

    testWidgets('displays error message and icon in error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(
            body: MemoraTextField(label: 'Email', errorText: 'Please enter a valid email address'),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays success message and icon in verified state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(
            body: MemoraTextField(label: 'Concept Title', successText: 'Concept verified'),
          ),
        ),
      );

      expect(find.text('Concept Title'), findsOneWidget);
      expect(find.text('Concept verified'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('disabled field prevents text editing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MemoraTheme.light(),
          home: const Scaffold(
            body: MemoraTextField(label: 'Locked Field', initialValue: 'Original value', enabled: false),
          ),
        ),
      );

      final Finder fieldFinder = find.byType(TextFormField);
      final TextFormField formField = tester.widget<TextFormField>(fieldFinder);
      expect(formField.enabled, isFalse);
    });
  });
}
