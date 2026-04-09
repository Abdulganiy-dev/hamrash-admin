

class ValidationUtil {
  static String? validateFullName(String value) {
    if (value.isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  static String? validateFirstName(String firstName) {
    if (firstName.isEmpty) {
      return "First name is required";
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(firstName)) {
      return "First name can only contain letters, spaces, hyphens, and apostrophes";
    }
    if (firstName.trim().length < 2) {
      return "First name must be at least 2 characters";
    }
    return null;
  }

  static String? validateLastName(String lastName) {
    if (lastName.isEmpty) {
      return "Last name is required";
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(lastName)) {
      return "Last name can only contain letters, spaces, hyphens, and apostrophes";
    }
    if (lastName.trim().length < 2) {
      return "Last name must be at least 2 characters";
    }
    return null;
  }

  static String? validateGender(String lastName) {
    if (lastName.isEmpty) {
      return "Gender is required";
    }
    return null;
  }

  static String? validatePhoneNumber(String phoneNumber) {
    final trimmed = phoneNumber.trim();

    if (trimmed.isEmpty) {
      return "Phone number is required";
    }

    // Nigerian phone number formats (your pattern):
    // ((^+)(234){1}[0-9]{10})|((^234)[0-9]{10})|((^0)(7|8|9){1}(0|1){1}[0-9]{8})
    //
    // Cleaned-up and adapted for Dart:
    // - +234XXXXXXXXXX
    // - 234XXXXXXXXXX
    // - 0(7|8|9)(0|1)XXXXXXXX
    final naijaPhoneRegex =
        RegExp(r'^(\+234[0-9]{10}|234[0-9]{10}|0(7|8|9)(0|1)[0-9]{8})$');

    if (!naijaPhoneRegex.hasMatch(trimmed)) {
      return "Enter a valid Nigerian phone number";
    }

    return null;
  }

  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return "Email address is required";
    }
    if (!RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email)) {
      return "email address is not valid";
    }

    return null;
  }

  static String? validateValue(String value, String displayText) {
    if (value.isEmpty) {
      return "$displayText is required";
    }
    return null;
  }
}
