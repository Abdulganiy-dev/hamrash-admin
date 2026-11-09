/// Reading and showing the numbers on the grading screens: marks and
/// percentages have up to 2 decimals, and show without trailing zeros.
class GradingNumbers {
  GradingNumbers._();

  /// 20 → "20", 12.5 → "12.5", 69.99 → "69.99".
  static String format(double value) {
    final rounded = round(value);
    if (rounded == rounded.roundToDouble()) return rounded.round().toString();
    final text = rounded.toStringAsFixed(2);
    return text.endsWith('0') ? text.substring(0, text.length - 1) : text;
  }

  /// To 2 decimals, so sums like 0.1 + 0.2 don't show as 0.30000000000000004.
  static double round(double value) => (value * 100).round() / 100;

  /// Plain number from a text field, or null when it isn't one. Accepts a
  /// comma as the decimal mark.
  static double? parse(String text) {
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    if (!RegExp(r'^\d*\.?\d+$|^\d+\.$').hasMatch(cleaned)) return null;
    return double.tryParse(cleaned);
  }

  /// More than 2 digits after the decimal mark.
  static bool hasTooManyDecimals(String text) {
    final cleaned = text.trim().replaceAll(',', '.');
    final dot = cleaned.indexOf('.');
    return dot >= 0 && cleaned.length - dot - 1 > 2;
  }
}
