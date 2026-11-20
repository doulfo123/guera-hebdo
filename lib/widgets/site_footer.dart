import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/config.dart';
import '../app/theme.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Brand.navy,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GUÉRA HEBDO', style: displayStyle(30, color: Colors.white)),
          const SizedBox(height: 6),
          const Text(
            "Le regard qui éclaire l'actualité.",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mongo, Guéra, Tchad · $kContactEmail',
            style: TextStyle(color: Color(0xFFC9D6EE), fontSize: 16),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () => context.go('/admin'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC9D6EE),
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 40),
            ),
            icon: const Icon(Icons.lock_outline, size: 16),
            label: const Text('Espace rédaction'),
          ),
        ],
      ),
    );
  }
}
