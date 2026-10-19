import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/tea_repository.dart';
import '../grading/grade.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';
import '../widgets/percent_slider.dart';
import '../widgets/shop_name_field.dart';
import '../widgets/topping_chip.dart';
import '../widgets/topping_color_picker.dart';

String drinkLoggerTitle({required bool editing}) =>
    editing ? 'Edit drink' : 'Log a drink';

class DrinkLoggerScreen extends StatefulWidget {
  const DrinkLoggerScreen({
    super.key,
    required this.repo,
    this.entryId,
  });

  final TeaRepository repo;
  final String? entryId;

  bool get isEditing => entryId != null && entryId!.isNotEmpty;

  @override
  State<DrinkLoggerScreen> createState() => _DrinkLoggerScreenState();
}

class _DrinkLoggerScreenState extends State<DrinkLoggerScreen> {
  final _shop = TextEditingController();
  final _tea = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();
  final _newTopping = TextEditingController();

  DateTime _day = DateTime.now();
  String? _base;
  late double _sugar;
  late double _ice;
  bool _defaultsApplied = false;
  bool _touchedLevels = false;
  LetterGrade? _grade;
  final _selected = <String>{};
  bool _saving = false;
  String? _banner;
  bool _hydratedEdit = false;
  bool _missingEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _sugar = 50;
      _ice = 50;
      _defaultsApplied = true;
      _hydrateEditIfNeeded(notify: false);
    } else {
      final account = widget.repo.account;
      if (account != null) {
        _sugar = account.defaultSugarPercent.toDouble();
        _ice = account.defaultIcePercent.toDouble();
        _defaultsApplied = true;
      } else {
        _sugar = 50;
        _ice = 50;
      }
    }
    widget.repo.addListener(_onRepo);
  }

  void _onRepo() {
    if (widget.isEditing) {
      _hydrateEditIfNeeded();
      return;
    }
    _applyDefaultsIfNeeded();
  }

  DrinkEntryRow? _existingEntry() {
    final id = widget.entryId;
    if (id == null) return null;
    final entries = widget.repo.profile?.entries ?? const <DrinkEntryRow>[];
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  void _hydrateEditIfNeeded({bool notify = true}) {
    if (_hydratedEdit) return;
    final entry = _existingEntry();
    if (entry == null) {
      if (widget.repo.profile != null &&
          !widget.repo.loading &&
          widget.repo.loadError == null) {
        _missingEdit = true;
        if (notify && mounted) setState(() {});
      }
      return;
    }
    _shop.text = entry.shop?.displayName ?? '';
    _tea.text = entry.teaName;
    _price.text = entry.price == entry.price.roundToDouble()
        ? entry.price.round().toString()
        : entry.price.toString();
    _notes.text = entry.notes ?? '';
    _day = DateTime(entry.loggedAt.year, entry.loggedAt.month, entry.loggedAt.day);
    _base = drinkBases.contains(entry.drinkType) ? entry.drinkType : null;
    _sugar = snapPercent(entry.sugarLevel).toDouble();
    _ice = snapPercent(entry.iceLevel).toDouble();
    _grade = entry.letter;
    _selected
      ..clear()
      ..addAll(entry.toppings.map((t) => t.id));
    _hydratedEdit = true;
    _missingEdit = false;
    _defaultsApplied = true;
    _touchedLevels = true;
    if (notify && mounted) setState(() {});
  }

  void _applyDefaultsIfNeeded() {
    if (widget.isEditing || _defaultsApplied || _touchedLevels) return;
    final account = widget.repo.account;
    if (account == null || !mounted) return;
    setState(() {
      _sugar = account.defaultSugarPercent.toDouble();
      _ice = account.defaultIcePercent.toDouble();
      _defaultsApplied = true;
    });
  }

  @override
  void dispose() {
    widget.repo.removeListener(_onRepo);
    _shop.dispose();
    _tea.dispose();
    _price.dispose();
    _notes.dispose();
    _newTopping.dispose();
    super.dispose();
  }

  bool get _canSave {
    final price = double.tryParse(_price.text.trim());
    return _shop.text.trim().isNotEmpty &&
        _tea.text.trim().isNotEmpty &&
        price != null &&
        price >= 0 &&
        _base != null &&
        _grade != null &&
        !_saving;
  }

  List<ToppingRow> get _catalog => widget.repo.toppings;

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _addTopping() async {
    final name = _newTopping.text.trim();
    if (name.isEmpty) return;
    final needle = name.toLowerCase();
    for (final t in _catalog) {
      if (t.name.trim().toLowerCase() == needle) {
        setState(() {
          _selected.add(t.id);
          _newTopping.clear();
        });
        return;
      }
    }
    if (!mounted) return;
    final picked = await showToppingColorPicker(
      context: context,
      toppingName: name,
      initialHex: colorHexForNewTopping(
        name,
        existingHexes: _catalog.map((t) => t.colorHex),
      ),
      confirmLabel: 'Add',
    );
    if (picked == null || !mounted) return;
    try {
      final row = await widget.repo.matchOrCreateTopping(
        name,
        colorHex: picked,
      );
      setState(() {
        _selected.add(row.id);
        _newTopping.clear();
      });
    } catch (e) {
      setState(() => _banner = 'Couldn’t add that topping.');
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _banner = null;
    });
    try {
      final selectedRows = _catalog.where((t) => _selected.contains(t.id)).toList();
      if (widget.isEditing) {
        final shopId = await widget.repo.updateDrink(
          drinkId: widget.entryId!,
          localDay: _day,
          shopName: _shop.text,
          teaName: _tea.text,
          price: double.parse(_price.text.trim()),
          drinkType: _base!,
          sugarLevel: _sugar.round(),
          iceLevel: _ice.round(),
          selectedToppings: selectedRows,
          grade: _grade!,
          notes: _notes.text,
        );
        if (!mounted) return;
        context.go('/shops/$shopId');
      } else {
        await widget.repo.saveDrink(
          localDay: _day,
          shopName: _shop.text,
          teaName: _tea.text,
          price: double.parse(_price.text.trim()),
          drinkType: _base!,
          sugarLevel: _sugar.round(),
          iceLevel: _ice.round(),
          selectedToppings: selectedRows,
          grade: _grade!,
          notes: _notes.text,
        );
        if (!mounted) return;
        context.go('/');
      }
    } catch (e) {
      setState(() => _banner = 'Couldn’t save this drink. Check the form and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final shops = widget.repo.profile?.shops ?? const <ShopRow>[];
        if (widget.isEditing && !_hydratedEdit) {
          return Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        icon: const Icon(Icons.close),
                      ),
                      Text(
                        drinkLoggerTitle(editing: true),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _missingEdit
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'That visit isn’t in your log.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      icon: const Icon(Icons.close),
                    ),
                    Text(
                      drinkLoggerTitle(editing: widget.isEditing),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            if (_banner != null)
              MaterialBanner(
                content: Text(_banner!),
                backgroundColor: AppColors.gradeDPlus.withValues(alpha: 0.15),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _banner = null),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _Section(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Date visited'),
                      subtitle: Text(DateFormat.yMMMEd().format(_day)),
                      onTap: _pickDay,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: ShopNameField(
                      controller: _shop,
                      shops: shops,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: TextField(
                      controller: _tea,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Drink',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: 'NT\$ ',
                        hintText: '65',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Base'),
                        value: _base,
                        items: [
                          for (final b in drinkBases)
                            DropdownMenuItem(value: b, child: Text(b)),
                        ],
                        onChanged: (v) => setState(() => _base = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PercentGradientSlider(
                          label: 'Sugar',
                          value: _sugar,
                          strongColor: AppColors.sugarRed,
                          onChanged: (v) {
                            _touchedLevels = true;
                            setState(() => _sugar = v);
                          },
                        ),
                        PercentGradientSlider(
                          label: 'Ice',
                          value: _ice,
                          strongColor: AppColors.iceBlue,
                          onChanged: (v) {
                            _touchedLevels = true;
                            setState(() => _ice = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toppings',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in _catalog)
                              ToppingChip.fromRow(
                                t,
                                selected: _selected.contains(t.id),
                                onTap: () {
                                  setState(() {
                                    if (_selected.contains(t.id)) {
                                      _selected.remove(t.id);
                                    } else {
                                      _selected.add(t.id);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newTopping,
                                decoration: const InputDecoration(
                                  labelText: 'Add topping',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                ),
                                onSubmitted: (_) => _addTopping(),
                              ),
                            ),
                            TextButton(
                              onPressed: _addTopping,
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Grade',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        _GradeSegments(
                          selected: _grade,
                          onPick: (g) => setState(() => _grade = g),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: TextField(
                      controller: _notes,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Shell already pads for the nav + home indicator. Skip SafeArea
            // so Save sits just above the bar while Add stays `watching`.
            Material(
              color: AppColors.cream,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: AppLayout.minTap,
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: child,
      ),
    );
  }
}

class _GradeSegments extends StatelessWidget {
  const _GradeSegments({required this.selected, required this.onPick});
  final LetterGrade? selected;
  final ValueChanged<LetterGrade> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final g in LetterGrade.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AspectRatio(
                aspectRatio: 1,
                child: Material(
                  color: colorsForMark(g.letter).$1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected == g ? AppColors.boba : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => onPick(g),
                    child: Center(
                      child: Text(
                        g.letter,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: colorsForMark(g.letter).$2,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
