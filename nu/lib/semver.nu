# Semver parsing, bumping, comparison — pure Nushell, no external tools.

export def "semver parse" [version: string]: nothing -> record<major: int, minor: int, patch: int, pre: string> {
    let v = $version | str trim --left --char 'v'
    let parsed = $v | parse --regex '(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)(?P<pre>.*)' | first
    {
        major: ($parsed.major | into int)
        minor: ($parsed.minor | into int)
        patch: ($parsed.patch | into int)
        pre: $parsed.pre
    }
}

export def "semver bump" [version: string, level: string]: nothing -> string {
    let v = semver parse $version
    match $level {
        "major" => { $"($v.major + 1).0.0($v.pre)" }
        "minor" => { $"($v.major).($v.minor + 1).0($v.pre)" }
        "patch" => { $"($v.major).($v.minor).($v.patch + 1)($v.pre)" }
        _ => { error make { msg: $"Unknown bump level: ($level)" } }
    }
}

export def "semver compare" [a: string, b: string]: nothing -> int {
    let va = semver parse $a
    let vb = semver parse $b
    if $va.major > $vb.major { return 1 }
    if $va.major < $vb.major { return (-1) }
    if $va.minor > $vb.minor { return 1 }
    if $va.minor < $vb.minor { return (-1) }
    if $va.patch > $vb.patch { return 1 }
    if $va.patch < $vb.patch { return (-1) }
    0
}

export def "semver format" [version: string, prefix: string]: nothing -> string {
    $"($prefix)($version)"
}

export def "semver strip-prefix" [version: string, prefix: string]: nothing -> string {
    if ($prefix | is-not-empty) and ($version | str starts-with $prefix) {
        $version | str substring ($prefix | str length)..
    } else {
        $version
    }
}

export def "semver suggest-bump" [commits: list<record>]: nothing -> string {
    let has_breaking = ($commits | where { $in.breaking } | length) > 0
    let has_feat = ($commits | where { $in.type == "feat" } | length) > 0
    if $has_breaking { "major" } else if $has_feat { "minor" } else { "patch" }
}

export def "semver valid" [version: string]: nothing -> bool {
    ($version | parse --regex '^v?\d+\.\d+\.\d+.*' | length) > 0
}
