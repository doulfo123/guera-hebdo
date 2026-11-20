import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';
import 'admin_repository.dart';
import 'admin_scaffold.dart';
import 'admin_widgets.dart';

class AdminAdsPage extends StatefulWidget {
  const AdminAdsPage({super.key});

  @override
  State<AdminAdsPage> createState() => _AdminAdsPageState();
}

class _AdminAdsPageState extends State<AdminAdsPage> {
  late Future<List<AdminAd>> _future = adminRepo.listAds();

  void _reload() => setState(() => _future = adminRepo.listAds());

  Future<void> _edit(AdminAd? existing) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AdDialog(ad: existing ?? AdminAd()),
    );
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      current: 'ads',
      title: 'Publicités',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle publicité'),
      ),
      builder: (context, me) => FutureBuilder<List<AdminAd>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(friendlyError(snap.error!)));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('Aucune publicité.'));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = items[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  onTap: () => _edit(a),
                  leading: a.imageUrl == null
                      ? const Icon(Icons.campaign_outlined)
                      : Image.network(a.imageUrl!, width: 56, height: 40, fit: BoxFit.cover),
                  title: Text(a.advertiser),
                  subtitle: Text(AdminAd.placements[a.placement] ?? a.placement,
                      style: const TextStyle(color: Brand.muted)),
                  trailing: Text(a.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                          color: a.isActive ? const Color(0xFF1E8E3E) : Brand.muted, fontWeight: FontWeight.w700)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdDialog extends StatefulWidget {
  const _AdDialog({required this.ad});
  final AdminAd ad;

  @override
  State<_AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<_AdDialog> {
  late final AdminAd a = widget.ad;
  late final _advertiser = TextEditingController(text: a.advertiser);
  late final _title = TextEditingController(text: a.title ?? '');
  late final _body = TextEditingController(text: a.body ?? '');
  late final _link = TextEditingController(text: a.linkUrl ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _advertiser.dispose();
    _title.dispose();
    _body.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
      if (f == null) return;
      setState(() => _busy = true);
      final url = await adminRepo.uploadImage(f, 'ads');
      setState(() => a.imageUrl = url);
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: (start ? a.startsOn : a.endsOn) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d != null) setState(() => start ? a.startsOn = d : a.endsOn = d);
  }

  String _fmt(DateTime? d) => d == null ? '—' : '${d.day}/${d.month}/${d.year}';

  Future<void> _save() async {
    if (_advertiser.text.trim().isEmpty) {
      snack(context, "Indiquez le nom de l'annonceur.");
      return;
    }
    a
      ..advertiser = _advertiser.text.trim()
      ..title = _title.text
      ..body = _body.text
      ..linkUrl = _link.text;
    setState(() => _busy = true);
    try {
      await adminRepo.saveAd(a);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(a.id == null ? 'Nouvelle publicité' : 'Modifier la publicité'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: a.placement,
              decoration: const InputDecoration(labelText: 'Emplacement'),
              items: [
                for (final e in AdminAd.placements.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => a.placement = v ?? a.placement),
            ),
            TextField(controller: _advertiser, decoration: const InputDecoration(labelText: 'Annonceur')),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Titre')),
            TextField(controller: _body, maxLines: 2, decoration: const InputDecoration(labelText: 'Texte')),
            TextField(controller: _link, decoration: const InputDecoration(labelText: 'Lien (https://…)')),
            const SizedBox(height: 8),
            Row(children: [
              OutlinedButton(onPressed: _busy ? null : _pickImage, child: Text(a.imageUrl == null ? 'Image' : "Changer l'image")),
              const SizedBox(width: 8),
              if (a.imageUrl != null) Expanded(child: Text('Image ajoutée', style: const TextStyle(color: Brand.muted))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              TextButton(onPressed: () => _pickDate(true), child: Text('Début : ${_fmt(a.startsOn)}')),
              TextButton(onPressed: () => _pickDate(false), child: Text('Fin : ${_fmt(a.endsOn)}')),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: a.isActive,
              onChanged: (v) => setState(() => a.isActive = v),
            ),
          ]),
        ),
      ),
      actions: [
        if (a.id != null)
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    if (await confirmDialog(context, 'Supprimer cette publicité ?', action: 'Supprimer')) {
                      await adminRepo.deleteAd(a.id!);
                      if (mounted) Navigator.pop(context, true);
                    }
                  },
            child: const Text('Supprimer', style: TextStyle(color: Brand.red)),
          ),
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Enregistrer')),
      ],
    );
  }
}
