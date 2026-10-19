# Agent Guide

## Adding a new external tool

1. **Confirm the GitHub repo** — ask user if unsure, don't guess
2. **Get release URLs** for Linux, macOS, Windows from GitHub
3. **Download & checksum** in a temp dir:
   ```bash
   mkdir -p /tmp/opencode/<app>-checksums && cd /tmp/opencode/<app>-checksums
   curl -sL -o <app>-linux.tar.gz "<linux-url>"
   curl -sL -o <app>-darwin.tar.gz "<darwin-url>"
   curl -sL -o <app>-windows.zip "<windows-url>"
   sha256sum <app>-*
   ```
4. **Check archive structure** (nested folder vs flat):
   ```bash
   tar -tzf <app>-linux.tar.gz | head -5
   unzip -l <app>-windows.zip
   ```
5. **Create `.chezmoiexternals/<app>.toml`** — see `bat.toml` for nested folders, `fzf.toml` for flat
6. **Add version + repo + dotup regexes** to `.chezmoidata/tools.toml`
7. **Add hashes** to `.chezmoidata/hashes.toml`
8. **Verify**: `chezmoi execute-template < .chezmoiexternals/<app>.toml`
9. **Clean up**: `rm -rf /tmp/opencode/<app>-checksums`

## dotup section in tools.toml

`[tools.<app>.dotup.assets]` maps each `hashes.toml` platform key
(`<os>_<arch>`) to an anchored regex matching exactly ONE asset filename in
the GitHub release. Rules:

- Never embed a version number — use `[0-9.]+`
- Always anchor with `^…$` so sidecars (`.sha256`, source archives, GUI
  builds, `croc-web-*`, etc.) can't match
- Only list platforms the external actually downloads
- Omit the whole `dotup` section when the mapping can't be expressed
  (e.g. neovim picks repos by glibc version) — dotup then version-checks
  only and never touches hashes

When bumping a tool's version manually, no regex changes are needed — they're
version-independent by design.

## Template patterns

| Pattern | Use for |
|---------|---------|
| `archive-file` | `.tar.gz` / `.zip` archives |
| `file` | Single binary downloads |
| Triples | `x86_64-unknown-linux-musl`, `aarch64-apple-darwin`, `x86_64-pc-windows-msvc` |

## Key files

- `.chezmoiexternals/` — external tool definitions
- `.chezmoidata/tools.toml` — tool versions + GitHub repos (`owner/name`)
- `.chezmoidata/hashes.toml` — SHA256 checksums
