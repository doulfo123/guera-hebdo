/// Identifiant spécial : tout le Guéra, sans ville précise.
const String provinceId = 'guera';

const List<String> _months = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String frenchDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Les paragraphes d'un article sont séparés par une ligne vide.
List<String> splitParagraphs(String body) {
  return body
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
}

class Town {
  const Town({
    required this.id,
    required this.name,
    required this.department,
    required this.dx,
    required this.dy,
    this.subtitle,
  });

  factory Town.fromMap(Map<String, dynamic> m) {
    return Town(
      id: m['id'] as String,
      name: m['name'] as String,
      department: m['department'] as String,
      dx: (m['dx'] as num).toDouble(),
      dy: (m['dy'] as num).toDouble(),
      subtitle: m['subtitle'] as String?,
    );
  }

  final String id;
  final String name;
  final String department;

  /// Position sur la carte stylisée, en fraction de la largeur / hauteur (0 à 1).
  final double dx;
  final double dy;
  final String? subtitle;

  String get subtitleLabel {
    final dept = department == 'Guéra' ? 'DU GUÉRA' : department.toUpperCase();
    return subtitle ?? 'SOUS-PRÉFECTURE · DÉPARTEMENT $dept';
  }
}

class Article {
  const Article({
    required this.slug,
    required this.title,
    required this.category,
    required this.summary,
    required this.dateLabel,
    required this.body,
    this.townId,
    this.author = 'La rédaction',
    this.coverUrl,
    this.videoUrl,
  });

  factory Article.fromMap(Map<String, dynamic> m) {
    final published = DateTime.tryParse((m['published_at'] ?? '') as String)?.toLocal();
    final author = (m['author_name'] as String?)?.trim();
    return Article(
      slug: m['slug'] as String,
      title: m['title'] as String,
      category: (m['category'] as String).toUpperCase(),
      summary: (m['summary'] as String?) ?? '',
      dateLabel: published == null ? '' : frenchDate(published),
      body: splitParagraphs((m['body'] as String?) ?? ''),
      townId: m['town_id'] as String?,
      author: (author == null || author.isEmpty) ? 'La rédaction' : author,
      coverUrl: m['cover_url'] as String?,
      videoUrl: m['video_url'] as String?,
    );
  }

  final String slug;
  final String title;
  final String category;
  final String summary;
  final String dateLabel;
  final List<String> body;

  /// Ville concernée ; null = information d'intérêt provincial.
  final String? townId;
  final String author;
  final String? coverUrl;

  /// Lien Facebook de la vidéo (les vidéos ne sont pas hébergées sur le site).
  final String? videoUrl;
}

/// Communiqué ou annonce locale (nomination, avis, offre d'emploi, événement…).
class Notice {
  const Notice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.dateLabel,
    this.townId,
    this.status = 'published',
    this.contact,
  });

  factory Notice.fromMap(Map<String, dynamic> m) {
    final d = DateTime.tryParse(
      ((m['published_at'] ?? m['created_at']) ?? '') as String,
    )?.toLocal();
    return Notice(
      id: m['id'] as String,
      kind: m['kind'] as String,
      title: m['title'] as String,
      body: (m['body'] as String?) ?? '',
      dateLabel: d == null ? '' : frenchDate(d),
      townId: m['town_id'] as String?,
      status: (m['status'] as String?) ?? 'published',
      contact: m['contact'] as String?,
    );
  }

  static const Map<String, String> kinds = {
    'communique': 'Communiqué',
    'nomination': 'Nomination',
    'avis': 'Avis',
    'emploi': "Offre d'emploi",
    'evenement': 'Événement',
  };

  final String id;
  final String kind;
  final String title;
  final String body;
  final String dateLabel;
  final String? townId;
  final String status;
  final String? contact;

  String get kindLabel => kinds[kind] ?? kind;
}

class PollOption {
  const PollOption({required this.id, required this.letter, required this.label});

  final String id;
  final String letter;
  final String label;
}

class Poll {
  const Poll({required this.id, required this.question, required this.options});

  final String id;
  final String question;
  final List<PollOption> options;
}

class Ad {
  const Ad({
    required this.id,
    required this.placement,
    required this.advertiser,
    this.title,
    this.body,
    this.imageUrl,
    this.linkUrl,
  });

  factory Ad.fromMap(Map<String, dynamic> m) {
    return Ad(
      id: m['id'] as String,
      placement: m['placement'] as String,
      advertiser: m['advertiser'] as String,
      title: m['title'] as String?,
      body: m['body'] as String?,
      imageUrl: m['image_url'] as String?,
      linkUrl: m['link_url'] as String?,
    );
  }

  final String id;
  final String placement;
  final String advertiser;
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? linkUrl;
}
