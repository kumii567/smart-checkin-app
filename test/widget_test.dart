import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:smart_class_checkin/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders auth actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Don’t have an account? Sign up'), findsOneWidget);
  });
}
