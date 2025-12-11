import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'ai_analyze_sheet.dart';

/// Насыщённый ярко-жёлтый (без ухода в оранжевый)
const kBrightYellow = Color(0xFFFFD400);

class AiAnalyzeCard extends StatefulWidget {
  final int year;
  final int month;
  final String currency;

  /// Вкл/выкл анимацию (уважает системное Disable Animations)
  final bool animate;

  /// Цвет бейджа "NEW". По умолчанию — ярко-жёлтый [kBrightYellow].
  final Color? badgeColor;

  const AiAnalyzeCard({
    super.key,
    required this.year,
    required this.month,
    required this.currency,
    this.animate = true,
    this.badgeColor,
  });

  @override
  State<AiAnalyzeCard> createState() => _AiAnalyzeCardState();
}

class _AiAnalyzeCardState extends State<AiAnalyzeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // уважать системное "Отключить анимации"
    final sysDisabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate = widget.animate && !sysDisabled;

    // Чуть быстрее и заметнее, если анимация включена
    if (shouldAnimate) {
      if (_c.duration != const Duration(seconds: 6)) {
        _c.duration = const Duration(seconds: 6);
      }
      if (!_c.isAnimating) _c.repeat();
    } else {
      if (_c.isAnimating) _c.stop();
    }

    // Базовые оттенки под тему
    final base1 = cs.primaryContainer.withOpacity(0.92);
    final base2 = cs.secondaryContainer.withOpacity(0.88);
    final base3 = cs.primary.withOpacity(0.75);
    final onCard = _onColorFor(Color.alphaBlend(base1, base2));

    // Цвет иконки: светлая тема — primary (виден на белом), тёмная — белый
    final iconColor = theme.brightness == Brightness.light ? cs.primary : Colors.white;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // амплитуда побольше для заметности
          final t = shouldAnimate ? Curves.easeInOut.transform((_c.value * 2) % 1) : 0.5;
          const ampX = 0.45;
          const ampY = 0.30;
          final begin = Alignment(-.8 + ampX * t, -.9 + ampY * t);
          final end   = Alignment( .9 - ampX * t,  .8 - ampY * t);

          // «дыхание» стрелки
          final chevronShift = shouldAnimate ? 4 * sin(_c.value * pi * 2) : 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.22),
                  blurRadius: 28,
                  spreadRadius: -2,
                  offset: const Offset(0, 12),
                ),
              ]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      builder: (_) => AiAnalyzeSheet(
                        year: widget.year,
                        month: widget.month,
                        currency: widget.currency,
                      ),
                    ),
                    splashColor: onCard.withOpacity(.08),
                    highlightColor: Colors.transparent,
                    child: SizedBox(
                      height: 128,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Градиентный фон
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: begin,
                                end: end,
                                colors: [base1, base2, base3],
                              ),
                            ),
                          ),
                          // Размытые «пятна» — амплитуда побольше
                          Positioned(
                            right: -40 + 28 * t,
                            top: -36,
                            child: _Blob(color: cs.primary.withOpacity(.22), size: 140),
                          ),
                          Positioned(
                            left: -30,
                            bottom: -46 + 32 * (1 - t),
                            child: _Blob(color: cs.tertiary.withOpacity(.20), size: 130),
                          ),
                          // Нежный шум (для глубины)
                          _NoiseOverlay(opacity: theme.brightness == Brightness.dark ? .06 : .04),
                          // Искорки — только когда анимация включена
                          if (shouldAnimate)
                            _Sparkles(progress: _c.value, color: onCard.withOpacity(.35)),
                          // Контент
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            child: Row(
                              children: [
                                _GlassCircle(
                                  size: 66,
                                  child: Icon(Icons.smart_toy_rounded, size: 36, color: iconColor),
                                  // стекло: различный fill/бордер под тему
                                  fillOverride: theme.brightness == Brightness.light
                                      ? Colors.black.withOpacity(.05)
                                      : Colors.white.withOpacity(.10),
                                  borderOverride: theme.brightness == Brightness.light
                                      ? Colors.black.withOpacity(.10)
                                      : Colors.white.withOpacity(.28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DefaultTextStyle(
                                    style: theme.textTheme.bodyMedium!.copyWith(color: onCard),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'AI-анализ расходов',
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.titleMedium!.copyWith(
                                                  color: onCard,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: .2,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _NewBadge(
                                              // по умолчанию сочный жёлтый; можно переопределить
                                              color: widget.badgeColor ?? kBrightYellow,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Экспресс или глубокий AI-анализ 💡\nУзнай свои финансы на новом уровне!',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium!.copyWith(
                                            color: onCard.withOpacity(.92),
                                            height: 1.18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Transform.translate(
                                  offset: Offset(chevronShift + 2, 0),
                                  child: Icon(Icons.chevron_right, size: 28, color: onCard.withOpacity(.95)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _onColorFor(Color bg) =>
      ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
          ? Colors.white
          : Colors.black87;
}

/// Стеклянная капсула под иконкой
class _GlassCircle extends StatelessWidget {
  final double size;
  final Widget child;
  final Color? fillOverride;
  final Color? borderOverride;

  const _GlassCircle({
    required this.size,
    required this.child,
    this.fillOverride,
    this.borderOverride,
  });

  @override
  Widget build(BuildContext context) {
    final fill = fillOverride ?? Colors.white.withOpacity(.10);
    final border = borderOverride ?? Colors.white.withOpacity(.28);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(size),
            border: Border.all(color: border),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Нежный шум — добавляет глубины
class _NoiseOverlay extends StatelessWidget {
  final double opacity;
  const _NoiseOverlay({this.opacity = .05});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: Colors.transparent,
        child: CustomPaint(painter: _NoisePainter(opacity)),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double opacity;
  _NoisePainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final paint = Paint()..color = Colors.black.withOpacity(opacity);
    for (int i = 0; i < 180; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), rnd.nextDouble() * .6 + .2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter old) => old.opacity != opacity;
}

/// Размытое цветовое «пятно»
class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color, color.withOpacity(0)],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Искорки
class _Sparkles extends StatelessWidget {
  final double progress; // 0..1
  final Color color;
  const _Sparkles({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _SparklesPainter(progress, color)),
    );
  }
}

class _SparklesPainter extends CustomPainter {
  final double t;
  final Color color;
  _SparklesPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    for (int i = 0; i < 14; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final pulse = (sin((t * 2 * pi) + i) + 1) / 2; // 0..1
      final p = Paint()..color = color.withOpacity(0.15 + 0.25 * pulse);
      canvas.drawCircle(Offset(x, y), 1.2 + pulse, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter old) =>
      old.t != t || old.color != color;
}

/// Бейдж «NEW»
class _NewBadge extends StatelessWidget {
  final Color color;
  const _NewBadge({this.color = kBrightYellow}); // по умолчанию ярко-жёлтый

  @override
  Widget build(BuildContext context) {
    final bg     = color.withOpacity(.28);
    final border = _darken(color, .22).withOpacity(.55);
    final text   = _darken(color, .25);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: ShapeDecoration(
        color: bg,
        shape: StadiumBorder(side: BorderSide(color: border)),
      ),
      child: Text(
        'NEW',
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: text,
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
        ),
      ),
    );
  }

  // аккуратно притемнить любой цвет
  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
