/// Utility to parse and evaluate mathematical expressions (e.g., '125+125+250', '500-120*2', '100/4')
/// entered by users in financial amount input fields.
class MathExpressionEvaluator {
  /// Evaluates a math expression string and returns the resulting [double].
  /// Returns `null` if the expression is empty or cannot be parsed.
  static double? tryEvaluate(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) return null;

    // Normalize multiplication and division symbols
    final sanitized = cleaned
        .replaceAll('×', '*')
        .replaceAll('x', '*')
        .replaceAll('X', '*')
        .replaceAll('÷', '/')
        .replaceAll(',', '') // Remove thousands commas if pasted
        .replaceAll(' ', '');

    // If it's a simple number already, parse directly
    final directVal = double.tryParse(sanitized);
    if (directVal != null) {
      return directVal.isFinite ? directVal : null;
    }

    try {
      final parser = _Parser(sanitized);
      final result = parser.parse();
      if (result != null && result.isFinite && !result.isNaN) {
        return result;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Formats the evaluated result to a clean string.
  /// E.g., `500.0` -> `'500'`, `125.75` -> `'125.75'`.
  static String formatResult(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    // Limit to up to 2 decimal places without trailing zeros
    final fixed = value.toStringAsFixed(2);
    if (fixed.endsWith('.00')) {
      return fixed.substring(0, fixed.length - 3);
    }
    if (fixed.endsWith('0')) {
      return fixed.substring(0, fixed.length - 1);
    }
    return fixed;
  }

  /// Evaluates the input string and returns the formatted string if valid,
  /// or the trimmed original input if evaluation is not applicable.
  static String evaluateAndFormat(String input) {
    final result = tryEvaluate(input);
    if (result != null) {
      return formatResult(result);
    }
    return input.trim();
  }

  /// Checks if the input string contains any math operators (+, -, *, /, etc.)
  static bool hasOperator(String input) {
    return input.contains('+') ||
        input.contains('-') ||
        input.contains('*') ||
        input.contains('x') ||
        input.contains('X') ||
        input.contains('×') ||
        input.contains('/') ||
        input.contains('÷');
  }
}

/// Recursive descent parser for arithmetic expressions with standard precedence:
/// 1. Primary: numbers, unary +/-
/// 2. Factors: *, /
/// 3. Terms: +, -
class _Parser {
  final String src;
  int _pos = 0;

  _Parser(this.src);

  double? parse() {
    if (src.isEmpty) return null;
    final res = _parseExpression();
    if (_pos < src.length) {
      // Unconsumed trailing characters (like trailing operator e.g. "125+")
      final remaining = src.substring(_pos).trim();
      if (remaining == '+' ||
          remaining == '-' ||
          remaining == '*' ||
          remaining == '/') {
        return res;
      }
      return null;
    }
    return res;
  }

  double? _parseExpression() {
    final first = _parseTerm();
    if (first == null) return null;
    double left = first;

    while (_pos < src.length) {
      final ch = src[_pos];
      if (ch == '+') {
        _pos++;
        final right = _parseTerm();
        if (right == null) return left; // Gracefully handle trailing operator
        left = left + right;
      } else if (ch == '-') {
        _pos++;
        final right = _parseTerm();
        if (right == null) return left;
        left = left - right;
      } else {
        break;
      }
    }
    return left;
  }

  double? _parseTerm() {
    final first = _parseFactor();
    if (first == null) return null;
    double left = first;

    while (_pos < src.length) {
      final ch = src[_pos];
      if (ch == '*') {
        _pos++;
        final right = _parseFactor();
        if (right == null) return left;
        left = left * right;
      } else if (ch == '/') {
        _pos++;
        final right = _parseFactor();
        if (right == null || right == 0) return null; // Avoid division by zero
        left = left / right;
      } else {
        break;
      }
    }
    return left;
  }

  double? _parseFactor() {
    if (_pos >= src.length) return null;

    // Handle Unary + / -
    if (src[_pos] == '+') {
      _pos++;
      return _parseFactor();
    }
    if (src[_pos] == '-') {
      _pos++;
      final f = _parseFactor();
      return f != null ? -f : null;
    }

    // Handle Parentheses
    if (src[_pos] == '(') {
      _pos++;
      final inside = _parseExpression();
      if (_pos < src.length && src[_pos] == ')') {
        _pos++;
      }
      return inside;
    }

    // Parse Number
    final start = _pos;
    bool hasDot = false;
    while (_pos < src.length) {
      final c = src[_pos];
      if (c == '.') {
        if (hasDot) break;
        hasDot = true;
        _pos++;
      } else if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
        _pos++;
      } else {
        break;
      }
    }

    if (start == _pos) return null;
    final numStr = src.substring(start, _pos);
    return double.tryParse(numStr);
  }
}
