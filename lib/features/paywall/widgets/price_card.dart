import 'package:flutter/material.dart';

class PriceCard extends StatelessWidget {
  const PriceCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    this.isSelected = false,
    required this.onTap,
  });

  final String title;
  final String price;
  final String period;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? colorScheme.primaryContainer : null,
        ),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(price, style: Theme.of(context).textTheme.headlineMedium),
            Text(period, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
