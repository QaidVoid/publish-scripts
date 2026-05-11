# git-cliff integration — changelog generation and preview.

export def "changelog resolve-config" [dir: path]: nothing -> path {
    let local_config = $dir | path join "cliff.toml"
    if ($local_config | path exists) {
        $local_config
    } else {
        let default_config = [$env.HOME dev personal publish-scripts cliff.default.toml] | path join
        if not ($default_config | path exists) {
            error make { msg: $"Default cliff config not found at ($default_config)" }
        }
        $default_config
    }
}

export def "changelog generate" [dir: path, tag: string, config: path]: nothing -> nothing {
    cd $dir
    git-cliff --tag $tag --config $config -o CHANGELOG.md
}

export def "changelog preview" [dir: path, tag: string, config: path]: nothing -> string {
    cd $dir
    let result = do { git-cliff --tag $tag --unreleased --strip header --config $config } | complete
    if ($result.exit_code != 0) {
        $"Release ($tag)"
    } else {
        $result.stdout
    }
}

export def "changelog unreleased" [dir: path, config: path]: nothing -> string {
    cd $dir
    let result = do { git-cliff --unreleased --config $config } | complete
    if ($result.exit_code != 0) {
        "No unreleased changes."
    } else {
        $result.stdout
    }
}
