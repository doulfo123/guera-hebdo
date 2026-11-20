import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'admin_repository.dart';
import 'admin_scaffold.dart';
import 'admin_widgets.dart';

class AdminPollPage extends StatefulWidget {
  const AdminPollPage({super.key});

  @override
  State<AdminPollPage> createState() => _AdminPollPageState();
}

class _AdminPollPageState extends State<AdminPollPage> {
  late Future<AdminPollData?> _future = adminRepo.activePoll();
  final _question = TextEditingController();
  final List<TextEditingController> _opts = [for (var i = 0; i < 4; i++) TextEditingController()];
  bool _busy = false;

  @override
  void dispose() {
    _question.dispose();
    for (final c in _opts) {
      c.dispose();
    }
    super.dispose();
  }

  void _reload() => setState(() => _future = adminRepo.activePoll());

  Future<void> _create() async {
    final labels = _opts.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (_question.text.trim().length < 5 || labels.length < 2) {
      snack(context, 'Une question et au moins 2 réponses sont nécessaires.');
      return;
    }
    setState(() => _busy = true);
    try {
      await adminRepo.createPoll(_question.text.trim(), labels);
      _question.clear();
      for (final c in _opts) {
        c.clear();
      }
      _reload();
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      current: 'poll',
      title: 'Sondage',
      builder: (context, me) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<AdminPollData?>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) return Text(friendlyError(snap.error!));
              if (!snap.hasData && snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final p = snap.data;
              if (p == null) return const Text('Aucun sondage actif.');
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SONDAGE ACTIF · ${p.total} vote(s)',
                        style: const TextStyle(color: Brand.blue, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(p.question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 12),
                    for (final o in p.options) ...[
                      Text('${o.letter}. ${o.label}  —  ${p.votes[o.id] ?? 0}'
                          '${p.total == 0 ? '' : ' (${((p.votes[o.id] ?? 0) * 100 / p.total).round()} %)'}'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: p.total == 0 ? 0 : (p.votes[o.id] ?? 0) / p.total,
                        minHeight: 8,
                        color: Brand.blue,
                        backgroundColor: Brand.line,
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton(
                      onPressed: () async {
                        if (await confirmDialog(context, 'Clôturer ce sondage ?')) {
                          await adminRepo.closePoll(p.id);
                          _reload();
                        }
                      },
                      child: const Text('Clôturer'),
                    ),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('NOUVEAU SONDAGE', style: displayStyle(20, color: Brand.navy)),
          const SizedBox(height: 4),
          const Text('Le sondage actif sera remplacé.', style: TextStyle(color: Brand.muted)),
          const SizedBox(height: 12),
          TextField(
            controller: _question,
            decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
          ),
          for (var i = 0; i < _opts.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _opts[i],
                decoration: InputDecoration(
                  labelText: 'Réponse ${String.fromCharCode(65 + i)}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          Row(children: [
            if (_opts.length < 6)
              TextButton(
                onPressed: () => setState(() => _opts.add(TextEditingController())),
                child: const Text('+ Ajouter une réponse'),
              ),
          ]),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: const Text('Lancer le sondage'),
          ),
        ],
      ),
    );
  }
}
