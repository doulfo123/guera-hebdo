import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/models.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final meta = article.dateLabel.isEmpty
        ? article.category
        : '${article.category} · ${article.dateLabel.toUpperCase()}';
    return Material(
      color: Brand.paper,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Brand.line),
      ),
      child: InkWell(
        onTap: () => context.go('/article/${article.slug}'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Brand.red, width: 6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meta,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Brand.red,
                ),
              ),
              const SizedBox(height: 6),
              Text(article.title, style: displayStyle(28, height: 1.02)),
            ],
          ),
        ),
      ),
    );
  }
}
