import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Logo « Guéra [Hebdo] » redessiné en Flutter (net à toutes les tailles).
/// À remplacer par le logo vectoriel officiel quand le fichier source sera disponible.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.framed = false});

  /// Fond blanc arrondi, pour l'afficher sur une image ou un fond foncé.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final logo = Semantics(
      label: 'Guéra Hebdo',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Guéra', style: displayStyle(26, color: Brand.blue)),
            const SizedBox(width: 4),
            ClipPath(
              clipper: _MegaphoneClipper(),
              child: Container(
                color: Brand.red,
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                child: Text('Hebdo', style: displayStyle(22, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
    if (!framed) return logo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: logo,
    );
  }
}

class _MegaphoneClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * 0.14)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height * 0.86)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
