import 'package:flutter/material.dart';

class FeatureComparisonRow extends StatelessWidget {
  const FeatureComparisonRow({
    super.key,
    required this.feature,
    required this.freeIncluded,
    required this.premiumIncluded,
  });

  final String feature;
  final bool freeIncluded;
  final bool premiumIncluded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(feature)),
          Expanded(
            child: Icon(
              freeIncluded ? Icons.check_circle : Icons.cancel,
              color: freeIncluded ? Colors.green : Colors.grey,
            ),
          ),
          Expanded(
            child: Icon(
              premiumIncluded ? Icons.check_circle : Icons.cancel,
              color: premiumIncluded ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
