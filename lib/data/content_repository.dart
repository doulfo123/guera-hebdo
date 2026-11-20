import 'models.dart';

/// Toutes les données du site passent par ici. Deux implémentations :
/// Supabase (production) et démo (sans serveur, pour développer).
abstract class ContentRepository {
  Future<List<Town>> towns();

  /// Articles publiés, du plus récent au plus ancien.
  Future<List<Article>> publishedArticles();

  Future<Article?> articleBySlug(String slug);

  Future<Poll?> activePoll();

  /// Enregistre (ou change) le vote de cet appareil.
  Future<void> vote({required String optionId, required String voterKey});

  /// Nombre de votes par option (clé : id de l'option).
  Future<Map<String, int>> pollResults(String pollId);

  /// Publicité à afficher pour cet emplacement, ou null s'il n'y en a pas.
  Future<Ad?> ad(String placement);

  /// Communiqués publiés, du plus récent au plus ancien.
  Future<List<Notice>> publishedNotices();

  /// Propose un communiqué : il reste « en attente » jusqu'à validation par l'équipe.
  Future<void> submitNotice({
    required String kind,
    required String title,
    required String body,
    String? townId,
    String? contact,
  });
}

/// Dépôt de données utilisé par toute l'application (choisi dans main.dart).
late ContentRepository contentRepo;
