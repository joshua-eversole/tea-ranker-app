import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../grading/grade.dart';
import '../theme/topping_colors.dart';
import 'models.dart';
import 'taste_stats.dart';

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
    final payload = [
      for (final seed in toInsert)
        {
          'user_id': uid,
          'name': seed,
          'is_user_added': true,
          'color_hex': namedColorHexForTopping(seed) ??
              colorHexForNewTopping(seed, existingHexes: const []),
        },
    ];
    try {
      await _client.from('toppings').insert(payload);
    } catch (_) {
      // Column `color_hex` may not exist until Joshua pastes the SQL snippet.
      await _client.from('toppings').insert([
        for (final seed in toInsert)
          {
            'user_id': uid,
            'name': seed,
            'is_user_added': true,
          },
      ]);
    }
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

      profile = buildTasteProfile(entries, shops);
      loading = false;
      notifyListeners();
    } catch (e) {
      loadError = e;
      loading = false;
      notifyListeners();
    }
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

  Future<ToppingRow> matchOrCreateTopping(
    String rawName, {
    String? colorHex,
  }) async {
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
    final name = rawName.trim();
    final hex = normalizeColorHex(
      colorHex ??
          colorHexForNewTopping(
            name,
            existingHexes: toppings.map((t) => t.colorHex),
          ),
    );
    Map<String, dynamic> inserted;
    try {
      inserted = await _client
          .from('toppings')
          .insert({
            'user_id': uid,
            'name': name,
            'is_user_added': true,
            'color_hex': hex,
          })
          .select()
          .single();
    } catch (_) {
      inserted = await _client
          .from('toppings')
          .insert({
            'user_id': uid,
            'name': name,
            'is_user_added': true,
          })
          .select()
          .single();
    }
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
    final entry = await _client
        .from('drink_entries')
        .insert({
          'user_id': uid,
          'photo_url': null,
          ...drinkEntryWritePayload(
            shopId: shop.id,
            teaName: teaName,
            drinkType: drinkType,
            sugarLevel: sugarLevel,
            iceLevel: iceLevel,
            price: price,
            grade: grade,
            notes: notes,
            localDay: localDay,
          ),
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

  /// Updates one owned visit. Never inserts a second `drink_entries` row.
  Future<String> updateDrink({
    required String drinkId,
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
    await _client
        .from('drink_entries')
        .update(
          drinkEntryWritePayload(
            shopId: shop.id,
            teaName: teaName,
            drinkType: drinkType,
            sugarLevel: sugarLevel,
            iceLevel: iceLevel,
            price: price,
            grade: grade,
            notes: notes,
            localDay: localDay,
          ),
        )
        .eq('id', drinkId)
        .eq('user_id', uid);
    await replaceDrinkToppings(
      client: _client,
      drinkId: drinkId,
      selectedToppings: selectedToppings,
    );
    await refresh();
    return shop.id;
  }

  /// Deletes join rows first (in case the FK is not CASCADE), then the visit.
  /// Scoped to `user_id` so RLS + this filter cannot touch another diary.
  Future<void> deleteDrink(String drinkId) async {
    final uid = userId;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    await _client.from('drink_toppings').delete().eq('drink_id', drinkId);
    await _client
        .from('drink_entries')
        .delete()
        .eq('id', drinkId)
        .eq('user_id', uid);
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

  Future<void> updateToppingColor({
    required String toppingId,
    required String colorHex,
  }) async {
    final uid = userId;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final hex = normalizeColorHex(colorHex);
    await _client
        .from('toppings')
        .update({'color_hex': hex})
        .eq('id', toppingId)
        .eq('user_id', uid);
    toppings = [
      for (final t in toppings)
        if (t.id == toppingId) t.copyWith(colorHex: hex) else t,
    ];
    final current = profile;
    if (current != null) {
      final entries = [
        for (final e in current.entries)
          e.withRelations(
            toppings: [
              for (final t in e.toppings)
                if (t.id == toppingId) t.copyWith(colorHex: hex) else t,
            ],
          ),
      ];
      profile = buildTasteProfile(entries, current.shops);
    }
    notifyListeners();
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

/// Shared insert/update body. Always writes both `grade` (1–5) and `overall_grade`.
Map<String, dynamic> drinkEntryWritePayload({
  required String shopId,
  required String teaName,
  required String drinkType,
  required int sugarLevel,
  required int iceLevel,
  required double price,
  required LetterGrade grade,
  required String? notes,
  required DateTime localDay,
}) {
  final loggedAt = DateTime(localDay.year, localDay.month, localDay.day, 12);
  final trimmedNotes = notes?.trim();
  return {
    'shop_id': shopId,
    'tea_name': teaName.trim(),
    'drink_type': drinkType,
    'sugar_level': sugarLevel,
    'ice_level': iceLevel,
    'price': price,
    'grade': grade.points,
    'overall_grade': grade.letter,
    'notes': (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
    'logged_at': loggedAt.toUtc().toIso8601String(),
  };
}

Future<void> replaceDrinkToppings({
  required SupabaseClient client,
  required String drinkId,
  required List<ToppingRow> selectedToppings,
}) async {
  await client.from('drink_toppings').delete().eq('drink_id', drinkId);
  if (selectedToppings.isEmpty) return;
  await client.from('drink_toppings').insert([
    for (final t in selectedToppings) {'drink_id': drinkId, 'topping_id': t.id},
  ]);
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
