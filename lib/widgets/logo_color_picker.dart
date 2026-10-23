import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models.dart';
import '../data/shop_brands.dart';
import '../theme/logo_palette.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';

class ShopChromeSheetResult {
  const ShopChromeSheetResult({
    this.bytes,
    this.contentType,
    required this.paletteHex,
    this.selectedHex,
    required this.tintHome,
    this.tintStrength = kDefaultTintStrength,
    this.name = '',
    this.nameZh = '',
  });

  final Uint8List? bytes;
  final String? contentType;
  final List<String> paletteHex;
  final String? selectedHex;
  final bool tintHome;
  final int tintStrength;
  final String name;
  final String nameZh;
}

typedef ShopLogoSheetResult = ShopChromeSheetResult;

Future<ShopChromeSheetResult?> showShopChromeSheet({
  required BuildContext context,
  ShopRow? shop,
  ShopBrand? brand,
}) {
  return showModalBottomSheet<ShopChromeSheetResult>(
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
        child: _ShopChromeSheet(shop: shop, brand: brand),
      );
    },
  );
}

Future<ShopChromeSheetResult?> showShopLogoSheet({
  required BuildContext context,
  ShopBrand? brand,
}) {
  return showShopChromeSheet(context: context, brand: brand);
}

class _ShopChromeSheet extends StatefulWidget {
  const _ShopChromeSheet({this.shop, this.brand});

  final ShopRow? shop;
  final ShopBrand? brand;

  @override
  State<_ShopChromeSheet> createState() => _ShopChromeSheetState();
}

class _ShopChromeSheetState extends State<_ShopChromeSheet> {
  late List<String> _palette = List.of(widget.brand?.paletteHex ?? const []);
  late String? _picked =
      widget.brand?.effectiveSelectedHex ??
      (widget.brand?.paletteHex.isNotEmpty == true
          ? widget.brand!.paletteHex.first
          : null);
  late bool _tintHome = widget.brand?.tintHome ?? true;
  late int _tintStrength = snapTintStrength(widget.brand?.tintStrength);
  Uint8List? _bytes;
  String? _contentType;
  bool _picking = false;
  late final TextEditingController _hex = TextEditingController(
    text: _picked ?? '',
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.shop?.name ?? '',
  );
  late final TextEditingController _nameZh = TextEditingController(
    text: widget.shop?.nameZh ?? '',
  );

  bool get _hasPicture => _bytes != null || (widget.brand?.hasLogo ?? false);

  bool get _canRecolor => _hasPicture || _palette.isNotEmpty;

  bool get _namesOk {
    if (widget.shop == null) return true;
    return _name.text.trim().isNotEmpty || _nameZh.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _hex.dispose();
    _name.dispose();
    _nameZh.dispose();
    super.dispose();
  }

  void _setPicked(String hex, {bool syncHex = true}) {
    final normalized = tryNormalizeColorHex(hex) ?? hex;
    setState(() {
      _picked = normalized;
      if (syncHex) _hex.text = normalized;
    });
  }

  List<String> _paletteForSave() {
    final picked = _picked;
    if (picked == null || _palette.contains(picked)) return _palette;
    return [..._palette, picked];
  }

  void _applyHex(String raw) {
    final normalized = tryNormalizeColorHex(raw);
    if (normalized == null) return;
    _setPicked(normalized, syncHex: false);
  }

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
        _hex.text = palette.first;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final custom = colorFromHex(_picked, fallback: AppColors.seed);
    final r = (custom.r * 255).round();
    final g = (custom.g * 255).round();
    final b = (custom.b * 255).round();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              kEditShopSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.shop != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'English'),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameZh,
                decoration: const InputDecoration(labelText: '中文'),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              kPickMainColorTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _picking ? null : _pickLogo,
              child: Text(_picking ? '…' : kAddOrReplaceLogoTooltip),
            ),
            if (_canRecolor) ...[
              if (_palette.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final hex in _palette)
                      InkWell(
                        onTap: () => _setPicked(hex),
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
              const SizedBox(height: 16),
              const Text(
                kCustomRgbLabel,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              _ChannelSlider(
                label: 'R',
                value: r,
                color: const Color(0xFFE53935),
                onChanged: (v) =>
                    _setPicked(hexFromColor(Color.fromARGB(255, v, g, b))),
              ),
              _ChannelSlider(
                label: 'G',
                value: g,
                color: const Color(0xFF43A047),
                onChanged: (v) =>
                    _setPicked(hexFromColor(Color.fromARGB(255, r, v, b))),
              ),
              _ChannelSlider(
                label: 'B',
                value: b,
                color: const Color(0xFF1E88E5),
                onChanged: (v) =>
                    _setPicked(hexFromColor(Color.fromARGB(255, r, g, v))),
              ),
              TextField(
                controller: _hex,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                decoration: const InputDecoration(
                  labelText: 'Hex',
                  hintText: '#C5E1A5',
                ),
                onChanged: _applyHex,
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(kTintHomeRowLabel),
              value: _tintHome,
              onChanged: (v) => setState(() => _tintHome = v),
            ),
            Text(
              kTintStrengthLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: kTintStrengthLabel,
                    value: '$_tintStrength%',
                    child: Slider(
                      min: 0,
                      max: 100,
                      divisions: 100,
                      value: _tintStrength.toDouble(),
                      label: '$_tintStrength%',
                      onChanged: (v) =>
                          setState(() => _tintStrength = v.round()),
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('$_tintStrength%', textAlign: TextAlign.end),
                ),
              ],
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
                  onPressed: !_namesOk
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            ShopChromeSheetResult(
                              bytes: _bytes,
                              contentType: _contentType,
                              paletteHex: _paletteForSave(),
                              selectedHex: _picked,
                              tintHome: _tintHome,
                              tintStrength: _tintStrength,
                              name: _name.text,
                              nameZh: _nameZh.text,
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

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            divisions: 255,
            value: value.toDouble(),
            activeColor: color,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.end)),
      ],
    );
  }
}
