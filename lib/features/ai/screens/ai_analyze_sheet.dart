import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ai_deep_analyze_screen.dart';
import 'ai_quick_analyze_screen.dart';

import 'package:flutter/material.dart';

class AiAnalyzeSheet extends StatelessWidget {
  final int year;
  final int month;
  final String currency;

  const AiAnalyzeSheet({
    super.key,
    required this.year,
    required this.month,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Выберите тип AI-анализа", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 18),
            ListTile(
              leading: Icon(Icons.flash_on_rounded, color: Colors.green, size: 30),
              title: Text("Быстрый анализ"),
              subtitle: Text("Мгновенный совет и сводка расходов"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/ai-quick-analyze',
                  arguments: {"year": year, "month": month, "currency": currency},
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.auto_awesome_rounded, color: Colors.deepPurple, size: 30),
              title: Text("Глубокий AI-анализ"),
              subtitle: Text("Подробный разбор, челленджи, советы"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/ai-deep-analyze',
                  arguments: {"year": year, "month": month, "currency": currency},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
