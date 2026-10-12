import '../grading/grade.dart';

class ProfileRow {
  const ProfileRow({required this.id, required this.username});
  final String id;
  final String username;

  factory ProfileRow.fromMap(Map<String, dynamic> map) => ProfileRow(
        id: map['id'] as String,
        username: (map['username'] as String?) ?? '',
      );
}

class ShopRow {
  const ShopRow({
    required this.id,
    required this.name,
    required this.userId,
    required this.isUserAdded,
  });

  final String id;
  final String name;
  final String? userId;
  final bool isUserAdded;

  factory ShopRow.fromMap(Map<String, dynamic> map) => ShopRow(
        id: map['id'] as String,
        name: map['name'] as String,
        userId: map['user_id'] as String?,
        isUserAdded: map['is_user_added'] as bool? ?? true,
      );
}

class ToppingRow {
  const ToppingRow({
    required this.id,
    required this.name,
    required this.userId,
    required this.isUserAdded,
  });

  final String id;
  final String name;
  final String? userId;
  final bool isUserAdded;

  factory ToppingRow.fromMap(Map<String, dynamic> map) => ToppingRow(
        id: map['id'] as String,
        name: map['name'] as String,
        userId: map['user_id'] as String?,
        isUserAdded: map['is_user_added'] as bool? ?? true,
      );
}

class DrinkEntryRow {
  const DrinkEntryRow({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.teaName,
    required this.drinkType,
    required this.sugarLevel,
    required this.iceLevel,
    required this.price,
    required this.grade,
    required this.overallGrade,
    required this.notes,
    required this.loggedAt,
    this.shop,
    this.toppings = const [],
  });

  final String id;
  final String userId;
  final String shopId;
  final String teaName;
  final String drinkType;
  final int sugarLevel;
  final int iceLevel;
  final double price;
  final int? grade;
  final String? overallGrade;
  final String? notes;
  final DateTime loggedAt;
  final ShopRow? shop;
  final List<ToppingRow> toppings;

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
      sugarLevel: (map['sugar_level'] as num).toInt(),
      iceLevel: (map['ice_level'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
      grade: (map['grade'] as num?)?.toInt(),
      overallGrade: map['overall_grade'] as String?,
      notes: map['notes'] as String?,
      loggedAt: DateTime.parse(map['logged_at'] as String).toLocal(),
      shop: shop,
      toppings: toppings,
    );
  }

  DrinkEntryRow withRelations({
    ShopRow? shop,
    List<ToppingRow>? toppings,
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
      shop: shop ?? this.shop,
      toppings: toppings ?? this.toppings,
    );
  }
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

class TasteProfile {
  const TasteProfile({
    required this.entries,
    required this.shops,
    required this.averageSugarPercent,
    required this.favoriteBase,
    required this.highestRatedShop,
    required this.shopFeed,
  });

  final List<DrinkEntryRow> entries;
  final List<ShopRow> shops;
  final int? averageSugarPercent;
  final String? favoriteBase;
  final ShopFeedItem? highestRatedShop;
  final List<ShopFeedItem> shopFeed;
}

const drinkBases = <String>[
  'Milk-based',
  'Tea-based',
  'Fruit-based',
  'Other',
];

const newUserToppingSeeds = <String>[
  'Boba',
  'Pudding',
  'Grass Jelly',
  'Aloe',
  'Red Bean',
  'Cheese Foam',
];

/// Seed the six default names only for a true new user (zero toppings).
/// Users who already have a catalog — including Joshua’s 11 — get nothing.
List<String> toppingsToSeedForUser(Iterable<String> existingNames) {
  if (existingNames.any((name) => name.trim().isNotEmpty)) {
    return const [];
  }
  return List<String>.from(newUserToppingSeeds);
}

String formatTwd(num price) {
  if (price == price.roundToDouble()) {
    return 'NT\$ ${price.round()}';
  }
  return 'NT\$ ${price.toStringAsFixed(2)}';
}
