import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/screens/profile_screen.dart';
import 'package:tea_ranker/theme/tokens.dart';

void main() {
  test('display version is v. 0.27', () {
    expect(kAppDisplayVersion, 'v. 0.27');
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
    expect(find.text(kAppDisplayVersion), findsOneWidget);
    expect(find.text('v. 0.26'), findsNothing);
    final text = tester.widget<Text>(find.text(kAppDisplayVersion));
    final style = text.style!;
    expect(style.fontSize, 12);
    expect(style.color, AppColors.chocolate.withValues(alpha: 0.7));
    final versionBox = tester.getRect(find.text(kAppDisplayVersion));
    final titleBox = tester.getRect(find.text('Profile'));
    expect(versionBox.left, greaterThanOrEqualTo(titleBox.right));
    expect(versionBox.right, greaterThan(titleBox.center.dx));
    expect(versionBox.center.dy, closeTo(titleBox.center.dy, 8));
  });
}
