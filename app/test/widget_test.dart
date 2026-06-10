import 'package:flutter_test/flutter_test.dart';
import 'package:quickslot/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickSlotApp());
    expect(find.byType(QuickSlotApp), findsOneWidget);
  });
}
