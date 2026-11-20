import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../data/content_repository.dart';
import '../../data/models.dart';
import '../../widgets/ad_slot.dart';
import '../../widgets/article_card.dart';
import '../../widgets/poll_card.dart';
import '../../widgets/site_footer.dart';
import 'notice_sheet.dart';
import 'search_dialog.dart';
import 'guera_map.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _place = 'mongo';
  late Future<(List<Town>, List<Article>)> _load;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<(List<Town>, List<Article>)> _fetch() async {
    final towns = await contentRepo.towns();
    final articles = await contentRepo.publishedArticles();
    return (towns, articles);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(String id) => setState(() => _place = id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.navy,
      body: FutureBuilder<(List<Town>, List<Article>)>(
        future: _load,
        builder: (context, snap) {
          if (snap.hasError) {
            return _LoadError(
              onRetry: () => setState(() => _load = _fetch()),
            );
          }
          final data = snap.data;
          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          final towns = data.$1;
          final articles = data.$2;
          final withNews = <String>{
            for (final a in articles)
              if (a.townId != null) a.townId!,
          };
          final map = GueraMap(
            towns: towns,
            townsWithNews: withNews,
            selected: _place,
            onSelect: _select,
            onSearch: () => showSearchDialog(context, articles),
          );
          final content = <Widget>[
            _PlaceSheet(
              place: _place,
              towns: towns,
              articles: articles,
              onSelect: _select,
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: const AdSlot(),
            ),
            const _NoticesSection(),
            const PollCard(),
            const SiteFooter(),
          ];
          return LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 900) {
                // Grand écran : la carte s'ouvre en grand, puis se range à gauche
                // pendant qu'on fait défiler et que le contenu apparaît à droite.
                final W = c.maxWidth;
                final H = c.maxHeight;
                final paneW = W * 5 / 11;
                final bigW = (H * 390 / 560).clamp(0.0, W * 0.9);
                final smallW = (bigW * 0.92).clamp(0.0, paneW - 24);
                final spacer = H * 0.72;
                return AnimatedBuilder(
                  animation: _scroll,
                  builder: (context, _) {
                    final off = _scroll.hasClients ? _scroll.offset : 0.0;
                    final t = Curves.easeInOut.transform((off / (H * 0.5)).clamp(0.0, 1.0));
                    final mw = bigW + (smallW - bigW) * t;
                    final mh = mw * 560 / 390;
                    final left = (W - bigW) / 2 + ((paneW - smallW) / 2 - (W - bigW) / 2) * t;
                    final top = (H - mh) / 2;
                    return Listener(
                      // La molette fonctionne aussi au-dessus de la carte.
                      onPointerSignal: (e) {
                        if (e is PointerScrollEvent && _scroll.hasClients) {
                          final max = _scroll.position.maxScrollExtent;
                          _scroll.jumpTo((_scroll.offset + e.scrollDelta.dy).clamp(0.0, max));
                        }
                      },
                      child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _scroll,
                          child: Column(
                            children: [
                              SizedBox(height: spacer, width: double.infinity),
                              Opacity(
                                opacity: t,
                                child: Container(
                                  margin: EdgeInsets.only(left: paneW),
                                  color: Colors.white,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 760),
                                      child: Column(children: content),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(left: left, top: top, width: mw, height: mh, child: map),
                        if (t < 0.15)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 12,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 1 - t / 0.15,
                                child: const Center(
                                  child: Text('Faites défiler ↓',
                                      style: TextStyle(color: Color(0xFFC9D6EE), fontSize: 13)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    );
                  },
                );
              }
              // Téléphone et tablette : une seule colonne.
              return SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: c.maxWidth >= 600 ? 640 : 560),
                    child: Column(children: [map, ...content]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Impossible de charger l'actualité",
              textAlign: TextAlign.center,
              style: displayStyle(34, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez votre connexion, puis réessayez.',
              style: TextStyle(color: Color(0xFFC9D6EE), fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: Brand.yellow,
                foregroundColor: Brand.ink,
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille blanche sous la carte : choix de la ville et infos du lieu.
class _PlaceSheet extends StatelessWidget {
  const _PlaceSheet({
    required this.place,
    required this.towns,
    required this.articles,
    required this.onSelect,
  });

  final String place;
  final List<Town> towns;
  final List<Article> articles;
  final ValueChanged<String> onSelect;

  Town? _town() {
    for (final t in towns) {
      if (t.id == place) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final town = _town();
    final name = town?.name ?? 'Toute la province';
    final subtitle = town == null
        ? 'PROVINCE DU GUÉRA · 4 DÉPARTEMENTS'
        : town.subtitleLabel;
    final list = town == null
        ? articles.where((a) => a.townId == null).toList()
        : articles.where((a) => a.townId == town.id).toList();

    final options = <(String, String)>[
      (provinceId, 'Toute la province'),
      for (final t in towns) (t.id, t.name),
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC9D3E6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: options.length,
              separatorBuilder: (context, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final o = options[i];
                final on = (town == null && o.$1 == provinceId) ||
                    (town != null && town.id == o.$1);
                return ChoiceChip(
                  label: Text(o.$2),
                  selected: on,
                  showCheckmark: false,
                  selectedColor: Brand.navy,
                  backgroundColor: const Color(0xFFEEF2F9),
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: on ? Colors.white : Brand.navy,
                  ),
                  onSelected: (_) => onSelect(o.$1),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: Brand.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(name.toUpperCase(), style: displayStyle(46, height: 0.95)),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  _EmptyPlace(name: name)
                else
                  for (final a in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ArticleCard(article: a),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlace extends StatelessWidget {
  const _EmptyPlace({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.paper,
        border: Border.all(color: const Color(0xFF8FA3C4), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pas encore d'info de $name.",
            style: displayStyle(26, height: 1.05),
          ),
          const SizedBox(height: 10),
          const Text(
            'Vous y vivez ou vous y étiez ? Envoyez-nous une info, une photo ou un communiqué.',
            style: TextStyle(fontSize: 16, height: 1.45, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => launchUrl(Uri.parse('mailto:$kContactEmail')),
            style: FilledButton.styleFrom(
              backgroundColor: Brand.red,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            child: const Text(kContactEmail),
          ),
        ],
      ),
    );
  }
}

/// Communiqués et annonces locales + bouton pour en proposer un.
class _NoticesSection extends StatefulWidget {
  const _NoticesSection();

  @override
  State<_NoticesSection> createState() => _NoticesSectionState();
}

class _NoticesSectionState extends State<_NoticesSection> {
  late final Future<List<Notice>> _future = contentRepo.publishedNotices().catchError((_) => <Notice>[]);
  late final Future<List<Town>> _towns = contentRepo.towns().catchError((_) => <Town>[]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Brand.paper,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMUNIQUÉS ET ANNONCES', style: displayStyle(24, color: Brand.navy)),
          const SizedBox(height: 12),
          FutureBuilder<List<Notice>>(
            future: _future,
            builder: (context, snap) {
              final items = snap.data ?? const <Notice>[];
              if (items.isEmpty) {
                return const Text('Aucune annonce pour le moment.', style: TextStyle(color: Brand.muted));
              }
              return Column(
                children: [
                  for (final n in items.take(6))
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () async => showNoticeSheet(context, n, await _towns),
                      child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Brand.line),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${n.kindLabel.toUpperCase()} · ${n.dateLabel}',
                              style: const TextStyle(color: Brand.blue, fontWeight: FontWeight.w700, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Brand.ink)),
                          if (n.body.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Brand.muted)),
                            ),
                          const SizedBox(height: 6),
                          const Text('Lire la suite →',
                              style: TextStyle(color: Brand.blue, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/communique'),
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Publier un communiqué'),
          ),
        ],
      ),
    );
  }
}
