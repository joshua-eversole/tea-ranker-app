import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import '../theme/topping_colors.dart';
import 'topping_chip.dart';

class ToppingColorChoice {
  const ToppingColorChoice({required this.colorHex, required this.intensity});

  final String colorHex;
  final int intensity;
}

Future<ToppingColorChoice?> showToppingColorPicker({
  required BuildContext context,
  required String toppingName,
  required String initialHex,
  int initialIntensity = kToppingDefaultIntensity,
  String confirmLabel = 'Save',
}) {
  return showModalBottomSheet<ToppingColorChoice>(
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
        child: ToppingColorPicker(
          toppingName: toppingName,
          initialHex: initialHex,
          initialIntensity: initialIntensity,
          confirmLabel: confirmLabel,
        ),
      );
    },
  );
}

class ToppingColorPicker extends StatefulWidget {
  const ToppingColorPicker({
    super.key,
    required this.toppingName,
    required this.initialHex,
    this.initialIntensity = kToppingDefaultIntensity,
    this.confirmLabel = 'Save',
  });

  final String toppingName;
  final String initialHex;
  final int initialIntensity;
  final String confirmLabel;

  @override
  State<ToppingColorPicker> createState() => _ToppingColorPickerState();
}

class _ToppingColorPickerState extends State<ToppingColorPicker> {
  late Color _color;
  late int _intensity;
  late TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    _color = colorFromHex(widget.initialHex);
    _intensity = snapIntensity(widget.initialIntensity);
    _hex = TextEditingController(text: hexFromColor(_color));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _setColor(Color color, {bool syncHex = true}) {
    setState(() {
      _color = color;
      if (syncHex) _hex.text = hexFromColor(color);
    });
  }

  void _applyHex(String raw) {
    final normalized = tryNormalizeColorHex(raw);
    if (normalized == null) return;
    _setColor(colorFromHex(normalized), syncHex: false);
  }

  Color get _previewFill =>
      toppingFill(colorHex: hexFromColor(_color), intensity: _intensity);

  @override
  Widget build(BuildContext context) {
    final r = (_color.r * 255).round();
    final g = (_color.g * 255).round();
    final b = (_color.b * 255).round();
    final preview = _previewFill;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.seed,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Topping color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Center(
              child: ToppingChip(
                label: widget.toppingName.isEmpty
                    ? 'Preview'
                    : widget.toppingName,
                colorHex: hexFromColor(_color),
                intensity: _intensity,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                toppingFillNeedsWhiteLabel(preview)
                    ? 'White label — fill is too dark for brown text'
                    : 'Brown label — contrast is at least 4.5:1',
                style: const TextStyle(
                  color: AppColors.chocolate,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bright defaults',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hex in toppingBrightPaletteHex)
                  _Swatch(
                    hex: hex,
                    selected: hexFromColor(_color) == hex.toUpperCase(),
                    onTap: () => _setColor(colorFromHex(hex)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Intensity',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Intensity',
                    value: '$_intensity%',
                    child: Slider(
                      min: 0,
                      max: 100,
                      divisions: 100,
                      value: _intensity.toDouble(),
                      label: '$_intensity%',
                      onChanged: (v) => setState(() => _intensity = v.round()),
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('$_intensity%', textAlign: TextAlign.end),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Custom RGB',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            _ChannelSlider(
              label: 'R',
              value: r,
              color: const Color(0xFFE53935),
              onChanged: (v) => _setColor(Color.fromARGB(255, v, g, b)),
            ),
            _ChannelSlider(
              label: 'G',
              value: g,
              color: const Color(0xFF43A047),
              onChanged: (v) => _setColor(Color.fromARGB(255, r, v, b)),
            ),
            _ChannelSlider(
              label: 'B',
              value: b,
              color: const Color(0xFF1E88E5),
              onChanged: (v) => _setColor(Color.fromARGB(255, r, g, v)),
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
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    ToppingColorChoice(
                      colorHex: hexFromColor(_color),
                      intensity: _intensity,
                    ),
                  ),
                  child: Text(widget.confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = colorFromHex(hex);
    return Semantics(
      button: true,
      label: 'Palette color $hex',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.boba : AppColors.seed,
              width: selected ? 3 : 1,
            ),
          ),
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
