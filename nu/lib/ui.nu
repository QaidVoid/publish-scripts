# Interactive UI helpers — colors, prompts, selections.

export def "ui confirm" [message: string, default_yes: bool = true]: nothing -> bool {
    let hint = if $default_yes { "Y/n" } else { "y/N" }
    let answer = input $"($message) [($hint)] "
    if ($answer | is-empty) {
        $default_yes
    } else {
        ($answer | str downcase) == "y"
    }
}

export def "ui header" [text: string]: nothing -> nothing {
    print $"(ansi green_bold)▸ ($text)(ansi reset)"
}

export def "ui warn" [text: string]: nothing -> nothing {
    print $"(ansi yellow_bold)⚠ ($text)(ansi reset)"
}

export def "ui error" [text: string]: nothing -> nothing {
    print $"(ansi red_bold)✗ ($text)(ansi reset)"
}

export def "ui success" [text: string]: nothing -> nothing {
    print $"(ansi green_bold)✓ ($text)(ansi reset)"
}

export def "ui info" [text: string]: nothing -> nothing {
    print $"(ansi cyan)  ($text)(ansi reset)"
}

export def "ui dry-run" [text: string]: nothing -> nothing {
    print $"(ansi magenta)[dry-run] (ansi reset)($text)"
}

export def "ui select-bump" [
    current: string
    suggestion: string
    changes_summary: string
]: nothing -> string {
    let patch = semver bump $current "patch"
    let minor = semver bump $current "minor"
    let major = semver bump $current "major"
    let default_choice = if $suggestion == "major" { "3" } else if $suggestion == "minor" { "2" } else { "1" }

    print ""
    print $"(ansi purple_bold)  Current:    (ansi reset)($current)"
    print $"(ansi purple_bold)  Suggested:  (ansi reset)($suggestion)"
    print $"(ansi purple_bold)  Changes:    (ansi reset)($changes_summary)"
    print ""
    print $"  1) patch  ($current) → ($patch)"
    print $"  2) minor  ($current) → ($minor)"
    print $"  3) major  ($current) → ($major)"
    print $"  4) custom version"
    print $"  0) cancel"
    print ""

    let choice = input $"Choose [($default_choice)]: "
    let chosen = if ($choice | is-empty) { $default_choice } else { $choice }

    match $chosen {
        "1" => { $patch }
        "2" => { $minor }
        "3" => { $major }
        "4" => {
            let custom = input "Enter version: "
            if ($custom | is-empty) { null } else { $custom }
        }
        _ => { null }
    }
}

export def "ui select-project" [projects: table]: nothing -> string {
    print $"(ansi green_bold)Available projects:(ansi reset)"
    print ""
    $projects | enumerate | each {|row|
        print $"  ($row.index + 1)) ($row.item.name) (ansi cyan)(($row.item.lang))(ansi reset)"
    }
    print ""
    let choice = input "Select project (name or number): "
    if ($choice | is-empty) { return null }

    let as_num = $choice | into int -s
    if $as_num != null and $as_num >= 1 and $as_num <= ($projects | length) {
        $projects | get ($as_num - 1) | get name
    } else {
        let found = $projects | where name == $choice
        if ($found | is-empty) { null } else { $found | get name | first }
    }
}

export def "ui show-preflight" [results: record]: nothing -> nothing {
    let clean_mark = if $results.clean { $"(ansi green)✓(ansi reset)" } else { $"(ansi red)✗(ansi reset)" }
    let remote_mark = if $results.remote_ok { $"(ansi green)✓(ansi reset)" } else { $"(ansi yellow)~(ansi reset)" }
    print ""
    print $"  clean tree:   ($clean_mark)"
    print $"  branch:       ($results.branch)"
    print $"  remote sync:  ($remote_mark)"
    print ""
}
