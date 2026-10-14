import 'package:flutter/material.dart';

import '../data/models.dart';

/// One line: `English / 中文`, English only, or 中文 only. Never two lines.
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
    return Text(
      shop.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: nameStyle ??
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    );
  }
}
