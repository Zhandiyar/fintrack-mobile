import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../blocs/ai_analyze_bloc.dart';
import '../blocs/ai_analyze_event.dart';
import '../blocs/ai_analyze_state.dart';
import '../model/finance_analyze_request.dart';
import 'ai_analyze_loading_view.dart';

class AiDeepAnalyzeScreen extends StatelessWidget {
  final int year;
  final int month;
  final String currency;

  const AiDeepAnalyzeScreen({
    super.key,
    required this.year,
    required this.month,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Глубокий AI-анализ')),
      body: BlocBuilder<AiAnalyzeBloc, AiAnalyzeState>(
        builder: (context, state) {
          if (state is AiAnalyzeInitial) {
            context.read<AiAnalyzeBloc>().add(
              AiDeepAnalyzeRequested(
                FinanceAnalyzeRequest(
                  year: year,
                  month: month,
                  currency: currency,
                ),
              ),
            );
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AiAnalyzeLoading) {
            return AiAnalyzeLoadingView();
          }
          if (state is AiAnalyzeLoaded) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: MarkdownBody(
                      data: state.response.analysis,
                      styleSheet: MarkdownStyleSheet(
                        h3: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                        p: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.35),
                        strong: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                        listBullet: TextStyle(
                            fontSize: 16, color: Colors.deepPurple),
                        blockSpacing: 20,
                        code: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey.shade800),
                        // Можно добавить кастомизацию для других элементов
                      ),
                      selectable: true,
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
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
