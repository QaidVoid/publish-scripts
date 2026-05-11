# TypeScript/JavaScript version bumping — package.json.

export def "node bump" [dir: path, new_version: string]: nothing -> nothing {
    let pkg_path = $dir | path join "package.json"
    if not ($pkg_path | path exists) {
        error make { msg: $"package.json not found at ($pkg_path)" }
    }
    let pkg = open $pkg_path
    $pkg | update version $new_version | save --force $pkg_path
}

export def "node current-version" [dir: path]: nothing -> string {
    let pkg_path = $dir | path join "package.json"
    if not ($pkg_path | path exists) {
        error make { msg: $"package.json not found at ($pkg_path)" }
    }
    open $pkg_path | get version
}
