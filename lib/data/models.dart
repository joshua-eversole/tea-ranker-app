import '../grading/grade.dart';

int snapPercent(int value) {
  final clamped = value.clamp(0, 100);
  return ((clamped / 10).round() * 10).clamp(0, 100);
}

class ProfileRow {
  const ProfileRow({
    required this.id,
    required this.username,
    this.defaultSugarPercent = 50,
    this.defaultIcePercent = 50,
  });
  final String id;
  final String username;
  final int defaultSugarPercent;
  final int defaultIcePercent;

  factory ProfileRow.fromMap(Map<String, dynamic> map) => ProfileRow(
    id: map['id'] as String,
    username: (map['username'] as String?) ?? '',
    defaultSugarPercent: snapPercent(
      (map['default_sugar_percent'] as num?)?.toInt() ?? 50,
    ),
    defaultIcePercent: snapPercent(
      (map['default_ice_percent'] as num?)?.toInt() ?? 50,
    ),
  );

  ProfileRow copyWith({
    String? username,
    int? defaultSugarPercent,
    int? defaultIcePercent,
  }) {
    return ProfileRow(
      id: id,
      username: username ?? this.username,
      defaultSugarPercent: defaultSugarPercent ?? this.defaultSugarPercent,
      defaultIcePercent: defaultIcePercent ?? this.defaultIcePercent,
    );
  }
}

final _latin = RegExp(r'[A-Za-z]');
final _cjk = RegExp(r'[\u3400-\u9FFF\uF900-\uFAFF]');

/// Logger heuristic: CJK with no Latin letters → save as `name_zh` only.
bool looksLikeChineseOnly(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return false;
  return _cjk.hasMatch(t) && !_latin.hasMatch(t);
}

String? trimToNull(String? value) {
  final t = value?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}

class ShopRow {
  const ShopRow({
    required this.id,
    this.name,
    required this.userId,
    required this.isUserAdded,
    this.nameZh,
    this.notes,
  });

  final String id;

  /// English name (`shops.name`). Null when the shop is Chinese-only.
  final String? name;

  /// Optional Chinese name (`shops.name_zh`).
  final String? nameZh;

  /// Shop-level notes (`shops.notes`), not drink notes.
  final String? notes;
  final String? userId;
  final bool isUserAdded;

  String? get englishName => trimToNull(name);

  String? get chineseName => trimToNull(nameZh);

  /// `English / 中文` when both exist; otherwise the one that exists.
  String get displayName {
    final en = englishName;
    final zh = chineseName;
    if (en != null && zh != null) return '$en / $zh';
    return en ?? zh ?? '';
  }

  bool matchesNeedle(String raw) {
    final n = raw.trim().toLowerCase();
    if (n.isEmpty) return false;
    if (englishName?.toLowerCase() == n) return true;
    if (chineseName?.toLowerCase() == n) return true;
    if (displayName.toLowerCase() == n) return true;
    return false;
  }

  factory ShopRow.fromMap(Map<String, dynamic> map) => ShopRow(
    id: map['id'] as String,
    name: map['name'] as String?,
    nameZh: map['name_zh'] as String?,
    notes: map['notes'] as String?,
    userId: map['user_id'] as String?,
    isUserAdded: map['is_user_added'] as bool? ?? true,
  );

  ShopRow copyWith({
    String? name,
    String? nameZh,
    String? notes,
    bool clearName = false,
    bool clearNameZh = false,
    bool clearNotes = false,
  }) {
    return ShopRow(
      id: id,
      name: clearName ? null : (name ?? this.name),
      nameZh: clearNameZh ? null : (nameZh ?? this.nameZh),
      notes: clearNotes ? null : (notes ?? this.notes),
      userId: userId,
      isUserAdded: isUserAdded,
    );
  }
}

Map<String, dynamic> shopCreateColumns(String raw) {
  final trimmed = raw.trim();
  if (looksLikeChineseOnly(trimmed)) {
    return {'name': null, 'name_zh': trimmed};
  }
  return {'name': trimmed, 'name_zh': null};
}

class ToppingRow {
  const ToppingRow({
    required this.id,
    required this.name,
    required this.userId,
    required this.isUserAdded,
    this.colorHex,
    this.colorIntensity,
  });

  final String id;
  final String name;
  final String? userId;
  final bool isUserAdded;

  /// Chip fill `#RRGGBB`. Null until the SQL snippet is applied / row is colored.
  final String? colorHex;

  /// 0–100. Null until `color_intensity` is migrated; treat as 100.
  final int? colorIntensity;

  factory ToppingRow.fromMap(Map<String, dynamic> map) => ToppingRow(
    id: map['id'] as String,
    name: map['name'] as String,
    userId: map['user_id'] as String?,
    isUserAdded: map['is_user_added'] as bool? ?? true,
    colorHex: map['color_hex'] as String?,
    colorIntensity: (map['color_intensity'] as num?)?.toInt(),
  );

  ToppingRow copyWith({String? colorHex, int? colorIntensity}) {
    return ToppingRow(
      id: id,
      name: name,
      userId: userId,
      isUserAdded: isUserAdded,
      colorHex: colorHex ?? this.colorHex,
      colorIntensity: colorIntensity ?? this.colorIntensity,
    );
  }
}

class DrinkEntryRow {
  const DrinkEntryRow({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.teaName,
    required this.drinkType,
    this.sugarLevel,
    this.iceLevel,
    required this.price,
    required this.grade,
    required this.overallGrade,
    required this.notes,
    required this.loggedAt,
    this.hangoutId,
    this.shop,
    this.toppings = const [],
    this.companions = const [],
  });

  final String id;
  final String userId;
  final String shopId;
  final String teaName;
  final String drinkType;

  /// Null = Fixed / unassigned (shop specials). Do not treat as 0.
  final int? sugarLevel;
  final int? iceLevel;
  final double price;
  final int? grade;
  final String? overallGrade;
  final String? notes;
  final DateTime loggedAt;
  final String? hangoutId;
  final ShopRow? shop;
  final List<ToppingRow> toppings;
  final List<DrinkCompanionView> companions;

  LetterGrade? get letter {
    if (grade != null) return LetterGrade.fromPoints(grade!);
    return LetterGrade.fromOverall(overallGrade);
  }

  factory DrinkEntryRow.fromMap(Map<String, dynamic> map) {
    ShopRow? shop;
    final rawShop = map['shops'];
    if (rawShop is Map<String, dynamic>) {
      shop = ShopRow.fromMap(rawShop);
    }

    final toppings = <ToppingRow>[];
    final joins = map['drink_toppings'];
    if (joins is List) {
      for (final join in joins) {
        if (join is Map<String, dynamic>) {
          final t = join['toppings'];
          if (t is Map<String, dynamic>) {
            toppings.add(ToppingRow.fromMap(t));
          }
        }
      }
    }

    return DrinkEntryRow(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      shopId: map['shop_id'] as String,
      teaName: map['tea_name'] as String,
      drinkType: map['drink_type'] as String,
      sugarLevel: (map['sugar_level'] as num?)?.toInt(),
      iceLevel: (map['ice_level'] as num?)?.toInt(),
      price: (map['price'] as num).toDouble(),
      grade: (map['grade'] as num?)?.toInt(),
      overallGrade: map['overall_grade'] as String?,
      notes: map['notes'] as String?,
      loggedAt: DateTime.parse(map['logged_at'] as String).toLocal(),
      hangoutId: map['hangout_id'] as String?,
      shop: shop,
      toppings: toppings,
    );
  }

  DrinkEntryRow withRelations({
    ShopRow? shop,
    List<ToppingRow>? toppings,
    List<DrinkCompanionView>? companions,
    String? hangoutId,
  }) {
    return DrinkEntryRow(
      id: id,
      userId: userId,
      shopId: shopId,
      teaName: teaName,
      drinkType: drinkType,
      sugarLevel: sugarLevel,
      iceLevel: iceLevel,
      price: price,
      grade: grade,
      overallGrade: overallGrade,
      notes: notes,
      loggedAt: loggedAt,
      hangoutId: hangoutId ?? this.hangoutId,
      shop: shop ?? this.shop,
      toppings: toppings ?? this.toppings,
      companions: companions ?? this.companions,
    );
  }
}

class DrinkCompanionView {
  const DrinkCompanionView({
    required this.userId,
    required this.username,
    this.peerDrinkId,
    this.inviteStatus,
  });

  final String userId;
  final String username;
  final String? peerDrinkId;
  final String? inviteStatus;

  bool get hasLinkedPeer => peerDrinkId != null && peerDrinkId!.isNotEmpty;
}

class ShopFeedItem {
  const ShopFeedItem({
    required this.shop,
    required this.visitCount,
    required this.averageGrade,
    required this.lastLoggedAt,
  });

  final ShopRow shop;
  final int visitCount;
  final double averageGrade;
  final DateTime lastLoggedAt;

  AggregateBand? get band => bandForAverage(averageGrade);
}

class FavoriteShopForBase {
  const FavoriteShopForBase({
    required this.drinkType,
    required this.shop,
    required this.averageGrade,
  });

  final String drinkType;
  final ShopRow shop;
  final double averageGrade;

  AggregateBand? get band => bandForAverage(averageGrade);
}

class TasteProfile {
  const TasteProfile({
    required this.entries,
    required this.shops,
    required this.averageSugarPercent,
    required this.favoriteBase,
    required this.highestRatedShop,
    required this.shopFeed,
    this.averageIcePercent,
    this.mostVisitedShop,
    this.favoriteShopsByBase = const [],
    this.averagePrice,
    this.favoriteTopping,
    this.favoriteToppingColorHex,
    this.favoriteToppingIntensity,
    this.daysSinceLastDrink,
  });

  final List<DrinkEntryRow> entries;
  final List<ShopRow> shops;
  final int? averageSugarPercent;
  final String? favoriteBase;
  final ShopFeedItem? highestRatedShop;
  final List<ShopFeedItem> shopFeed;
  final int? averageIcePercent;
  final ShopFeedItem? mostVisitedShop;
  final List<FavoriteShopForBase> favoriteShopsByBase;
  final double? averagePrice;
  final String? favoriteTopping;
  final String? favoriteToppingColorHex;
  final int? favoriteToppingIntensity;
  final int? daysSinceLastDrink;

  bool get isEmpty => entries.isEmpty;
}

const drinkBases = <String>['Milk-based', 'Tea-based', 'Fruit-based', 'Other'];

const newUserToppingSeeds = <String>[
  'Boba',
  'Pudding',
  'Grass Jelly',
  'Aloe',
  'Red Bean',
  'Cheese Foam',
];

class ChainShopSeed {
  const ChainShopSeed({required this.name, required this.nameZh});
  final String name;
  final String nameZh;
}

/// Well-known Taiwan chains for a true new user. English in `name`, Chinese in `name_zh`.
const newUserShopSeeds = <ChainShopSeed>[
  ChainShopSeed(name: '50 Lan', nameZh: '五十嵐'),
  ChainShopSeed(name: 'Comebuy', nameZh: '清心福全'),
  ChainShopSeed(name: 'Chun Shui Tang', nameZh: '春水堂'),
  ChainShopSeed(name: 'TP Tea', nameZh: '茶湯會'),
  ChainShopSeed(name: 'Milksha', nameZh: '迷客夏'),
  ChainShopSeed(name: 'Kebuke', nameZh: '可不可熟成紅茶'),
  ChainShopSeed(name: 'Macu', nameZh: '麻古茶坊'),
  ChainShopSeed(name: 'WOOTEA', nameZh: '五桐號'),
  ChainShopSeed(name: 'Tiger Sugar', nameZh: '老虎堂'),
  ChainShopSeed(name: 'Yi Fang', nameZh: '一芳水果茶'),
  ChainShopSeed(name: 'Dayungs', nameZh: '大苑子'),
  ChainShopSeed(name: 'Presotea', nameZh: '鮮茶道'),
  ChainShopSeed(name: 'Gong Cha', nameZh: '貢茶'),
  ChainShopSeed(name: 'Chatime', nameZh: '日出茶太'),
  ChainShopSeed(name: 'Sharetea', nameZh: '歇腳亭'),
  ChainShopSeed(name: 'CoCo', nameZh: '都可'),
  ChainShopSeed(name: 'Wanpo', nameZh: '萬波島嶼紅茶'),
  ChainShopSeed(name: 'Truedan', nameZh: '珍煮丹'),
];

/// Seed the six default names only for a true new user (zero toppings).
/// Users who already have a catalog — including Joshua’s 11 — get nothing.
List<String> toppingsToSeedForUser(Iterable<String> existingNames) {
  if (existingNames.any((name) => name.trim().isNotEmpty)) {
    return const [];
  }
  return List<String>.from(newUserToppingSeeds);
}

/// Seed bilingual chain shops only for a true new user (zero shops).
/// Existing catalogs — including Joshua’s 18 — are left untouched.
List<ChainShopSeed> shopsToSeedForUser(Iterable<String> existingNames) {
  if (existingNames.any((name) => name.trim().isNotEmpty)) {
    return const [];
  }
  return List<ChainShopSeed>.from(newUserShopSeeds);
}

String formatTwd(num price) {
  if (price == price.roundToDouble()) {
    return 'NT\$ ${price.round()}';
  }
  return 'NT\$ ${price.toStringAsFixed(2)}';
}
