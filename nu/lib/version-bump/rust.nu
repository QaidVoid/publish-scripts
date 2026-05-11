# Rust version bumping — Cargo.toml (single package and workspace).

# Internal: bump version in a single Cargo.toml using regex replacement.
def "rust bump-cargo-toml" [path: path, new_version: string]: nothing -> nothing {
    let content = open --raw $path
    let updated = $content
        | str replace --all --multiline '(?m)^(\s*version\s*=\s*")[^"]*(")' $"${1}($new_version)${2}"
    $updated | save --force $path
}

export def "rust is-workspace" [dir: path]: nothing -> bool {
    let cargo_path = $dir | path join "Cargo.toml"
    if not ($cargo_path | path exists) { return false }
    let content = open --raw $cargo_path
    ($content | str contains "[workspace]")
}

export def "rust bump-package" [dir: path, new_version: string]: nothing -> nothing {
    rust bump-cargo-toml ($dir | path join "Cargo.toml") $new_version
}

export def "rust bump-workspace" [dir: path, new_version: string]: nothing -> nothing {
    let cargo_path = $dir | path join "Cargo.toml"
    let cargo = open $cargo_path
    let members = $cargo | get -o workspace.members

    # Bump root Cargo.toml
    rust bump-cargo-toml $cargo_path $new_version

    # Bump each member crate
    if $members != null {
        for member in $members {
            let member_cargo = [$dir $member "Cargo.toml"] | path join
            if ($member_cargo | path exists) {
                rust bump-cargo-toml $member_cargo $new_version
            }
        }
    }
}

export def "rust bump" [dir: path, new_version: string, is_workspace: bool]: nothing -> nothing {
    if $is_workspace {
        rust bump-workspace $dir $new_version
    } else {
        rust bump-package $dir $new_version
    }
}

export def "rust current-version" [dir: path]: nothing -> string {
    let cargo = open ($dir | path join "Cargo.toml")
    let wp = $cargo | get -o workspace.package.version
    if $wp != null { return $wp }
    let p = $cargo | get -o package.version
    if $p != null { return $p }
    "0.0.0"
}
