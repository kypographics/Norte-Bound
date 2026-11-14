abstract final class AuthValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Enter your email address.';
    }

    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password.';
    }

    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Create a password.';
    }

    if (value.length < 8) {
      return 'Use at least 8 characters.';
    }

    if (value.length > 72) {
      return 'Use at most 72 characters.';
    }

    return null;
  }

  static String? fullName(String? value) {
    return _validateFullName(value, maxLength: 150);
  }

  static String? profileFullName(String? value) {
    return _validateFullName(value, maxLength: 100);
  }

  static String? inviteCode(String? value) {
    final inviteCode = value?.trim() ?? '';

    if (inviteCode.isEmpty) {
      return 'Enter the curator invite code.';
    }

    if (inviteCode.length > 100) {
      return 'Use at most 100 characters.';
    }

    return null;
  }

  static String? _validateFullName(String? value, {required int maxLength}) {
    final fullName = value?.trim() ?? '';

    if (fullName.isEmpty) {
      return 'Enter your full name.';
    }

    if (fullName.length < 2) {
      return 'Use at least 2 characters.';
    }

    if (fullName.length > maxLength) {
      return 'Use at most $maxLength characters.';
    }

    return null;
  }
}
