import 'package:flutter_test/flutter_test.dart';
import 'package:drp/main.dart';

void main() {
  testWidgets('MainApp renders Hello World text correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    expect(find.text('Hello World!!!'), findsOneWidget);
    expect(find.text('Goodbye World'), findsNothing);
  });
}
