import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_cost/features/onboarding/onboarding_wizard_screen.dart';

void main() {
  testWidgets('Fixed Monthly Costs allows 0 amount and remains selected on backspace',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: OnboardingWizardScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: Currency -> tap Next (Continue)
    final nextButtons = find.widgetWithText(ElevatedButton, 'Continue');
    expect(nextButtons, findsOneWidget);
    await tester.tap(nextButtons);
    await tester.pumpAndSettle();

    // Step 2: Enter income -> tap Next
    final incomeField = find.byType(TextField).first;
    await tester.enterText(incomeField, '5000');
    await tester.pumpAndSettle();

    final nextToFixedBtn = find.widgetWithText(ElevatedButton, 'Next: Fixed Costs');
    expect(nextToFixedBtn, findsOneWidget);
    await tester.tap(nextToFixedBtn);
    await tester.pumpAndSettle();

    // Step 3: Fixed Monthly Costs
    expect(find.text('Fixed Monthly Costs'), findsOneWidget);

    // Tap on "Utilities & Internet" checkbox or row
    final utilitiesText = find.text('Utilities & Internet');
    expect(utilitiesText, findsOneWidget);
    await tester.tap(utilitiesText);
    await tester.pumpAndSettle();

    // Default amount should be 100 and Total Fixed Costs should show 100.00
    expect(find.text('100'), findsOneWidget);
    expect(find.textContaining('100.00'), findsOneWidget);

    // Now find the amount TextFormField and clear it (simulating backspacing 100)
    final amountFormField = find.widgetWithText(TextFormField, '100');
    expect(amountFormField, findsOneWidget);
    await tester.enterText(amountFormField, '');
    await tester.pumpAndSettle();

    // Total Fixed Costs should now reflect 0.00, but option must REMAIN selected!
    expect(find.textContaining('0.00'), findsWidgets);
    // Checkbox is still checked (Utilities & Internet is index 1)
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).at(1));
    expect(checkbox.value, isTrue);

    // TextFormField is still present
    expect(find.byType(TextFormField), findsOneWidget);

    // Enter a new amount, e.g., '250'
    await tester.enterText(find.byType(TextFormField).first, '250');
    await tester.pumpAndSettle();
    expect(find.textContaining('250.00'), findsOneWidget);

    // Uncheck it
    await tester.tap(utilitiesText);
    await tester.pumpAndSettle();
    expect(find.textContaining('0.00'), findsWidgets);
    final checkboxUnchecked = tester.widget<Checkbox>(find.byType(Checkbox).at(1));
    expect(checkboxUnchecked.value, isFalse);

    // Re-check it
    await tester.tap(utilitiesText);
    await tester.pumpAndSettle();
    final checkboxRechecked = tester.widget<Checkbox>(find.byType(Checkbox).at(1));
    expect(checkboxRechecked.value, isTrue);
  });
}
