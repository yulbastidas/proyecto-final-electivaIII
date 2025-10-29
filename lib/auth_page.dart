import 'package:flutter/material.dart';
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
  bool isLogin = true;
  bool loading = false;
  String? error;

  Future<void> _submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final email = emailCtrl.text.trim();
      final pass = passCtrl.text.trim();
      if (email.isEmpty || pass.length < 6) {
        throw 'Correo y contraseña (mín. 6) son requeridos';
      }

      if (isLogin) {
        await supa.auth.signInWithPassword(email: email, password: pass);
      } else {
        final res = await supa.auth.signUp(email: email, password: pass);
        if (res.user == null) throw 'No se pudo crear el usuario';
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'PETS',
                    style: theme.textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLogin ? 'Bienvenido de nuevo' : 'Crea tu cuenta',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 22),
                  if (error != null)
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: loading ? null : _submit,
                      child: Text(
                        loading
                            ? 'Procesando...'
                            : (isLogin ? 'Acceso' : 'Crear cuenta'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
