import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/shop_brands.dart';
import '../theme/logo_palette.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';

class ShopLogoSheetResult {
  const ShopLogoSheetResult({
    this.bytes,
    this.contentType,
    required this.paletteHex,
    this.selectedHex,
    required this.tintHome,
  });

  final Uint8List? bytes;
  final String? contentType;
  final List<String> paletteHex;
  final String? selectedHex;
  final bool tintHome;
}

Future<ShopLogoSheetResult?> showShopLogoSheet({
  required BuildContext context,
  ShopBrand? brand,
}) {
  return showModalBottomSheet<ShopLogoSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ShopLogoSheet(brand: brand),
      );
    },
  );
}

class _ShopLogoSheet extends StatefulWidget {
  const _ShopLogoSheet({this.brand});

  final ShopBrand? brand;

  @override
  State<_ShopLogoSheet> createState() => _ShopLogoSheetState();
}

class _ShopLogoSheetState extends State<_ShopLogoSheet> {
  late List<String> _palette = List.of(widget.brand?.paletteHex ?? const []);
  late String? _picked =
      widget.brand?.selectedHex ??
      (widget.brand?.paletteHex.isNotEmpty == true
          ? widget.brand!.paletteHex.first
          : null);
  late bool _tintHome = widget.brand?.tintHome ?? true;
  Uint8List? _bytes;
  String? _contentType;
  bool _picking = false;

  Future<void> _pickLogo() async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      var palette = await extractLogoPalette(bytes);
      if (!mounted) return;
      if (palette.isEmpty) palette = const ['#D4B59E'];
      setState(() {
        _bytes = bytes;
        _contentType = picked.mimeType ?? 'image/jpeg';
        _palette = palette;
        _picked = palette.first;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              kPickMainColorTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _picking ? null : _pickLogo,
              child: Text(_picking ? '…' : kAddOrReplaceLogoTooltip),
            ),
            if (_palette.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hex in _palette)
                    InkWell(
                      onTap: () => setState(() => _picked = hex),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: AppLayout.minTap,
                        height: AppLayout.minTap,
                        decoration: BoxDecoration(
                          color: colorFromHex(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _picked == hex
                                ? AppColors.boba
                                : AppColors.seed,
                            width: _picked == hex ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(kTintHomeRowLabel),
              value: _tintHome,
              onChanged: (v) => setState(() => _tintHome = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ShopLogoSheetResult(
                        bytes: _bytes,
                        contentType: _contentType,
                        paletteHex: _palette,
                        selectedHex: _picked,
                        tintHome: _tintHome,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
