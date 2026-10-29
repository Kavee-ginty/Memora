import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/app.dart';

void main() {
  testWidgets('renders the application shell with Memora splash brand', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MemoraApp());

    expect(find.text('Memora'), findsOneWidget);
  });
}
