import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/cs_button.dart';
import '../../catalog/domain/models.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';

class PeliculasAdminScreen extends StatefulWidget {
  const PeliculasAdminScreen({super.key});

  @override
  State<PeliculasAdminScreen> createState() => _PeliculasAdminScreenState();
}

class _PeliculasAdminScreenState extends State<PeliculasAdminScreen> {
  late Future<List<Pelicula>> _future;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _future = _repo.peliculas();
  }

  void _reload() => setState(() => _future = _repo.peliculas());

  Future<void> _add() async {
    final ok = await showAdminSheet<bool>(context, _PeliculaForm(repo: _repo));
    if (ok == true) _reload();
  }

  Future<void> _archivar(Pelicula p) async {
    try {
      await _repo.archivarPelicula(p.id);
      if (mounted) {
        adminSnack(context, 'Película archivada');
        _reload();
      }
    } catch (e) {
      if (mounted) adminSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Películas',
      onAdd: _add,
      body: FutureBuilder<List<Pelicula>>(
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
                child: Text('Sin películas. Usa + para importar de TMDB.',
                    style: TextStyle(color: AppColors.textDim)));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: items
                .map((p) => AdminTile(
                      title: p.titulo,
                      subtitle:
                          '${p.duracionLegible} · ${p.generosLegible}${p.activa ? '' : ' · ARCHIVADA'}',
                      trailing: IconButton(
                        icon: const Icon(Icons.archive_outlined,
                            color: AppColors.textDim, size: 20),
                        onPressed: p.activa ? () => _archivar(p) : null,
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _PeliculaForm extends StatefulWidget {
  final AdminRepository repo;
  const _PeliculaForm({required this.repo});

  @override
  State<_PeliculaForm> createState() => _PeliculaFormState();
}

class _PeliculaFormState extends State<_PeliculaForm> {
  final _tmdbTitulo = TextEditingController();
  final _tmdbId = TextEditingController();
  bool _busy = false;

  Future<void> _importar() async {
    final titulo = _tmdbTitulo.text.trim();
    final id = int.tryParse(_tmdbId.text.trim());
    if (titulo.isEmpty && id == null) {
      adminSnack(context, 'Ingresa un título o un tmdb_id');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repo.importarTmdb(tmdbId: id, titulo: titulo.isEmpty ? null : titulo);
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
        Text('Importar de TMDB', style: AppTextStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        AdminField(label: 'Título a buscar', controller: _tmdbTitulo),
        AdminField(
            label: 'o TMDB id',
            controller: _tmdbId,
            keyboardType: TextInputType.number),
        const SizedBox(height: 4),
        CSButton(
          label: _busy ? 'Importando…' : 'Importar',
          onPressed: _busy ? null : _importar,
          icon: const Icon(Icons.download),
          fullWidth: true,
        ),
      ],
    );
  }
}
