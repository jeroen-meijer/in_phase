import 'dart:convert';
import 'dart:io';

/// A video entry parsed from a YouTube mix watch-page panel.
class MixPanelVideo {
  const MixPanelVideo({
    required this.videoId,
    required this.title,
    required this.author,
  });

  final String videoId;
  final String title;
  final String author;
}

/// Mix panel content parsed from a YouTube watch page.
class MixPanel {
  const MixPanel({required this.videos, this.title});

  final String? title;
  final List<MixPanelVideo> videos;
}

/// Fetches one page of a mix from a YouTube watch URL (`v` + `list=RD…`).
Future<MixPanel> fetchMixPanel({
  required String seedVideoId,
  required String listId,
}) async {
  final watchUri = Uri.https('www.youtube.com', '/watch', {
    'v': seedVideoId,
    'list': listId,
    'hl': 'en',
    'gl': 'US',
  });

  final client = HttpClient();
  try {
    final request = await client.getUrl(watchUri);
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Safari/537.36',
    );
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');

    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      return const MixPanel(videos: []);
    }

    final body = await response.transform(utf8.decoder).join();
    final data = extractYtInitialData(body);
    if (data == null) {
      return const MixPanel(videos: []);
    }

    return MixPanel(
      title: parseMixPlaylistTitle(data),
      videos: parseMixPanelVideos(data),
    );
  } finally {
    client.close(force: true);
  }
}

/// Extracts `ytInitialData` JSON from a YouTube watch page HTML body.
Map<String, dynamic>? extractYtInitialData(String html) {
  return extractJsonAssignment(html, 'ytInitialData');
}

/// Extracts a `var <name> = {…};` JSON assignment from YouTube HTML.
Map<String, dynamic>? extractJsonAssignment(String html, String varName) {
  final marker = 'var $varName = ';
  final start = html.indexOf(marker);
  if (start < 0) {
    return null;
  }

  var i = start + marker.length;
  if (i >= html.length || html[i] != '{') {
    return null;
  }

  var depth = 0;
  final buf = StringBuffer();
  for (; i < html.length; i++) {
    final ch = html[i];
    buf.write(ch);
    if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) {
        break;
      }
    }
  }

  try {
    return jsonDecode(buf.toString()) as Map<String, dynamic>;
  } on FormatException {
    return null;
  }
}

Map<String, dynamic>? _mixPlaylistNode(Map<String, dynamic> data) {
  final playlist = deepGet(data, [
    'contents',
    'twoColumnWatchNextResults',
    'playlist',
    'playlist',
  ]);
  return playlist is Map<String, dynamic> ? playlist : null;
}

/// Parses the mix title from parsed `ytInitialData`.
String? parseMixPlaylistTitle(Map<String, dynamic> data) {
  final playlist = _mixPlaylistNode(data);
  if (playlist == null) {
    return null;
  }

  final title = playlist['title'];
  if (title is String && title.isNotEmpty) {
    return title;
  }
  if (title is Map) {
    final simple = title['simpleText'] as String?;
    if (simple != null && simple.isNotEmpty) {
      return simple;
    }
    return runsText(title);
  }
  return null;
}

/// Parses mix panel videos from parsed `ytInitialData`.
List<MixPanelVideo> parseMixPanelVideos(Map<String, dynamic> data) {
  final playlist = _mixPlaylistNode(data);
  if (playlist == null) {
    return [];
  }

  final contents = playlist['contents'];
  if (contents is! List) {
    return [];
  }

  final results = <MixPanelVideo>[];
  for (final item in contents) {
    if (item is! Map) {
      continue;
    }
    final renderer = item['playlistPanelVideoRenderer'];
    if (renderer is! Map) {
      continue;
    }

    final videoId = renderer['videoId'] as String?;
    final title =
        (renderer['title'] as Map?)?['simpleText'] as String? ??
        runsText(renderer['title']);
    final author = runsText(renderer['longBylineText']);
    if (videoId == null || title == null || title.isEmpty) {
      continue;
    }

    results.add(
      MixPanelVideo(
        videoId: videoId,
        title: title,
        author: author ?? '',
      ),
    );
  }

  return results;
}

dynamic deepGet(dynamic node, List<String> path) {
  dynamic current = node;
  for (final key in path) {
    if (current is! Map) {
      return null;
    }
    current = current[key];
  }
  return current;
}

String? runsText(dynamic node) {
  if (node is! Map) {
    return null;
  }
  final runs = node['runs'];
  if (runs is! List) {
    return null;
  }
  return runs.map((run) => (run as Map)['text'] as String? ?? '').join();
}
