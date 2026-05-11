# Go version bumping — tags only.
# Go doesn't store version in source files (uses module path + tags).

export def "golang bump" [_dir: path, _new_version: string]: nothing -> nothing {
    # Go uses git tags for versioning — no file modification needed.
}

export def "golang current-version" [_dir: path]: nothing -> nothing {
    null
}
