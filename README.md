# publish-scripts

A unified, interactive CLI to manage releases across all your GitHub repos from one place. Replaces release-plz with a transparent, old-school semver workflow.

**Written in [Nushell](https://nushell.sh)** — because every step in a release pipeline is structured data.

## Install

```bash
# Add nushell to your nix config, or just use the dev shell:
nix develop

# Or install the package:
nix profile install .
```

## Usage

```bash
# Full interactive release
release ghpulse
release compak --bump minor

# Dashboard — see all projects and their release readiness
release status

# Workspace scoped release
release onelf --crate onelf-preload

# Preview without doing anything
release netinject --dry-run

# Only generate the changelog
release awsim --changelog-only

# Add a new project to the registry
release init my-new-repo

# Undo the last release
release rollback compak

# No arguments — pick a project interactively
release
```

## How It Works

The release workflow has 9 steps:

1. **Resolve** — Load project config from `projects.toml`
2. **Preflight** — Check clean tree, correct branch, remote sync
3. **Detect** — Parse conventional commits, suggest bump level
4. **Bump** — Update version in `Cargo.toml`, `package.json`, or `build.zig.zon`
5. **Changelog** — Generate with `git-cliff` (repo-local or fallback config)
6. **Commit + Tag** — `chore(release): vX.Y.Z` + annotated tag
7. **Push** — Push commit + tags (confirmation required)
8. **GitHub Release** — Create via `gh release create`
9. **Post-release** — Optional `cargo publish` / `npm publish`

## Configuration

Projects are registered in `projects.toml`:

```toml
[defaults]
tag_prefix = "v"
publish = false

[projects.my-project]
lang = "rust"
tag_prefix = "v"
publish = true
```

### Supported languages

| Language    | Version file      | Bump method                |
|-------------|-------------------|---------------------------|
| Rust        | `Cargo.toml`      | Nu native TOML update     |
| TypeScript  | `package.json`    | Nu native JSON update     |
| Zig         | `build.zig.zon`   | sed (non-standard format) |
| Go          | —                 | Tags only (no file bump)  |

### Supported project types

- **Rust package** — single `Cargo.toml` with `[package]`
- **Rust workspace** — root `Cargo.toml` with `[workspace]` + member crates
- **Workspace scoped** — `--crate` flag to release a specific crate with prefixed tag

## Requirements

- [Nushell](https://nushell.sh) 0.100+
- [git-cliff](https://git-cliff.org) 2.x
- [GitHub CLI (`gh`)](https://cli.github.com) 2.x
- `git`, `jq`, `sed`

## Safety

- Always confirms before push (point of no return)
- `--dry-run` shows every command without executing
- Preflight checks verify clean state
- Refuses to overwrite existing tags
- Unknown projects prompt `release init` instead of guessing

## License

MIT
