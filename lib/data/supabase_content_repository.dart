import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_repository.dart';
import 'models.dart';

/// Lit les données depuis Supabase. La sécurité est assurée côté serveur
/// (règles RLS de supabase/migrations) : le public ne voit que ce qui est publié.
class SupabaseContentRepository implements ContentRepository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<List<Town>> towns() async {
    final rows = await _db.from('towns').select().order('name');
    return rows.map<Town>((r) => Town.fromMap(r)).toList();
  }

  @override
  Future<List<Article>> publishedArticles() async {
    final rows = await _db
        .from('articles')
        .select()
        .eq('status', 'published')
        .order('published_at', ascending: false)
        .limit(200);
    return rows.map<Article>((r) => Article.fromMap(r)).toList();
  }

  @override
  Future<Article?> articleBySlug(String slug) async {
    final row = await _db
        .from('articles')
        .select()
        .eq('slug', slug)
        .eq('status', 'published')
        .maybeSingle();
    return row == null ? null : Article.fromMap(row);
  }

  @override
  Future<Poll?> activePoll() async {
    final rows = await _db
        .from('polls')
        .select('id, question, poll_options(id, letter, label, sort)')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final p = rows.first;
    final opts = List<Map<String, dynamic>>.from(p['poll_options'] as List)
      ..sort((a, b) => (a['sort'] as num).compareTo(b['sort'] as num));
    return Poll(
      id: p['id'] as String,
      question: p['question'] as String,
      options: [
        for (final o in opts)
          PollOption(
            id: o['id'] as String,
            letter: o['letter'] as String,
            label: o['label'] as String,
          ),
      ],
    );
  }

  @override
  Future<void> vote({required String optionId, required String voterKey}) async {
    await _db.rpc('vote', params: {
      'p_option_id': optionId,
      'p_voter_key': voterKey,
    });
  }

  @override
  Future<Map<String, int>> pollResults(String pollId) async {
    final rows = await _db.from('poll_results').select().eq('poll_id', pollId);
    return {
      for (final r in rows) r['option_id'] as String: (r['votes'] as num).toInt(),
    };
  }

  @override
  Future<Ad?> ad(String placement) async {
    final rows = await _db
        .from('ads')
        .select()
        .eq('placement', placement)
        .order('created_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : Ad.fromMap(rows.first);
  }

  @override
  Future<List<Notice>> publishedNotices() async {
    final rows = await _db
        .from('notices')
        .select()
        .eq('status', 'published')
        .order('published_at', ascending: false)
        .limit(20);
    return rows.map<Notice>((r) => Notice.fromMap(r)).toList();
  }

  @override
  Future<void> submitNotice({
    required String kind,
    required String title,
    required String body,
    String? townId,
    String? contact,
  }) async {
    // Le public ne peut insérer que des communiqués « en attente » (règle RLS).
    await _db.from('notices').insert({
      'kind': kind,
      'title': title,
      'body': body,
      'town_id': townId,
      'contact': contact,
      'status': 'pending',
    });
  }
}
