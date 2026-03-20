import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:tilde_expansion/tilde_expansion.dart';

/// Resolves a user-supplied config path for [File].
///
/// - Trims surrounding whitespace.
/// - Correctly expands a leading `~` or `~/`.
File resolveConfigPath(String rawPath) {
  final trimmedPath = rawPath.trim();
  if (trimmedPath.isEmpty) {
    throw ArgumentError('Config path cannot be empty');
  }

  final expandedPath = trimmedPath.expandUser();
  return File(path.normalize(expandedPath));
}
