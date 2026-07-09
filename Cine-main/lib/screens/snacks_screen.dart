import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/top_bar.dart';
import '../widgets/icon_btn.dart';
import '../widgets/cs_button.dart';
import '../features/checkout/presentation/checkout_cubit.dart';
import '../features/snacks/data/snacks_repository.dart';
import '../features/snacks/domain/models.dart';
import '../features/snacks/presentation/snacks_cubit.dart';

/// Dulcería real (productos + combos), con cantidades en el [CheckoutCubit].
class SnacksScreen extends StatelessWidget {
  const SnacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => SnacksCubit(c.read<SnacksRepository>())..load(),
      child: const _SnacksView(),
    );
  }
}

class _SnacksView extends StatelessWidget {
  const _SnacksView();

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutCubit>();
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Dulcería',
                          style: AppTextStyles.display.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                      Text('OPCIONAL · ENTREGA EN SALA',
                          style: AppTextStyles.mono.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.55,
                              color: AppColors.textDim)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SnacksCubit, SnacksState>(
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/confirmation'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.borderStrong, width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '¿Sin antojo? Continúa sin dulcería.',
                                    style: AppTextStyles.body.copyWith(
                                        fontSize: 12, color: AppColors.textDim),
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textDim, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...state.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SnackItemCard(
                                item: item,
                                qty: checkout.snackQty(item),
                                onChanged: (q) =>
                                    checkout.setSnackQty(item, q),
                              ),
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),
            _CartTray(
              count: checkout.state.snacksCount,
              subtotal: checkout.state.subtotalSnacks,
              onContinue: () => context.push('/confirmation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnackItemCard extends StatelessWidget {
  final SnackItem item;
  final int qty;
  final ValueChanged<int> onChanged;

  const _SnackItemCard(
      {required this.item, required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          _Thumb(imageUrl: item.imagenUrl, esCombo: item.esCombo),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.nombre,
                    style: AppTextStyles.display.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
                const SizedBox(height: 2),
                Text(item.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                        fontSize: 11, color: AppColors.textDim, height: 1.3)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('S/${item.precio.toStringAsFixed(2)}',
                          style: AppTextStyles.display.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                    ),
                    _QtyStepper(qty: qty, onChanged: onChanged),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? imageUrl;
  final bool esCombo;
  const _Thumb({required this.imageUrl, required this.esCombo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface2,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageUrl != null
          ? Image.network(imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _icon())
          : _icon(),
    );
  }

  Widget _icon() => Icon(
        esCombo ? Icons.fastfood : Icons.local_drink,
        color: AppColors.textDim,
        size: 28,
      );
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  const _QtyStepper({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return GestureDetector(
        onTap: () => onChanged(1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderStrong, width: 1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text('Añadir',
              style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
          color: AppColors.red, borderRadius: BorderRadius.circular(11)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () => onChanged(qty - 1)),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            alignment: Alignment.center,
            child: Text('$qty',
                style: AppTextStyles.display.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          _btn(Icons.add, () => onChanged(qty + 1)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      );
}

class _CartTray extends StatelessWidget {
  final int count;
  final double subtotal;
  final VoidCallback onContinue;
  const _CartTray(
      {required this.count, required this.subtotal, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SUBTOTAL DULCERÍA ($count)',
                    style: AppTextStyles.mono.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: AppColors.textDim)),
                const SizedBox(height: 2),
                Text('S/${subtotal.toStringAsFixed(2)}',
                    style: AppTextStyles.display.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ],
            ),
          ),
          CSButton(
            label: 'Continuar',
            onPressed: onContinue,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
