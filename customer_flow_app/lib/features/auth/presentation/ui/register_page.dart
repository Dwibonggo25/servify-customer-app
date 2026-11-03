import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/validation/app_validators.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/widgets/app_auth_scaffold.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../../libraries/design_system/widgets/app_password_field.dart';
import '../../../../libraries/design_system/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

final class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

final class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      RegisterSubmitted(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthSubmissionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message ?? context.tr(LanguageKeys.accountCreated),
              ),
            ),
          );
          context.go(state.requiresEmailConfirmation ? '/login' : '/home');
        } else if (state.status == AuthSubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message ?? context.tr(LanguageKeys.registerFailed),
              ),
            ),
          );
        }
      },
      child: AppAuthScaffold(
        title: context.tr(LanguageKeys.createCustomerAccount),
        subtitle: context.tr(LanguageKeys.registerSubtitle),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: context.tr(LanguageKeys.fullName),
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (value) => AppValidators.requiredField(
                    value,
                    label: context.tr(LanguageKeys.fullName),
                  ),
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  label: context.tr(LanguageKeys.email),
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: AppValidators.email,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                AppPasswordField(
                  controller: _passwordController,
                  validator: AppValidators.password,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => AppButton(
                    label: context.tr(LanguageKeys.createAccount),
                    isLoading: state.isLoading,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.tr(LanguageKeys.alreadyHaveAccount)),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(context.tr(LanguageKeys.login)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
