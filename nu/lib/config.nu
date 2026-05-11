# Project configuration loader — reads projects.toml.

# Root directory of publish-scripts.
export def "config root" []: nothing -> path {
    [$env.HOME dev personal publish-scripts] | path join
}

export def "config load-projects" []: nothing -> table {
    let config_path = config root | path join "projects.toml"
    if not ($config_path | path exists) {
        error make { msg: $"projects.toml not found at ($config_path)" }
    }
    let raw = open $config_path
    let defaults = $raw | get -o defaults
    let projects = $raw | get projects
    $projects
        | transpose name info
        | each {|row|
            let merged = if $defaults != null {
                $defaults | merge $row.info
            } else {
                $row.info
            }
            $merged | insert name $row.name
        }
}

export def "config resolve" [name: string]: nothing -> record {
    let projects = config load-projects
    let match = $projects | where name == $name
    if ($match | is-empty) {
        let hint = $"Project '($name)' not found. Use 'release init ($name)' to add it."
        error make { msg: $hint }
    }
    $match | first
}

export def "config exists" [name: string]: nothing -> bool {
    (config load-projects | where name == $name | length) > 0
}

export def "config local-path" [name: string]: nothing -> path {
    [$env.HOME dev personal $name] | path join
}

export def "config list-names" []: nothing -> list<string> {
    config load-projects | get name
}

export def "config default-branch" [cfg: record]: nothing -> string {
    $cfg | get -o branch | default "main"
}
