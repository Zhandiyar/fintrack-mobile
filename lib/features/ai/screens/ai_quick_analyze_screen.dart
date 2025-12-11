import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/ai_analyze_bloc.dart';
import '../blocs/ai_analyze_event.dart';
import '../blocs/ai_analyze_state.dart';
import '../model/finance_analyze_request.dart';

class AiQuickAnalyzeScreen extends StatelessWidget {
  final int year;
  final int month;
  final String currency;

  const AiQuickAnalyzeScreen({
    super.key,
    required this.year,
    required this.month,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Цвет карточки:
    //  • в светлой теме — secondaryContainer (приятный пастельный)
    //  • в тёмной — мягко приглушаем через surfaceVariant + прозрачность
    final Color cardColor =
    isDark ? cs.surfaceVariant.withOpacity(0.20) : cs.secondaryContainer;

    // Текст всегда читаемый: если используем secondaryContainer —
    // берём систему onSecondaryContainer, иначе вычислим контраст.
    final Color onCard = isDark
        ? _onColorFor(cardColor)
        : cs.onSecondaryContainer;

    return Scaffold(
      appBar: AppBar(title: const Text('Быстрый AI-анализ')),
      body: BlocBuilder<AiAnalyzeBloc, AiAnalyzeState>(
        builder: (context, state) {
          if (state is AiAnalyzeInitial) {
            // Запускаем загрузку только при первом входе
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AiAnalyzeBloc>().add(
                AiQuickAnalyzeRequested(
                  FinanceAnalyzeRequest(
                    year: year,
                    month: month,
                    currency: currency,
                  ),
                ),
              );
            });
            return const _CenteredLoader();
          }

          if (state is AiAnalyzeLoading) {
            return const _CenteredLoader();
          }

          if (state is AiAnalyzeLoaded) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? cs.outlineVariant.withOpacity(.25)
                          : cs.outlineVariant.withOpacity(.35),
                    ),
                    boxShadow: isDark
                        ? [
                      // лёгкая подсветка в тёмной теме
                      BoxShadow(
                        color: Colors.black.withOpacity(.35),
                        blurRadius: 18,
                        spreadRadius: -4,
                        offset: const Offset(0, 10),
                      ),
                    ]
                        : [
                      BoxShadow(
                        color: cs.primary.withOpacity(.10),
                        blurRadius: 22,
                        spreadRadius: -2,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      // слегка смягчим фон, особенно приятно в тёмной теме
                      filter: ImageFilter.blur(sigmaX: isDark ? 0.0 : 0.5, sigmaY: isDark ? 0.0 : 0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: SelectableText(
                          state.response.analysis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: onCard,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          if (state is AiAnalyzeError) {
            return Center(
              child: Text(
                state.message,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // вычисление читабельного цвета текста на произвольном фоне
  static Color _onColorFor(Color bg) =>
      ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
          ? Colors.white
          : Colors.black87;
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
