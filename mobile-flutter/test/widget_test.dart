// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:driver_license_registration_and_verification_system/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DriverLicenseApp());

    // Verify that the login screen is displayed.
    expect(find.text('Driver License System'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Verify that we are on the login screen and not the home screen.
    expect(find.text('Driver Registrations'), findsNothing);
  });
}
