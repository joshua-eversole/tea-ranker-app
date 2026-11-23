import 'models.dart';
import 'tea_types.dart';

/// Overlay open control on the compact Taste Profile card.
const kMoreTasteDetailsLabel = 'More taste details';

/// Semantics / tooltip for that control.
const kOpenTasteDetailsHint = 'Open for more information';

const kTasteDetailsTitle = 'Taste details';
const kNoDrinksYetCopy = 'No drinks yet';
const kCloseTasteDetailsTooltip = 'Close';
const kHighestTypeLabel = 'Highest type';
const kTeaTypeRankingsLabel = 'Tea type rankings';

/// Bases that get a “favorite shop” row. Skip any the user has never logged.
const kTasteDetailBases = <String>['Tea-based', 'Milk-based', 'Fruit-based'];

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
  int? favoriteToppingIntensity;
  int? daysSince;
  if (sorted.isNotEmpty) {
    avgSugar = _meanInt(sorted.map((e) => e.sugarLevel).whereType<int>());
    avgIce = _meanInt(sorted.map((e) => e.iceLevel).whereType<int>());
    avgPrice =
        sorted.map((e) => e.price).reduce((a, b) => a + b) / sorted.length;
    favoriteBase = _favoriteBaseByAvg(sorted);
    final favTop = _favoriteTopping(sorted);
    favoriteTopping = favTop?.name;
    favoriteToppingColorHex = favTop?.colorHex;
    favoriteToppingIntensity = favTop?.colorIntensity;
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
    teaTypeRankings: _teaTypeRankings(sorted),
    averagePrice: avgPrice,
    favoriteTopping: favoriteTopping,
    favoriteToppingColorHex: favoriteToppingColorHex,
    favoriteToppingIntensity: favoriteToppingIntensity,
    daysSinceLastDrink: daysSince,
  );
}

int? _meanInt(Iterable<int> values) {
  final list = values.toList();
  if (list.isEmpty) return null;
  final mean = list.reduce((a, b) => a + b) / list.length;
  return mean.round();
}

double? _averageGrade(Iterable<DrinkEntryRow> entries) {
  final grades = entries
      .map((e) => e.grade ?? e.letter?.points)
      .whereType<int>()
      .toList();
  if (grades.isEmpty) return null;
  return grades.reduce((a, b) => a + b) / grades.length;
}

/// Highest `avg(grade)` among Tea / Milk / Fruit. Skip a base with none.
/// Tie = most recent drink of that base (same idea as favorite shop).
String? _favoriteBaseByAvg(List<DrinkEntryRow> recencyDesc) {
  String? best;
  double? bestAvg;
  DateTime? bestRecent;
  for (final base in kTasteDetailBases) {
    final ofType = recencyDesc.where((e) => e.drinkType == base).toList();
    if (ofType.isEmpty) continue;
    final avg = _averageGrade(ofType);
    if (avg == null) continue;
    final recent = ofType.first.loggedAt;
    if (best == null ||
        avg > bestAvg! ||
        (avg == bestAvg && (bestRecent == null || recent.isAfter(bestRecent)))) {
      best = base;
      bestAvg = avg;
      bestRecent = recent;
    }
  }
  return best;
}

/// Types the user has logged, highest `avg(grade)` first. Skip types with no drinks.
List<TeaTypeRanking> _teaTypeRankings(List<DrinkEntryRow> recencyDesc) {
  final byId = <String, List<DrinkEntryRow>>{};
  final typeById = <String, TeaTypeRow>{};
  for (final e in recencyDesc) {
    final type = e.teaType;
    if (type == null) continue;
    byId.putIfAbsent(type.id, () => []).add(e);
    typeById.putIfAbsent(type.id, () => type);
  }
  final rankings = <TeaTypeRanking>[];
  for (final grouping in byId.entries) {
    final list = grouping.value;
    final avg = _averageGrade(list);
    if (avg == null) continue;
    rankings.add(
      TeaTypeRanking(
        type: typeById[grouping.key]!,
        averageGrade: avg,
        lastLoggedAt: list.first.loggedAt,
      ),
    );
  }
  rankings.sort((a, b) {
    final byGrade = b.averageGrade.compareTo(a.averageGrade);
    if (byGrade != 0) return byGrade;
    return b.lastLoggedAt.compareTo(a.lastLoggedAt);
  });
  return rankings;
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
