import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/app.dart';

void main() {
  testWidgets('missing keys show setup copy', (tester) async {
    await tester.pumpWidget(const TeaRankerApp());
    expect(find.text('Tea Ranker'), findsOneWidget);
    expect(find.textContaining('publishable key'), findsOneWidget);
  });
}
