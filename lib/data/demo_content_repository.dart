import 'content_repository.dart';
import 'models.dart';

const String _placeholderText = "[Texte de l'article, à rédiger dans le back-office.]";

/// Données d'exemple pour développer sans serveur (mode démo).
/// Les titres viennent de vos publications Facebook ; les textes sont à écrire.
class DemoContentRepository implements ContentRepository {
  final Map<String, int> _votes = {};
  String? _myOption;

  static const List<Town> _towns = [
    Town(
      id: 'mongo',
      name: 'Mongo',
      department: 'Guéra',
      dx: 0.58,
      dy: 0.52,
      subtitle: 'CHEF-LIEU DE LA PROVINCE · DÉPARTEMENT DU GUÉRA',
    ),
    Town(id: 'bitkine', name: 'Bitkine', department: 'Abtouyour', dx: 0.24, dy: 0.58),
    Town(id: 'bangbang', name: 'Bang Bang', department: 'Abtouyour', dx: 0.28, dy: 0.42),
    Town(id: 'baro', name: 'Baro', department: 'Guéra', dx: 0.46, dy: 0.62),
    Town(id: 'niergui', name: 'Niergui', department: 'Guéra', dx: 0.59, dy: 0.38),
    Town(id: 'melfi', name: 'Mélfi', department: 'Barh Signaka', dx: 0.42, dy: 0.77),
    Town(id: 'chinguil', name: 'Chinguil', department: 'Barh Signaka', dx: 0.62, dy: 0.79),
    Town(id: 'mokofi', name: 'Mokofi', department: 'Barh Signaka', dx: 0.26, dy: 0.71),
    Town(id: 'mangalme', name: 'Mangalmé', department: 'Mangalmé', dx: 0.82, dy: 0.49),
    Town(id: 'eref', name: 'Eref', department: 'Mangalmé', dx: 0.76, dy: 0.61),
    Town(id: 'kouka', name: 'Kouka Margni', department: 'Mangalmé', dx: 0.82, dy: 0.38),
    Town(id: 'bitchotchi', name: 'Bitchotchi', department: 'Mangalmé', dx: 0.77, dy: 0.70),
  ];

  static const List<Article> _articles = [
    Article(
      slug: 'festival-cultures-mongo',
      title: 'Mongo accueille la 12e édition du Festival des cultures',
      category: 'CULTURE',
      summary: 'Les 12 et 13 décembre 2026.',
      dateLabel: '11 nov. 2026',
      body: [_placeholderText],
      townId: 'mongo',
    ),
    Article(
      slug: 'formation-points-focaux-mongo',
      title: "Formation des points focaux à l'Espace Betna Mongo",
      category: 'ATELIER',
      summary: 'Du 10 au 12 novembre 2026.',
      dateLabel: '11 nov. 2026',
      body: [_placeholderText],
      townId: 'mongo',
    ),
    Article(
      slug: 'eclairage-public-bitkine',
      title: 'La commune de Bitkine renforce son éclairage public',
      category: 'BITKINE',
      summary: "Une opération de réhabilitation de l'éclairage public.",
      dateLabel: '11 nov. 2026',
      body: [_placeholderText],
      townId: 'bitkine',
    ),
    Article(
      slug: 'conseil-provincial-travaux-urgence',
      title: "Le Conseil provincial du Guéra réceptionne les travaux d'urgence",
      category: 'GUÉRA',
      summary: 'Réception effectuée le mercredi 11 novembre 2026.',
      dateLabel: '11 nov. 2026',
      body: [_placeholderText],
    ),
    Article(
      slug: 'festival-pastoral-abdelaziz-hassan',
      title: 'Abdelaziz Hassan, président des éleveurs du Guéra, décroche le 3e prix',
      category: 'FESTIVAL PASTORAL',
      summary: 'Une distinction qui honore les acteurs pastoraux de la province.',
      dateLabel: '11 nov. 2026',
      body: [_placeholderText],
    ),
  ];

  static const Poll _poll = Poll(
    id: 'demo-poll',
    question: 'Quel est le plus grand défi du Guéra ?',
    options: [
      PollOption(id: 'demo-a', letter: 'A', label: 'Infrastructures et services sociaux'),
      PollOption(id: 'demo-b', letter: 'B', label: 'Emploi et entrepreneuriat des jeunes'),
      PollOption(id: 'demo-c', letter: 'C', label: 'Agriculture, élevage et économie locale'),
      PollOption(id: 'demo-d', letter: 'D', label: 'Valorisation et coordination des initiatives'),
    ],
  );

  @override
  Future<List<Town>> towns() async => _towns;

  @override
  Future<List<Article>> publishedArticles() async => _articles;

  @override
  Future<Article?> articleBySlug(String slug) async {
    for (final a in _articles) {
      if (a.slug == slug) return a;
    }
    return null;
  }

  @override
  Future<Poll?> activePoll() async => _poll;

  @override
  Future<void> vote({required String optionId, required String voterKey}) async {
    if (_myOption != null) {
      _votes[_myOption!] = (_votes[_myOption!] ?? 1) - 1;
    }
    _myOption = optionId;
    _votes[optionId] = (_votes[optionId] ?? 0) + 1;
  }

  @override
  Future<Map<String, int>> pollResults(String pollId) async => Map.of(_votes);

  @override
  Future<Ad?> ad(String placement) async => null;

  static const List<Notice> _notices = [
    Notice(
      id: 'demo-n1',
      kind: 'nomination',
      title: 'M. Aguid Kodo nommé SG programme La Tchadienne FEP-Tchad',
      body: 'Décision N°00088/DRH/DG/SNE/CA/PCA/FEP26 du 5 nov. 2026.',
      dateLabel: '11 nov. 2026',
    ),
    Notice(
      id: 'demo-n2',
      kind: 'evenement',
      title: "Atelier de formation des points focaux à l'Espace Betna Mongo",
      body: 'Du 10 au 12 novembre 2026.',
      dateLabel: '11 nov. 2026',
      townId: 'mongo',
    ),
  ];

  @override
  Future<List<Notice>> publishedNotices() async => _notices;

  @override
  Future<void> submitNotice({
    required String kind,
    required String title,
    required String body,
    String? townId,
    String? contact,
  }) async {
    // Mode démo : rien n'est envoyé. Avec Supabase, le communiqué attend la validation.
  }
}
