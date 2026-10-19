import 'models.dart';

/// Overlay open control on the compact Taste Profile card.
const kMoreTasteDetailsLabel = 'More taste details';

/// Semantics / tooltip for that control.
const kOpenTasteDetailsHint = 'Open for more information';

const kTasteDetailsTitle = 'Taste details';
const kNoDrinksYetCopy = 'No drinks yet';
const kCloseTasteDetailsTooltip = 'Close';

/// Bases that get a “favorite shop” row. Skip any the user has never logged.
const kTasteDetailBases = <String>[
  'Tea-based',
  'Milk-based',
  'Fruit-based',
];

int calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

String formatDaysSinceLastDrink(int? days) {
  if (days == null) return '—';
  if (days == 1) return '1 day';
  return '$days days';
}

String formatAveragePercent(int? percent) {
  if (percent == null) return '—';
  return '$percent%';
}

String formatAveragePrice(double? price) {
  if (price == null) return '—';
  return formatTwd(price);
}

String favoriteShopLabelForBase(String drinkType) {
  return 'Favorite $drinkType shop';
}

/// Client-side rollup of the signed-in user’s drinks. No extra SQL.
TasteProfile buildTasteProfile(
  List<DrinkEntryRow> entries,
  List<ShopRow> shops, {
  DateTime? now,
}) {
  final sorted = [...entries]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  final clock = now ?? DateTime.now();

  int? avgSugar;
  int? avgIce;
  double? avgPrice;
  String? favoriteBase;
  String? favoriteTopping;
  String? favoriteToppingColorHex;
  int? daysSince;
  if (sorted.isNotEmpty) {
    avgSugar = _meanInt(sorted.map((e) => e.sugarLevel));
    avgIce = _meanInt(sorted.map((e) => e.iceLevel));
    avgPrice = sorted.map((e) => e.price).reduce((a, b) => a + b) / sorted.length;
    favoriteBase = _favoriteByCount(
      sorted,
      keyOf: (e) => e.drinkType,
    );
    final favTop = _favoriteTopping(sorted);
    favoriteTopping = favTop?.name;
    favoriteToppingColorHex = favTop?.colorHex;
    daysSince = calendarDaysBetween(sorted.first.loggedAt, clock);
    if (daysSince < 0) daysSince = 0;
  }

  final byShop = <String, List<DrinkEntryRow>>{};
  for (final e in sorted) {
    byShop.putIfAbsent(e.shopId, () => []).add(e);
  }

  final shopById = {for (final s in shops) s.id: s};
  final feed = <ShopFeedItem>[];
  ShopFeedItem? mostVisited;

  for (final grouping in byShop.entries) {
    final list = grouping.value;
    final shop = shopById[grouping.key] ?? list.first.shop;
    if (shop == null) continue;
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final grades = list
        .map((e) => e.grade ?? e.letter?.points)
        .whereType<int>()
        .toList();
    final avg = grades.isEmpty
        ? 0.0
        : grades.reduce((a, b) => a + b) / grades.length;
    final item = ShopFeedItem(
      shop: shop,
      visitCount: list.length,
      averageGrade: avg,
      lastLoggedAt: list.first.loggedAt,
    );
    if (grades.isNotEmpty) {
      feed.add(item);
    }
    if (mostVisited == null ||
        item.visitCount > mostVisited.visitCount ||
        (item.visitCount == mostVisited.visitCount &&
            item.lastLoggedAt.isAfter(mostVisited.lastLoggedAt))) {
      mostVisited = item;
    }
  }
  feed.sort((a, b) => b.lastLoggedAt.compareTo(a.lastLoggedAt));

  ShopFeedItem? highest;
  if (feed.isNotEmpty) {
    highest = feed.first;
    for (final item in feed) {
      if (item.averageGrade > highest!.averageGrade) {
        highest = item;
      }
    }
  }

  final favoriteShopsByBase = <FavoriteShopForBase>[];
  for (final base in kTasteDetailBases) {
    final pick = _favoriteShopForBase(sorted, shopById, base);
    if (pick != null) favoriteShopsByBase.add(pick);
  }

  return TasteProfile(
    entries: sorted,
    shops: shops,
    averageSugarPercent: avgSugar,
    favoriteBase: favoriteBase,
    highestRatedShop: highest,
    shopFeed: feed,
    averageIcePercent: avgIce,
    mostVisitedShop: mostVisited,
    favoriteShopsByBase: favoriteShopsByBase,
    averagePrice: avgPrice,
    favoriteTopping: favoriteTopping,
    favoriteToppingColorHex: favoriteToppingColorHex,
    daysSinceLastDrink: daysSince,
  );
}

int _meanInt(Iterable<int> values) {
  final list = values.toList();
  final mean = list.reduce((a, b) => a + b) / list.length;
  return mean.round();
}

String? _favoriteByCount(
  List<DrinkEntryRow> recencyDesc, {
  required String Function(DrinkEntryRow) keyOf,
}) {
  final counts = <String, int>{};
  for (final e in recencyDesc) {
    final key = keyOf(e);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  var bestCount = 0;
  String? favorite;
  for (final e in recencyDesc) {
    final key = keyOf(e);
    final c = counts[key] ?? 0;
    if (c > bestCount) {
      bestCount = c;
      favorite = key;
    }
  }
  return favorite;
}

ToppingRow? _favoriteTopping(List<DrinkEntryRow> recencyDesc) {
  final counts = <String, int>{};
  for (final e in recencyDesc) {
    for (final t in e.toppings) {
      counts[t.name] = (counts[t.name] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return null;
  var bestCount = 0;
  for (final c in counts.values) {
    if (c > bestCount) bestCount = c;
  }
  for (final e in recencyDesc) {
    for (final t in e.toppings) {
      if ((counts[t.name] ?? 0) == bestCount) return t;
    }
  }
  return null;
}

FavoriteShopForBase? _favoriteShopForBase(
  List<DrinkEntryRow> recencyDesc,
  Map<String, ShopRow> shopById,
  String drinkType,
) {
  final ofType = recencyDesc.where((e) => e.drinkType == drinkType).toList();
  if (ofType.isEmpty) return null;

  final byShop = <String, List<DrinkEntryRow>>{};
  for (final e in ofType) {
    byShop.putIfAbsent(e.shopId, () => []).add(e);
  }

  FavoriteShopForBase? best;
  DateTime? bestRecent;
  for (final grouping in byShop.entries) {
    final list = grouping.value;
    final shop = shopById[grouping.key] ?? list.first.shop;
    if (shop == null) continue;
    final grades = list
        .map((e) => e.grade ?? e.letter?.points)
        .whereType<int>()
        .toList();
    if (grades.isEmpty) continue;
    final avg = grades.reduce((a, b) => a + b) / grades.length;
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final recent = list.first.loggedAt;
    final candidate = FavoriteShopForBase(
      drinkType: drinkType,
      shop: shop,
      averageGrade: avg,
    );
    if (best == null ||
        avg > best.averageGrade ||
        (avg == best.averageGrade &&
            (bestRecent == null || recent.isAfter(bestRecent)))) {
      best = candidate;
      bestRecent = recent;
    }
  }
  return best;
}
