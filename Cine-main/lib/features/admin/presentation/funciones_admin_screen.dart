import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/cs_button.dart';
import '../../catalog/domain/models.dart';
import '../data/admin_repository.dart';
import '../domain/models.dart';
import 'admin_common.dart';

class FuncionesAdminScreen extends StatefulWidget {
  const FuncionesAdminScreen({super.key});

  @override
  State<FuncionesAdminScreen> createState() => _FuncionesAdminScreenState();
}

class _FuncionesAdminScreenState extends State<FuncionesAdminScreen> {
  late Future<_FuncionesData> _future;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FuncionesData> _load() async {
    final funciones = await _repo.funciones();
    final peliculas = await _repo.peliculas();
    final salas = await _repo.salas();
    return _FuncionesData(funciones, peliculas, salas);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _add(List<Pelicula> peliculas, List<Sala> salas) async {
    if (peliculas.isEmpty || salas.isEmpty) {
      adminSnack(context, 'Primero crea al menos una película y una sala');
      return;
    }
    final ok = await showAdminSheet<bool>(
        context, _FuncionForm(repo: _repo, peliculas: peliculas, salas: salas));
    if (ok == true) _reload();
  }

  Future<void> _cancelar(Funcion f) async {
    try {
      await _repo.eliminarFuncion(f.id);
      if (mounted) {
        adminSnack(context, 'Función cancelada');
        _reload();
      }
    } catch (e) {
      if (mounted) adminSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FuncionesData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        return AdminScaffold(
          title: 'Funciones',
          onAdd: data == null
              ? null
              : () => _add(data.peliculas, data.salas),
          body: Builder(builder: (context) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.red));
            }
            if (snap.hasError) {
              return Center(
                  child: Text('${snap.error}',
                      style: const TextStyle(color: AppColors.textDim)));
            }
            final d = data!;
            if (d.funciones.isEmpty) {
              return const Center(
                  child: Text('Sin funciones. Usa + para programar una.',
                      style: TextStyle(color: AppColors.textDim)));
            }
            final df = DateFormat('EEE d MMM · HH:mm', 'es');
            return ListView(
              padding: const EdgeInsets.all(20),
              children: d.funciones.map((f) {
                final peli = d.peliMap[f.peliculaId];
                final sala = d.salaMap[f.salaId];
                return AdminTile(
                  title: peli?.titulo ?? 'Película ${f.peliculaId}',
                  subtitle:
                      '${sala?.nombre ?? 'Sala'} · ${df.format(f.inicio.toLocal())} · S/${f.precioBase.toStringAsFixed(2)}',
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel_outlined,
                        color: AppColors.textDim, size: 20),
                    onPressed: () => _cancelar(f),
                  ),
                );
              }).toList(),
            );
          }),
        );
      },
    );
  }
}

class _FuncionesData {
  final List<Funcion> funciones;
  final List<Pelicula> peliculas;
  final List<Sala> salas;
  late final Map<int, Pelicula> peliMap = {for (final p in peliculas) p.id: p};
  late final Map<int, Sala> salaMap = {for (final s in salas) s.id: s};
  _FuncionesData(this.funciones, this.peliculas, this.salas);
}

class _FuncionForm extends StatefulWidget {
  final AdminRepository repo;
  final List<Pelicula> peliculas;
  final List<Sala> salas;
  const _FuncionForm(
      {required this.repo, required this.peliculas, required this.salas});

  @override
  State<_FuncionForm> createState() => _FuncionFormState();
}

class _FuncionFormState extends State<_FuncionForm> {
  late int _peliculaId = widget.peliculas.first.id;
  late int _salaId = widget.salas.first.id;
  final _precio = TextEditingController(text: '25.00');
  DateTime _inicio = DateTime.now().add(const Duration(hours: 1));
  bool _busy = false;

  Future<void> _pickFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _inicio,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_inicio));
    if (t == null) return;
    setState(() =>
        _inicio = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _crear() async {
    final precio = double.tryParse(_precio.text.trim());
    if (precio == null) {
      adminSnack(context, 'Precio inválido');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repo.crearFuncion(
        peliculaId: _peliculaId,
        salaId: _salaId,
        inicio: _inicio,
        precioBase: precio,
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
    final df = DateFormat('EEE d MMM yyyy · HH:mm', 'es');
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nueva función', style: AppTextStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          _Dropdown<int>(
            label: 'Película',
            value: _peliculaId,
            items: widget.peliculas
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.titulo)))
                .toList(),
            onChanged: (v) => setState(() => _peliculaId = v!),
          ),
          const SizedBox(height: 12),
          _Dropdown<int>(
            label: 'Sala',
            value: _salaId,
            items: widget.salas
                .map((s) => DropdownMenuItem(
                    value: s.id, child: Text('${s.nombre} · ${s.tipo}')))
                .toList(),
            onChanged: (v) => setState(() => _salaId = v!),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickFecha,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.textDim, size: 18),
                  const SizedBox(width: 10),
                  Text(df.format(_inicio),
                      style: AppTextStyles.body.copyWith(color: AppColors.text)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AdminField(
              label: 'Precio base',
              controller: _precio,
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          CSButton(
            label: _busy ? 'Creando…' : 'Programar función',
            onPressed: _busy ? null : _crear,
            icon: const Icon(Icons.add),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textDim),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface2,
          style: const TextStyle(color: AppColors.text),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
