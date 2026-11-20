import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/config.dart';
import 'data/content_repository.dart';
import 'data/demo_content_repository.dart';
import 'data/supabase_content_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Adresses propres (/article/mon-article) au lieu de /#/article/...
  usePathUrlStrategy();

  if (kUseSupabase) {
    await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
    contentRepo = SupabaseContentRepository();
  } else {
    contentRepo = DemoContentRepository();
  }

  runApp(const GueraHebdoApp());
}
