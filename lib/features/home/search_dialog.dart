import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models.dart';

/// Recherche dans les articles publiés (titre, résumé, rubrique).
Future<void> showSearchDialog(BuildContext context, List<Article> articles) {
  return showDialog<void>(
    context: context,
    builder: (_) => _SearchDialog(articles: articles),
  );
}

String _norm(String s) {
  const from = 'àâäéèêëîïôöùûüç';
  const to = 'aaaeeeeiioouuuc';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({required this.articles});
  final List<Article> articles;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _norm(_q.trim());
    final results = q.isEmpty
        ? <Article>[]
        : widget.articles
            .where((a) => _norm('${a.title} ${a.summary} ${a.category}').contains(q))
            .toList();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher un article…',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: q.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Tapez un mot : ville, nom, sujet…', style: TextStyle(color: Brand.muted)),
                      )
                    : results.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Aucun résultat.', style: TextStyle(color: Brand.muted)),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              for (final a in results)
                                ListTile(
                                  title: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: Text('${a.category} · ${a.dateLabel}'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go('/article/${a.slug}');
                                  },
                                ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
