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
  String countryCode = 'CO';
  bool isLogin = true;
  String? error;

  Future<void> _submit() async {
    setState(() => error = null);
    try {
      if (isLogin) {
        final res = await supa.auth.signInWithPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );
        if (res.user == null) throw 'Credenciales inválidas';
      } else {
        final res = await supa.auth.signUp(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );
        final uid = res.user!.id;
        // crea perfil con país
        await supa.from('profiles').upsert({
          'id': uid,
          'display_name': emailCtrl.text.split('@').first,
          'country_code': countryCode,
        });
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Iniciar sesión' : 'Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            if (!isLogin)
              DropdownButtonFormField(
                value: countryCode,
                items: const [
                  DropdownMenuItem(value: 'CO', child: Text('Colombia')),
                  DropdownMenuItem(value: 'MX', child: Text('México')),
                  DropdownMenuItem(value: 'AR', child: Text('Argentina')),
                  DropdownMenuItem(value: 'PE', child: Text('Perú')),
                ],
                onChanged: (v) => setState(() => countryCode = v as String),
                decoration: const InputDecoration(labelText: 'País'),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submit,
              child: Text(isLogin ? 'Entrar' : 'Registrarme'),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'Crear cuenta' : 'Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
