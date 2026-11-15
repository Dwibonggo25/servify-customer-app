import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/detail_app_bar.dart';
import '../cubit/ai_assistant_cubit.dart';
import '../cubit/ai_assistant_state.dart';

final class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

final class _AiAssistantPageState extends State<AiAssistantPage> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AiAssistantCubit>().ask(_promptController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiAssistantCubit, AiAssistantState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AiAssistantStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                state.message ?? context.tr(LanguageKeys.aiRequestFailed),
              ),
            ),
          );
      },
      builder: (context, state) => Scaffold(
        appBar: DetailAppBar(
          title: context.tr(LanguageKeys.aiAssistant),
          subtitle: context.tr(LanguageKeys.aiAssistantSubtitle),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  children: [
                    _AssistantIntro(
                      title: context.tr(LanguageKeys.aiWelcomeTitle),
                      description: context.tr(
                        LanguageKeys.aiWelcomeDescription,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (state.isLoading)
                      const _ThinkingCard()
                    else if (state.status == AiAssistantStatus.success &&
                        state.response != null)
                      _ResponseCard(response: state.response!)
                    else if (state.status == AiAssistantStatus.failure)
                      _FailureCard(
                        message:
                            state.message ??
                            context.tr(LanguageKeys.aiRequestFailed),
                        onRetry: _submit,
                      )
                    else
                      _PromptExample(
                        onSelected: (value) {
                          _promptController.text = value;
                          _promptController.selection = TextSelection.collapsed(
                            offset: value.length,
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr(LanguageKeys.aiDisclaimer),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _PromptComposer(
                controller: _promptController,
                isLoading: state.isLoading,
                onSubmitted: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _AssistantIntro extends StatelessWidget {
  const _AssistantIntro({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(color: Color(0xFFE7E5FF), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _ThinkingCard extends StatelessWidget {
  const _ThinkingCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 14),
          Text(context.tr(LanguageKeys.aiThinking)),
        ],
      ),
    ),
  );
}

final class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const Key('ai_retry_button'),
          tooltip: context.tr(LanguageKeys.aiRetry),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ],
    ),
  );
}

final class _ResponseCard extends StatelessWidget {
  const _ResponseCard({required this.response});

  final String response;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              context.tr(LanguageKeys.aiResponseLabel),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SelectableText(response, style: const TextStyle(height: 1.55)),
      ],
    ),
  );
}

final class _PromptExample extends StatelessWidget {
  const _PromptExample({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final prompt = context.tr(LanguageKeys.aiPromptExample);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onSelected(prompt),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(prompt)),
            const Icon(Icons.north_west_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

final class _PromptComposer extends StatelessWidget {
  const _PromptComposer({
    required this.controller,
    required this.isLoading,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('ai_prompt_field'),
                controller: controller,
                enabled: !isLoading,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: context.tr(LanguageKeys.aiPromptHint),
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              key: const Key('ai_send_button'),
              tooltip: context.tr(LanguageKeys.aiSend),
              onPressed: isLoading ? null : onSubmitted,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    ),
  );
}
