import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/cs_button.dart';
import '../../snacks/domain/models.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';

class DulceriaAdminScreen extends StatelessWidget {
  const DulceriaAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              const _DulceriaHeader(),
              const TabBar(
                labelColor: AppColors.red,
                unselectedLabelColor: AppColors.textDim,
                indicatorColor: AppColors.red,
                tabs: [Tab(text: 'Productos'), Tab(text: 'Combos')],
              ),
              const Expanded(
                child: TabBarView(
                  children: [_ProductosTab(), _CombosTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DulceriaHeader extends StatelessWidget {
  const _DulceriaHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text('Dulcería',
              style: AppTextStyles.display.copyWith(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------- Productos ----------
class _ProductosTab extends StatefulWidget {
  const _ProductosTab();
  @override
  State<_ProductosTab> createState() => _ProductosTabState();
}

class _ProductosTabState extends State<_ProductosTab> {
  late Future<List<Producto>> _future;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _future = _repo.productos();
  }

  void _reload() => setState(() => _future = _repo.productos());

  Future<void> _add() async {
    final ok = await showAdminSheet<bool>(context, _ProductoForm(repo: _repo));
    if (ok == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<Producto>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.red));
            }
            final items = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              children: items
                  .map((p) => AdminTile(
                      title: p.nombre,
                      subtitle:
                          'S/${p.precio.toStringAsFixed(2)}${p.categoria != null ? ' · ${p.categoria}' : ''}'))
                  .toList(),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: AppColors.red,
            onPressed: _add,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _ProductoForm extends StatefulWidget {
  final AdminRepository repo;
  const _ProductoForm({required this.repo});
  @override
  State<_ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<_ProductoForm> {
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _categoria = TextEditingController();
  bool _busy = false;

  Future<void> _crear() async {
    final nombre = _nombre.text.trim();
    final precio = double.tryParse(_precio.text.trim());
    if (nombre.isEmpty || precio == null) {
      adminSnack(context, 'Completa nombre y precio');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repo.crearProducto(
          nombre: nombre,
          precio: precio,
          categoria: _categoria.text.trim().isEmpty ? null : _categoria.text.trim());
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
        Text('Nuevo producto', style: AppTextStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        AdminField(label: 'Nombre', controller: _nombre),
        AdminField(
            label: 'Precio',
            controller: _precio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        AdminField(label: 'Categoría (opcional)', controller: _categoria),
        CSButton(
          label: _busy ? 'Creando…' : 'Crear producto',
          onPressed: _busy ? null : _crear,
          icon: const Icon(Icons.add),
          fullWidth: true,
        ),
      ],
    );
  }
}

// ---------- Combos ----------
class _CombosTab extends StatefulWidget {
  const _CombosTab();
  @override
  State<_CombosTab> createState() => _CombosTabState();
}

class _CombosTabState extends State<_CombosTab> {
  late Future<List<Combo>> _future;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _future = _repo.combos();
  }

  void _reload() => setState(() => _future = _repo.combos());

  Future<void> _add() async {
    final productos = await _repo.productos();
    if (!mounted) return;
    if (productos.isEmpty) {
      adminSnack(context, 'Primero crea productos para armar un combo');
      return;
    }
    final ok = await showAdminSheet<bool>(
        context, _ComboForm(repo: _repo, productos: productos));
    if (ok == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<Combo>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.red));
            }
            final items = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              children: items
                  .map((c) => AdminTile(
                      title: c.nombre,
                      subtitle: 'S/${c.precio.toStringAsFixed(2)}'))
                  .toList(),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: AppColors.red,
            onPressed: _add,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _ComboForm extends StatefulWidget {
  final AdminRepository repo;
  final List<Producto> productos;
  const _ComboForm({required this.repo, required this.productos});
  @override
  State<_ComboForm> createState() => _ComboFormState();
}

class _ComboFormState extends State<_ComboForm> {
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final Set<int> _selected = {};
  bool _busy = false;

  Future<void> _crear() async {
    final nombre = _nombre.text.trim();
    final precio = double.tryParse(_precio.text.trim());
    if (nombre.isEmpty || precio == null || _selected.isEmpty) {
      adminSnack(context, 'Completa nombre, precio y elige productos');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repo.crearCombo(
        nombre: nombre,
        precio: precio,
        items: _selected.map((id) => {'producto_id': id, 'cantidad': 1}).toList(),
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
          Text('Nuevo combo', style: AppTextStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          AdminField(label: 'Nombre', controller: _nombre),
          AdminField(
              label: 'Precio',
              controller: _precio,
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 4),
          Text('Productos incluidos', style: AppTextStyles.eyebrow),
          ...widget.productos.map((p) => CheckboxListTile(
                value: _selected.contains(p.id),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selected.add(p.id);
                  } else {
                    _selected.remove(p.id);
                  }
                }),
                title: Text(p.nombre,
                    style: const TextStyle(color: AppColors.text)),
                activeColor: AppColors.red,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              )),
          const SizedBox(height: 8),
          CSButton(
            label: _busy ? 'Creando…' : 'Crear combo',
            onPressed: _busy ? null : _crear,
            icon: const Icon(Icons.add),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
