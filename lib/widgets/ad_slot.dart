import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/config.dart';
import '../app/theme.dart';
import '../data/content_repository.dart';
import '../data/models.dart';

/// Emplacement publicitaire, toujours étiqueté « Publicité ».
/// Avec Supabase : affiche l'annonce active ; sans annonce, l'emplacement disparaît.
/// En mode démo : affiche un emplacement factice.
class AdSlot extends StatefulWidget {
  const AdSlot({super.key, this.placement = 'top_banner', this.height = 90});

  /// 'top_banner', 'inline_banner' ou 'card' (voir la table ads).
  final String placement;
  final double height;

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  late final Future<Ad?> _ad = contentRepo.ad(widget.placement);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Ad?>(
      future: _ad,
      builder: (context, snap) {
        final ad = snap.data;
        if (ad == null) {
          if (kUseSupabase) return const SizedBox.shrink();
          return _frame(_placeholder());
        }
        return _frame(_realAd(ad));
      },
    );
  }

  Widget _frame(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PUBLICITÉ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Brand.muted,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FA),
        border: Border.all(color: const Color(0xFF8FA3C4), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '[Bandeau image · votre annonce ici]',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Brand.blue,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _realAd(Ad ad) {
    final content = ad.imageUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              ad.imageUrl!,
              height: widget.height,
              width: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: ad.title ?? ad.advertiser,
              errorBuilder: (context, error, stack) => _textAd(ad),
            ),
          )
        : _textAd(ad);
    final link = ad.linkUrl;
    if (link == null) return content;
    return InkWell(
      onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
      child: content,
    );
  }

  Widget _textAd(Ad ad) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Brand.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ad.title ?? ad.advertiser, style: displayStyle(24, height: 1.05)),
          if (ad.body != null) ...[
            const SizedBox(height: 6),
            Text(
              ad.body!,
              style: const TextStyle(fontSize: 16, height: 1.4, color: Brand.muted),
            ),
          ],
        ],
      ),
    );
  }
}
