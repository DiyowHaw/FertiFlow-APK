import 'package:flutter_test/flutter_test.dart';
import 'package:fertiflow/main.dart';

void main() {
  testWidgets('App landing screen builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FertiFlowApp());
    await tester.pumpAndSettle();

    // Verify that the app starts successfully without breaking.
    expect(find.byType(FertiFlowApp), findsOneWidget);
  });
}

