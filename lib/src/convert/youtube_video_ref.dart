import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Minimal YouTube video metadata used by convert (title, author, id).
class YoutubeVideoRef {
  const YoutubeVideoRef({
    required this.id,
    required this.title,
    required this.author,
  });

  factory YoutubeVideoRef.fromVideo(Video video) {
    final music = video.musicData.firstOrNull;
    return youtubeVideoRefFromMetadata(
      id: video.id.value,
      title: video.title,
      author: video.author,
      musicArtist: music?.artist,
      musicSong: music?.song,
    );
  }

  final String id;
  final String title;
  final String author;
}

/// Builds a [YoutubeVideoRef], preferring YouTube Music metadata when present.
///
/// Auto-uploaded tracks often use Topic channels named after the release
/// (e.g. `Release - Topic` / `Energy`) while [musicArtist] is the real artist.
YoutubeVideoRef youtubeVideoRefFromMetadata({
  required String id,
  required String title,
  required String author,
  String? musicArtist,
  String? musicSong,
}) {
  final resolvedArtist = musicArtist?.trim();
  if (resolvedArtist != null && resolvedArtist.isNotEmpty) {
    final resolvedSong = musicSong?.trim();
    return YoutubeVideoRef(
      id: id,
      title: resolvedSong != null && resolvedSong.isNotEmpty
          ? resolvedSong
          : title,
      author: resolvedArtist,
    );
  }

  return YoutubeVideoRef(id: id, title: title, author: author);
}
