import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/top_bar.dart';
import '../widgets/icon_btn.dart';
import '../widgets/bottom_tabs.dart';
import '../features/tickets/data/tickets_repository.dart';
import '../features/tickets/domain/models.dart';
import '../features/tickets/presentation/tickets_cubit.dart';

/// Historial de compras real (activos / usados / cancelados).
class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => TicketsCubit(c.read<TicketsRepository>())..load(),
      child: const _MyTicketsView(),
    );
  }
}

class _MyTicketsView extends StatefulWidget {
  const _MyTicketsView();

  @override
  State<_MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<_MyTicketsView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              sticky: true,
              left: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('HISTORIAL', style: AppTextStyles.eyebrow),
                  Text('Mis tickets',
                      style: AppTextStyles.h2.copyWith(fontSize: 24)),
                ],
              ),
              right: IconBtn(
                onTap: () => context.read<TicketsCubit>().load(),
                child: const Icon(Icons.refresh, size: 18),
              ),
            ),
            Expanded(
              child: BlocBuilder<TicketsCubit, TicketsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.red));
                  }
                  if (state.error != null) {
                    return Center(
                        child: Text(state.error!,
                            style: const TextStyle(color: AppColors.textDim)));
                  }
                  final lists = [state.activos, state.usados, state.cancelados];
                  final current = lists[_tab];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SegmentTabs(
                          selected: _tab,
                          onChange: (i) => setState(() => _tab = i),
                          items: [
                            ('Activos', state.activos.length),
                            ('Usados', state.usados.length),
                            ('Cancelados', state.cancelados.length),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (current.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text('Nada por aquí',
                                  style:
                                      TextStyle(color: AppColors.textDim)),
                            ),
                          )
                        else
                          ...current.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TicketRow(compra: c),
                              )),
                      ],
                    ),
                  );
                },
              ),
            ),
            BottomTabs(
              active: BottomTab.tickets,
              onTap: (tab) {
                if (tab == BottomTab.home) {
                  context.go('/home');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChange;
  final List<(String, int)> items;
  const _SegmentTabs(
      {required this.selected, required this.onChange, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: List.generate(items.length, (i) {
          final (label, count) = items[i];
          final sel = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                decoration: BoxDecoration(
                    color: sel ? AppColors.red : Colors.transparent,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : AppColors.textDim)),
                    ),
                    const SizedBox(width: 6),
                    Text('$count',
                        style: AppTextStyles.mono.copyWith(
                            fontSize: 10,
                            color: sel ? Colors.white : AppColors.textDim)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final Compra compra;
  const _TicketRow({required this.compra});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM · HH:mm', 'es');
    return GestureDetector(
      onTap: () => context.push('/ticket/${compra.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(compra.funcion.peliculaTitulo,
                      style: AppTextStyles.display.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(
                      '${compra.funcion.salaNombre} · '
                      '${df.format(compra.funcion.inicio.toLocal())}',
                      style: AppTextStyles.body
                          .copyWith(fontSize: 11, color: AppColors.textDim)),
                  const SizedBox(height: 4),
                  Text(compra.asientosLabel,
                      style: AppTextStyles.mono.copyWith(
                          fontSize: 11, color: AppColors.textFaint)),
                ],
              ),
            ),
            const Icon(Icons.qr_code_2, size: 24, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }
}
