/// Adresse du site. À remplacer quand le nom de domaine sera acheté.
const String kSiteUrl = 'https://guerahebdo.com';

/// Adresse e-mail officielle (à confirmer : une seule adresse pour tout le média).
const String kContactEmail = 'guerahebdo@gmail.com';

/// Clés Supabase, données au lancement :
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
/// La clé « anon » est publique par conception : c'est la sécurité RLS
/// de la base qui protège les données. Ne mettez JAMAIS la clé « service_role » ici.
const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://unowcsikpxcbmxqzukmn.supabase.co',
);
const String kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  // Clé « publishable » du projet : publique par conception, sans danger dans le code.
  defaultValue: 'sb_publishable_X1LAKHCUsZ8dz7Qu_JfHUA_VJU_WctR',
);

/// Sans clés, l'application tourne en mode démo (données d'exemple).
const bool kUseSupabase = kSupabaseUrl != '' && kSupabaseAnonKey != '';
