import 'package:in_phase/src/cli/commands/sync_command.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:test/test.dart';

void main() {
  test('collect targets match playlist names, ids, and URLs', () {
    final id = SpotifyPlaylistId('2YOnG57uXftLvuGj3SyTlK');
    expect(isCollectTarget(['COL_GEN_DNB'], id, 'COL_GEN_DNB'), isTrue);
    expect(isCollectTarget([id.toString()], id, 'Renamed'), isTrue);
    expect(
      isCollectTarget(
        ['https://open.spotify.com/playlist/$id'],
        id,
        'Renamed',
      ),
      isTrue,
    );
    expect(isCollectTarget(['COL_GEN_DNB'], id, 'FLOW_UNDEURO_Fm-4A'), isFalse);
  });
}
