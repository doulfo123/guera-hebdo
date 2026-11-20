import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import 'admin_auth.dart';
import 'admin_repository.dart';

/// Cadre commun des écrans du back-office : barre du haut + onglets selon le rôle.
class AdminScaffold extends StatefulWidget {
  const AdminScaffold({
    super.key,
    required this.current,
    required this.builder,
    this.floatingActionButton,
    this.title,
  });

  final String current; // 'articles' | 'notices' | 'poll' | 'ads'
  final Widget Function(BuildContext context, Profile me) builder;
  final Widget? floatingActionButton;
  final String? title;

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  late final Future<Profile?> _profile = adminAuth.loadProfile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile?>(
      future: _profile,
      builder: (context, snap) {
        final me = snap.data;
        return Scaffold(
          backgroundColor: Brand.paper,
          appBar: AppBar(
            backgroundColor: Brand.navy,
            foregroundColor: Colors.white,
            title: Text(widget.title ?? 'Back-office', style: displayStyle(22, color: Colors.white)),
            actions: [
              if (me != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Text('${me.displayName} · ${me.roleLabel}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              IconButton(
                tooltip: 'Voir le site',
                icon: const Icon(Icons.public),
                onPressed: () => context.go('/'),
              ),
              IconButton(
                tooltip: 'Se déconnecter',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await adminAuth.signOut();
                  if (context.mounted) context.go('/admin/login');
                },
              ),
            ],
          ),
          floatingActionButton: widget.floatingActionButton,
          body: Builder(builder: (context) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (me == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text("Profil introuvable. Demandez à l'administrateur de vérifier votre compte."),
                ),
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    _Tabs(current: widget.current, me: me),
                    Expanded(child: widget.builder(context, me)),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.current, required this.me});
  final String current;
  final Profile me;

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, String, String)>[
      ('articles', 'Articles', '/admin'),
      if (me.isStaff) ('notices', 'Communiqués', '/admin/notices'),
      if (me.isStaff) ('poll', 'Sondage', '/admin/poll'),
      if (me.isAdmin) ('ads', 'Publicités', '/admin/ads'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final t in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(t.$2),
                selected: current == t.$1,
                onSelected: (_) => context.go(t.$3),
              ),
            ),
        ],
      ),
    );
  }
}
