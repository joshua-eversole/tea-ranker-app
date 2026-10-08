import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/grading/grade.dart';

void main() {
  test('spec examples: 4.35 is A+, 4.7 is S', () {
    expect(bandForAverage(4.35), AggregateBand.aPlus);
    expect(bandForAverage(4.7), AggregateBand.s);
  });

  test('inclusive lower, exclusive upper, S includes 5.0', () {
    expect(bandForAverage(5.0), AggregateBand.s);
    expect(bandForAverage(4.7), AggregateBand.s);
    expect(bandForAverage(4.6999), AggregateBand.aPlus);
    expect(bandForAverage(4.3), AggregateBand.aPlus);
    expect(bandForAverage(4.0), AggregateBand.a);
    expect(bandForAverage(3.7), AggregateBand.aMinus);
    expect(bandForAverage(3.3), AggregateBand.bPlus);
    expect(bandForAverage(3.0), AggregateBand.b);
    expect(bandForAverage(2.7), AggregateBand.bMinus);
    expect(bandForAverage(2.3), AggregateBand.cPlus);
    expect(bandForAverage(2.0), AggregateBand.c);
    expect(bandForAverage(1.7), AggregateBand.cMinus);
    expect(bandForAverage(1.3), AggregateBand.dPlus);
    expect(bandForAverage(1.0), AggregateBand.d);
    expect(bandForAverage(0.0), AggregateBand.dMinus);
  });

  test('zero drinks: null average has no band', () {
    expect(bandForAverage(null), isNull);
  });

  test('logger letters map to 5..1', () {
    expect(LetterGrade.s.points, 5);
    expect(LetterGrade.d.points, 1);
    expect(LetterGrade.fromPoints(4)?.letter, 'A');
  });
}
