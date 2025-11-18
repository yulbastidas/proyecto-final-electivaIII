import 'package:flutter/material.dart';

class AuthFormData {
  final bool isLogin;
  final String email;
  final String password;
  final String username;

  const AuthFormData({
    required this.isLogin,
    required this.email,
    required this.password,
    this.username = '',
  });
}

class AuthForm extends StatefulWidget {
  final Future<void> Function(AuthFormData data) onSubmit;

  const AuthForm({super.key, required this.onSubmit});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final data = AuthFormData(
      isLogin: _isLogin,
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
    );

    await widget.onSubmit(data);

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isLogin ? 'Inicia sesión' : 'Crea tu cuenta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (!_isLogin) ...[
            TextFormField(
              controller: _usernameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                label: Text('Usuario'),
                hintText: 'Tu nombre visible',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) {
                if (_isLogin) return null;
                if (v == null || v.trim().isEmpty) return 'Ingresa un usuario';
                if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 10),
          ],

          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              label: Text('Email'),
              hintText: 'tucorreo@ejemplo.com',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
              if (!v.contains('@') || !v.contains('.')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              label: const Text('Contraseña'),
              hintText: 'Mínimo 6 caracteres',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isLogin ? 'Entrar' : 'Registrarme'),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'Crear una' : 'Iniciar sesión'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
