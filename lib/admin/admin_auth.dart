import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/config.dart';
import 'admin_repository.dart';

/// État de connexion de l'équipe. Sert aussi à rafraîchir le routeur.
class AdminAuth extends ChangeNotifier {
  AdminAuth() {
    if (kUseSupabase) {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        _profile = null;
        notifyListeners();
      });
    }
  }

  StreamSubscription<AuthState>? _sub;
  Future<Profile?>? _profile;

  bool get signedIn => kUseSupabase && Supabase.instance.client.auth.currentSession != null;

  Future<Profile?> loadProfile() => _profile ??= adminRepo.fetchProfile();

  Future<void> signOut() async {
    await adminRepo.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final AdminAuth adminAuth = AdminAuth();
