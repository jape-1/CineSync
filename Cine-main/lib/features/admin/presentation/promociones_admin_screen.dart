import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/cs_button.dart';
import '../data/admin_repository.dart';
import '../domain/models.dart';
import 'admin_common.dart';

class PromocionesAdminScreen extends StatefulWidget {
  const PromocionesAdminScreen({super.key});

  @override
  State<PromocionesAdminScreen> createState() => _PromocionesAdminScreenState();
}

class _PromocionesAdminScreenState extends State<PromocionesAdminScreen> {
  late Future<List<Promocion>> _future;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _future = _repo.promociones();
  }

  void _reload() => setState(() => _future = _repo.promociones());

  Future<void> _add() async {
    final ok = await showAdminSheet<bool>(context, _PromoForm(repo: _repo));
    if (ok == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Promociones',
      onAdd: _add,
      body: FutureBuilder<List<Promocion>>(
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
                child: Text('Sin promociones. Usa + para crear una.',
                    style: TextStyle(color: AppColors.textDim)));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: items
                .map((p) => AdminTile(
                      title: '${p.codigo} · ${p.valorLegible}',
                      subtitle:
                          '${p.descripcion ?? p.tipoDescuento} · usos ${p.usosActuales}${p.usosMaximos != null ? '/${p.usosMaximos}' : ''}${p.activo ? '' : ' · INACTIVA'}',
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _PromoForm extends StatefulWidget {
  final AdminRepository repo;
  const _PromoForm({required this.repo});
  @override
  State<_PromoForm> createState() => _PromoFormState();
}

class _PromoFormState extends State<_PromoForm> {
  final _codigo = TextEditingController();
  final _valor = TextEditingController();
  final _descripcion = TextEditingController();
  final _usos = TextEditingController();
  String _tipo = 'porcentaje';
  bool _busy = false;

  Future<void> _crear() async {
    final codigo = _codigo.text.trim().toUpperCase();
    final valor = double.tryParse(_valor.text.trim());
    if (codigo.isEmpty || valor == null) {
      adminSnack(context, 'Completa código y valor');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repo.crearPromocion(
        codigo: codigo,
        tipoDescuento: _tipo,
        valor: valor,
        descripcion:
            _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
        usosMaximos: int.tryParse(_usos.text.trim()),
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
          Text('Nueva promoción', style: AppTextStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          AdminField(label: 'Código', controller: _codigo),
          Row(
            children: ['porcentaje', 'monto'].map((t) {
              final sel = t == _tipo;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t == 'porcentaje' ? '% Porcentaje' : 'S/ Monto'),
                  selected: sel,
                  onSelected: (_) => setState(() => _tipo = t),
                  selectedColor: AppColors.red,
                  backgroundColor: AppColors.surface,
                  labelStyle:
                      TextStyle(color: sel ? Colors.white : AppColors.text),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          AdminField(
              label: _tipo == 'porcentaje' ? 'Valor (%)' : 'Valor (S/)',
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          AdminField(label: 'Descripción (opcional)', controller: _descripcion),
          AdminField(
              label: 'Usos máximos (opcional)',
              controller: _usos,
              keyboardType: TextInputType.number),
          CSButton(
            label: _busy ? 'Creando…' : 'Crear promoción',
            onPressed: _busy ? null : _crear,
            icon: const Icon(Icons.add),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
