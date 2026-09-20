import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_cost/main.dart';
import 'package:daily_cost/core/constants/app_constants.dart';
import 'package:daily_cost/data/repositories/providers.dart';

void main() {
  testWidgets('DailyCost App builds smoke test and renders AuthScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const DailyCostApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app starts up and displays AuthScreen with DailyCost title, tagline, and auth CTAs
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appTagline), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
