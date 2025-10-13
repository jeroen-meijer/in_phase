import 'dart:io';

import 'package:intl/intl.dart';
import 'package:rkdb_dart/src/entities/entities.dart';
import 'package:rkdb_dart/src/reports/base_report_generator.dart';
import 'package:rkdb_dart/src/reports/markdown_generator.dart';

/// Generates a markdown report for a sync command run.
class SyncReportGenerator extends BaseReportGenerator {
  SyncReportGenerator();

  /// Generates and writes a sync report to a file.
  Future<File> generate(SyncReport report) async {
    final buffer = StringBuffer();

    // Header with basic metadata
    writeReportHeader(buffer, 'Sync Report', report.startTime, report.endTime);

    // Add sync-specific summary items
    buffer.write(
      MarkdownGenerator.list([
        'Playlists Synced: ${MarkdownGenerator.bold(report.playlistReports.length.toString())}',
        'Total Tracks: ${MarkdownGenerator.bold(report.totalTracks.toString())}',
        'Successfully Added: ${MarkdownGenerator.bold(report.totalAdded.toString())}',
        'Custom Tracks: ${MarkdownGenerator.bold(report.totalCustom.toString())}',
        'Missing (Not Found): ${MarkdownGenerator.bold(report.totalMissing.toString())}',
      ]),
    );
    buffer.writeln();

    // Per-playlist reports
    for (final playlistReport in report.playlistReports) {
      _generatePlaylistSection(buffer, playlistReport);
    }

    // Write to file using base class
    return writeReportToFile(
      reportType: 'sync',
      startTime: report.startTime,
      content: buffer,
    );
  }

  void _generatePlaylistSection(
    StringBuffer buffer,
    SyncPlaylistReport report,
  ) {
    final addedCount = report.tracks.whereType<SyncTrackAdded>().length;
    final customCount = report.tracks.whereType<SyncTrackCustom>().length;
    final missingCount = report.tracks.whereType<SyncTrackMissing>().length;

    // Use base class for section header
    writeSectionHeader(
      buffer,
      report.playlistName,
      [
        'Playlist ID: ${MarkdownGenerator.code(report.playlistId.toString())}',
        'Snapshot ID: ${MarkdownGenerator.code(report.snapshotId)}',
        'Runtime: ${MarkdownGenerator.bold(MarkdownGenerator.formatDuration(report.duration))}',
        'Total Tracks: ${MarkdownGenerator.bold(report.tracks.length.toString())}',
        'Added: ${MarkdownGenerator.bold(addedCount.toString())}',
        'Custom: ${MarkdownGenerator.bold(customCount.toString())}',
        'Missing: ${MarkdownGenerator.bold(missingCount.toString())}',
        'Source: ${MarkdownGenerator.bold(report.wasFromCache ? 'Cache' : 'Spotify API')}',
      ],
    );

    // Use base class for tracks table
    final headers = ['Track', 'Artist(s)', 'Rekordbox Match', 'Status'];
    final rows = report.tracks.map((track) {
      final trackName = track.trackName;
      final artists = track.artistNames.join(', ');

      return switch (track) {
        SyncTrackAdded(:final rekordboxTitle) => [
          trackName,
          artists,
          rekordboxTitle,
          '✅ Added',
        ],
        SyncTrackCustom(:final rekordboxTitle, :final position) => [
          trackName,
          artists,
          rekordboxTitle,
          '🔧 Custom (pos: $position)',
        ],
        SyncTrackMissing() => [
          trackName,
          artists,
          '-',
          '❌ Missing',
        ],
      };
    }).toList();

    writeTracksTable(buffer, 'Tracks', headers, rows);
  }
}
