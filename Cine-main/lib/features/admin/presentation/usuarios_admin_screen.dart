import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/cs_button.dart';
import '../../auth/domain/app_user.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';

class UsuariosAdminScreen extends StatefulWidget {
  const UsuariosAdminScreen({super.key});

  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
  static const _roles = ['trabajador', 'administrador', 'cliente'];
  int _tab = 0;
  late Future<List<AppUser>> _future;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _future = _repo.usuarios(rol: _roles[_tab]);
  }

  void _reload() => setState(() => _future = _repo.usuarios(rol: _roles[_tab]));

  Future<void> _add() async {
    final ok = await showAdminSheet<bool>(context, _UsuarioForm(repo: _repo));
    if (ok == true) _reload();
  }

  Future<void> _toggle(AppUser u) async {
    try {
      await _repo.editarUsuario(u.id, activo: !u.activo);
      if (mounted) _reload();
    } catch (e) {
      if (mounted) adminSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Usuarios',
      onAdd: _add,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: List.generate(_roles.length, (i) {
                const labels = ['Trabajadores', 'Admins', 'Clientes'];
                final sel = i == _tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(labels[i]),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      _tab = i;
                      _reload();
                    }),
                    selectedColor: AppColors.red,
                    backgroundColor: AppColors.surface,
                    labelStyle:
                        TextStyle(color: sel ? Colors.white : AppColors.text),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.red));
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('${snap.error}',
                          style: const TextStyle(color: AppColors.textDim)));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                      child: Text('Sin usuarios en esta categoría',
                          style: TextStyle(color: AppColors.textDim)));
                }
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: items
                      .map((u) => AdminTile(
                            title: u.nombre,
                            subtitle:
                                '${u.email}${u.turno != null ? ' · ${u.turno}' : ''}${u.activo ? '' : ' · DESACTIVADO'}',
                            trailing: Switch(
                              value: u.activo,
                              activeThumbColor: AppColors.green,
                              onChanged: (_) => _toggle(u),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsuarioForm extends StatefulWidget {
  final AdminRepository repo;
  const _UsuarioForm({required this.repo});
  @override
  State<_UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<_UsuarioForm> {
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _rol = 'trabajador';
  String? _turno = 'manana';
  bool _busy = false;

  Future<void> _crear() async {
    final nombre = _nombre.text.trim();
    final email = _email.text.trim();
    final pass = _password.text;
    if (nombre.isEmpty || email.isEmpty || pass.length < 6) {
      adminSnack(context, 'Completa nombre, correo y contraseña (6+)');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repo.crearUsuario(
        nombre: nombre,
        email: email,
        password: pass,
        rol: _rol,
        turno: _rol == 'trabajador' ? _turno : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        adminSnack(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nuevo usuario', style: AppTextStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          AdminField(label: 'Nombre', controller: _nombre),
          AdminField(
              label: 'Correo',
              controller: _email,
              keyboardType: TextInputType.emailAddress),
          AdminField(label: 'Contraseña', controller: _password, obscure: true),
          Row(
            children: ['trabajador', 'administrador'].map((r) {
              final sel = r == _rol;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(r == 'trabajador' ? 'Trabajador' : 'Administrador'),
                  selected: sel,
                  onSelected: (_) => setState(() => _rol = r),
                  selectedColor: AppColors.red,
                  backgroundColor: AppColors.surface,
                  labelStyle:
                      TextStyle(color: sel ? Colors.white : AppColors.text),
                ),
              );
            }).toList(),
          ),
          if (_rol == 'trabajador') ...[
            const SizedBox(height: 12),
            Row(
              children: ['manana', 'tarde', 'noche'].map((t) {
                final sel = t == _turno;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: sel,
                    onSelected: (_) => setState(() => _turno = t),
                    selectedColor: AppColors.amber,
                    backgroundColor: AppColors.surface,
                    labelStyle:
                        TextStyle(color: sel ? Colors.black : AppColors.text),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          CSButton(
            label: _busy ? 'Creando…' : 'Crear usuario',
            onPressed: _busy ? null : _crear,
            icon: const Icon(Icons.add),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
