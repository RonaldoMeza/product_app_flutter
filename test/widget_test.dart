import 'package:flutter_test/flutter_test.dart';
import 'package:product_app/main.dart';

void main() {
  testWidgets('ProductApp renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProductApp());
    expect(find.text('ProductApp'), findsOneWidget);
  });
}
