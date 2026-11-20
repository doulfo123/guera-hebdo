import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../data/models.dart';

/// Affiche un communiqué en entier, avec partage WhatsApp.
Future<void> showNoticeSheet(BuildContext context, Notice n, List<Town> towns) {
  String? townName;
  for (final t in towns) {
    if (t.id == n.townId) townName = t.name;
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (c, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            [n.kindLabel.toUpperCase(), n.dateLabel, if (townName != null) townName.toUpperCase()].join(' · '),
            style: const TextStyle(color: Brand.red, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(n.title, style: displayStyle(30, color: Brand.navy, height: 1.05)),
          const SizedBox(height: 16),
          if (n.body.isNotEmpty) SelectableText(n.body, style: const TextStyle(fontSize: 17, height: 1.5)),
          const SizedBox(height: 24),
          Row(children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Brand.whatsapp),
              onPressed: () => launchUrl(
                Uri.parse('https://wa.me/?text=${Uri.encodeComponent('${n.title}\n\n${n.body}\n\nGuéra Hebdo · $kSiteUrl')}'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('WhatsApp'),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fermer')),
          ]),
        ],
      ),
    ),
  );
}
