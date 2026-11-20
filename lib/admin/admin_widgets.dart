import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'admin_repository.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'published' => const Color(0xFF1E8E3E),
      'review' || 'pending' => const Color(0xFFB26A00),
      'archived' || 'rejected' => Brand.muted,
      _ => Brand.blue,
    };
    final label = kStatusLabels[status] ??
        switch (status) {
          'pending' => 'En attente',
          'rejected' => 'Refusé',
          _ => status,
        };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String message, {String action = 'Confirmer'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
      ],
    ),
  );
  return ok ?? false;
}

void snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Message d'erreur lisible en français.
String friendlyError(Object e) {
  if (e is AppMessage) return e.message;
  final s = e.toString();
  if (s.contains('row-level security') || s.contains('42501')) {
    return "Action non autorisée pour votre rôle.";
  }
  if (s.contains('Invalid login')) return 'E-mail ou mot de passe incorrect.';
  if (s.contains('Image trop lourde')) return 'Image trop lourde (2 Mo maximum).';
  return "Une erreur est survenue. Vérifiez votre connexion et réessayez.";
}
