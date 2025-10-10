// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:rkdb_dart/src/crawl/cover_generator.dart';
import 'package:rkdb_dart/src/crawl/template_engine.dart';
import 'package:rkdb_dart/src/entities/entities.dart';
import 'package:rkdb_dart/src/misc/misc.dart';

Future<void> main() async {
  print('🎨 Cover Generator Test\n');

  // Load crawl config
  final configFile = Constants.crawlConfigFile;
  print('📁 Loading config from: ${configFile.path}');
  final config = await CrawlConfig.fromFile(configFile);

  final configDir = configFile.parent.path;
  final outputDir = Constants.generatedCoversDir.path;

  // Create output directory
  await Directory(outputDir).create(recursive: true);
  print('📁 Output directory: $outputDir\n');

  // Process each job that has a cover config
  var generated = 0;
  for (final job in config.jobs) {
    if (job.cover == null) continue;

    print('🔄 Processing job: ${job.name}');

    // Render template variables with dummy data
    const templateEngine = TemplateEngine();
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final endDate = DateTime.now();

    final caption = job.cover!.caption ?? job.name;
    final renderedCaption = templateEngine.render(
      caption,
      job: job,
      cutoffDate: cutoffDate,
      endDate: endDate,
      trackCount: 42, // Dummy values for testing
      realArtistCount: 15,
      realAlbumCount: 20,
      realPlaylistCount: 3,
      realArtistSourceCount: 5,
      realLabelCount: 8,
    );

    print('  📝 Caption: $renderedCaption');

    // Generate cover
    final imagePath = job.cover!.image;
    final outputFilename = '${job.name}_cover.jpg';
    final outputPath = path.join(outputDir, outputFilename);

    final generatedImage = await generatePlaylistCover(
      imagePath: imagePath,
      caption: renderedCaption,
      outputPath: outputPath,
      assetsDir: configDir,
      size: 512,
    );

    if (generatedImage != null) {
      print('  ✅ Generated: $outputPath\n');
      generated++;
    } else {
      print('  ❌ Failed to generate cover\n');
    }
  }

  print('✨ Done! Generated $generated cover(s)');
}
