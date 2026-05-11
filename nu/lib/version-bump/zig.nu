# Zig version bumping — build.zig.zon.
# build.zig.zon uses Zig's own struct syntax, not standard TOML.
# Falls back to sed for this edge case.

export def "zig bump" [dir: path, new_version: string]: nothing -> nothing {
    let zon_path = $dir | path join "build.zig.zon"
    if not ($zon_path | path exists) {
        error make { msg: $"build.zig.zon not found at ($zon_path)" }
    }
    sed -i $"s/\\.version = \"[^\"]*\"/.version = \"($new_version)\"/" $zon_path
}

export def "zig current-version" [dir: path]: nothing -> string {
    let zon_path = $dir | path join "build.zig.zon"
    if not ($zon_path | path exists) {
        error make { msg: $"build.zig.zon not found at ($zon_path)" }
    }
    let content = open --raw $zon_path
    let parsed = $content | parse --regex '\.version\s*=\s*"(?P<version>[^"]+)"'
    if ($parsed | is-empty) {
        error make { msg: "Could not parse version from build.zig.zon" }
    }
    $parsed | first | get version
}
