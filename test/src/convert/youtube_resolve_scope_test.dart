import 'package:in_phase/src/convert/youtube_resolve_scope.dart';
import 'package:test/test.dart';

void main() {
  group('resolveWatchAndListScope', () {
    test('honours --scope playlist flag', () {
      expect(
        resolveWatchAndListScope(isMix: true, scopeFlag: 'playlist'),
        YoutubeResolveScope.playlist,
      );
    });

    test('honours --scope video flag', () {
      expect(
        resolveWatchAndListScope(isMix: false, scopeFlag: 'video'),
        YoutubeResolveScope.singleVideo,
      );
    });
  });
}
