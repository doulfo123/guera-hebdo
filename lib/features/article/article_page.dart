import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../data/content_repository.dart';
import '../../data/models.dart';
import '../../widgets/ad_slot.dart';
import '../../widgets/article_card.dart';
import '../../widgets/site_footer.dart';
import '../../widgets/wordmark.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key, required this.slug});

  final String slug;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticleData {
  const _ArticleData(this.article, this.town, this.related);

  final Article? article;
  final Town? town;
  final List<Article> related;
}

class _ArticlePageState extends State<ArticlePage> {
  late Future<_ArticleData> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  void didUpdateWidget(covariant ArticlePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) _load = _fetch();
  }

  Future<_ArticleData> _fetch() async {
    final article = await contentRepo.articleBySlug(widget.slug);
    if (article == null) return const _ArticleData(null, null, []);
    final all = await contentRepo.publishedArticles();
    Town? town;
    if (article.townId != null) {
      final towns = await contentRepo.towns();
      for (final t in towns) {
        if (t.id == article.townId) town = t;
      }
    }
    final related = all.where((x) => x.slug != article.slug).take(2).toList();
    return _ArticleData(article, town, related);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          tooltip: "Retour à l'accueil",
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Wordmark(),
      ),
      body: FutureBuilder<_ArticleData>(
        future: _load,
        builder: (context, snap) {
          if (snap.hasError) {
            return _Message(
              title: "Impossible de charger l'article",
              action: 'Réessayer',
              onTap: () => setState(() => _load = _fetch()),
            );
          }
          final data = snap.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final article = data.article;
          if (article == null) {
            return _Message(
              title: 'Article introuvable',
              action: "Retour à l'accueil",
              onTap: () => context.go('/'),
            );
          }
          return _ArticleView(
            article: article,
            town: data.town,
            related: data.related,
          );
        },
      ),
    );
  }
}

class _ArticleView extends StatelessWidget {
  const _ArticleView({
    required this.article,
    required this.town,
    required this.related,
  });

  final Article article;
  final Town? town;
  final List<Article> related;

  @override
  Widget build(BuildContext context) {
    final a = article;
    final url = '$kSiteUrl/article/${a.slug}';
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Brand.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            a.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          town?.name ?? 'Guéra',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Brand.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(a.title, style: displayStyle(38, height: 1.02)),
                    if (a.summary.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        a.summary,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.4,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Brand.blue,
                          child: Text(
                            'GH',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Par ${a.author}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if (a.dateLabel.isNotEmpty)
                              Text(
                                a.dateLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Brand.muted,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Cover(url: a.coverUrl, label: a.title),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'https://wa.me/?text=${Uri.encodeComponent('${a.title} $url')}',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text('WhatsApp'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.whatsapp,
                          minimumSize: const Size(0, 48),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.blue,
                          minimumSize: const Size(0, 48),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('Facebook'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Copier le lien',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lien copié')),
                        );
                      },
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        side: const BorderSide(color: Brand.blue, width: 1.5),
                        foregroundColor: Brand.blue,
                      ),
                      icon: const Icon(Icons.link),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in a.body)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          p,
                          style: const TextStyle(fontSize: 19, height: 1.6),
                        ),
                      ),
                    if (a.videoUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(a.videoUrl!),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Voir la vidéo sur Facebook'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: Brand.blue,
                            side: const BorderSide(color: Brand.blue, width: 1.5),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    const AdSlot(placement: 'inline_banner'),
                  ],
                ),
              ),
              if (related.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('À LIRE AUSSI', style: displayStyle(26, color: Brand.blue)),
                      const SizedBox(height: 12),
                      for (final r in related)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ArticleCard(article: r),
                        ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 24),
              const SiteFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo de l'article, ou un dégradé aux couleurs du Guéra s'il n'y en a pas.
class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.label});

  final String? url;
  final String label;

  @override
  Widget build(BuildContext context) {
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B4FA8), Color(0xFFB2455A), Color(0xFFE8572F)],
        ),
      ),
      child: SizedBox.expand(),
    );
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: url == null
          ? fallback
          : Image.network(
              url!,
              fit: BoxFit.cover,
              semanticLabel: label,
              errorBuilder: (context, error, stack) => fallback,
            ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.action, required this.onTap});

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: displayStyle(38)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
