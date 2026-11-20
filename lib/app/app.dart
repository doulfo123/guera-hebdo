import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../admin/admin_auth.dart';
import '../admin/ads_admin_page.dart';
import '../admin/article_editor_page.dart';
import '../admin/articles_page.dart';
import '../admin/login_page.dart';
import '../admin/notices_admin_page.dart';
import '../admin/poll_admin_page.dart';
import '../features/article/article_page.dart';
import '../features/communique/communique_page.dart';
import '../features/home/home_page.dart';
import 'theme.dart';

final GoRouter _router = GoRouter(
  refreshListenable: adminAuth,
  redirect: (context, state) {
    final path = state.uri.path;
    if (!path.startsWith('/admin')) return null;
    final signedIn = adminAuth.signedIn;
    if (!signedIn && path != '/admin/login') return '/admin/login';
    if (signedIn && path == '/admin/login') return '/admin';
    return null;
  },
  routes: [
    GoRoute(path: '/communique', builder: (c, s) => const CommuniquePage()),
    GoRoute(path: '/admin/login', builder: (c, s) => const LoginPage()),
    GoRoute(path: '/admin', builder: (c, s) => const AdminArticlesPage()),
    GoRoute(path: '/admin/article/new', builder: (c, s) => const ArticleEditorPage()),
    GoRoute(
      path: '/admin/article/:id',
      builder: (c, s) => ArticleEditorPage(articleId: s.pathParameters['id']),
    ),
    GoRoute(path: '/admin/notices', builder: (c, s) => const AdminNoticesPage()),
    GoRoute(path: '/admin/poll', builder: (c, s) => const AdminPollPage()),
    GoRoute(path: '/admin/ads', builder: (c, s) => const AdminAdsPage()),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/article/:slug',
      builder: (context, state) =>
          ArticlePage(slug: state.pathParameters['slug'] ?? ''),
    ),
  ],
);

class GueraHebdoApp extends StatelessWidget {
  const GueraHebdoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Guéra Hebdo',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}
