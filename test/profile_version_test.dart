import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/screens/profile_screen.dart';
import 'package:tea_ranker/theme/tokens.dart';

void main() {
  test('display version is 0.17', () {
    expect(kAppDisplayVersion, '0.17');
  });

  testWidgets('Profile header shows a quiet version at the top right', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: const Scaffold(
          backgroundColor: AppColors.cream,
          body: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(child: Text('Profile')),
                ProfileVersionLabel(),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('0.17'), findsOneWidget);
    final text = tester.widget<Text>(find.text('0.17'));
    final style = text.style!;
    expect(style.fontSize, 12);
    expect(style.color, AppColors.chocolate.withValues(alpha: 0.7));
    final versionBox = tester.getRect(find.text('0.17'));
    final titleBox = tester.getRect(find.text('Profile'));
    expect(versionBox.left, greaterThanOrEqualTo(titleBox.right));
    expect(versionBox.right, greaterThan(titleBox.center.dx));
    expect(versionBox.center.dy, closeTo(titleBox.center.dy, 8));
  });
}
