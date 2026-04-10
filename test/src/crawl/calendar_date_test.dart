import 'package:in_phase/src/crawl/date_range.dart';
import 'package:in_phase/src/crawl/date_range_resolver.dart';
import 'package:in_phase/src/crawl/date_utils.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:simple_date/simple_date.dart';
import 'package:test/test.dart';

void main() {
  group('inclusiveCalendarStartForLastNDays', () {
    test('7 calendar days ending 2026-04-03 starts 2026-03-28 (DST-safe)', () {
      final end = SimpleDate.parse('2026-04-03');
      final start = inclusiveCalendarStartForLastNDays(end, 7);
      expect(start, SimpleDate(2026, 3, 28));
      expect(end, SimpleDate(2026, 4, 3));
    });

    test('7 calendar days ending 2026-02-10 starts 2026-02-04', () {
      final end = SimpleDate.parse('2026-02-10');
      final start = inclusiveCalendarStartForLastNDays(end, 7);
      expect(start, SimpleDate(2026, 2, 4));
    });
  });

  group('CrawlDateRangeDays', () {
    test('resolve uses calendar days across late March (EU DST)', () {
      const range = CrawlDateRangeDays(7);
      final r = range.resolve(DateTime.parse('2026-04-03'));
      expect(r.end, SimpleDate(2026, 4, 3));
      expect(r.start, SimpleDate(2026, 3, 28));
    });
  });

  group('DateRangeResolver', () {
    test('default 7-day window with --end-date parses to expected range', () {
      const filters = CrawlFilters(
        dateRange: CrawlDateRangeDays(7),
      );
      final r = DateRangeResolver.resolve(
        filters,
        cliEndDate: DateTime.parse('2026-04-03'),
      );
      expect(r.start, SimpleDate(2026, 3, 28));
      expect(r.end, SimpleDate(2026, 4, 3));
    });
  });
}
