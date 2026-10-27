import 'package:flutter/material.dart';

import '../data/tea_types.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';
import 'topping_chip.dart';
import 'topping_color_picker.dart';

const kAddNewChipLabel = 'Add new +';
const kAddNewChipHex = '#FFFFFF';
const kNewTeaTypeTitle = 'New Tea Type';
const kNewToppingTitle = 'New Topping';

class NewToppingDraft {
  const NewToppingDraft({
    required this.name,
    required this.colorHex,
    required this.intensity,
  });

  final String name;
  final String colorHex;
  final int intensity;
}

Future<String?> showNewTeaTypeDialog({required BuildContext context}) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _NewTeaTypeDialog(),
  );
}

Future<NewToppingDraft?> showNewToppingDialog({
  required BuildContext context,
  required Iterable<String?> existingHexes,
}) {
  return showDialog<NewToppingDraft>(
    context: context,
    builder: (context) => _NewToppingDialog(existingHexes: existingHexes),
  );
}

class _NewTeaTypeDialog extends StatefulWidget {
  const _NewTeaTypeDialog();

  @override
  State<_NewTeaTypeDialog> createState() => _NewTeaTypeDialogState();
}

class _NewTeaTypeDialogState extends State<_NewTeaTypeDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _add() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      title: const Text(kNewTeaTypeTitle),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Name'),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _add(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty ? null : _add,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _NewToppingDialog extends StatefulWidget {
  const _NewToppingDialog({required this.existingHexes});

  final Iterable<String?> existingHexes;

  @override
  State<_NewToppingDialog> createState() => _NewToppingDialogState();
}

class _NewToppingDialogState extends State<_NewToppingDialog> {
  final _name = TextEditingController();
  late String _hex;
  late int _intensity;

  @override
  void initState() {
    super.initState();
    _hex = colorHexForNewTopping('', existingHexes: widget.existingHexes);
    _intensity = kToppingDefaultIntensity;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _add() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      NewToppingDraft(name: name, colorHex: _hex, intensity: _intensity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _name.text.trim().isEmpty
        ? 'Preview'
        : _name.text.trim();
    return AlertDialog(
      backgroundColor: AppColors.cream,
      title: const Text(kNewToppingTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Name'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _add(),
            ),
            const SizedBox(height: 16),
            Center(
              child: ToppingChip(
                label: previewName,
                colorHex: _hex,
                intensity: _intensity,
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
                  PaletteColorSwatch(
                    hex: hex,
                    selected: _hex == hex.toUpperCase(),
                    onTap: () => setState(() => _hex = hex.toUpperCase()),
                  ),
              ],
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty ? null : _add,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class TeaTypeNoteField extends StatelessWidget {
  const TeaTypeNoteField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: kTeaTypeNoteLabel,
        hintText: kTeaTypeNoteHint,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      ),
    );
  }
}
