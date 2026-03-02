import 'package:flutter_test/flutter_test.dart';
import 'package:dave_farm/main.dart';
import 'package:dave_farm/features/settings/settings_controller.dart';
import 'package:dave_farm/features/settings/settings_service.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final settingsService = SettingsService();
    final settingsController = SettingsController(settingsService);
    await settingsController.loadSettings();

    await tester.pumpWidget(DaveFarmApp(settingsController: settingsController));
    await tester.pump();
    // The app should render without crashing
    expect(find.byType(DaveFarmApp), findsOneWidget);
  });
}
