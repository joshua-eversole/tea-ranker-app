import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../grading/grade.dart';
import '../theme/topping_colors.dart';
import 'hangouts.dart';
import 'models.dart';
import 'shop_brands.dart';
import 'social.dart';
import 'taste_stats.dart';

class TeaRepository extends ChangeNotifier {
  TeaRepository(this._client);

  final SupabaseClient _client;

  TasteProfile? profile;
  Object? loadError;
  bool loading = false;
  ProfileRow? account;
  List<ToppingRow> toppings = const [];
  List<ShopBrand> shopBrands = const [];

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
    final rows = await _client.from('toppings').select().eq('user_id', uid);
    final existing = (rows as List)
        .map((e) => ToppingRow.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final toInsert = toppingsToSeedForUser(existing.map((t) => t.name));
    if (toInsert.isEmpty) return;
    final withColor = [
      for (final seed in toInsert)
        {
          'user_id': uid,
          'name': seed,
          'is_user_added': true,
          'color_hex':
              namedColorHexForTopping(seed) ??
              colorHexForNewTopping(seed, existingHexes: const []),
          'color_intensity': kToppingDefaultIntensity,
        },
    ];
    try {
      await _client.from('toppings').insert(withColor);
    } catch (_) {
      try {
        await _client.from('toppings').insert([
          for (final row in withColor)
            {
              'user_id': uid,
              'name': row['name'],
              'is_user_added': true,
              'color_hex': row['color_hex'],
            },
        ]);
      } catch (_) {
        // Columns may not exist until Joshua pastes the SQL snippets.
        await _client.from('toppings').insert([
          for (final seed in toInsert)
            {'user_id': uid, 'name': seed, 'is_user_added': true},
        ]);
      }
    }
  }

  Future<void> seedShopsIfMissing() async {
    final uid = userId;
    if (uid == null) return;
    final rows = await _client.from('shops').select().eq('user_id', uid);
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
          {'user_id': uid, 'name': seed.name, 'is_user_added': false},
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
        entryRows = await _client
            .from('drink_entries')
            .select('*, shops(*), drink_toppings(*, toppings(*))')
            .eq('user_id', uid);
      } catch (_) {
        entryRows = await _client
            .from('drink_entries')
            .select()
            .eq('user_id', uid);
      }
      final shopRows = await _client.from('shops').select().eq('user_id', uid);
      final toppingRows = await _client
          .from('toppings')
          .select()
          .eq('user_id', uid);
      final joinRows = await _client.from('drink_toppings').select();
      final profileRow = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      final shops = (shopRows as List)
          .map((e) => ShopRow.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      toppings =
          (toppingRows as List)
              .map(
                (e) => ToppingRow.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

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

      final entryList = List<dynamic>.from(entryRows as List);
      final companionsByDrink = await _companionsByDrink([
        for (final e in entryList)
          Map<String, dynamic>.from(e as Map)['id'] as String,
      ]);

      final entries = entryList.map((e) {
        final row = DrinkEntryRow.fromMap(Map<String, dynamic>.from(e as Map));
        return row.withRelations(
          shop: shopById[row.shopId],
          toppings: toppingsByDrink[row.id] ?? row.toppings,
          companions: companionsByDrink[row.id] ?? const [],
        );
      }).toList()..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

      if (profileRow != null) {
        account = ProfileRow.fromMap(profileRow);
      }

      await _loadShopBrands();

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
          .insert({'user_id': uid, ...columns, 'is_user_added': true})
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
    int? colorIntensity,
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
    final intensity = snapIntensity(colorIntensity);
    Map<String, dynamic>? inserted;
    Object? lastError;
    for (final payload in [
      {
        'user_id': uid,
        'name': name,
        'is_user_added': true,
        'color_hex': hex,
        'color_intensity': intensity,
      },
      {'user_id': uid, 'name': name, 'is_user_added': true, 'color_hex': hex},
      {'user_id': uid, 'name': name, 'is_user_added': true},
    ]) {
      try {
        inserted = await _client
            .from('toppings')
            .insert(payload)
            .select()
            .single();
        lastError = null;
        break;
      } catch (e) {
        lastError = e;
      }
    }
    if (inserted == null) {
      throw lastError ?? StateError('Couldn’t add that topping.');
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
    List<String> companionUserIds = const [],
    HangoutLogPrefill? hangoutPrefill,
  }) async {
    final uid = userId;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final shop = await matchOrCreateShop(shopName);
    final hangoutId =
        hangoutPrefill?.hangoutId ??
        (companionUserIds.isNotEmpty ? newHangoutId() : null);
    final insertPayload = <String, dynamic>{
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
    };
    if (hangoutId != null) insertPayload['hangout_id'] = hangoutId;
    Map<String, dynamic> entry;
    try {
      entry = await _client
          .from('drink_entries')
          .insert(insertPayload)
          .select()
          .single();
    } catch (_) {
      insertPayload.remove('hangout_id');
      entry = await _client
          .from('drink_entries')
          .insert(insertPayload)
          .select()
          .single();
    }
    final drinkId = entry['id'] as String;
    if (selectedToppings.isNotEmpty) {
      await _client.from('drink_toppings').insert([
        for (final t in selectedToppings)
          {'drink_id': drinkId, 'topping_id': t.id},
      ]);
    }
    await syncHangoutCompanions(
      drinkId: drinkId,
      shopName: shop.displayName.isNotEmpty ? shop.displayName : shopName,
      localDay: localDay,
      hangoutId: hangoutId ?? entry['hangout_id'] as String?,
      selectedFriendIds: companionUserIds,
      previousFriendIds: const [],
      hangoutPrefill: hangoutPrefill,
    );
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
    List<String> companionUserIds = const [],
  }) async {
    final uid = userId;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final shop = await matchOrCreateShop(shopName);
    DrinkEntryRow? existing;
    for (final e in profile?.entries ?? const <DrinkEntryRow>[]) {
      if (e.id == drinkId) existing = e;
    }
    var hangoutId = existing?.hangoutId;
    if (companionUserIds.isNotEmpty) {
      hangoutId ??= newHangoutId();
    }
    final payload = drinkEntryWritePayload(
      shopId: shop.id,
      teaName: teaName,
      drinkType: drinkType,
      sugarLevel: sugarLevel,
      iceLevel: iceLevel,
      price: price,
      grade: grade,
      notes: notes,
      localDay: localDay,
    );
    try {
      await _client
          .from('drink_entries')
          .update({...payload, 'hangout_id': ?hangoutId})
          .eq('id', drinkId)
          .eq('user_id', uid);
    } catch (_) {
      await _client
          .from('drink_entries')
          .update(payload)
          .eq('id', drinkId)
          .eq('user_id', uid);
    }
    await replaceDrinkToppings(
      client: _client,
      drinkId: drinkId,
      selectedToppings: selectedToppings,
    );
    await syncHangoutCompanions(
      drinkId: drinkId,
      shopName: shop.displayName.isNotEmpty ? shop.displayName : shopName,
      localDay: localDay,
      hangoutId: hangoutId,
      selectedFriendIds: companionUserIds,
      previousFriendIds: [
        for (final c in existing?.companions ?? const <DrinkCompanionView>[])
          c.userId,
      ],
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
    final payload = <String, dynamic>{'name': en, 'name_zh': zh};
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
    await _client
        .from('profiles')
        .update({'default_sugar_percent': sugar, 'default_ice_percent': ice})
        .eq('id', uid);
    final current = account;
    if (current != null) {
      account = current.copyWith(
        defaultSugarPercent: sugar,
        defaultIcePercent: ice,
      );
      notifyListeners();
    }
  }

  Future<void> updateToppingColor({
    required String toppingId,
    required String colorHex,
    int? colorIntensity,
  }) async {
    final uid = userId;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final hex = normalizeColorHex(colorHex);
    final intensity = snapIntensity(colorIntensity);
    try {
      await _client
          .from('toppings')
          .update({'color_hex': hex, 'color_intensity': intensity})
          .eq('id', toppingId)
          .eq('user_id', uid);
    } catch (_) {
      await _client
          .from('toppings')
          .update({'color_hex': hex})
          .eq('id', toppingId)
          .eq('user_id', uid);
    }
    toppings = [
      for (final t in toppings)
        if (t.id == toppingId)
          t.copyWith(colorHex: hex, colorIntensity: intensity)
        else
          t,
    ];
    final current = profile;
    if (current != null) {
      final entries = [
        for (final e in current.entries)
          e.withRelations(
            toppings: [
              for (final t in e.toppings)
                if (t.id == toppingId)
                  t.copyWith(colorHex: hex, colorIntensity: intensity)
                else
                  t,
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
    await _client
        .from('shops')
        .update({'notes': (text == null || text.isEmpty) ? null : text})
        .eq('id', shopId);
    await refresh();
  }

  static const _friendDrinkSelect =
      'id, user_id, shop_id, tea_name, drink_type, sugar_level, ice_level, price, grade, overall_grade, logged_at, hangout_id, shops(id, user_id, name, name_zh, is_user_added), drink_toppings(drink_id, topping_id, toppings(id, user_id, name, is_user_added, color_hex, color_intensity))';

  Future<Map<String, List<DrinkCompanionView>>> _companionsByDrink(
    List<String> drinkIds,
  ) async {
    if (drinkIds.isEmpty) return {};
    List rows;
    try {
      rows = await _client.from('drink_companions').select() as List;
    } catch (_) {
      return {};
    }
    final wanted = drinkIds.toSet();
    final friendIds = <String>{};
    final raw = <DrinkCompanionRow>[];
    for (final item in rows) {
      final map = Map<String, dynamic>.from(item as Map);
      if (map['friend_user_id'] == null) continue;
      final row = DrinkCompanionRow.fromMap(map);
      if (!wanted.contains(row.drinkEntryId)) continue;
      raw.add(row);
      friendIds.add(row.friendUserId);
    }
    final names = <String, String>{};
    if (friendIds.isNotEmpty) {
      try {
        final profiles = await _client
            .from('profiles')
            .select('id, username')
            .inFilter('id', friendIds.toList());
        for (final p in profiles as List) {
          final m = Map<String, dynamic>.from(p as Map);
          names[m['id'] as String] = (m['username'] as String?) ?? '';
        }
      } catch (_) {}
    }
    final out = <String, List<DrinkCompanionView>>{};
    for (final row in raw) {
      out
          .putIfAbsent(row.drinkEntryId, () => [])
          .add(
            DrinkCompanionView(
              userId: row.friendUserId,
              username: names[row.friendUserId] ?? row.username,
              peerDrinkId: row.peerDrinkId,
              inviteStatus: row.inviteStatus?.name,
            ),
          );
    }
    return out;
  }

  Future<List<DrinkEntryRow>> _friendEntries(String friendId) async {
    dynamic entryRows;
    try {
      entryRows = await _client
          .from('drink_entries')
          .select(_friendDrinkSelect)
          .eq('user_id', friendId)
          .order('logged_at', ascending: false);
    } catch (_) {
      entryRows = await _client
          .from('drink_entries')
          .select(
            'id, user_id, shop_id, tea_name, drink_type, sugar_level, ice_level, price, grade, overall_grade, logged_at',
          )
          .eq('user_id', friendId)
          .order('logged_at', ascending: false);
    }
    final shopRows = await _client
        .from('shops')
        .select()
        .eq('user_id', friendId);
    final shops = (shopRows as List)
        .map((e) => ShopRow.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final shopById = {for (final s in shops) s.id: s};
    final parsed = <DrinkEntryRow>[];
    for (final e in entryRows as List) {
      parsed.add(DrinkEntryRow.fromMap(Map<String, dynamic>.from(e as Map)));
    }
    final companionsByDrink = await _companionsByDrink([
      for (final row in parsed) row.id,
    ]);
    return [
      for (final row in parsed)
        row.withRelations(
          shop: shopById[row.shopId] ?? row.shop,
          companions: companionsByDrink[row.id] ?? const [],
        ),
    ];
  }

  Future<List<DirectoryProfile>> loadDirectory() async {
    final rows = await _client.from('profiles').select('id, username');
    return [
      for (final raw in rows as List)
        DirectoryProfile.fromMap(Map<String, dynamic>.from(raw as Map)),
    ];
  }

  Future<List<FriendshipRow>> loadFriendships() async {
    final rows = await _client.from('friendships').select();
    return [
      for (final raw in rows as List)
        FriendshipRow.fromMap(Map<String, dynamic>.from(raw as Map)),
    ];
  }

  Future<void> sendFriendRequest(String friendId) async {
    final uid = userId;
    if (uid == null) throw StateError('Not signed in');
    if (uid == friendId) {
      throw StateError('You can’t friend yourself.');
    }
    try {
      await _client.from('friendships').insert({
        'user_id': uid,
        'friend_id': friendId,
        'status': 'pending',
      });
    } catch (_) {
      await _client
          .from('friendships')
          .update({'status': 'pending'})
          .eq('user_id', uid)
          .eq('friend_id', friendId)
          .eq('status', 'declined');
    }
  }

  Future<void> respondToInvite({
    required String requesterId,
    required FriendshipStatus status,
  }) async {
    final uid = userId;
    if (uid == null) throw StateError('Not signed in');
    if (status != FriendshipStatus.accepted &&
        status != FriendshipStatus.declined) {
      throw ArgumentError('Invite response must be accept or decline');
    }
    await _client
        .from('friendships')
        .update({'status': status.name})
        .eq('user_id', requesterId)
        .eq('friend_id', uid)
        .eq('status', 'pending');
  }

  Future<TasteProfile> fetchFriendTaste(String friendId) async {
    final uid = userId;
    if (uid == null) throw StateError('Not signed in');
    if (uid == friendId) {
      throw StateError('Open Profile for your own taste.');
    }
    final edges = await loadFriendships();
    if (friendRelation(me: uid, other: friendId, rows: edges) !=
        FriendRelation.accepted) {
      throw StateError('You can only view a friend’s log.');
    }
    final entries = await _friendEntries(friendId);
    final shops = [
      for (final e in entries)
        if (e.shop != null) e.shop!,
    ];
    final uniqueShops = <String, ShopRow>{for (final s in shops) s.id: s};
    return buildTasteProfile(entries, uniqueShops.values.toList());
  }

  Future<DrinkEntryRow> fetchFriendDrink({
    required String friendId,
    required String drinkId,
  }) async {
    final uid = userId;
    if (uid == null) throw StateError('Not signed in');
    final edges = await loadFriendships();
    if (friendRelation(me: uid, other: friendId, rows: edges) !=
        FriendRelation.accepted) {
      throw StateError('You can only view a friend’s log.');
    }
    final entries = await _friendEntries(friendId);
    for (final e in entries) {
      if (e.id == drinkId) return e;
    }
    throw StateError('That drink isn’t in their log.');
  }

  Future<List<HangoutInvite>> loadHangoutInvites() async {
    final uid = userId;
    if (uid == null) return const [];
    List rows;
    try {
      rows =
          await _client
                  .from('drink_companions')
                  .select()
                  .eq('friend_user_id', uid)
                  .eq('invite_status', 'pending')
              as List;
    } catch (_) {
      return const [];
    }
    final invites = <HangoutInvite>[];
    for (final item in rows) {
      final companion = DrinkCompanionRow.fromMap(
        Map<String, dynamic>.from(item as Map),
      );
      try {
        final drinkMap = await _client
            .from('drink_entries')
            .select(
              'id, user_id, hangout_id, logged_at, shops(id, user_id, name, name_zh, is_user_added)',
            )
            .eq('id', companion.drinkEntryId)
            .maybeSingle();
        if (drinkMap == null) continue;
        final map = Map<String, dynamic>.from(drinkMap);
        ShopRow? shop;
        final rawShop = map['shops'];
        if (rawShop is Map<String, dynamic>) {
          shop = ShopRow.fromMap(rawShop);
        }
        final loggedAt = DateTime.parse(map['logged_at'] as String).toLocal();
        final senderId = map['user_id'] as String;
        String senderName = '';
        final profile = await _client
            .from('profiles')
            .select('id, username')
            .eq('id', senderId)
            .maybeSingle();
        if (profile != null) {
          senderName = (profile['username'] as String?) ?? '';
        }
        invites.add(
          HangoutInvite(
            companion: companion,
            senderId: senderId,
            senderUsername: senderName,
            shopName: shop?.displayName ?? '',
            localDay: DateTime(loggedAt.year, loggedAt.month, loggedAt.day),
            hangoutId: map['hangout_id'] as String?,
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return invites;
  }

  Future<void> declineHangoutInvite(String drinkEntryId) async {
    final uid = userId;
    if (uid == null) throw StateError('Not signed in');
    await _client
        .from('drink_companions')
        .update({'invite_status': 'declined'})
        .eq('drink_entry_id', drinkEntryId)
        .eq('friend_user_id', uid)
        .eq('invite_status', 'pending');
  }

  Future<void> syncHangoutCompanions({
    required String drinkId,
    required String shopName,
    required DateTime localDay,
    required String? hangoutId,
    required List<String> selectedFriendIds,
    required List<String> previousFriendIds,
    HangoutLogPrefill? hangoutPrefill,
  }) async {
    final uid = userId;
    if (uid == null) return;
    final selected = {
      for (final id in selectedFriendIds)
        if (id != uid) id,
    };
    final previous = previousFriendIds.toSet();

    for (final removed in previous.difference(selected)) {
      await _client
          .from('drink_companions')
          .delete()
          .eq('drink_entry_id', drinkId)
          .eq('friend_user_id', removed);
    }

    if (selected.isEmpty) return;
    var sharedHangout = hangoutId ?? newHangoutId();
    try {
      await _client
          .from('drink_entries')
          .update({'hangout_id': sharedHangout})
          .eq('id', drinkId)
          .eq('user_id', uid);
    } catch (_) {}

    for (final friendId in selected) {
      if (previous.contains(friendId) &&
          hangoutPrefill?.friendUserId != friendId) {
        continue;
      }
      final isAcceptingSender = hangoutPrefill?.friendUserId == friendId;
      DrinkEntryRow? existing;
      if (!isAcceptingSender) {
        try {
          existing = mostRecentSameShopDay(
            friendDrinks: await _friendEntries(friendId),
            shopName: shopName,
            localDay: localDay,
          );
        } catch (_) {
          existing = null;
        }
      }
      if (isAcceptingSender) {
        await _upsertCompanion(
          drinkEntryId: drinkId,
          friendUserId: friendId,
          inviteStatus: CompanionInviteStatus.accepted,
          peerDrinkId: hangoutPrefill!.fromDrinkId,
        );
        await _client
            .from('drink_companions')
            .update({'invite_status': 'accepted', 'peer_drink_id': drinkId})
            .eq('drink_entry_id', hangoutPrefill.fromDrinkId)
            .eq('friend_user_id', uid);
        if (hangoutPrefill.hangoutId != null) {
          sharedHangout = hangoutPrefill.hangoutId!;
          try {
            await _client
                .from('drink_entries')
                .update({'hangout_id': sharedHangout})
                .eq('id', drinkId)
                .eq('user_id', uid);
          } catch (_) {}
        }
        continue;
      }
      if (existing != null) {
        final theirHangout = existing.hangoutId ?? sharedHangout;
        sharedHangout = theirHangout;
        try {
          await _client
              .from('drink_entries')
              .update({'hangout_id': sharedHangout})
              .eq('id', drinkId)
              .eq('user_id', uid);
          await _client
              .from('drink_entries')
              .update({'hangout_id': sharedHangout})
              .eq('id', existing.id)
              .eq('user_id', friendId);
        } catch (_) {}
        await _upsertCompanion(
          drinkEntryId: drinkId,
          friendUserId: friendId,
          inviteStatus: CompanionInviteStatus.linked,
          peerDrinkId: existing.id,
        );
        await _upsertCompanion(
          drinkEntryId: existing.id,
          friendUserId: uid,
          inviteStatus: CompanionInviteStatus.linked,
          peerDrinkId: drinkId,
        );
      } else {
        await _upsertCompanion(
          drinkEntryId: drinkId,
          friendUserId: friendId,
          inviteStatus: CompanionInviteStatus.pending,
          peerDrinkId: null,
        );
      }
    }
  }

  Future<void> _upsertCompanion({
    required String drinkEntryId,
    required String friendUserId,
    required CompanionInviteStatus inviteStatus,
    required String? peerDrinkId,
  }) async {
    final payload = <String, dynamic>{
      'drink_entry_id': drinkEntryId,
      'friend_user_id': friendUserId,
      'invite_status': inviteStatus.name,
      'peer_drink_id': peerDrinkId,
    };
    try {
      await _client
          .from('drink_companions')
          .upsert(payload, onConflict: 'drink_entry_id,friend_user_id');
    } catch (_) {
      try {
        await _client.from('drink_companions').insert(payload);
      } catch (_) {
        await _client
            .from('drink_companions')
            .update({
              'invite_status': inviteStatus.name,
              'peer_drink_id': peerDrinkId,
            })
            .eq('drink_entry_id', drinkEntryId)
            .eq('friend_user_id', friendUserId);
      }
    }
  }

  Future<void> _loadShopBrands() async {
    try {
      final rows = await _client.from('shop_brands').select();
      final parsed = <ShopBrand>[];
      for (final raw in rows as List) {
        try {
          parsed.add(ShopBrand.fromMap(Map<String, dynamic>.from(raw as Map)));
        } catch (_) {}
      }
      shopBrands = parsed;
    } catch (_) {
      shopBrands = const [];
    }
  }

  ShopBrand? brandFor(ShopRow shop) => brandForShop(shop, shopBrands);

  String? publicLogoUrl(ShopBrand? brand) {
    return resolveLogoUrl(
      brand?.logoPath,
      publicUrlFor: (path) =>
          _client.storage.from(kShopLogosBucket).getPublicUrl(path),
    );
  }

  Future<void> saveShopBrandSettings({
    required ShopRow shop,
    Uint8List? bytes,
    String? contentType,
    List<String> paletteHex = const [],
    String? selectedHex,
    required bool tintHome,
  }) async {
    var brand = brandForShop(shop, shopBrands);
    if (brand == null) {
      final inserted = await _insertBrand({
        'name': shop.englishName,
        'name_zh': shop.chineseName,
        if (paletteHex.isNotEmpty) 'palette_hex': paletteHex,
        'selected_hex': ?selectedHex,
        'tint_home': tintHome,
      });
      if (inserted != null) {
        brand = ShopBrand.fromMap(inserted);
      } else {
        await _loadShopBrands();
        brand = brandForShop(shop, shopBrands);
        if (brand == null) {
          throw StateError('Could not create shop_brands row');
        }
      }
    }
    String? path;
    if (bytes != null && contentType != null) {
      final ext = contentType.contains('png')
          ? 'png'
          : contentType.contains('webp')
          ? 'webp'
          : 'jpg';
      path = '${brand.id}/logo.$ext';
      await _client.storage
          .from(kShopLogosBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
    }
    await _updateBrand(brand.id, {
      'logo_path': ?path,
      if (paletteHex.isNotEmpty) 'palette_hex': paletteHex,
      'selected_hex': ?selectedHex,
      'tint_home': tintHome,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'name': shop.englishName ?? brand.name,
      'name_zh': shop.chineseName ?? brand.nameZh,
    });
    await _loadShopBrands();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _insertBrand(
    Map<String, dynamic> payload,
  ) async {
    try {
      return Map<String, dynamic>.from(
        await _client.from('shop_brands').insert(payload).select().single()
            as Map,
      );
    } catch (_) {
      final slim = Map<String, dynamic>.from(payload)
        ..remove('tint_home')
        ..remove('updated_at');
      try {
        return Map<String, dynamic>.from(
          await _client.from('shop_brands').insert(slim).select().single()
              as Map,
        );
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _updateBrand(String id, Map<String, dynamic> payload) async {
    try {
      await _client.from('shop_brands').update(payload).eq('id', id);
    } catch (_) {
      final slim = Map<String, dynamic>.from(payload)
        ..remove('tint_home')
        ..remove('updated_at');
      await _client.from('shop_brands').update(slim).eq('id', id);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _signInWork = null;
    profile = null;
    account = null;
    toppings = const [];
    shopBrands = const [];
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
    'notes': (trimmedNotes == null || trimmedNotes.isEmpty)
        ? null
        : trimmedNotes,
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
