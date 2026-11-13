import 'dart:io';

import 'package:in_phase/src/misc/misc.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('Constants.version matches pubspec.yaml', () {
    final pubspec =
        loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    expect(Constants.version, pubspec['version']);
  });
}
