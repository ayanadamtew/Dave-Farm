import 'package:flutter_test/flutter_test.dart';
import 'package:dave_farm/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DaveFarmApp());
    await tester.pump();
    // The app should render without crashing
    expect(find.byType(DaveFarmApp), findsOneWidget);
  });
}
