import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_keys.dart';
import 'app_text_field.dart';

final class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    required this.controller,
    required this.validator,
    this.textInputAction,
    super.key,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputAction? textInputAction;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

final class _AppPasswordFieldState extends State<AppPasswordField> {
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);

  @override
  void dispose() {
    _obscurePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _obscurePassword,
      builder: (context, isObscured, _) => AppTextField(
        controller: widget.controller,
        label: context.tr(LanguageKeys.password),
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: isObscured,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        autofillHints: const [AutofillHints.password],
        suffixIcon: IconButton(
          tooltip: context.tr(
            isObscured ? LanguageKeys.showPassword : LanguageKeys.hidePassword,
          ),
          onPressed: () => _obscurePassword.value = !isObscured,
          icon: Icon(
            isObscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}
