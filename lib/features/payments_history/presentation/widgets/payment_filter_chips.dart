import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/payments_history_cubit.dart';

class PaymentFilterChips extends StatelessWidget {
  const PaymentFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = context.locale.languageCode == 'ar';

    return BlocBuilder<PaymentsHistoryCubit, PaymentsHistoryState>(
      builder: (context, state) {
        if (state is! PaymentsHistoryLoaded) return const SizedBox();

        final selectedStatus = state.selectedStatus ?? 'all';

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: isRtl ? 'الكل' : 'All',
                isSelected: selectedStatus == 'all',
                onTap: () =>
                    context.read<PaymentsHistoryCubit>().filterByStatus('all'),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: isRtl ? 'مدفوع' : 'Paid',
                isSelected: selectedStatus == 'paid',
                onTap: () =>
                    context.read<PaymentsHistoryCubit>().filterByStatus('paid'),
                theme: theme,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: isRtl ? 'قيد المراجعة' : 'Pending',
                isSelected: selectedStatus == 'pending_manual_payment',
                onTap: () => context
                    .read<PaymentsHistoryCubit>()
                    .filterByStatus('pending_manual_payment'),
                theme: theme,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: isRtl ? 'مسترد' : 'Refunded',
                isSelected: selectedStatus == 'refunded',
                onTap: () => context
                    .read<PaymentsHistoryCubit>()
                    .filterByStatus('refunded'),
                theme: theme,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: isRtl ? 'ملغي' : 'Cancelled',
                isSelected: selectedStatus == 'cancelled',
                onTap: () => context
                    .read<PaymentsHistoryCubit>()
                    .filterByStatus('cancelled'),
                theme: theme,
                color: Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : chipColor,
          ),
        ),
      ),
    );
  }
}
