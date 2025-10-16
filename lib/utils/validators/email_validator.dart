import 'form_validators.dart';

class EmailValidator extends FormValidator<String> {
  static final _emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}");
  static final _disposableDomains = {
    'mailinator.com', '10minutemail.com', 'guerrillamail.com', 'tempmail.com',
    'yopmail.com', 'trashmail.com', 'fakeinbox.com', 'getnada.com',
  };

  @override
  String? validate(String value) {
    if (value.isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(value)) return 'Invalid email format.';
    final domain = value.split('@').last;
    if (_disposableDomains.contains(domain)) return 'Disposable email addresses are not allowed.';
    return null;
  }
}
