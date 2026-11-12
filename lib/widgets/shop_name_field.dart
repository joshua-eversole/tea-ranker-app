import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/shop_search.dart';
import '../theme/tokens.dart';

export '../data/shop_search.dart';

/// One-column shop picker: text field plus a matching list (not overlay chips).
class ShopNameField extends StatefulWidget {
  const ShopNameField({
    super.key,
    required this.controller,
    required this.shops,
    required this.onChanged,
    this.searchOtherShops,
  });

  final TextEditingController controller;
  final List<ShopRow> shops;
  final VoidCallback onChanged;
  final Future<List<ShopRow>> Function(String query)? searchOtherShops;

  @override
  State<ShopNameField> createState() => _ShopNameFieldState();
}

class _ShopNameFieldState extends State<ShopNameField> {
  Timer? _debounce;
  List<ShopRow> _others = const [];
  int _searchToken = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String _) {
    widget.onChanged();
    _scheduleOtherSearch();
  }

  void _scheduleOtherSearch() {
    _debounce?.cancel();
    final text = widget.controller.text;
    if (ownCatalogMatchesQuery(widget.shops, text) || text.trim().isEmpty) {
      if (_others.isNotEmpty) {
        setState(() => _others = const []);
      }
      return;
    }
    if (widget.searchOtherShops == null) return;
    _debounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_loadOthers(text));
    });
  }

  Future<void> _loadOthers(String text) async {
    final search = widget.searchOtherShops;
    if (search == null) return;
    final token = ++_searchToken;
    try {
      final rows = await search(text);
      if (!mounted || token != _searchToken) return;
      if (ownCatalogMatchesQuery(widget.shops, widget.controller.text)) {
        setState(() => _others = const []);
        return;
      }
      setState(() => _others = rows);
    } catch (_) {
      if (!mounted || token != _searchToken) return;
      setState(() => _others = const []);
    }
  }

  void _pick(ShopRow shop) {
    widget.controller.text = shop.displayName;
    widget.controller.selection = TextSelection.collapsed(
      offset: shop.displayName.length,
    );
    widget.onChanged();
    if (_others.isNotEmpty) {
      setState(() => _others = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = shopLoggerSuggestions(
      ownShops: widget.shops,
      otherShops: _others,
      query: widget.controller.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _onTextChanged,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Shop',
            hintText: 'English or 中文',
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
                for (final hit in suggestions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    minLeadingWidth: 28,
                    leading: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.chocolate,
                    ),
                    title: Text(
                      hit.shop.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: hit.createdByAnotherUser
                        ? const Text(kCreatedByAnotherUserSubtitle)
                        : null,
                    onTap: () => _pick(hit.shop),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
