import 'dart:io';

import 'package:intl/intl.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:rkdb_dart/src/reports/markdown_generator.dart';

/// Base class for report generators with common functionality.
abstract class BaseReportGenerator {
  /// Generates a report and writes it to a file.
  Future<File> writeReportToFile({
    required String reportType,
    required DateTime startTime,
    required StringBuffer content,
  }) async {
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(startTime);
    final filename = '${reportType}_report_$timestamp.md';
    final file = File('${Constants.appDataDir.path}/build/$filename');
    await file.create(recursive: true);
    await file.writeAsString(content.toString());
    return file;
  }

  /// Creates a report header with title and basic metadata.
  void writeReportHeader(
    StringBuffer buffer,
    String title,
    DateTime startTime,
    DateTime endTime,
  ) {
    buffer
      ..write(MarkdownGenerator.header(title, level: 1))
      ..writeln()
      ..write(MarkdownGenerator.header('Summary', level: 2))
      ..writeln()
      ..write(
        MarkdownGenerator.list([
          'Started: ${MarkdownGenerator.bold(MarkdownGenerator.formatDateTime(startTime))}',
          'Completed: ${MarkdownGenerator.bold(MarkdownGenerator.formatDateTime(endTime))}',
          'Total Runtime: ${MarkdownGenerator.bold(MarkdownGenerator.formatDuration(endTime.difference(startTime)))}',
        ]),
      )
      ..writeln();
  }

  /// Creates a section header with metadata list.
  void writeSectionHeader(
    StringBuffer buffer,
    String title,
    List<String> metadata,
  ) {
    buffer
      ..write(MarkdownGenerator.header(title, level: 2))
      ..writeln()
      ..write(MarkdownGenerator.list(metadata))
      ..writeln();
  }

  /// Creates a tracks table with optional empty state message.
  void writeTracksTable(
    StringBuffer buffer,
    String title,
    List<String> headers,
    List<List<String>> rows, {
    String? emptyMessage,
  }) {
    if (rows.isNotEmpty) {
      buffer
        ..write(MarkdownGenerator.header(title, level: 3))
        ..writeln()
        ..writeln(MarkdownGenerator.table(headers: headers, rows: rows))
        ..writeln();
    } else if (emptyMessage != null) {
      buffer.write('*$emptyMessage*\n\n');
    }
  }
}
