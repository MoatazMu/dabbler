import 'form_validators.dart';

class PasswordValidator extends FormValidator<String> {
  @override
  String? validate(String value) {
    if (value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must contain an uppercase letter.';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must contain a lowercase letter.';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain a number.';
    if (!RegExp(r'[!@#\$&*~_\-]').hasMatch(value)) return 'Password must contain a special character.';
    return null;
  }
}
