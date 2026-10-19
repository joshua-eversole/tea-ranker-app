import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/screens/home_screen.dart';
import 'package:tea_ranker/theme/tokens.dart';

void main() {
  testWidgets('Home loading shows copy and skeleton bones, not empty copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ColoredBox(
          color: AppColors.cream,
          child: HomeLoadSkeleton(
            welcome: 'Welcome back',
            loadingCopy: kHomeLoadingCopy,
          ),
        ),
      ),
    );
    expect(find.text(kHomeLoadingCopy), findsOneWidget);
    expect(find.text('No drinks yet.'), findsNothing);
    expect(find.text('Log your first drink'), findsNothing);
  });
}
