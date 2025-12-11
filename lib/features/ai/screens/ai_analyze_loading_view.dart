// ai_loading_view.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AiAnalyzeLoadingView extends StatelessWidget {
  final String label;
  const AiAnalyzeLoadingView({this.label = "AI анализирует ваши финансы..."});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI-аватарка с анимацией
            SizedBox(
              height: 60, width: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 5,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                  Icon(Icons.smart_toy_rounded, color: Colors.deepPurple, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            // Шиммер-скелетон для текста
            Shimmer.fromColors(
              baseColor: colorScheme.primaryContainer.withOpacity(0.17),
              highlightColor: colorScheme.primary.withOpacity(0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(3, (i) => Container(
                  height: 18,
                  margin: EdgeInsets.symmetric(vertical: 7),
                  width: 200 + 40.0 * (2 - i),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 22),
            Text("Обычно это занимает 10–30 секунд", style: TextStyle(fontSize: 13, color: colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
