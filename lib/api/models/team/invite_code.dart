/// Claim codes are stored and shared as 8 raw characters and shown with a
/// dash after the fourth: `K7M2-QX9P`. Join accepts either form; the
/// database strips the dash.
abstract final class InviteCode {
  InviteCode._();

  /// `K7M2QX9P` → `K7M2-QX9P`. Anything shorter is returned as it is.
  static String format(String code) {
    final raw = rawOf(code);
    if (raw.length <= 4) return raw;
    return '${raw.substring(0, 4)}-${raw.substring(4)}';
  }

  /// `K7M2-QX9P` → `K7M2QX9P`: upper case, letters and numbers only, at
  /// most 8 characters.
  static String rawOf(String code) {
    final clean = code.toUpperCase().split('').where((character) {
      final unit = character.codeUnitAt(0);
      return (unit >= 48 && unit <= 57) || (unit >= 65 && unit <= 90);
    }).join();
    return clean.length > 8 ? clean.substring(0, 8) : clean;
  }
}
