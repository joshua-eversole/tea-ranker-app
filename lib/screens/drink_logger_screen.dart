import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/hangouts.dart';
import '../data/models.dart';
import '../data/social.dart';
import '../data/tea_repository.dart';
import '../data/tea_types.dart';
import '../grading/grade.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';
import '../widgets/base_toggles.dart';
import '../widgets/percent_slider.dart';
import '../widgets/shop_name_field.dart';
import '../widgets/tea_type_chip.dart';
import '../widgets/topping_chip.dart';
import '../widgets/topping_color_picker.dart';
import '../widgets/with_companions_line.dart';

String drinkLoggerTitle({required bool editing}) =>
    editing ? 'Edit drink' : 'Log a drink';

const kFixedLevelLabel = 'Fixed';

bool loggerCanSave({
  required String shop,
  required String tea,
  required String priceText,
  required LetterGrade? grade,
  required bool sugarFixed,
  required bool iceFixed,
  required double sugar,
  required double ice,
  required bool saving,
}) {
  final price = double.tryParse(priceText.trim());
  final sugarOk = sugarFixed || (sugar >= 0 && sugar <= 100);
  final iceOk = iceFixed || (ice >= 0 && ice <= 100);
  return shop.trim().isNotEmpty &&
      tea.trim().isNotEmpty &&
      price != null &&
      price >= 0 &&
      grade != null &&
      sugarOk &&
      iceOk &&
      !saving;
}

class DrinkLoggerScreen extends StatefulWidget {
  const DrinkLoggerScreen({
    super.key,
    required this.repo,
    this.entryId,
    this.hangoutPrefill,
  });

  final TeaRepository repo;
  final String? entryId;
  final HangoutLogPrefill? hangoutPrefill;

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
  final _teaTypeNote = TextEditingController();
  final _newTeaType = TextEditingController();

  DateTime _day = DateTime.now();
  bool _milk = false;
  bool _fruit = false;
  String? _teaTypeId;
  late double _sugar;
  late double _ice;
  bool _sugarFixed = false;
  bool _iceFixed = false;
  bool _defaultsApplied = false;
  bool _touchedLevels = false;
  LetterGrade? _grade;
  final _selected = <String>{};
  bool _saving = false;
  String? _banner;
  bool _hydratedEdit = false;
  bool _missingEdit = false;
  bool _hangoutApplied = false;
  final _companionIds = <String>{};
  List<DirectoryProfile> _friends = const [];

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
    _loadFriends();
    _applyHangoutPrefill();
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
    _day = DateTime(
      entry.loggedAt.year,
      entry.loggedAt.month,
      entry.loggedAt.day,
    );
    final toggles = togglesFromDrinkType(entry.drinkType);
    _milk = toggles.milk;
    _fruit = toggles.fruit;
    _teaTypeId = entry.teaTypeId;
    _teaTypeNote.text = entry.teaTypeNote ?? '';
    _sugarFixed = entry.sugarLevel == null;
    _iceFixed = entry.iceLevel == null;
    _sugar = snapPercent(entry.sugarLevel ?? 50).toDouble();
    _ice = snapPercent(entry.iceLevel ?? 50).toDouble();
    _grade = entry.letter;
    _selected
      ..clear()
      ..addAll(entry.toppings.map((t) => t.id));
    _companionIds
      ..clear()
      ..addAll(entry.companions.map((c) => c.userId));
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
    _teaTypeNote.dispose();
    _newTeaType.dispose();
    super.dispose();
  }

  bool get _canSave => loggerCanSave(
    shop: _shop.text,
    tea: _tea.text,
    priceText: _price.text,
    grade: _grade,
    sugarFixed: _sugarFixed,
    iceFixed: _iceFixed,
    sugar: _sugar,
    ice: _ice,
    saving: _saving,
  );

  List<ToppingRow> get _catalog => widget.repo.toppings;

  String get _drinkType => drinkTypeFromToggles(milk: _milk, fruit: _fruit);

  List<TeaTypeRow> get _typeCatalog {
    final live = widget.repo.teaTypes;
    if (live.isNotEmpty) return live;
    return [
      for (final s in newUserTeaTypeSeeds)
        TeaTypeRow(
          id: 'seed:${s.name}',
          name: s.name,
          userId: null,
          isPrimary: s.isPrimary,
          isUserAdded: false,
          colorHex: s.colorHex,
        ),
    ];
  }

  Future<void> _loadFriends() async {
    try {
      final directory = await widget.repo.loadDirectory();
      final friendships = await widget.repo.loadFriendships();
      final me = widget.repo.userId ?? '';
      if (!mounted) return;
      setState(() {
        _friends = acceptedFriendsOnly(
          me: me,
          friendships: friendships,
          directory: directory,
        );
      });
    } catch (_) {}
  }

  void _applyHangoutPrefill() {
    final prefill = widget.hangoutPrefill;
    if (prefill == null || widget.isEditing || _hangoutApplied) return;
    _day = prefill.localDay;
    _shop.text = prefill.shopName;
    _companionIds.add(prefill.friendUserId);
    _hangoutApplied = true;
  }

  Future<void> _pickCompanions() async {
    final picked = await showCompanionsSheet(
      context: context,
      friends: _friends,
      selected: _companionIds,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _companionIds
        ..clear()
        ..addAll(picked);
    });
  }

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
        colorHex: picked.colorHex,
        colorIntensity: picked.intensity,
      );
      setState(() {
        _selected.add(row.id);
        _newTopping.clear();
      });
    } catch (e) {
      setState(() => _banner = 'Couldn’t add that topping.');
    }
  }

  Future<void> _toggleTeaType(TeaTypeRow t) async {
    if (_teaTypeId == t.id) {
      setState(() {
        _teaTypeId = null;
        _teaTypeNote.clear();
      });
      return;
    }
    var id = t.id;
    if (id.startsWith('seed:')) {
      try {
        final row = await widget.repo.matchOrCreateTeaType(t.name);
        id = row.id;
      } catch (_) {
        setState(
          () => _banner =
              'Couldn’t save that tea type. Paste supabase/tea_types.sql first.',
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() => _teaTypeId = id);
  }

  Future<void> _addTeaType() async {
    final name = _newTeaType.text.trim();
    if (name.isEmpty) return;
    final needle = name.toLowerCase();
    for (final t in _typeCatalog) {
      if (t.name.trim().toLowerCase() == needle) {
        await _toggleTeaType(t);
        if (mounted) _newTeaType.clear();
        return;
      }
    }
    if (!mounted) return;
    final picked = await showToppingColorPicker(
      context: context,
      toppingName: name,
      initialHex: colorHexForNewTeaType(
        name,
        existingHexes: _typeCatalog.map(effectiveTeaTypeColorHex),
      ),
      confirmLabel: 'Add',
    );
    if (picked == null || !mounted) return;
    try {
      final row = await widget.repo.matchOrCreateTeaType(
        name,
        colorHex: picked.colorHex,
        colorIntensity: picked.intensity,
      );
      if (!mounted) return;
      setState(() {
        _teaTypeId = row.id;
        _newTeaType.clear();
      });
    } catch (_) {
      setState(
        () => _banner =
            'Couldn’t add that tea type. Paste supabase/tea_types.sql first.',
      );
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _banner = null;
    });
    try {
      final selectedRows = _catalog
          .where((t) => _selected.contains(t.id))
          .toList();
      if (widget.isEditing) {
        final shopId = await widget.repo.updateDrink(
          drinkId: widget.entryId!,
          localDay: _day,
          shopName: _shop.text,
          teaName: _tea.text,
          price: double.parse(_price.text.trim()),
          drinkType: _drinkType,
          sugarLevel: _sugarFixed ? null : snapPercent(_sugar.round()),
          iceLevel: _iceFixed ? null : snapPercent(_ice.round()),
          teaTypeId: _teaTypeId,
          teaTypeNote: _teaTypeNote.text,
          selectedToppings: selectedRows,
          grade: _grade!,
          notes: _notes.text,
          companionUserIds: _companionIds.toList(),
        );
        if (!mounted) return;
        context.go('/shops/$shopId');
      } else {
        await widget.repo.saveDrink(
          localDay: _day,
          shopName: _shop.text,
          teaName: _tea.text,
          price: double.parse(_price.text.trim()),
          drinkType: _drinkType,
          sugarLevel: _sugarFixed ? null : snapPercent(_sugar.round()),
          iceLevel: _iceFixed ? null : snapPercent(_ice.round()),
          teaTypeId: _teaTypeId,
          teaTypeNote: _teaTypeNote.text,
          selectedToppings: selectedRows,
          grade: _grade!,
          notes: _notes.text,
          companionUserIds: _companionIds.toList(),
          hangoutPrefill: widget.hangoutPrefill,
        );
        if (!mounted) return;
        context.go('/');
      }
    } catch (e) {
      setState(
        () =>
            _banner = 'Couldn’t save this drink. Check the form and try again.',
      );
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tea type',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TeaTypePrimaryRow(
                          types: primaryTeaTypes(_typeCatalog),
                          selectedId: _teaTypeId,
                          onToggle: _toggleTeaType,
                        ),
                        const SizedBox(height: 8),
                        TeaTypeSecondaryScroller(
                          types: secondaryTeaTypes(_typeCatalog),
                          selectedId: _teaTypeId,
                          onToggle: _toggleTeaType,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newTeaType,
                                decoration: const InputDecoration(
                                  labelText: kAddTeaTypeLabel,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                ),
                                onSubmitted: (_) => _addTeaType(),
                              ),
                            ),
                            TextButton(
                              onPressed: _addTeaType,
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        if (_teaTypeId != null) ...[
                          const SizedBox(height: 4),
                          TextField(
                            controller: _teaTypeNote,
                            decoration: const InputDecoration(
                              labelText: kTeaTypeNoteLabel,
                              hintText: kTeaTypeNoteHint,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Base',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        BaseToggles(
                          milk: _milk,
                          fruit: _fruit,
                          onMilk: (v) => setState(() => _milk = v),
                          onFruit: (v) => setState(() => _fruit = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LevelSliderRow(
                          label: 'Sugar',
                          value: _sugar,
                          strongColor: AppColors.sugarRed,
                          fixed: _sugarFixed,
                          onFixed: (v) => setState(() {
                            _sugarFixed = v;
                            _touchedLevels = true;
                          }),
                          onChanged: (v) {
                            _touchedLevels = true;
                            setState(() => _sugar = v);
                          },
                        ),
                        _LevelSliderRow(
                          label: 'Ice',
                          value: _ice,
                          strongColor: AppColors.iceBlue,
                          fixed: _iceFixed,
                          onFixed: (v) => setState(() {
                            _iceFixed = v;
                            _touchedLevels = true;
                          }),
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
                  const SizedBox(height: 12),
                  _Section(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(kWithAnyoneLabel),
                      subtitle: _companionIds.isEmpty
                          ? null
                          : Text(
                              withCompanionsCopy([
                                for (final f in _friends)
                                  if (_companionIds.contains(f.id)) f.username,
                              ]),
                            ),
                      trailing: const Icon(Icons.group_add_outlined),
                      onTap: _pickCompanions,
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
                      color: selected == g
                          ? AppColors.boba
                          : Colors.transparent,
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

class _LevelSliderRow extends StatelessWidget {
  const _LevelSliderRow({
    required this.label,
    required this.value,
    required this.strongColor,
    required this.fixed,
    required this.onFixed,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color strongColor;
  final bool fixed;
  final ValueChanged<bool> onFixed;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: PercentGradientSlider(
            label: label,
            value: value,
            strongColor: strongColor,
            enabled: !fixed,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: fixed,
              semanticLabel: kFixedLevelLabel,
              onChanged: (v) => onFixed(v ?? false),
            ),
            const Text(kFixedLevelLabel, style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
