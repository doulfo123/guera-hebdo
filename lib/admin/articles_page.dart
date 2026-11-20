import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import 'admin_repository.dart';
import 'admin_scaffold.dart';
import 'admin_widgets.dart';

class AdminArticlesPage extends StatefulWidget {
  const AdminArticlesPage({super.key});

  @override
  State<AdminArticlesPage> createState() => _AdminArticlesPageState();
}

class _AdminArticlesPageState extends State<AdminArticlesPage> {
  String _filter = 'all';
  Future<List<AdminArticle>>? _future;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      current: 'articles',
      title: 'Articles',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/article/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel article'),
      ),
      builder: (context, me) {
        _future ??= adminRepo.listArticles(me);
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final f in ['all', ...kStatusLabels.keys])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f == 'all' ? 'Tous' : kStatusLabels[f]!),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<AdminArticle>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.hasError) return Center(child: Text(friendlyError(snap.error!)));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final items = snap.data!.where((a) => _filter == 'all' || a.status == _filter).toList();
                  if (items.isEmpty) return const Center(child: Text('Aucun article.'));
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final a = items[i];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          onTap: () async {
                            await context.push('/admin/article/${a.id}');
                            if (mounted) setState(() => _future = adminRepo.listArticles(me));
                          },
                          title: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${a.category} · ${a.authorName ?? ''}',
                                style: const TextStyle(color: Brand.muted)),
                          ),
                          trailing: StatusBadge(a.status),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
