import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';

/// Primary English name with optional Chinese line.
class ShopNameText extends StatelessWidget {
  const ShopNameText({
    super.key,
    required this.shop,
    this.nameStyle,
  });

  final ShopRow shop;
  final TextStyle? nameStyle;

  @override
  Widget build(BuildContext context) {
    final zh = shop.chineseName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shop.name,
          style: nameStyle ??
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        if (zh != null) ...[
          const SizedBox(height: 2),
          Text(
            zh,
            style: const TextStyle(color: AppColors.chocolate, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
