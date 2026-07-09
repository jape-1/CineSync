import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/top_bar.dart';
import '../widgets/icon_btn.dart';
import '../widgets/cs_button.dart';
import '../widgets/input_field.dart';
import '../features/checkout/presentation/checkout_cubit.dart';

/// Resumen de compra real: asientos + dulcería + promoción → checkout.
class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final _promoCtrl = TextEditingController();

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final compra = await context.read<CheckoutCubit>().submit();
    if (compra != null && mounted) {
      context.go('/ticket/${compra.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (p, c) => c.error != null && c.error != p.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error!)));
      },
      builder: (context, state) {
        final f = state.funcion;
        final df = DateFormat('EEE d MMM · HH:mm', 'es');
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                TopBar(
                  sticky: true,
                  left: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconBtn(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Resumen de compra',
                          style: AppTextStyles.display.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Película / función
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f?.pelicula?.titulo ?? 'Función',
                                  style: AppTextStyles.display.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text)),
                              const SizedBox(height: 4),
                              Text(
                                '${f?.sala?.nombre ?? ''} · '
                                '${f != null ? df.format(f.inicio.toLocal()) : ''}',
                                style: AppTextStyles.body.copyWith(
                                    fontSize: 12, color: AppColors.textDim),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        _Row(
                          label: 'Asientos',
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: state.seats
                                .map((s) => _chip(s.label))
                                .toList(),
                          ),
                        ),
                        if (state.snacks.isNotEmpty)
                          _Row(
                            label: 'Dulcería',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: state.snacks.values
                                  .map((s) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Text('×${s.cantidad}',
                                                style: AppTextStyles.mono
                                                    .copyWith(
                                                        fontSize: 13,
                                                        color:
                                                            AppColors.textDim)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(s.item.nombre,
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                            fontSize: 13,
                                                            color: AppColors
                                                                .text))),
                                            Text(
                                                'S/${(s.item.precio * s.cantidad).toStringAsFixed(2)}',
                                                style: AppTextStyles.mono
                                                    .copyWith(
                                                        fontSize: 13,
                                                        color:
                                                            AppColors.textDim)),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),

                        const SizedBox(height: 18),
                        Text('CÓDIGO DE PROMOCIÓN',
                            style: AppTextStyles.eyebrow),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InputField(
                                controller: _promoCtrl,
                                placeholder: 'Ej. CINE10',
                                icon: const Icon(Icons.sell_outlined),
                              ),
                            ),
                            const SizedBox(width: 10),
                            CSButton(
                              label: 'Aplicar',
                              variant: CSButtonVariant.secondary,
                              onPressed: () => context
                                  .read<CheckoutCubit>()
                                  .applyPromo(_promoCtrl.text.trim()),
                            ),
                          ],
                        ),
                        if (state.promo != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            state.promo!.valido
                                ? '✓ ${state.promo!.descripcion ?? 'Descuento aplicado'}'
                                : '✕ ${state.promo!.motivo ?? 'Código inválido'}',
                            style: AppTextStyles.body.copyWith(
                                fontSize: 12,
                                color: state.promo!.valido
                                    ? AppColors.green
                                    : AppColors.red),
                          ),
                        ],

                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Column(
                            children: [
                              _TotalRow(
                                  label:
                                      'Asientos (${state.seats.length})',
                                  value:
                                      'S/${state.subtotalAsientos.toStringAsFixed(2)}'),
                              if (state.snacks.isNotEmpty)
                                _TotalRow(
                                    label:
                                        'Dulcería (${state.snacksCount})',
                                    value:
                                        'S/${state.subtotalSnacks.toStringAsFixed(2)}'),
                              if (state.descuento > 0)
                                _TotalRow(
                                    label: 'Descuento',
                                    value:
                                        '−S/${state.descuento.toStringAsFixed(2)}',
                                    green: true),
                              Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  height: 1,
                                  color: AppColors.border),
                              Row(
                                children: [
                                  Text('Total a pagar',
                                      style: AppTextStyles.display.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text)),
                                  const Spacer(),
                                  Text('S/${state.total.toStringAsFixed(2)}',
                                      style: AppTextStyles.display.copyWith(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  decoration: const BoxDecoration(
                    color: AppColors.bgDeep,
                    border:
                        Border(top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: Column(
                    children: [
                      CSButton(
                        label: state.submitting
                            ? 'Procesando…'
                            : 'Confirmar compra · S/${state.total.toStringAsFixed(2)}',
                        onPressed: state.submitting ? null : _confirm,
                        icon: const Icon(Icons.check, size: 16),
                        fullWidth: true,
                      ),
                      const SizedBox(height: 10),
                      Text('PAGO SIMULADO · SIN PASARELA REAL',
                          style: AppTextStyles.mono.copyWith(
                              fontSize: 10,
                              letterSpacing: 1,
                              color: AppColors.textFaint)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: AppTextStyles.mono.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final Widget child;
  const _Row({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(label.toUpperCase(),
                  style: AppTextStyles.mono.copyWith(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: AppColors.textDim)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool green;
  const _TotalRow(
      {required this.label, required this.value, this.green = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.body
                  .copyWith(fontSize: 12, color: AppColors.textDim)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.mono.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: green ? AppColors.green : AppColors.text)),
        ],
      ),
    );
  }
}
