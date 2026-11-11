import 'models.dart';

const kCreatedByAnotherUserSubtitle = 'Created by another user';

bool _nameStarts(String name, String q) => name.startsWith(q);
bool _nameContains(String name, String q) => name.contains(q);

/// Prefix matches first, then substring. Exact current text is omitted
/// unless [omitExact] is false (other-user hits should stay visible).
/// Matches English `name` and Chinese `name_zh`.
List<ShopRow> matchingShops(
  List<ShopRow> shops,
  String query, {
  int limit = 8,
  bool omitExact = true,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final starts = <ShopRow>[];
  final contains = <ShopRow>[];
  for (final shop in shops) {
    final name = (shop.englishName ?? '').toLowerCase();
    final zh = (shop.chineseName ?? '').toLowerCase();
    if (omitExact && shop.matchesNeedle(q)) continue;
    if ((name.isNotEmpty && _nameStarts(name, q)) ||
        (zh.isNotEmpty && _nameStarts(zh, q))) {
      starts.add(shop);
    } else if ((name.isNotEmpty && _nameContains(name, q)) ||
        (zh.isNotEmpty && _nameContains(zh, q))) {
      contains.add(shop);
    } else if (!omitExact && shop.matchesNeedle(q)) {
      starts.add(shop);
    }
  }
  return [...starts, ...contains].take(limit).toList();
}

/// True when the signed-in user’s catalog already has this query
/// (exact name / 中文 / display line, or a prefix/substring suggestion).
bool ownCatalogMatchesQuery(List<ShopRow> ownShops, String query) {
  final q = query.trim();
  if (q.isEmpty) return false;
  for (final shop in ownShops) {
    if (shop.matchesNeedle(q)) return true;
  }
  return matchingShops(ownShops, q).isNotEmpty;
}

class ShopNameSuggestion {
  const ShopNameSuggestion({
    required this.shop,
    required this.createdByAnotherUser,
  });

  final ShopRow shop;
  final bool createdByAnotherUser;
}

/// Own hits first. Other-user names only when the query is non-empty and
/// the signed-in user’s catalog has no match. Empty query never lists others.
List<ShopNameSuggestion> shopLoggerSuggestions({
  required List<ShopRow> ownShops,
  required List<ShopRow> otherShops,
  required String query,
  int limit = 8,
}) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final own = matchingShops(ownShops, q, limit: limit);
  if (own.isNotEmpty || ownCatalogMatchesQuery(ownShops, q)) {
    return [
      for (final shop in own)
        ShopNameSuggestion(shop: shop, createdByAnotherUser: false),
    ];
  }
  final others = matchingShops(
    otherShops,
    q,
    limit: limit,
    omitExact: false,
  );
  return [
    for (final shop in others)
      ShopNameSuggestion(shop: shop, createdByAnotherUser: true),
  ];
}

ShopRow? existingShopForName(Iterable<ShopRow> shops, String raw) {
  for (final shop in shops) {
    if (shop.matchesNeedle(raw)) return shop;
  }
  return null;
}

bool looksLikeUniqueViolation(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('23505') ||
      text.contains('duplicate key') ||
      text.contains('unique constraint') ||
      text.contains('already exists');
}

List<ShopRow> mergeShopsForLog(
  List<ShopRow> owned,
  Iterable<ShopRow?> fromDrinks,
) {
  final byId = {for (final shop in owned) shop.id: shop};
  for (final shop in fromDrinks) {
    if (shop != null) byId.putIfAbsent(shop.id, () => shop);
  }
  return byId.values.toList();
}
