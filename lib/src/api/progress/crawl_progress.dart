import 'package:in_phase/src/entities/reports/crawl_report.dart';

/// Progress events for crawl operations
sealed class CrawlProgress {
  const CrawlProgress();
}

class CrawlProgressStarted extends CrawlProgress {
  const CrawlProgressStarted({required this.jobCount});
  final int jobCount;
}

class CrawlProgressJobStarted extends CrawlProgress {
  const CrawlProgressJobStarted({required this.jobName});
  final String jobName;
}

class CrawlProgressTrackFound extends CrawlProgress {
  const CrawlProgressTrackFound({required this.trackEntry});
  final CrawlTrackEntry trackEntry;
}

class CrawlProgressJobCompleted extends CrawlProgress {
  const CrawlProgressJobCompleted({required this.report});
  final CrawlJobReport report;
}

class CrawlProgressCompleted extends CrawlProgress {
  const CrawlProgressCompleted({required this.report});
  final CrawlReport report;
}

class CrawlProgressError extends CrawlProgress {
  const CrawlProgressError({required this.message, this.error});
  final String message;
  final Object? error;
}
