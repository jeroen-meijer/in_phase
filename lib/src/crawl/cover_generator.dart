// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_phase/src/logger/logger.dart' show log;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:path/path.dart' as path;

/// Check if the image path is a URL.
bool _isUrl(String imagePath) {
  return imagePath.startsWith('http://') || imagePath.startsWith('https://');
}

/// Load an image from either a local file or URL.
///
/// Returns the loaded image or null if loading fails.
Future<img.Image?> loadImage(
  String imagePath, {
  String assetsDir = 'assets/images',
}) async {
  try {
    if (_isUrl(imagePath)) {
      // Load from URL
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(imagePath));
        final response = await request.close();

        if (response.statusCode != 200) {
          log.warning(
            "Could not load image '$imagePath': "
            'HTTP ${response.statusCode}',
          );
          return null;
        }

        final bytes = await response.fold<List<int>>(
          [],
          (previous, element) => previous..addAll(element),
        );
        return img.decodeImage(Uint8List.fromList(bytes));
      } finally {
        client.close();
      }
    } else {
      // Load from local file
      final localPath = path.join(assetsDir, imagePath);
      final file = File(localPath);

      if (!await file.exists()) {
        log.warning("Image file not found: '$localPath'");
        return null;
      }

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        log.warning("Failed to decode image: '$localPath'");
      }
      return decoded;
    }
  } catch (e) {
    log.warning("Could not load image '$imagePath': $e");
    return null;
  }
}

/// Crop an image to a square, centering the content.
img.Image cropToSquare(img.Image image) {
  final width = image.width;
  final height = image.height;

  // Find the smaller dimension
  final size = width < height ? width : height;

  // Calculate crop box to center the image
  final left = (width - size) ~/ 2;
  final top = (height - size) ~/ 2;

  return img.copyCrop(
    image,
    x: left,
    y: top,
    width: size,
    height: size,
  );
}

/// Wrap text to fit within a maximum width.
///
/// Note: This is a simplified version that wraps by character count
/// since we don't have font rendering capabilities in pure Dart.
/// For production, consider using a more sophisticated text measurement
/// approach.
List<String> _wrapText(String text, int maxCharsPerLine) {
  final words = text.split(' ');
  final lines = <String>[];
  var currentLine = <String>[];
  var currentLength = 0;

  for (final word in words) {
    final wordLength = word.length;
    final spaceNeeded = currentLine.isEmpty ? 0 : 1; // For space between words

    if (currentLength + spaceNeeded + wordLength <= maxCharsPerLine) {
      currentLine.add(word);
      currentLength += spaceNeeded + wordLength;
    } else {
      if (currentLine.isNotEmpty) {
        lines.add(currentLine.join(' '));
        currentLine = [word];
        currentLength = wordLength;
      } else {
        // Single word is too long, force it
        currentLine = [word];
        currentLength = wordLength;
      }
    }
  }

  if (currentLine.isNotEmpty) {
    lines.add(currentLine.join(' '));
  }

  return lines;
}

/// Create a gradient overlay that darkens the bottom half for better
/// text visibility.
img.Image _createGradientOverlay(int size) {
  // Create image with alpha channel
  final gradient = img.Image(width: size, height: size, numChannels: 4);

  // Fill entire image with transparent pixels first
  img.fill(gradient, color: img.ColorRgba8(0, 0, 0, 0));

  // Start gradient at middle (50% of image height)
  final startY = size ~/ 2;

  for (var y = startY; y < size; y++) {
    // Calculate alpha (transparency) - goes from 0 to 180 (not fully opaque)
    final alpha = ((y - startY) / (size - startY) * 180).round();

    for (var x = 0; x < size; x++) {
      gradient.setPixelRgba(x, y, 0, 0, 0, alpha);
    }
  }

  return gradient;
}

/// Generate a playlist cover image with text overlay.
///
/// Returns the generated image or null if generation fails.
Future<img.Image?> generatePlaylistCover({
  required String imagePath,
  required String caption,
  required int size,
  required String assetsDir,
  String? outputPath,
}) async {
  try {
    // Load background image
    var background = await loadImage(imagePath, assetsDir: assetsDir);
    if (background == null) {
      log.warning("Could not load image '$imagePath'");
      return null;
    }

    // Crop to square
    background = cropToSquare(background);

    // Resize to target size
    background = img.copyResize(
      background,
      width: size,
      height: size,
      interpolation: img.Interpolation.cubic,
    );

    // Add gradient overlay for better text visibility
    final gradient = _createGradientOverlay(size);
    background = img.compositeImage(background, gradient);

    // Add text overlay using default font
    final padding = size ~/ 12;
    const maxCharsPerLine = 15; // Approximate chars that fit in the width

    // Split caption into lines and wrap long lines
    final originalLines = caption.split('\n');
    final lines = <String>[];
    for (final line in originalLines) {
      final wrappedLines = _wrapText(line, maxCharsPerLine);
      lines.addAll(wrappedLines);
    }

    // Calculate text positioning
    final fontSize = size ~/ 8;
    final lineHeight = fontSize + 4;
    final totalTextHeight = lines.length * lineHeight;
    final bottomPadding = padding;
    final startY = size - bottomPadding - totalTextHeight;

    // Draw each line using built-in Arial 48 font
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final y = startY + i * lineHeight;

      // Draw text with white color
      img.drawString(
        background,
        line,
        font: img.arial48,
        x: padding,
        y: y,
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    // Save if output path is provided
    if (outputPath != null) {
      // Spotify requires JPEG format for playlist covers
      var jpegPath = outputPath;
      if (outputPath.toLowerCase().endsWith('.png')) {
        jpegPath = outputPath.replaceAll('.png', '.jpg');
      }

      final jpegBytes = img.encodeJpg(background, quality: 95);
      await File(jpegPath).writeAsBytes(jpegBytes);
      log.info('✅ Generated playlist cover: $jpegPath');
    }

    return background;
  } catch (e) {
    log.error('❌ Error generating playlist cover: $e');
    return null;
  }
}

/// Upload a playlist cover image to Spotify.
///
/// Returns true if upload successful, false otherwise.
Future<bool> uploadPlaylistImage({
  required oauth2.Client spotifyClient,
  required String playlistId,
  required String imagePath,
}) async {
  try {
    // Read image file
    final file = File(imagePath);
    final imageBytes = await file.readAsBytes();

    // Spotify API requires base64 encoded image data
    final base64Image = base64Encode(imageBytes);

    // Upload to Spotify using custom request
    // PUT https://api.spotify.com/v1/playlists/{playlist_id}/images
    final uri = Uri.parse(
      'https://api.spotify.com/v1/playlists/$playlistId/images',
    );

    final response = await spotifyClient.put(
      uri,
      headers: {'Content-Type': 'image/jpeg'},
      body: base64Image,
    );

    if (response.statusCode == 202) {
      log.info('✅ Uploaded playlist cover to Spotify');
      return true;
    } else {
      log.error(
        '❌ Failed to upload playlist cover: HTTP ${response.statusCode}',
      );
      return false;
    }
  } catch (e) {
    log.error('❌ Error uploading playlist cover: $e');
    return false;
  }
}

// /// Process playlist cover generation and upload for a job.
// ///
// /// Returns true if successful, false otherwise.
// Future<bool> processPlaylistCover({
//   required SpotifyApi spotifyApi,
//   required Map<String, dynamic> coverConfig,
//   required String playlistId,
//   required String renderedCaption,
//   required String outputDir,
//   required String jobName,
//   required String assetsDir,
// }) async {
//   final imagePath = coverConfig['image'] as String?;
//   if (imagePath == null) {
//     log.warning("⚠️  Cover config missing 'image' field");
//     return false;
//   }

//   // Create output directory if it doesn't exist
//   await Directory(outputDir).create(recursive: true);

//   // Generate cover image
//   final outputFilename = '${jobName}_cover.png';
//   final outputPath = path.join(outputDir, outputFilename);

//   final generatedImage = await generatePlaylistCover(
//     imagePath: imagePath,
//     caption: renderedCaption,
//     outputPath: outputPath,
//     assetsDir: assetsDir,
//     size: 512,
//   );

//   if (generatedImage == null) {
//     return false;
//   }

//   // The generatePlaylistCover function converts .png to .jpg for Spotify
//   // So we need to use the JPEG path for upload
//   final jpegPath = outputPath.replaceAll('.png', '.jpg');

//   // Upload to Spotify
//   final client = await spotifyApi.client;
//   return uploadPlaylistImage(
//     spotifyClient: client,
//     playlistId: playlistId,
//     imagePath: jpegPath,
//   );
// }
