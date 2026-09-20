import 'package:flutter_test/flutter_test.dart';
import 'package:daily_cost/core/utils/math_expression_evaluator.dart';

void main() {
  group('MathExpressionEvaluator Tests', () {
    test('Evaluates simple numbers', () {
      expect(MathExpressionEvaluator.tryEvaluate('500'), 500.0);
      expect(MathExpressionEvaluator.tryEvaluate('125.75'), 125.75);
    });

    test('Evaluates addition expressions like 125+125+250', () {
      expect(MathExpressionEvaluator.tryEvaluate('125+125+250'), 500.0);
      expect(MathExpressionEvaluator.evaluateAndFormat('125+125+250'), '500');
    });

    test('Evaluates subtraction expressions', () {
      expect(MathExpressionEvaluator.tryEvaluate('500-100-50'), 350.0);
      expect(MathExpressionEvaluator.evaluateAndFormat('500-100-50'), '350');
    });

    test('Evaluates multiplication with *, x, X, and ×', () {
      expect(MathExpressionEvaluator.tryEvaluate('25*4'), 100.0);
      expect(MathExpressionEvaluator.tryEvaluate('25x4'), 100.0);
      expect(MathExpressionEvaluator.tryEvaluate('25X4'), 100.0);
      expect(MathExpressionEvaluator.tryEvaluate('25×4'), 100.0);
    });

    test('Evaluates division with / and ÷', () {
      expect(MathExpressionEvaluator.tryEvaluate('100/4'), 25.0);
      expect(MathExpressionEvaluator.tryEvaluate('100÷4'), 25.0);
      expect(MathExpressionEvaluator.evaluateAndFormat('100/4'), '25');
    });

    test('Respects operator precedence (* and / before + and -)', () {
      expect(MathExpressionEvaluator.tryEvaluate('10+20*3'), 70.0);
      expect(MathExpressionEvaluator.tryEvaluate('100-50/2'), 75.0);
    });

    test('Handles parentheses', () {
      expect(MathExpressionEvaluator.tryEvaluate('(10+20)*3'), 90.0);
      expect(MathExpressionEvaluator.tryEvaluate('(500-100)/2'), 200.0);
    });

    test('Handles decimals and formatting correctly', () {
      expect(MathExpressionEvaluator.tryEvaluate('250.50+49.50'), 300.0);
      expect(MathExpressionEvaluator.evaluateAndFormat('250.50+49.50'), '300');
      expect(MathExpressionEvaluator.evaluateAndFormat('10.25+20.50'), '30.75');
    });

    test('Handles trailing incomplete operators gracefully', () {
      expect(MathExpressionEvaluator.tryEvaluate('125+'), 125.0);
      expect(MathExpressionEvaluator.evaluateAndFormat('125+'), '125');
    });

    test('Returns null / fallback for empty or invalid input', () {
      expect(MathExpressionEvaluator.tryEvaluate(''), isNull);
      expect(MathExpressionEvaluator.tryEvaluate('abc'), isNull);
      expect(MathExpressionEvaluator.tryEvaluate('10/0'), isNull);
    });
  });
}
