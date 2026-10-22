import 'package:flutter/material.dart';

import '../data/shop_brands.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';

Future<String?> showLogoColorPicker({
  required BuildContext context,
  required List<String> paletteHex,
}) {
  if (paletteHex.isEmpty) return Future.value(null);
  return showDialog<String>(
    context: context,
    builder: (context) => _LogoColorDialog(paletteHex: paletteHex),
  );
}

class _LogoColorDialog extends StatefulWidget {
  const _LogoColorDialog({required this.paletteHex});
  final List<String> paletteHex;

  @override
  State<_LogoColorDialog> createState() => _LogoColorDialogState();
}

class _LogoColorDialogState extends State<_LogoColorDialog> {
  late String _picked = widget.paletteHex.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      title: const Text(kPickMainColorTitle),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final hex in widget.paletteHex)
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
                    color: _picked == hex ? AppColors.boba : AppColors.seed,
                    width: _picked == hex ? 3 : 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _picked),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
