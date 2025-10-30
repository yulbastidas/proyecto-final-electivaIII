import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  bool signup = false;

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      if (signup) {
        await Supabase.instance.client.auth.signUp(
          email: email.text.trim(),
          password: pass.text.trim(),
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Pest • Login',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pass,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: signup,
                        onChanged: (v) => setState(() => signup = v ?? false),
                      ),
                      const Text('Crear cuenta'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: loading ? null : _submit,
                    child: Text(
                      loading ? '...' : (signup ? 'Register' : 'Login'),
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
