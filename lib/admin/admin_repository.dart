import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';

/// Erreur dont le message est déjà lisible par l'équipe.
class AppMessage implements Exception {
  AppMessage(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Transforme un titre en adresse : « Éclairage à Bitkine » → « eclairage-a-bitkine ».
String slugify(String input) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyyoa';
  final b = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  var s = b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');
  if (s.length > 80) s = s.substring(0, 80).replaceAll(RegExp(r'-+$'), '');
  return s.isEmpty ? 'article' : s;
}

class Profile {
  const Profile({required this.id, required this.fullName, required this.role});

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: (m['full_name'] as String?) ?? '',
        role: (m['role'] as String?) ?? 'writer',
      );

  final String id;
  final String fullName;
  final String role;

  bool get isStaff => role == 'editor' || role == 'admin';
  bool get isAdmin => role == 'admin';
  String get roleLabel => switch (role) {
        'admin' => 'Administrateur',
        'editor' => 'Éditeur',
        _ => 'Rédacteur',
      };
  String get displayName => fullName.isEmpty ? roleLabel : fullName;
}

const Map<String, String> kStatusLabels = {
  'draft': 'Brouillon',
  'review': 'En relecture',
  'published': 'Publié',
  'archived': 'Archivé',
};

const List<String> kCategories = [
  'GUÉRA',
  'POLITIQUE',
  'SOCIÉTÉ',
  'ÉCONOMIE',
  'CULTURE',
  'SPORT',
  'ÉDUCATION',
  'SANTÉ',
  'ÉLEVAGE',
  'FESTIVAL PASTORAL',
  'ATELIER',
];

class AdminArticle {
  AdminArticle({
    this.id,
    this.slug = '',
    this.title = '',
    this.category = 'GUÉRA',
    this.summary = '',
    this.body = '',
    this.townId,
    this.authorId,
    this.authorName,
    this.coverUrl,
    this.videoUrl,
    this.status = 'draft',
    this.reviewNote,
    this.updatedAt,
    this.facebookPostId,
  });

  factory AdminArticle.fromMap(Map<String, dynamic> m) => AdminArticle(
        id: m['id'] as String,
        slug: m['slug'] as String,
        title: m['title'] as String,
        category: m['category'] as String,
        summary: (m['summary'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        townId: m['town_id'] as String?,
        authorId: m['author_id'] as String?,
        authorName: m['author_name'] as String?,
        coverUrl: m['cover_url'] as String?,
        videoUrl: m['video_url'] as String?,
        status: m['status'] as String,
        reviewNote: m['review_note'] as String?,
        updatedAt: DateTime.tryParse((m['updated_at'] as String?) ?? '')?.toLocal(),
        facebookPostId: m['facebook_post_id'] as String?,
      );

  String? facebookPostId;
  String? id;
  String slug;
  String title;
  String category;
  String summary;
  String body;
  String? townId;
  String? authorId;
  String? authorName;
  String? coverUrl;
  String? videoUrl;
  String status;
  String? reviewNote;
  DateTime? updatedAt;

  Map<String, dynamic> toRow() => {
        'title': title,
        'category': category,
        'summary': summary,
        'body': body,
        'town_id': townId,
        'cover_url': coverUrl,
        'video_url': (videoUrl == null || videoUrl!.trim().isEmpty) ? null : videoUrl!.trim(),
        'status': status,
        'review_note': reviewNote,
      };
}

class AdminNotice {
  const AdminNotice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.status,
    this.townId,
    this.contact,
    this.createdAt,
  });

  factory AdminNotice.fromMap(Map<String, dynamic> m) => AdminNotice(
        id: m['id'] as String,
        kind: m['kind'] as String,
        title: m['title'] as String,
        body: (m['body'] as String?) ?? '',
        status: m['status'] as String,
        townId: m['town_id'] as String?,
        contact: m['contact'] as String?,
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? '')?.toLocal(),
      );

  final String id;
  final String kind;
  final String title;
  final String body;
  final String status;
  final String? townId;
  final String? contact;
  final DateTime? createdAt;

  String get kindLabel => Notice.kinds[kind] ?? kind;
}

class AdminAd {
  AdminAd({
    this.id,
    this.placement = 'inline_banner',
    this.advertiser = '',
    this.title,
    this.body,
    this.imageUrl,
    this.linkUrl,
    this.startsOn,
    this.endsOn,
    this.isActive = true,
  });

  factory AdminAd.fromMap(Map<String, dynamic> m) => AdminAd(
        id: m['id'] as String,
        placement: m['placement'] as String,
        advertiser: m['advertiser'] as String,
        title: m['title'] as String?,
        body: m['body'] as String?,
        imageUrl: m['image_url'] as String?,
        linkUrl: m['link_url'] as String?,
        startsOn: DateTime.tryParse((m['starts_on'] as String?) ?? ''),
        endsOn: DateTime.tryParse((m['ends_on'] as String?) ?? ''),
        isActive: (m['is_active'] as bool?) ?? true,
      );

  static const Map<String, String> placements = {
    'top_banner': 'Bandeau du haut',
    'inline_banner': 'Bandeau dans les pages',
    'card': 'Encart « Annonce »',
  };

  String? id;
  String placement;
  String advertiser;
  String? title;
  String? body;
  String? imageUrl;
  String? linkUrl;
  DateTime? startsOn;
  DateTime? endsOn;
  bool isActive;

  static String? _d(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toRow() => {
        'placement': placement,
        'advertiser': advertiser,
        'title': _nn(title),
        'body': _nn(body),
        'image_url': imageUrl,
        'link_url': _nn(linkUrl),
        'starts_on': _d(startsOn),
        'ends_on': _d(endsOn),
        'is_active': isActive,
      };

  static String? _nn(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}

class AdminPollData {
  const AdminPollData({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
  });

  final String id;
  final String question;
  final List<PollOption> options;
  final Map<String, int> votes;

  int get total => votes.values.fold(0, (a, b) => a + b);
}

/// Opérations réservées à l'équipe. La sécurité est assurée par les règles RLS :
/// même si l'interface est contournée, la base refuse ce que le rôle ne permet pas.
class AdminRepository {
  SupabaseClient get _db => Supabase.instance.client;

  // ---- Compte -----------------------------------------------------------
  Future<void> signIn(String email, String password) async {
    await _db.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _db.auth.signOut();

  Future<Profile?> fetchProfile() async {
    final u = _db.auth.currentUser;
    if (u == null) return null;
    final row = await _db.from('profiles').select().eq('id', u.id).maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  // ---- Articles ---------------------------------------------------------
  Future<List<AdminArticle>> listArticles(Profile me) async {
    var q = _db.from('articles').select();
    if (!me.isStaff) q = q.eq('author_id', me.id);
    final rows = await q.order('updated_at', ascending: false).limit(300);
    return rows.map<AdminArticle>((r) => AdminArticle.fromMap(r)).toList();
  }

  Future<AdminArticle?> getArticle(String id) async {
    final row = await _db.from('articles').select().eq('id', id).maybeSingle();
    return row == null ? null : AdminArticle.fromMap(row);
  }

  Future<AdminArticle> createArticle(AdminArticle a) async {
    final base = slugify(a.title);
    for (var i = 0; i < 5; i++) {
      final slug = i == 0 ? base : '$base-${DateTime.now().millisecondsSinceEpoch % 100000 + i}';
      try {
        final row = await _db
            .from('articles')
            .insert({...a.toRow(), 'slug': slug})
            .select()
            .single();
        return AdminArticle.fromMap(row);
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow; // adresse déjà prise : on réessaie
      }
    }
    throw Exception("Impossible de créer l'adresse de l'article.");
  }

  Future<AdminArticle> updateArticle(AdminArticle a) async {
    final row = await _db.from('articles').update(a.toRow()).eq('id', a.id!).select().single();
    return AdminArticle.fromMap(row);
  }

  Future<void> deleteArticle(String id) async {
    await _db.from('articles').delete().eq('id', id);
  }

  /// Envoie une image (2 Mo max) dans le stockage et renvoie son adresse publique.
  Future<String> uploadImage(XFile file, String folder) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw Exception('Image trop lourde (2 Mo maximum).');
    }
    final name = file.name.toLowerCase();
    final ext = name.endsWith('.png') ? 'png' : (name.endsWith('.webp') ? 'webp' : 'jpg');
    final mime = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage
        .from('media')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    return _db.storage.from('media').getPublicUrl(path);
  }

  // ---- Facebook ---------------------------------------------------------
  Future<Map<String, dynamic>> _fn(String name, Map<String, dynamic> body) async {
    try {
      final r = await _db.functions.invoke(name, body: body);
      return Map<String, dynamic>.from(r.data as Map);
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] != null) throw AppMessage(d['error'].toString());
      throw AppMessage('La liaison Facebook ne répond pas (${e.status}).');
    }
  }

  /// Lit une publication Facebook à partir de son lien.
  Future<Map<String, dynamic>> importFromFacebook(String url) => _fn('facebook-import', {'url': url});

  /// Dernières publications de la page Facebook (id, message, picture, date).
  Future<List<Map<String, dynamic>>> recentFacebookPosts() async {
    final d = await _fn('facebook-import', {'list': true});
    return List<Map<String, dynamic>>.from((d['posts'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
  }

  /// Importe une publication choisie dans la liste.
  Future<Map<String, dynamic>> importFacebookPost(String postId) => _fn('facebook-import', {'postId': postId});

  /// Publie l'article (déjà publié sur le site) sur la page Facebook.
  Future<void> publishToFacebook(String articleId) async {
    await _fn('facebook-publish', {'articleId': articleId});
  }

  // ---- Communiqués ------------------------------------------------------
  Future<List<AdminNotice>> listNotices() async {
    final rows = await _db.from('notices').select().order('created_at', ascending: false).limit(200);
    return rows.map<AdminNotice>((r) => AdminNotice.fromMap(r)).toList();
  }

  Future<void> updateNotice(AdminNotice n) async {
    await _db.from('notices').update({
      'kind': n.kind,
      'title': n.title,
      'body': n.body,
      'town_id': n.townId,
      'contact': (n.contact == null || n.contact!.trim().isEmpty) ? null : n.contact!.trim(),
    }).eq('id', n.id);
  }

  Future<void> setNoticeStatus(String id, String status) async {
    await _db.from('notices').update({'status': status}).eq('id', id);
  }

  Future<void> deleteNotice(String id) async {
    await _db.from('notices').delete().eq('id', id);
  }

  // ---- Sondage ----------------------------------------------------------
  Future<AdminPollData?> activePoll() async {
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
    final res = await _db.from('poll_results').select().eq('poll_id', p['id'] as String);
    return AdminPollData(
      id: p['id'] as String,
      question: p['question'] as String,
      options: [
        for (final o in opts)
          PollOption(id: o['id'] as String, letter: o['letter'] as String, label: o['label'] as String),
      ],
      votes: {for (final r in res) r['option_id'] as String: (r['votes'] as num).toInt()},
    );
  }

  Future<void> createPoll(String question, List<String> labels) async {
    await _db.from('polls').update({'is_active': false}).eq('is_active', true);
    final poll = await _db.from('polls').insert({'question': question}).select().single();
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    await _db.from('poll_options').insert([
      for (var i = 0; i < labels.length; i++)
        {'poll_id': poll['id'], 'letter': letters[i], 'label': labels[i], 'sort': i},
    ]);
  }

  Future<void> closePoll(String id) async {
    await _db.from('polls').update({'is_active': false}).eq('id', id);
  }

  // ---- Publicités -------------------------------------------------------
  Future<List<AdminAd>> listAds() async {
    final rows = await _db.from('ads').select().order('created_at', ascending: false);
    return rows.map<AdminAd>((r) => AdminAd.fromMap(r)).toList();
  }

  Future<void> saveAd(AdminAd a) async {
    if (a.id == null) {
      await _db.from('ads').insert(a.toRow());
    } else {
      await _db.from('ads').update(a.toRow()).eq('id', a.id!);
    }
  }

  Future<void> deleteAd(String id) async {
    await _db.from('ads').delete().eq('id', id);
  }
}

final AdminRepository adminRepo = AdminRepository();
