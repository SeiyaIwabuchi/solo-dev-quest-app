/// Validation utility functions for user input
library;

/// Validates if the given email address is in a valid format
///
/// Returns `true` if the email matches standard email format pattern,
/// `false` otherwise.
///
/// Example:
/// ```dart
/// isValidEmail('user@example.com'); // true
/// isValidEmail('invalid.email'); // false
/// ```
bool isValidEmail(String email) {
  if (email.isEmpty) {
    return false;
  }

  // Standard email regex pattern
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  return emailRegex.hasMatch(email);
}

/// Validates if the given password meets minimum security requirements
///
/// Password must be at least 8 characters long.
///
/// Returns `true` if the password meets requirements, `false` otherwise.
///
/// Example:
/// ```dart
/// isValidPassword('password123'); // true
/// isValidPassword('pass'); // false
/// ```
bool isValidPassword(String password) {
  if (password.isEmpty) {
    return false;
  }

  // Minimum length requirement: 8 characters
  return password.length >= 8;
}

/// Returns a user-friendly error message for invalid email
String getEmailValidationError() {
  return '有効なメールアドレスを入力してください';
}

/// Returns a user-friendly error message for invalid password
String getPasswordValidationError() {
  return 'パスワードは8文字以上で入力してください';
}
