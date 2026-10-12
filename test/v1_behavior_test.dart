import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/screens/shop_detail_screen.dart';

const joshuaToppings = [
  'Agar Jelly',
  'Almond Jelly',
  'Ayou Jelly',
  'Boba',
  'Coffee',
  'Grape Foam',
  'Honeycomb Coffee Mochi',
  'Pear Chunks',
  'Pineapple Chunks',
  'Sesame Milk',
  'Tea Jelly',
];

void main() {
  group('toppingsToSeedForUser', () {
    test('true new user (zero toppings) gets the six seed names', () {
      expect(toppingsToSeedForUser(const []), newUserToppingSeeds);
    });

    test('does not add Pudding/Grass Jelly/Aloe/Red Bean/Cheese Foam to Joshua', () {
      expect(toppingsToSeedForUser(joshuaToppings), isEmpty);
    });

    test('any existing catalog is left alone', () {
      expect(toppingsToSeedForUser(['Boba']), isEmpty);
      expect(toppingsToSeedForUser(['Pear Chunks', 'Tea Jelly']), isEmpty);
    });
  });

  group('shopDetailPhase', () {
    test('deep link / first load before data is loading, not empty-pop', () {
      expect(
        shopDetailPhase(
          loading: true,
          loadError: null,
          hasProfile: false,
          hasDrinks: false,
        ),
        ShopDetailPhase.loading,
      );
      expect(
        shopDetailPhase(
          loading: false,
          loadError: null,
          hasProfile: false,
          hasDrinks: false,
        ),
        ShopDetailPhase.loading,
      );
    });

    test('failed refresh shows error even if a profile is in memory', () {
      expect(
        shopDetailPhase(
          loading: false,
          loadError: 'network',
          hasProfile: true,
          hasDrinks: true,
        ),
        ShopDetailPhase.error,
      );
      expect(
        shopDetailPhase(
          loading: false,
          loadError: 'network',
          hasProfile: true,
          hasDrinks: false,
        ),
        ShopDetailPhase.error,
      );
    });

    test('pop Home only after a successful load with zero drinks', () {
      expect(
        shopDetailPhase(
          loading: false,
          loadError: null,
          hasProfile: true,
          hasDrinks: false,
        ),
        ShopDetailPhase.empty,
      );
    });

    test('successful load with drinks is ready', () {
      expect(
        shopDetailPhase(
          loading: false,
          loadError: null,
          hasProfile: true,
          hasDrinks: true,
        ),
        ShopDetailPhase.ready,
      );
    });

    test('refresh in flight without this shop still loading, not pop', () {
      expect(
        shopDetailPhase(
          loading: true,
          loadError: null,
          hasProfile: true,
          hasDrinks: false,
        ),
        ShopDetailPhase.loading,
      );
    });
  });
}
