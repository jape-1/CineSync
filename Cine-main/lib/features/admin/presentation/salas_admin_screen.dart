import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/cs_button.dart';
import '../data/admin_repository.dart';
import '../domain/models.dart';
import 'admin_common.dart';

class SalasAdminScreen extends StatefulWidget {
  const SalasAdminScreen({super.key});

  @override
  State<SalasAdminScreen> createState() => _SalasAdminScreenState();
}

class _SalasAdminScreenState extends State<SalasAdminScreen> {
  late Future<List<Sala>> _future;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _future = _repo.salas();
  }

  void _reload() => setState(() => _future = _repo.salas());

  Future<void> _add() async {
    final ok = await showAdminSheet<bool>(context, _SalaForm(repo: _repo));
    if (ok == true) _reload();
  }

  Future<void> _eliminar(Sala s) async {
    try {
      await _repo.eliminarSala(s.id);
      if (mounted) {
        adminSnack(context, 'Sala eliminada');
        _reload();
      }
    } catch (e) {
      if (mounted) adminSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Salas',
      onAdd: _add,
      body: FutureBuilder<List<Sala>>(
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
                child: Text('Sin salas. Usa + para crear una.',
                    style: TextStyle(color: AppColors.textDim)));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: items
                .map((s) => AdminTile(
                      title: '${s.nombre} · ${s.tipo}',
                      subtitle:
                          '${s.filas}×${s.columnas} = ${s.capacidad} asientos',
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.textDim, size: 20),
                        onPressed: () => _eliminar(s),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _SalaForm extends StatefulWidget {
  final AdminRepository repo;
  const _SalaForm({required this.repo});

  @override
  State<_SalaForm> createState() => _SalaFormState();
}

class _SalaFormState extends State<_SalaForm> {
  final _nombre = TextEditingController();
  final _filas = TextEditingController(text: '5');
  final _columnas = TextEditingController(text: '8');
  String _tipo = '2D';
  bool _busy = false;

  Future<void> _crear() async {
    final nombre = _nombre.text.trim();
    final filas = int.tryParse(_filas.text.trim());
    final columnas = int.tryParse(_columnas.text.trim());
    if (nombre.isEmpty || filas == null || columnas == null) {
      adminSnack(context, 'Completa nombre, filas y columnas');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repo
          .crearSala(nombre: nombre, tipo: _tipo, filas: filas, columnas: columnas);
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nueva sala', style: AppTextStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        AdminField(label: 'Nombre', controller: _nombre),
        Row(
          children: ['2D', '3D', 'VIP'].map((t) {
            final sel = t == _tipo;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => setState(() => _tipo = t),
                selectedColor: AppColors.red,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.text),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: AdminField(
                    label: 'Filas',
                    controller: _filas,
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(
                child: AdminField(
                    label: 'Columnas',
                    controller: _columnas,
                    keyboardType: TextInputType.number)),
          ],
        ),
        CSButton(
          label: _busy ? 'Creando…' : 'Crear sala',
          onPressed: _busy ? null : _crear,
          icon: const Icon(Icons.add),
          fullWidth: true,
        ),
      ],
    );
  }
}
