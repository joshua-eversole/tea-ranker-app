import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/widgets/app_shell.dart';
import 'package:tea_ranker/widgets/phone_frame.dart';
import 'package:tea_ranker/widgets/shop_name_field.dart';

ShopRow shop(String id, String name, {String? nameZh}) => ShopRow(
      id: id,
      name: name,
      nameZh: nameZh,
      userId: 'u',
      isUserAdded: true,
    );

void main() {
  group('shellTabIndex', () {
    test('Home Map Social Profile, idle on logger and shop details', () {
      expect(shellTabIndex('/'), 0);
      expect(shellTabIndex('/map'), 1);
      expect(shellTabIndex('/social'), 2);
      expect(shellTabIndex('/profile'), 3);
      expect(shellTabIndex('/log'), -1);
      expect(shellTabIndex('/shops/abc'), -1);
    });
  });

  group('framedContentWidth', () {
    test('phones fill the viewport instead of sitting in a 430px well', () {
      expect(framedContentWidth(390), 390);
      expect(framedContentWidth(430), 430);
      expect(framedContentWidth(480), 480);
      expect(framedContentWidth(AppLayout.phoneFillBreakpoint), 700);
    });

    test('wide desktop is capped, not a stretched dashboard', () {
      expect(framedContentWidth(701), AppLayout.maxContentWidth);
      expect(framedContentWidth(1280), AppLayout.maxContentWidth);
      expect(AppLayout.maxContentWidth, 480);
    });
  });

  group('shopsToSeedForUser', () {
    test('true new user gets bilingual Taiwan chains', () {
      final seeds = shopsToSeedForUser(const []);
      expect(seeds, isNotEmpty);
      expect(seeds.map((s) => s.name), containsAll(['50 Lan', 'Kebuke', 'Milksha']));
      expect(
        seeds.firstWhere((s) => s.name == '50 Lan').nameZh,
        '五十嵐',
      );
      expect(
        seeds.firstWhere((s) => s.name == 'Chun Shui Tang').nameZh,
        '春水堂',
      );
    });

    test('existing catalogs including Joshua are not seeded or wiped', () {
      expect(shopsToSeedForUser(['50 Lan']), isEmpty);
      expect(shopsToSeedForUser(['My neighborhood shop']), isEmpty);
    });
  });

  group('matchingShops', () {
    test('matches Chinese names as well as English', () {
      final shops = [
        shop('1', '50 Lan', nameZh: '五十嵐'),
        shop('2', 'Lan Shan'),
        shop('3', 'Chun Shui Tang', nameZh: '春水堂'),
      ];
      expect(matchingShops(shops, 'lan').map((s) => s.name), ['Lan Shan', '50 Lan']);
      expect(matchingShops(shops, '五十').map((s) => s.name), ['50 Lan']);
      expect(matchingShops(shops, '春水堂'), isEmpty);
    });
  });
}
