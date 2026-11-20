import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/content_repository.dart';
import '../../data/models.dart';

/// Formulaire public : toute personne peut proposer un communiqué.
/// Il n'est publié qu'après validation par l'équipe.
class CommuniquePage extends StatefulWidget {
  const CommuniquePage({super.key});

  @override
  State<CommuniquePage> createState() => _CommuniquePageState();
}

class _CommuniquePageState extends State<CommuniquePage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _contact = TextEditingController();
  String _kind = 'communique';
  String? _townId;
  List<Town> _towns = [];
  bool _busy = false;
  bool _done = false;
  String? _error;

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

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await contentRepo.submitNotice(
        kind: _kind,
        title: _title.text.trim(),
        body: _body.text.trim(),
        townId: _townId,
        contact: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
      );
      setState(() => _done = true);
    } catch (_) {
      setState(() => _error = "L'envoi a échoué. Réessayez dans un instant.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.paper,
      appBar: AppBar(
        backgroundColor: Brand.navy,
        foregroundColor: Colors.white,
        title: Text('PUBLIER UN COMMUNIQUÉ', style: displayStyle(22, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _done
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle, color: Color(0xFF1E8E3E), size: 56),
                    const SizedBox(height: 12),
                    const Text(
                      'Merci ! Votre communiqué a bien été reçu et sera publié après validation par la rédaction.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => context.go('/'), child: const Text("Retour à l'accueil")),
                  ]),
                )
              : Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Nominations, avis, offres d\'emploi, événements : envoyez votre annonce, '
                        "la rédaction la vérifie avant publication.",
                        style: TextStyle(color: Brand.muted),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _kind,
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        items: [
                          for (final e in Notice.kinds.entries)
                            DropdownMenuItem(value: e.key, child: Text(e.value)),
                        ],
                        onChanged: (v) => setState(() => _kind = v ?? _kind),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _title,
                        maxLength: 200,
                        decoration: const InputDecoration(labelText: 'Titre', border: OutlineInputBorder()),
                        validator: (v) => (v ?? '').trim().length < 3 ? 'Titre trop court' : null,
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _body,
                        minLines: 5,
                        maxLines: 12,
                        maxLength: 5000,
                        decoration: const InputDecoration(
                          labelText: 'Texte du communiqué',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Indiquez le texte' : null,
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String?>(
                        value: _townId,
                        decoration: const InputDecoration(labelText: 'Localité (facultatif)', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Toute la province')),
                          for (final t in _towns) DropdownMenuItem<String?>(value: t.id, child: Text(t.name)),
                        ],
                        onChanged: (v) => setState(() => _townId = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contact,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Votre contact (téléphone ou e-mail, non publié)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_error != null) Text(_error!, style: const TextStyle(color: Brand.red)),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_busy ? 'Envoi…' : 'Envoyer'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
