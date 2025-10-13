import 'dart:io';

import 'package:intl/intl.dart';
import 'package:rkdb_dart/src/entities/entities.dart';
import 'package:rkdb_dart/src/reports/markdown_generator.dart';

/// Generates markdown reports for crawl operations.
class CrawlReportGenerator {
  /// Generates a markdown report from a crawl report and writes it to a file.
  ///
  /// Returns the path to the generated report file.
  static Future<String> generateReport(
    CrawlReport report,
    Directory buildDir,
  ) async {
    final buffer = StringBuffer()
      // Generate title and metadata
      ..write(MarkdownGenerator.header('Crawl Report'))
      ..write('\n')
      // Generate report metadata
      ..write(MarkdownGenerator.bold('Date:'))
      ..write(' ')
      ..write(MarkdownGenerator.formatDateTime(report.startTime))
      ..write('\n\n')
      ..write(MarkdownGenerator.bold('Total Runtime:'))
      ..write(' ')
      ..write(MarkdownGenerator.formatDuration(report.totalRuntime))
      ..write('\n\n')
      ..write(MarkdownGenerator.horizontalRule())
      ..write('\n');

    // Generate job reports
    for (final jobReport in report.jobReports) {
      _generateJobReport(buffer, jobReport);
      buffer.write('\n');
    }

    // Write to file
    await buildDir.create(recursive: true);
    final filename = _generateFilename(report.startTime);
    final file = File('${buildDir.path}/$filename');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  /// Generates a section for a single job report.
  static void _generateJobReport(StringBuffer buffer, CrawlJobReport report) {
    buffer
      ..write(MarkdownGenerator.header(report.jobName, level: 2))
      ..write('\n')
      // Job metadata
      ..write(MarkdownGenerator.bold('Tracks:'))
      ..write(' ')
      ..write('${report.trackCount}\n\n')
      ..write(MarkdownGenerator.bold('Runtime:'))
      ..write(' ')
      ..write(MarkdownGenerator.formatDuration(report.runtime))
      ..write('\n\n');

    // Tracks table
    if (report.trackEntries.isNotEmpty) {
      buffer
        ..write(MarkdownGenerator.header('Tracks Added', level: 3))
        ..write('\n')
        ..write(
          MarkdownGenerator.table(
            headers: ['Track Name', 'Artists', 'Source', 'Reason'],
            rows: report.trackEntries.map((entry) {
              return [
                entry.trackName,
                entry.artistsString,
                '${entry.sourceInfo.typeName}: ${entry.sourceInfo.displayName}',
                entry.reason,
              ];
            }).toList(),
          ),
        )
        ..write('\n');
    } else {
      buffer.write('*No tracks added for this job.*\n\n');
    }

    buffer.write(MarkdownGenerator.horizontalRule());
  }

  /// Generates a filename for the report based on the start time.
  static String _generateFilename(DateTime startTime) {
    final formatter = DateFormat('yyyy-MM-dd_HH-mm');
    return 'crawl_report_${formatter.format(startTime)}.md';
  }
}
