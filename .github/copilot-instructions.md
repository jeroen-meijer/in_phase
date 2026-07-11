# GitHub Copilot Instructions for InPhase

Before making any suggestions or changes to this codebase, please read the following files to understand the project:

- **[README.md](../README.md)** — Installation instructions, setup guide, usage examples, and requirements
- **[CLAUDE.md](../CLAUDE.md)** — Technical documentation including tech stack, key directories, common commands, code standards, changelog workflow, and project-specific warnings
- **[.github/workflows/](../.github/workflows/)** — CI (format, analyze, tests, Codecov, pana) and semantic PR title checks
- **[tool/prepare_release.sh](../tool/prepare_release.sh)** — release PR helper; **[tool/rewrite_changelog_for_release.sh](../tool/rewrite_changelog_for_release.sh)** — changelog headings (`awk`/`sed`)

## Additional Documentation

- [SYNC_CONFIG.md](../docs/SYNC_CONFIG.md) — Sync configuration format
- [CRAWL_CONFIG.md](../docs/CRAWL_CONFIG.md) — Crawl configuration format
- [COLLECT_CONFIG.md](../docs/COLLECT_CONFIG.md) — Collect configuration format
- [CURATE_CONFIG.md](../docs/CURATE_CONFIG.md) — Curate configuration (playlist arg + string-list `targets` accept ID/URI/URL/name; move mode `m`) and keyboard controls
