import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final supa = Supabase.instance.client;

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String countryCode = 'CO';
  bool isLogin = true;
  String? error;
  bool loading = false;

  // --- Helpers --------------------------------------------------------------

  String _sanitizeEmail(String raw) {
    String email = raw
        .toLowerCase()
        .trim()
        // elimina espacios normales
        .replaceAll(RegExp(r'\s+'), '')
        // NBSP
        .replaceAll('\u00A0', '')
        // zero-width chars
        .replaceAll(RegExp(r'[\u2000-\u200D\u2060\uFEFF]'), '')
        // cualquier carácter no permitido
        .replaceAll(RegExp(r'[^a-z0-9@._+\-]'), '');
    return email;
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  // --- Submit ---------------------------------------------------------------

  Future<void> _submit() async {
    setState(() {
      error = null;
      loading = true;
    });

    try {
      final email = _sanitizeEmail(emailCtrl.text);
      final pass = passCtrl.text.trim();

      // Logs útiles en consola
      debugPrint(
        'EMAIL_DEBUG="$email" codeUnits=${email.codeUnits} length=${email.length}',
      );

      // Validaciones locales rápidas
      if (!_isValidEmail(email)) {
        setState(() {
          error = 'Email inválido';
          loading = false;
        });
        return;
      }
      if (pass.length < 6) {
        setState(() {
          error = 'La contraseña debe tener al menos 6 caracteres';
          loading = false;
        });
        return;
      }

      if (isLogin) {
        await supa.auth.signInWithPassword(email: email, password: pass);
      } else {
        final res = await supa.auth.signUp(email: email, password: pass);

        // Si confirm email está ON, user puede venir null hasta confirmar.
        final uid = res.user?.id ?? supa.auth.currentUser?.id;
        if (uid == null) {
          throw const AuthException(
            'Revisa tu correo para confirmar la cuenta.',
          );
        }

        // Crea/actualiza perfil con país
        await supa.from('profiles').upsert({
          'id': uid,
          'display_name': email.split('@').first,
          'country_code': countryCode,
        });
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      // Mensaje exacto de Supabase (user already registered, signups not allowed, etc.)
      debugPrint('AUTH ERROR: status=${e.statusCode} msg=${e.message}');
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'Iniciar sesión' : 'Crear cuenta';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),

            // Email
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              inputFormatters: [
                // Opcional: restringe lo que se puede tipear
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._+\-]')),
              ],
            ),
            const SizedBox(height: 8),

            // Password
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
            ),

            // País (solo en registro)
            if (!isLogin) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: countryCode,
                items: const [
                  DropdownMenuItem(value: 'CO', child: Text('Colombia')),
                  DropdownMenuItem(value: 'AR', child: Text('Argentina')),
                  DropdownMenuItem(value: 'MX', child: Text('México')),
                  DropdownMenuItem(value: 'PE', child: Text('Perú')),
                ],
                onChanged: (v) => setState(() => countryCode = v ?? 'CO'),
                decoration: const InputDecoration(labelText: 'País'),
              ),
            ],

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isLogin ? 'Entrar' : 'Registrarme'),
            ),
            TextButton(
              onPressed: loading
                  ? null
                  : () => setState(() {
                      isLogin = !isLogin;
                      error = null;
                    }),
              child: Text(isLogin ? 'Crear cuenta' : 'Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}
