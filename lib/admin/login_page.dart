import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/config.dart';
import '../app/theme.dart';
import 'admin_repository.dart';
import 'admin_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await adminRepo.signIn(_email.text, _password.text);
      if (mounted) context.go('/admin');
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.paper,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ESPACE RÉDACTION', style: displayStyle(30, color: Brand.navy)),
                const SizedBox(height: 4),
                const Text('Guéra Hebdo', style: TextStyle(color: Brand.muted)),
                const SizedBox(height: 24),
                if (!kUseSupabase)
                  const Text(
                    "Mode démo : la connexion n'est pas disponible. "
                    'Lancez le site avec SUPABASE_URL pour utiliser le back-office.',
                    style: TextStyle(color: Brand.red),
                  )
                else ...[
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Adresse e-mail', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Brand.red)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Connexion…' : 'Se connecter'),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(onPressed: () => context.go('/'), child: const Text('← Retour au site')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
