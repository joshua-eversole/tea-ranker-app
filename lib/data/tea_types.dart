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

/// Unicode apostrophe as in the spec (Pu’er).
const kPuerName = 'Pu’er';

const kPrimaryTeaTypeNames = <String>['Black', 'Green', 'Oolong'];
const kSecondarySeedTeaTypeNames = <String>[
  'Matcha',
  'Hojicha',
  kPuerName,
  'White',
];

class TeaTypeSeed {
  const TeaTypeSeed({required this.name, required this.isPrimary});
  final String name;
  final bool isPrimary;
}

const newUserTeaTypeSeeds = <TeaTypeSeed>[
  TeaTypeSeed(name: 'Black', isPrimary: true),
  TeaTypeSeed(name: 'Green', isPrimary: true),
  TeaTypeSeed(name: 'Oolong', isPrimary: true),
  TeaTypeSeed(name: 'Matcha', isPrimary: false),
  TeaTypeSeed(name: 'Hojicha', isPrimary: false),
  TeaTypeSeed(name: kPuerName, isPrimary: false),
  TeaTypeSeed(name: 'White', isPrimary: false),
];

class TeaTypeRow {
  const TeaTypeRow({
    required this.id,
    required this.name,
    required this.userId,
    required this.isPrimary,
    required this.isUserAdded,
  });

  final String id;
  final String name;
  final String? userId;
  final bool isPrimary;
  final bool isUserAdded;

  factory TeaTypeRow.fromMap(Map<String, dynamic> map) => TeaTypeRow(
    id: map['id'] as String,
    name: map['name'] as String,
    userId: map['user_id'] as String?,
    isPrimary: map['is_primary'] as bool? ?? false,
    isUserAdded: map['is_user_added'] as bool? ?? true,
  );
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

/// Seed the seven names only when the catalog is empty.
List<TeaTypeSeed> teaTypesToSeedForUser(Iterable<String> existingNames) {
  if (existingNames.any((name) => name.trim().isNotEmpty)) {
    return const [];
  }
  return List<TeaTypeSeed>.from(newUserTeaTypeSeeds);
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
