import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../widgets/wordmark.dart';

/// Carte stylisée du Guéra : on touche une ville pour voir ses informations.
class GueraMap extends StatelessWidget {
  const GueraMap({
    super.key,
    required this.towns,
    required this.townsWithNews,
    required this.selected,
    required this.onSelect,
    this.onSearch,
  });

  final List<Town> towns;

  /// Identifiants des villes qui ont au moins un article publié.
  final Set<String> townsWithNews;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 390 / 560,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _MapPainter())),
              const Positioned(left: 16, top: 16, child: Wordmark(framed: true)),
              Positioned(
                right: 16,
                top: 16,
                child: IconButton(
                  tooltip: 'Rechercher',
                  onPressed: onSearch,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(41),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.search),
                ),
              ),
              Positioned(left: 16, top: h * 76 / 560, child: const _MapTitle()),
              for (final t in towns)
                Positioned(
                  left: t.dx * w - 30,
                  top: t.dy * h - 12,
                  width: 60,
                  height: 56,
                  child: _Pin(
                    town: t,
                    selected: selected == t.id,
                    hasNews: townsWithNews.contains(t.id),
                    onTap: () => onSelect(t.id),
                  ),
                ),
              Positioned(
                left: 16,
                bottom: 44,
                child: _ProvinceButton(
                  selected: selected == provinceId,
                  onTap: () => onSelect(provinceId),
                ),
              ),
              const Positioned(right: 16, bottom: 52, child: _Legend()),
            ],
          );
        },
      ),
    );
  }
}

class _MapTitle extends StatelessWidget {
  const _MapTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROVINCE DU GUÉRA · 12 VILLES',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Brand.yellow,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "OÙ EST\nL'INFO ?",
          style: displayStyle(52, color: Colors.white, height: 0.92),
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.town,
    required this.selected,
    required this.hasNews,
    required this.onTap,
  });

  final Town town;
  final bool selected;
  final bool hasNews;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dotSize = selected ? 28.0 : 20.0;
    final dotColor =
        selected ? Brand.yellow : (hasNews ? Brand.red : Brand.mapPin);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Voir les infos de ${town.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: OverflowBox(
            maxWidth: 140,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(
                      color: Colors.white,
                      width: selected ? 4 : 3,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Brand.yellow.withAlpha(90),
                              spreadRadius: 7,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? Brand.yellow : Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    town.name,
                    style: TextStyle(
                      fontSize: selected ? 13 : 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      color: selected ? Brand.ink : Brand.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProvinceButton extends StatelessWidget {
  const _ProvinceButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: selected ? Brand.ink : Colors.white,
        backgroundColor: selected ? Brand.yellow : Colors.transparent,
        side: BorderSide(
          color: selected ? Brand.yellow : Colors.white,
          width: 1.5,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      child: const Text('Toute la province'),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget row(Color color, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        row(Brand.red, 'Infos publiées'),
        const SizedBox(height: 6),
        row(Brand.mapPin, 'À venir'),
      ],
    );
  }
}

/// Dessine le massif du Guéra en courbes de niveau (coordonnées de la maquette 390 × 560).
class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Brand.navy);
    canvas.save();
    canvas.scale(size.width / 390, size.height / 560);

    final contour = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x8C2B5FB8);
    canvas.drawPath(
      Path()
        ..moveTo(-20, 80)
        ..cubicTo(60, 60, 120, 100, 200, 70)
        ..cubicTo(280, 40, 340, 70, 410, 50),
      contour,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-20, 110)
        ..cubicTo(60, 90, 120, 130, 200, 100)
        ..cubicTo(280, 70, 340, 100, 410, 80),
      contour,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-20, 520)
        ..cubicTo(60, 500, 140, 540, 220, 510)
        ..cubicTo(300, 480, 350, 520, 410, 500),
      contour,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-20, 550)
        ..cubicTo(60, 530, 140, 570, 220, 540)
        ..cubicTo(300, 510, 350, 550, 410, 530),
      contour,
    );

    _blob(
      canvas,
      Path()
        ..moveTo(40, 320)
        ..cubicTo(45, 215, 140, 140, 230, 150)
        ..cubicTo(335, 160, 375, 250, 358, 345)
        ..cubicTo(340, 440, 240, 480, 150, 460)
        ..cubicTo(80, 445, 36, 385, 40, 320)
        ..close(),
      const Color(0xFF0E3478),
      const Color(0xFF2B5FB8),
    );
    _blob(
      canvas,
      Path()
        ..moveTo(80, 315)
        ..cubicTo(88, 240, 150, 185, 225, 192)
        ..cubicTo(300, 200, 335, 265, 320, 338)
        ..cubicTo(305, 405, 235, 435, 165, 420)
        ..cubicTo(115, 410, 76, 370, 80, 315)
        ..close(),
      const Color(0xFF12408F),
      const Color(0xFF2B5FB8),
    );
    _blob(
      canvas,
      Path()
        ..moveTo(120, 310)
        ..cubicTo(128, 262, 172, 228, 224, 233)
        ..cubicTo(276, 240, 296, 284, 286, 332)
        ..cubicTo(274, 374, 230, 396, 184, 386)
        ..cubicTo(145, 378, 116, 352, 120, 310)
        ..close(),
      const Color(0xFF1B4FA8),
      const Color(0xFF4A7BD0),
    );

    // Sommet
    canvas.drawPath(
      Path()
        ..moveTo(205, 290)
        ..lineTo(222, 262)
        ..lineTo(240, 292)
        ..close(),
      Paint()..color = const Color(0xD9FFFFFF),
    );
    canvas.restore();
  }

  void _blob(Canvas canvas, Path path, Color fill, Color stroke) {
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
