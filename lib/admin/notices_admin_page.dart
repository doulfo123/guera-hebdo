import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/models.dart';
import '../app/theme.dart';
import 'admin_repository.dart';
import 'admin_scaffold.dart';
import 'admin_widgets.dart';

class AdminNoticesPage extends StatefulWidget {
  const AdminNoticesPage({super.key});

  @override
  State<AdminNoticesPage> createState() => _AdminNoticesPageState();
}

class _AdminNoticesPageState extends State<AdminNoticesPage> {
  late Future<List<AdminNotice>> _future = adminRepo.listNotices();

  void _reload() => setState(() => _future = adminRepo.listNotices());

  Future<void> _act(Future<void> Function() f) async {
    try {
      await f();
      _reload();
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      current: 'notices',
      title: 'Communiqués',
      builder: (context, me) => FutureBuilder<List<AdminNotice>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(friendlyError(snap.error!)));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('Aucun communiqué.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = items[i];
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(n.kindLabel.toUpperCase(),
                            style: const TextStyle(color: Brand.blue, fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(width: 8),
                        StatusBadge(n.status),
                      ]),
                      const SizedBox(height: 6),
                      Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (n.body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(n.body)),
                      if (n.contact != null && n.contact!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Contact : ${n.contact}', style: const TextStyle(color: Brand.muted)),
                        ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final r = await showDialog<String>(
                              context: context,
                              builder: (_) => _NoticeEditDialog(notice: n),
                            );
                            if (r != null) _reload();
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Modifier'),
                        ),
                        if (n.status != 'published')
                          FilledButton(
                            onPressed: () => _act(() => adminRepo.setNoticeStatus(n.id, 'published')),
                            child: const Text('Publier'),
                          ),
                        if (n.status == 'pending')
                          OutlinedButton(
                            onPressed: () => _act(() => adminRepo.setNoticeStatus(n.id, 'rejected')),
                            child: const Text('Refuser'),
                          ),
                        if (n.status == 'published')
                          OutlinedButton(
                            onPressed: () => _act(() => adminRepo.setNoticeStatus(n.id, 'rejected')),
                            child: const Text('Retirer'),
                          ),
                        TextButton(
                          onPressed: () async {
                            if (await confirmDialog(context, 'Supprimer ce communiqué ?', action: 'Supprimer')) {
                              await _act(() => adminRepo.deleteNotice(n.id));
                            }
                          },
                          child: const Text('Supprimer', style: TextStyle(color: Brand.red)),
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Permet de corriger un communiqué avant de l'accepter.
class _NoticeEditDialog extends StatefulWidget {
  const _NoticeEditDialog({required this.notice});
  final AdminNotice notice;

  @override
  State<_NoticeEditDialog> createState() => _NoticeEditDialogState();
}

class _NoticeEditDialogState extends State<_NoticeEditDialog> {
  late final _title = TextEditingController(text: widget.notice.title);
  late final _body = TextEditingController(text: widget.notice.body);
  late final _contact = TextEditingController(text: widget.notice.contact ?? '');
  late String _kind = widget.notice.kind;
  late String? _townId = widget.notice.townId;
  List<Town> _towns = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    contentRepo.towns().then((t) {
      if (mounted) setState(() => _towns = t);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _save({required bool publish}) async {
    if (_title.text.trim().length < 3) {
      snack(context, 'Le titre est trop court.');
      return;
    }
    setState(() => _busy = true);
    try {
      final n = widget.notice;
      await adminRepo.updateNotice(AdminNotice(
        id: n.id,
        kind: _kind,
        title: _title.text.trim(),
        body: _body.text.trim(),
        status: n.status,
        townId: _townId,
        contact: _contact.text,
      ));
      if (publish) await adminRepo.setNoticeStatus(n.id, 'published');
      if (mounted) Navigator.pop(context, publish ? 'published' : 'saved');
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le communiqué'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _kind,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final e in Notice.kinds.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _kind = v ?? _kind),
            ),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Titre')),
            TextField(
              controller: _body,
              minLines: 5,
              maxLines: 12,
              decoration: const InputDecoration(labelText: 'Texte', alignLabelWithHint: true),
            ),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              value: _towns.any((t) => t.id == _townId) ? _townId : null,
              decoration: const InputDecoration(labelText: 'Localité'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Toute la province')),
                for (final t in _towns) DropdownMenuItem<String?>(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => setState(() => _townId = v),
            ),
            TextField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact (non publié)')),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        OutlinedButton(onPressed: _busy ? null : () => _save(publish: false), child: const Text('Enregistrer')),
        FilledButton(onPressed: _busy ? null : () => _save(publish: true), child: const Text('Enregistrer et publier')),
      ],
    );
  }
}
