import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/data/auth_repository.dart';

/// Diálogo de recuperación de contraseña en dos pasos:
/// 1) pide el correo → el backend devuelve un reset_token (modo dev)
/// 2) pide la nueva contraseña → la establece con ese token.
Future<void> showForgotPasswordDialog(BuildContext context) {
  final repo = context.read<AuthRepository>();
  return showDialog(
    context: context,
    builder: (_) => _ForgotDialog(repo: repo),
  );
}

class _ForgotDialog extends StatefulWidget {
  final AuthRepository repo;
  const _ForgotDialog({required this.repo});

  @override
  State<_ForgotDialog> createState() => _ForgotDialogState();
}

class _ForgotDialogState extends State<_ForgotDialog> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _resetToken;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestToken() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await widget.repo.forgotPassword(_emailCtrl.text.trim());
      setState(() => _resetToken = token);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.resetPassword(_resetToken!, _passCtrl.text);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada, inicia sesión')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step2 = _resetToken != null;
    return AlertDialog(
      title: Text(step2 ? 'Nueva contraseña' : 'Recuperar contraseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!step2)
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            )
          else
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _busy ? null : (step2 ? _reset : _requestToken),
          child: Text(step2 ? 'Guardar' : 'Continuar'),
        ),
      ],
    );
  }
}
