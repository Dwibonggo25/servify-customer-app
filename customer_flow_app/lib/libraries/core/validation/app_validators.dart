import '../localization/language_controller.dart';
import '../localization/language_keys.dart';

final class AppValidators {
  const AppValidators._();

  static String? requiredField(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return LanguageController.instance.translate(LanguageKeys.fieldRequired, {
        'field': label,
      });
    }
    return null;
  }

  static String? email(String? value) {
    final requiredMessage = requiredField(
      value,
      label: LanguageController.instance.translate(LanguageKeys.email),
    );
    if (requiredMessage != null) return requiredMessage;

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(value!.trim())) {
      return LanguageController.instance.translate(LanguageKeys.invalidEmail);
    }
    return null;
  }

  static String? password(String? value) {
    final requiredMessage = requiredField(
      value,
      label: LanguageController.instance.translate(LanguageKeys.password),
    );
    if (requiredMessage != null) return requiredMessage;
    if (value!.length < 8) {
      return LanguageController.instance.translate(
        LanguageKeys.minimumPassword,
      );
    }
    return null;
  }
}
