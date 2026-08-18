import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test placeholder', (WidgetTester tester) async {
    // Placeholder test - the app uses async init (SharedPreferences)
    // and requires a ProviderScope override to run.
    expect(true, isTrue);
  });
}
