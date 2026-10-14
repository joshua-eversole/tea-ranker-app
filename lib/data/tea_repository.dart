import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../grading/grade.dart';
import 'models.dart';

class TeaRepository extends ChangeNotifier {
  TeaRepository(this._client);

  final SupabaseClient _client;

  TasteProfile? profile;
  Object? loadError;
  bool loading = false;
  ProfileRow? account;
  List<ToppingRow> toppings = const [];

  String? get userId => _client.auth.currentUser?.id;

  Future<void>? _signInWork;

  Future<void> onSignedIn() {
    _signInWork ??= () async {
      try {
        await _onSignedInBody();
      } catch (_) {
        _signInWork = null;
        rethrow;
      }
    }();
    return _signInWork!;
  }

  Future<void> _onSignedInBody() async {
    await ensureProfile();
    await seedToppingsIfMissing();
    await seedShopsIfMissing();
    await refresh();
  }

  Future<void> ensureProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) {
      account = ProfileRow.fromMap(existing);
      notifyListeners();
      return;
    }
    final meta = user.userMetadata?['username'] as String?;
    final username = (meta != null && meta.trim().isNotEmpty)
        ? meta.trim()
        : (user.email?.split('@').first ?? 'drinker');
    await _client.from('profiles').insert({
      'id': user.id,
      'username': username,
    });
    account = ProfileRow(id: user.id, username: username);
    notifyListeners();
  }

  Future<void> seedToppingsIfMissing() async {
    final uid = userId;
    if (uid == null) return;
    final rows = await _client.from('toppings').select();
    final existing = (rows as List)
        .map((e) => ToppingRow.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final toInsert = toppingsToSeedForUser(existing.map((t) => t.name));
    if (toInsert.isEmpty) return;
    await _client.from('toppings').insert([
      for (final seed in toInsert)
        {
          'user_id': uid,
          'name': seed,
          'is_user_added': true,
        },
    ]);
  }

  Future<void> seedShopsIfMissing() async {
    final uid = userId;
    if (uid == null) return;
    final rows = await _client.from('shops').select();
    final existing = (rows as List)
        .map((e) => ShopRow.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    // Any existing catalog (Joshua’s 18, or ZH-only rows) is left untouched.
    if (existing.isNotEmpty) return;
    final toInsert = shopsToSeedForUser(const []);
    if (toInsert.isEmpty) return;
    final payload = [
      for (final seed in toInsert)
        {
          'user_id': uid,
          'name': seed.name,
          'name_zh': seed.nameZh,
          'is_user_added': false,
        },
    ];
    try {
      await _client.from('shops').insert(payload);
    } catch (_) {
      // Column `name_zh` may not exist until Joshua runs the SQL snippet.
      await _client.from('shops').insert([
        for (final seed in toInsert)
          {
            'user_id': uid,
            'name': seed.name,
            'is_user_added': false,
          },
      ]);
    }
  }

  Future<void> refresh() async {
    final uid = userId;
    if (uid == null) return;
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      dynamic entryRows;
      try {
        entryRows = await _client.from('drink_entries').select(
              '*, shops(*), drink_toppings(*, toppings(*))',
            );
      } catch (_) {
        entryRows = await _client.from('drink_entries').select();
      }
      final shopRows = await _client.from('shops').select();
      final toppingRows = await _client.from('toppings').select();
      final joinRows = await _client.from('drink_toppings').select();
      final profileRow = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      final shops = (shopRows as List)
          .map((e) => ShopRow.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      toppings = (toppingRows as List)
          .map((e) => ToppingRow.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final shopById = {for (final s in shops) s.id: s};
      final toppingById = {for (final t in toppings) t.id: t};
      final toppingsByDrink = <String, List<ToppingRow>>{};
      for (final raw in joinRows as List) {
        final map = Map<String, dynamic>.from(raw as Map);
        final drinkId = map['drink_id'] as String;
        final toppingId = map['topping_id'] as String;
        final topping = toppingById[toppingId];
        if (topping == null) continue;
        toppingsByDrink.putIfAbsent(drinkId, () => []).add(topping);
      }

      final entries = (entryRows as List)
          .map((e) {
            final row =
                DrinkEntryRow.fromMap(Map<String, dynamic>.from(e as Map));
            return row.withRelations(
              shop: shopById[row.shopId],
              toppings: toppingsByDrink[row.id] ?? row.toppings,
            );
          })
          .toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

      if (profileRow != null) {
        account = ProfileRow.fromMap(profileRow);
      }

      profile = _buildTasteProfile(entries, shops);
      loading = false;
      notifyListeners();
    } catch (e) {
      loadError = e;
      loading = false;
      notifyListeners();
    }
  }

  TasteProfile _buildTasteProfile(
    List<DrinkEntryRow> entries,
    List<ShopRow> shops,
  ) {
    int? avgSugar;
    String? favoriteBase;
    if (entries.isNotEmpty) {
      final sugarMean =
          entries.map((e) => e.sugarLevel).reduce((a, b) => a + b) /
              entries.length;
      avgSugar = sugarMean.round();

      final counts = <String, int>{};
      for (final e in entries) {
        counts[e.drinkType] = (counts[e.drinkType] ?? 0) + 1;
      }
      var bestCount = 0;
      for (final e in entries) {
        final c = counts[e.drinkType] ?? 0;
        if (c > bestCount) {
          bestCount = c;
          favoriteBase = e.drinkType;
        }
      }
      // Tie: most recent (entries already sorted by logged_at desc).
    }

    final byShop = <String, List<DrinkEntryRow>>{};
    for (final e in entries) {
      byShop.putIfAbsent(e.shopId, () => []).add(e);
    }

    final shopById = {for (final s in shops) s.id: s};
    final feed = <ShopFeedItem>[];
    for (final entry in byShop.entries) {
      final list = entry.value;
      final shop = shopById[entry.key] ?? list.first.shop;
      if (shop == null) continue;
      final grades = list
          .map((e) => e.grade ?? e.letter?.points)
          .whereType<int>()
          .toList();
      if (grades.isEmpty) continue;
      final avg = grades.reduce((a, b) => a + b) / grades.length;
      list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      feed.add(
        ShopFeedItem(
          shop: shop,
          visitCount: list.length,
          averageGrade: avg,
          lastLoggedAt: list.first.loggedAt,
        ),
      );
    }
    feed.sort((a, b) => b.lastLoggedAt.compareTo(a.lastLoggedAt));

    ShopFeedItem? highest;
    if (feed.isNotEmpty) {
      highest = feed.first;
      for (final item in feed) {
        if (item.averageGrade > highest!.averageGrade) {
          highest = item;
        }
        // TODO: spec does not define a tie-break when two shops share avg(grade).
      }
    }

    return TasteProfile(
      entries: entries,
      shops: shops,
      averageSugarPercent: avgSugar,
      favoriteBase: favoriteBase,
      highestRatedShop: highest,
      shopFeed: feed,
    );
  }

  List<DrinkEntryRow> drinksForShop(String shopId) {
    final entries = profile?.entries ?? const <DrinkEntryRow>[];
    return entries.where((e) => e.shopId == shopId).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  ShopFeedItem? feedItem(String shopId) {
    final feed = profile?.shopFeed ?? const <ShopFeedItem>[];
    for (final item in feed) {
      if (item.shop.id == shopId) return item;
    }
    return null;
  }

  Future<ShopRow> matchOrCreateShop(String rawName) async {
    final uid = userId;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final shops = profile?.shops ?? const <ShopRow>[];
    for (final shop in shops) {
      if (shop.matchesNeedle(rawName)) return shop;
    }
    final columns = shopCreateColumns(rawName);
    if (trimToNull(columns['name'] as String?) == null &&
        trimToNull(columns['name_zh'] as String?) == null) {
      throw ArgumentError('Shop name is empty');
    }
    try {
      final inserted = await _client
          .from('shops')
          .insert({
            'user_id': uid,
            ...columns,
            'is_user_added': true,
          })
          .select()
          .single();
      return ShopRow.fromMap(inserted);
    } catch (e) {
      // English-only fallback if `name_zh` is not migrated yet. Never invent
      // a dummy English name for a Chinese-only shop.
      if (columns['name'] == null) rethrow;
      final inserted = await _client
          .from('shops')
          .insert({
            'user_id': uid,
            'name': columns['name'],
            'is_user_added': true,
          })
          .select()
          .single();
      return ShopRow.fromMap(inserted);
    }
  }

  Future<ToppingRow> matchOrCreateTopping(String rawName) async {
    final uid = userId;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final needle = rawName.trim().toLowerCase();
    if (needle.isEmpty) {
      throw ArgumentError('Topping name is empty');
    }
    for (final t in toppings) {
      if (t.name.trim().toLowerCase() == needle) return t;
    }
    final inserted = await _client
        .from('toppings')
        .insert({
          'user_id': uid,
          'name': rawName.trim(),
          'is_user_added': true,
        })
        .select()
        .single();
    final row = ToppingRow.fromMap(inserted);
    toppings = [...toppings, row]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    return row;
  }

  Future<void> saveDrink({
    required DateTime localDay,
    required String shopName,
    required String teaName,
    required double price,
    required String drinkType,
    required int sugarLevel,
    required int iceLevel,
    required List<ToppingRow> selectedToppings,
    required LetterGrade grade,
    required String? notes,
  }) async {
    final uid = userId;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final shop = await matchOrCreateShop(shopName);
    final loggedAt = DateTime(localDay.year, localDay.month, localDay.day, 12);
    final entry = await _client
        .from('drink_entries')
        .insert({
          'user_id': uid,
          'shop_id': shop.id,
          'tea_name': teaName.trim(),
          'drink_type': drinkType,
          'sugar_level': sugarLevel,
          'ice_level': iceLevel,
          'price': price,
          'grade': grade.points,
          'overall_grade': grade.letter,
          'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
          'photo_url': null,
          'logged_at': loggedAt.toUtc().toIso8601String(),
        })
        .select()
        .single();
    final drinkId = entry['id'] as String;
    if (selectedToppings.isNotEmpty) {
      await _client.from('drink_toppings').insert([
        for (final t in selectedToppings)
          {'drink_id': drinkId, 'topping_id': t.id},
      ]);
    }
    await refresh();
  }

  Future<void> updateShopNames({
    required String shopId,
    required String name,
    String? nameZh,
  }) async {
    final en = trimToNull(name);
    final zh = trimToNull(nameZh);
    if (en == null && zh == null) {
      throw ArgumentError('Need an English or Chinese shop name');
    }
    final payload = <String, dynamic>{
      'name': en,
      'name_zh': zh,
    };
    try {
      await _client.from('shops').update(payload).eq('id', shopId);
    } catch (_) {
      if (en == null) rethrow;
      await _client.from('shops').update({'name': en}).eq('id', shopId);
    }
    await refresh();
  }

  Future<void> updateTasteDefaults({
    required int sugarPercent,
    required int icePercent,
  }) async {
    final uid = userId;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final sugar = snapPercent(sugarPercent);
    final ice = snapPercent(icePercent);
    await _client.from('profiles').update({
      'default_sugar_percent': sugar,
      'default_ice_percent': ice,
    }).eq('id', uid);
    final current = account;
    if (current != null) {
      account = ProfileRow(
        id: current.id,
        username: current.username,
        defaultSugarPercent: sugar,
        defaultIcePercent: ice,
      );
      notifyListeners();
    }
  }

  Future<void> updateShopNotes({
    required String shopId,
    required String? notes,
  }) async {
    final text = notes?.trim();
    await _client.from('shops').update({
      'notes': (text == null || text.isEmpty) ? null : text,
    }).eq('id', shopId);
    await refresh();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _signInWork = null;
    profile = null;
    account = null;
    toppings = const [];
    notifyListeners();
  }
}

String authSignInMessage(AuthException e) {
  final m = e.message.toLowerCase();
  if (m.contains('not confirmed') || m.contains('email not confirmed')) {
    return 'Confirm your email before signing in. Check your inbox for the link.';
  }
  if (m.contains('invalid login') || m.contains('invalid credentials')) {
    return 'Those credentials don’t match. Check your email and password.';
  }
  return e.message;
}
