import '../validators/form_validators.dart';

mixin ValidationMixin {
  String? validateField<T>(T value, FormValidator<T> validator) {
    return validator.validate(value);
  }

  String? validateFields<T>(T value, List<FormValidator<T>> validators) {
    return FormValidator.compose(validators).validate(value);
  }
}
