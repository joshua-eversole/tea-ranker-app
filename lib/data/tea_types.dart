import '../theme/topping_colors.dart';

const kDrinkTypeMilk = 'Milk-based';
const kDrinkTypeFruit = 'Fruit-based';
const kDrinkTypeTea = 'Tea-based';

/// Written bases after Milk/Fruit toggles. No Other.
const drinkTypeWrites = <String>[
  kDrinkTypeMilk,
  kDrinkTypeFruit,
  kDrinkTypeTea,
];

const kMilkToggleLabel = 'Milk';
const kFruitToggleLabel = 'Fruit';
const kTeaTypeNoteLabel = 'Note';
const kTeaTypeNoteHint = 'Assam, Jasmine';
const kAddTeaTypeLabel = 'Add type';
const kTeaTypeExtraDefaultHex = kToppingFallbackHex;

/// Unicode apostrophe as in the spec (Pu’er).
const kPuerName = 'Pu’er';

const kPrimaryTeaTypeNames = <String>['Black', 'Green', 'Oolong'];
const kSecondarySeedTeaTypeNames = <String>[
  'Matcha',
  'Hojicha',
  kPuerName,
  'White',
  'Jasmine',
  'Tieguanyin',
];

/// Same 16% cream mix as Home grade wash (`kGradeWashMix`). Row 1 tiles only.
const kTeaTypePrimaryIntensity = 16;

class TeaTypeSeed {
  const TeaTypeSeed({
    required this.name,
    required this.isPrimary,
    required this.colorHex,
  });
  final String name;
  final bool isPrimary;
  final String colorHex;
}

/// Logger / SQL seed fills. Keys are lowercase; Pu’er also matches ASCII apostrophe.
const namedTeaTypeColorHex = <String, String>{
  'black': kTeaTypeBlackHex,
  'green': kTeaTypeGreenHex,
  'oolong': kTeaTypeOolongHex,
  'matcha': kTeaTypeMatchaHex,
  'hojicha': kTeaTypeHojichaHex,
  "pu'er": kTeaTypePuerHex,
  'white': kTeaTypeWhiteHex,
  'jasmine': kTeaTypeJasmineHex,
  'tieguanyin': kTeaTypeTieguanyinHex,
};

const kTeaTypeBlackHex = '#3E2723';
const kTeaTypeGreenHex = '#43A047';
const kTeaTypeOolongHex = '#E6B422';
const kTeaTypeMatchaHex = '#8BC34A';
const kTeaTypeHojichaHex = '#795548';
const kTeaTypePuerHex = '#C4A484';
const kTeaTypeWhiteHex = '#FFF8E1';
const kTeaTypeJasmineHex = '#E4EEC0';
const kTeaTypeTieguanyinHex = '#A8B57A';

const newUserTeaTypeSeeds = <TeaTypeSeed>[
  TeaTypeSeed(name: 'Black', isPrimary: true, colorHex: kTeaTypeBlackHex),
  TeaTypeSeed(name: 'Green', isPrimary: true, colorHex: kTeaTypeGreenHex),
  TeaTypeSeed(name: 'Oolong', isPrimary: true, colorHex: kTeaTypeOolongHex),
  TeaTypeSeed(name: 'Matcha', isPrimary: false, colorHex: kTeaTypeMatchaHex),
  TeaTypeSeed(name: 'Hojicha', isPrimary: false, colorHex: kTeaTypeHojichaHex),
  TeaTypeSeed(name: kPuerName, isPrimary: false, colorHex: kTeaTypePuerHex),
  TeaTypeSeed(name: 'White', isPrimary: false, colorHex: kTeaTypeWhiteHex),
  TeaTypeSeed(name: 'Jasmine', isPrimary: false, colorHex: kTeaTypeJasmineHex),
  TeaTypeSeed(
    name: 'Tieguanyin',
    isPrimary: false,
    colorHex: kTeaTypeTieguanyinHex,
  ),
];

/// Jasmine + Tieguanyin for catalogs that already have the original seven.
const additiveSecondaryTeaTypeSeeds = <TeaTypeSeed>[
  TeaTypeSeed(name: 'Jasmine', isPrimary: false, colorHex: kTeaTypeJasmineHex),
  TeaTypeSeed(
    name: 'Tieguanyin',
    isPrimary: false,
    colorHex: kTeaTypeTieguanyinHex,
  ),
];

int teaTypeSeedIntensity(TeaTypeSeed seed) {
  return seed.isPrimary ? kTeaTypePrimaryIntensity : kToppingDefaultIntensity;
}

bool isPrimaryTeaTypeName(String name) {
  return kPrimaryTeaTypeNames
      .map((n) => n.toLowerCase())
      .contains(name.trim().toLowerCase());
}

class TeaTypeRow {
  const TeaTypeRow({
    required this.id,
    required this.name,
    required this.userId,
    required this.isPrimary,
    required this.isUserAdded,
    this.colorHex,
    this.colorIntensity,
  });

  final String id;
  final String name;
  final String? userId;
  final bool isPrimary;
  final bool isUserAdded;
  final String? colorHex;
  final int? colorIntensity;

  factory TeaTypeRow.fromMap(Map<String, dynamic> map) => TeaTypeRow(
    id: map['id'] as String,
    name: map['name'] as String,
    userId: map['user_id'] as String?,
    isPrimary: map['is_primary'] as bool? ?? false,
    isUserAdded: map['is_user_added'] as bool? ?? true,
    colorHex: map['color_hex'] as String?,
    colorIntensity: (map['color_intensity'] as num?)?.toInt(),
  );

  TeaTypeRow copyWith({String? colorHex, int? colorIntensity}) {
    return TeaTypeRow(
      id: id,
      name: name,
      userId: userId,
      isPrimary: isPrimary,
      isUserAdded: isUserAdded,
      colorHex: colorHex ?? this.colorHex,
      colorIntensity: colorIntensity ?? this.colorIntensity,
    );
  }
}

String teaTypeColorKey(String name) {
  return name.trim().toLowerCase().replaceAll('’', "'").replaceAll('‘', "'");
}

String? namedColorHexForTeaType(String name) {
  return namedTeaTypeColorHex[teaTypeColorKey(name)];
}

/// Stored hex, else the named seed, else cream/seed (recolor on Profile).
String? effectiveTeaTypeColorHex(TeaTypeRow row) {
  final stored = row.colorHex?.trim();
  if (stored != null && stored.isNotEmpty) return stored;
  return namedColorHexForTeaType(row.name) ?? kTeaTypeExtraDefaultHex;
}

/// Milk wins if both; fruit only → Fruit-based; neither → Tea-based.
String drinkTypeFromToggles({required bool milk, required bool fruit}) {
  if (milk) return kDrinkTypeMilk;
  if (fruit) return kDrinkTypeFruit;
  return kDrinkTypeTea;
}

({bool milk, bool fruit}) togglesFromDrinkType(String? drinkType) {
  return (
    milk: drinkType == kDrinkTypeMilk,
    fruit: drinkType == kDrinkTypeFruit,
  );
}

/// `{Type}` or `{Type} - {note}`. Null when no type.
String? teaTypeCardLine({String? typeName, String? note}) {
  final name = typeName?.trim();
  if (name == null || name.isEmpty) return null;
  final n = note?.trim();
  if (n == null || n.isEmpty) return name;
  return '$name - $n';
}

/// Empty catalog → all seeds. Existing catalog → Jasmine/Tieguanyin if missing.
List<TeaTypeSeed> teaTypesToSeedForUser(Iterable<String> existingNames) {
  final have = {
    for (final name in existingNames)
      if (name.trim().isNotEmpty) teaTypeColorKey(name),
  };
  if (have.isEmpty) {
    return List<TeaTypeSeed>.from(newUserTeaTypeSeeds);
  }
  return [
    for (final seed in additiveSecondaryTeaTypeSeeds)
      if (!have.contains(teaTypeColorKey(seed.name))) seed,
  ];
}

List<TeaTypeRow> primaryTeaTypes(Iterable<TeaTypeRow> catalog) {
  final byName = {for (final t in catalog) t.name.toLowerCase(): t};
  return [
    for (final name in kPrimaryTeaTypeNames)
      if (byName[name.toLowerCase()] != null) byName[name.toLowerCase()]!,
  ];
}

List<TeaTypeRow> secondaryTeaTypes(Iterable<TeaTypeRow> catalog) {
  final used = kPrimaryTeaTypeNames.map((n) => n.toLowerCase()).toSet();
  final secondarySeeds = {
    for (final n in kSecondarySeedTeaTypeNames) n.toLowerCase(),
  };
  final byName = {for (final t in catalog) t.name.toLowerCase(): t};
  final ordered = <TeaTypeRow>[
    for (final name in kSecondarySeedTeaTypeNames)
      if (byName[name.toLowerCase()] != null) byName[name.toLowerCase()]!,
  ];
  final extras =
      catalog
          .where(
            (t) =>
                !used.contains(t.name.toLowerCase()) &&
                !secondarySeeds.contains(t.name.toLowerCase()),
          )
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return [...ordered, ...extras];
}

String colorHexForNewTeaType(
  String name, {
  required Iterable<String?> existingHexes,
}) {
  final named = namedColorHexForTeaType(name);
  if (named != null) return named;
  // Keep the signature; extras share seed/cream instead of cycling the palette.
  existingHexes;
  return kTeaTypeExtraDefaultHex;
}
