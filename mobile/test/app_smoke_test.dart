import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/app.dart';

void main() {
  testWidgets('renders the T01 application shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MemoraApp());

    expect(find.text('Memora'), findsOneWidget);
    expect(find.text('Development baseline ready'), findsOneWidget);
  });
}
