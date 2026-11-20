import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Clé aléatoire propre à l'appareil, pour limiter à un vote par sondage.
/// Protection simple : elle limite les doublons mais n'arrête pas un utilisateur déterminé.
Future<String> voterKey() async {
  final prefs = await SharedPreferences.getInstance();
  var key = prefs.getString('voter_key');
  if (key == null || key.length < 16) {
    final rnd = Random.secure();
    key = List.generate(32, (_) => rnd.nextInt(16).toRadixString(16)).join();
    await prefs.setString('voter_key', key);
  }
  return key;
}

/// Option déjà choisie par cet appareil pour un sondage (null si aucun vote).
Future<String?> savedVote(String pollId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('vote_$pollId');
}

Future<void> saveVote(String pollId, String optionId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('vote_$pollId', optionId);
}
