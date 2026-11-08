import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:test/test.dart';

void main() {
  group('parseYamlConfig', () {
    CurateConfig parse(String content) => parseYamlConfig(
      content,
      fromJson: CurateConfig.fromJson,
      defaults: const CurateConfig.empty(),
      source: 'curate_config.yaml',
    );

    test('returns defaults for an empty or comment-only file', () {
      expect(parse('').seekStep, 15);
      expect(parse('# nothing configured yet\n').startPosition, '1:15');
    });

    test('parses a map', () {
      expect(parse('seek_step: 10\ntargets: [KEYSORT]').targets, ['KEYSORT']);
    });

    test('rejects a non-map root and names the file', () {
      expect(
        () => parse('- a\n- b'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('curate_config.yaml'),
          ),
        ),
      );
    });
  });
}
