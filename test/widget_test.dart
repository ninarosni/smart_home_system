import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home/main.dart';

void main() {
  testWidgets('App should load without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This will show the FirebaseInitializer which might be in loading state
    await tester.pumpWidget(const SmartHomeApp());

    // Verify that we see some initial loading text or the logo
    expect(find.text('Connecting to services...'), findsOneWidget);
  });
}
