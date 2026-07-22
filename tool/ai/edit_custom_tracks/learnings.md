# edit-custom-tracks learnings

Persistent notes for agents. After any friction (failed resolve, wrong fuzzy
hit, awkward YAML edit, missing CLI flag), append a dated bullet here **and**
fix the script/skill if the fix is mechanical. Keep bullets concrete.

## 2026-07-22

- Short title queries like `So Good` failed when the RB title is a WIP name
  (`So Good 2025-12-19 1938`). Fixed with title-prefix/word boosts in
  `scoreNameMatch`.
- Playlist anchors like `Twerp` failed because scoring used only
  `artists + title`, diluting short titles. Same scorer now used for playlist
  cache matching.
- Raw / token-sort **partial** ratios false-positived (`Twerp`→`Antwerp`,
  `So Good`→`Something Good`). `scoreNameMatch` now uses token-sort only +
  title prefix/word boosts.
- Prefer `--artist "Unknown Artist"` / `So Good by Unknown Artist` when the
  user names an artist; use `--search` to disambiguate before applying.
- On fuzzy failure, use `resolve.dart --search "…"` (lists top RB ids) — do
  not leave `tool/tmp_*.dart` behind. Failures print top candidates.
- `~/.in_phase/sync_config.yaml` is outside the git workspace; StrReplace can
  miss — patch that absolute path via a short Python/shell snippet. Never
  `SyncConfig.write` / `yamlEncode` (drops comments).
