/// Nigerian phone numbers as the staff forms store and show them.
///
/// Storage is the full international number (`+2348035550142`). The form's
/// +234 field holds the ten digits after the prefix; the details card shows
/// the national format (`0803 555 0142`).
abstract final class PhoneFormat {
  PhoneFormat._();

  static String _digits(String input) => input.replaceAll(RegExp('[^0-9]'), '');

  /// The ten digits after `+234`, accepting a typed leading `0` or `234`.
  static String digitsAfterPrefix(String input) {
    var digits = _digits(input);
    if (digits.startsWith('234')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  /// What the database stores, or null when the field is empty.
  static String? stored(String input) {
    final digits = digitsAfterPrefix(input);
    return digits.isEmpty ? null : '+234$digits';
  }

  /// Why the +234 field can't be saved, or null when it can.
  static String? problem(String input) {
    final digits = digitsAfterPrefix(input);
    if (digits.isEmpty) return null;
    if (digits.length != 10) return 'Enter a 10-digit number after +234';
    return null;
  }

  /// `0803 555 0142` for a Nigerian mobile number. Anything else comes back
  /// as written, trimmed.
  static String nationalDisplay(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return text;

    var digits = _digits(text);
    if (digits.startsWith('234')) digits = digits.substring(3);

    final String local;
    if (digits.length == 11 && digits.startsWith('0')) {
      local = digits;
    } else if (digits.length == 10) {
      local = '0$digits';
    } else {
      return text;
    }

    if (!RegExp(r'^0[789]').hasMatch(local)) return text;
    return '${local.substring(0, 4)} ${local.substring(4, 7)} '
        '${local.substring(7)}';
  }
}
