import 'package:in_phase/src/convert/youtube_mix_source.dart';
import 'package:in_phase/src/convert/youtube_resolve_scope.dart';
import 'package:in_phase/src/convert/youtube_video_ref.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const _youtubeMetadataConcurrency = 5;

/// How the user input was classified.
enum YoutubeInputKind { textQuery, videoUrl, playlistUrl }

/// Classified YouTube input before video resolution.
class ClassifiedYoutubeInput {
  const ClassifiedYoutubeInput({
    required this.kind,
    this.textQuery,
    this.videoUrl,
    this.playlistId,
    this.isMixPlaylist = false,
    this.seedVideoId,
    this.hasWatchAndList = false,
  });

  final YoutubeInputKind kind;
  final String? textQuery;
  final String? videoUrl;
  final String? playlistId;
  final bool isMixPlaylist;

  /// Seed `v=` video when the URL is a watch URL with `list=`.
  final String? seedVideoId;

  /// True when the URL includes both a video id and a `list=` parameter.
  final bool hasWatchAndList;
}

/// Returns true for YouTube auto-generated mix/radio list ids (`RD…`, `RDMM`).
///
/// Watch URLs with `list=PL…` are normal playlists and return false.
bool isYoutubeMixListId(String listId) {
  return listId == 'RDMM' || listId.startsWith('RD');
}

String? _parseVideoId(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host == 'youtu.be') {
    final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    return segment != null && segment.isNotEmpty ? segment : null;
  }
  final fromQuery = uri.queryParameters['v'];
  if (fromQuery != null && fromQuery.isNotEmpty) {
    return fromQuery;
  }
  return null;
}

String? _parseListId(String input, Uri uri) {
  return PlaylistId.parsePlaylistId(input) ?? uri.queryParameters['list'];
}

/// Classifies [input] as text query, video URL, or playlist URL.
ClassifiedYoutubeInput classifyYoutubeInput(String input) {
  final trimmed = input.trim();
  final uri = Uri.tryParse(trimmed);
  final isHttp = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

  if (isHttp) {
    final host = uri.host.toLowerCase();
    final isYoutube =
        host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('music.youtube.com');

    if (isYoutube) {
      final listId = _parseListId(trimmed, uri);
      final videoId = _parseVideoId(uri) ?? VideoId.parseVideoId(trimmed);
      if (listId != null) {
        final isMix = isYoutubeMixListId(listId);
        return ClassifiedYoutubeInput(
          kind: YoutubeInputKind.playlistUrl,
          playlistId: listId,
          isMixPlaylist: isMix,
          seedVideoId: videoId,
          hasWatchAndList: videoId != null,
        );
      }

      if (videoId != null) {
        return ClassifiedYoutubeInput(
          kind: YoutubeInputKind.videoUrl,
          videoUrl: trimmed,
        );
      }
    }
  }

  return ClassifiedYoutubeInput(
    kind: YoutubeInputKind.textQuery,
    textQuery: trimmed,
  );
}

/// Resolved YouTube videos plus optional source playlist title.
class ResolvedYoutubeVideos {
  const ResolvedYoutubeVideos({
    required this.videos,
    this.playlistTitle,
  });

  final List<YoutubeVideoRef> videos;

  /// Title from the source YouTube playlist or mix, when available.
  final String? playlistTitle;
}

/// Resolves YouTube video(s) for a classified input and [scope].
Future<ResolvedYoutubeVideos> resolveYoutubeVideos({
  required YoutubeExplode yt,
  required ClassifiedYoutubeInput classified,
  required YoutubeResolveScope scope,
  int? limit,
}) async {
  switch (classified.kind) {
    case YoutubeInputKind.textQuery:
      throw ArgumentError(
        'Use resolveYoutubeVideoFromTextQuery for text queries',
      );

    case YoutubeInputKind.videoUrl:
      final videoUrl = classified.videoUrl;
      if (videoUrl == null) {
        return const ResolvedYoutubeVideos(videos: []);
      }
      final video = await yt.videos.get(videoUrl);
      return ResolvedYoutubeVideos(videos: [YoutubeVideoRef.fromVideo(video)]);

    case YoutubeInputKind.playlistUrl:
      if (scope == YoutubeResolveScope.singleVideo) {
        final seedVideoId = classified.seedVideoId ?? classified.playlistId;
        if (seedVideoId == null) {
          return const ResolvedYoutubeVideos(videos: []);
        }
        final video = await yt.videos.get(seedVideoId);
        return ResolvedYoutubeVideos(
          videos: [YoutubeVideoRef.fromVideo(video)],
        );
      }

      if (classified.isMixPlaylist) {
        return _resolveMixPlaylistVideos(
          yt: yt,
          classified: classified,
          limit: limit,
        );
      }

      return _resolveStandardPlaylistVideos(
        yt: yt,
        classified: classified,
        limit: limit,
      );
  }
}

Future<ResolvedYoutubeVideos> _resolveMixPlaylistVideos({
  required YoutubeExplode yt,
  required ClassifiedYoutubeInput classified,
  int? limit,
}) async {
  final seedVideoId = classified.seedVideoId;
  final listId = classified.playlistId;
  if (seedVideoId == null || listId == null) {
    return const ResolvedYoutubeVideos(videos: []);
  }

  log.info('  🔍 Fetching mix panel from watch page (single page)...');
  final panel = await fetchMixPanel(
    seedVideoId: seedVideoId,
    listId: listId,
  );

  if (panel.videos.isEmpty) {
    log.warning(
      '  ⚠️  Could not parse mix panel; falling back to seed video only.',
    );
    final seedVideo = await yt.videos.get(seedVideoId);
    return ResolvedYoutubeVideos(
      videos: [YoutubeVideoRef.fromVideo(seedVideo)],
      playlistTitle: panel.title,
    );
  }

  log.info(
    '  ✅ Mix panel: ${panel.videos.length} video(s) '
    '(best-effort snapshot; may differ from YouTube app)',
  );

  final selected = limit != null
      ? panel.videos.take(limit).toList()
      : panel.videos;

  final fetchedById = await _fetchYoutubeVideosConcurrently(
    yt: yt,
    videoIds: selected.map((video) => video.videoId).toList(),
  );

  final refs = selected.map((panelVideo) {
    final fetched = fetchedById[panelVideo.videoId];
    if (fetched != null) {
      return YoutubeVideoRef.fromVideo(fetched);
    }
    return YoutubeVideoRef(
      id: panelVideo.videoId,
      title: panelVideo.title,
      author: panelVideo.author,
    );
  }).toList();

  return ResolvedYoutubeVideos(
    videos: refs,
    playlistTitle: panel.title,
  );
}

Future<Map<String, Video>> _fetchYoutubeVideosConcurrently({
  required YoutubeExplode yt,
  required List<String> videoIds,
}) async {
  final total = videoIds.length;
  if (total == 0) {
    return {};
  }

  log.info('  📥 Fetching metadata for $total video(s)...');
  final byId = <String, Video>{};

  for (var start = 0; start < total; start += _youtubeMetadataConcurrency) {
    final batchIds = videoIds
        .skip(start)
        .take(_youtubeMetadataConcurrency)
        .toList();
    final batch = await Future.wait(
      batchIds.map((id) async {
        final video = await yt.videos.get(id);
        return MapEntry(id, video);
      }),
    );
    for (final entry in batch) {
      byId[entry.key] = entry.value;
    }
    log.info('  📥 Fetched ${byId.length}/$total video metadata');
  }

  return byId;
}

Future<ResolvedYoutubeVideos> _resolveStandardPlaylistVideos({
  required YoutubeExplode yt,
  required ClassifiedYoutubeInput classified,
  int? limit,
}) async {
  final playlistId = classified.playlistId;
  if (playlistId == null) {
    return const ResolvedYoutubeVideos(videos: []);
  }

  log.info('  📋 Fetching playlist $playlistId...');
  String? playlistTitle;
  try {
    final playlist = await yt.playlists.get(playlistId);
    playlistTitle = playlist.title.trim();
    if (playlistTitle.isEmpty) {
      playlistTitle = null;
    }
  } catch (e) {
    log.debug('  Could not fetch playlist metadata: $e');
  }

  final videos = <YoutubeVideoRef>[];
  await for (final video in yt.playlists.getVideos(playlistId)) {
    videos.add(YoutubeVideoRef.fromVideo(video));
    if (limit != null && videos.length >= limit) {
      break;
    }
  }

  final capped = limit != null && videos.length > limit
      ? videos.take(limit).toList()
      : videos;

  return ResolvedYoutubeVideos(
    videos: capped,
    playlistTitle: playlistTitle,
  );
}
