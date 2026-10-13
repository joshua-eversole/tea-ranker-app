import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';

/// Prefix matches first, then substring. Exact current text is omitted.
List<ShopRow> matchingShops(List<ShopRow> shops, String query, {int limit = 8}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final starts = <ShopRow>[];
  final contains = <ShopRow>[];
  for (final shop in shops) {
    final name = shop.name.toLowerCase();
    if (name == q) continue;
    if (name.startsWith(q)) {
      starts.add(shop);
    } else if (name.contains(q)) {
      contains.add(shop);
    }
  }
  return [...starts, ...contains].take(limit).toList();
}

/// One-column shop picker: text field plus a matching list (not overlay chips).
class ShopNameField extends StatelessWidget {
  const ShopNameField({
    super.key,
    required this.controller,
    required this.shops,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<ShopRow> shops;
  final VoidCallback onChanged;

  List<ShopRow> get matches => matchingShops(shops, controller.text);

  @override
  Widget build(BuildContext context) {
    final suggestions = matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Shop',
            hintText: 'Start typing a shop name',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              children: [
                for (final shop in suggestions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    minLeadingWidth: 28,
                    leading: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.chocolate,
                    ),
                    title: Text(
                      shop.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      controller.text = shop.name;
                      controller.selection = TextSelection.collapsed(
                        offset: shop.name.length,
                      );
                      onChanged();
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
