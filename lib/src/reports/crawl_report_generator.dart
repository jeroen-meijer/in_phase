// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/reports/base_report_generator.dart';
import 'package:in_phase/src/reports/markdown_generator.dart';

/// Generates markdown reports for crawl operations.
class CrawlReportGenerator extends BaseReportGenerator {
  /// Generates a markdown report from a crawl report and writes it to a file.
  ///
  /// Returns the path to the generated report file.
  static Future<String> generateReport(
    CrawlReport report,
    Directory buildDir,
  ) async {
    final generator = CrawlReportGenerator();
    final file = await generator._generateReport(report, buildDir);
    return file.path;
  }

  /// Internal method to generate the report.
  Future<File> _generateReport(CrawlReport report, Directory buildDir) async {
    final buffer = StringBuffer();

    // Header with basic metadata
    writeReportHeader(buffer, 'Crawl Report', report.startTime, report.endTime);

    // Generate job reports
    for (final jobReport in report.jobReports) {
      _generateJobReport(buffer, jobReport);
      buffer.write('\n');
    }

    // Write to file using base class
    return writeReportToFile(
      reportType: 'crawl',
      startTime: report.startTime,
      content: buffer,
    );
  }

  /// Generates a section for a single job report.
  void _generateJobReport(StringBuffer buffer, CrawlJobReport report) {
    // Use base class for section header
    writeSectionHeader(
      buffer,
      report.jobName,
      [
        'Tracks: ${MarkdownGenerator.bold(report.trackCount.toString())}',
        'Runtime: ${MarkdownGenerator.bold(MarkdownGenerator.formatDuration(report.runtime))}',
      ],
    );

    // Use base class for tracks table
    final headers = ['Track Name', 'Artists', 'Source', 'Reason'];
    final rows = report.trackEntries.map((entry) {
      return [
        entry.trackName,
        entry.artistsString,
        '${entry.sourceInfo.typeName}: ${entry.sourceInfo.displayName}',
        entry.reason,
      ];
    }).toList();

    writeTracksTable(
      buffer,
      'Tracks Added',
      headers,
      rows,
      emptyMessage: 'No tracks added for this job.',
    );

    buffer.write(MarkdownGenerator.horizontalRule());
  }
}
