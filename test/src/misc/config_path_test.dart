import 'package:in_phase/src/misc/config_path.dart';
import 'package:in_phase/src/misc/constants.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('resolveConfigPath', () {
    test('expands a leading ~ to the user home directory', () {
      final file = resolveConfigPath('~/.in_phase/crawl_config.yaml');

      expect(
        file.path,
        path.normalize(
          path.join(
            Constants.userHomeDirectory,
            '.in_phase',
            'crawl_config.yaml',
          ),
        ),
      );
    });

    test(
      'middle ~ stays literal; relative paths resolve to absolute',
      () {
        final file = resolveConfigPath('some/dir/~/config.yaml');

        expect(
          file.path,
          path.normalize(path.absolute('some/dir/~/config.yaml')),
        );
      },
    );
  });
}
