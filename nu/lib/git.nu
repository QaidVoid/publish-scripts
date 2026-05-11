# Git operations — preflight checks, tag management, commit analysis.

export def "git preflight" [dir: path]: nothing -> record<clean: bool, branch: string, remote_ok: bool> {
    cd $dir
    let status_out = (do { git status --porcelain } | complete)
    let fetch_out = (do { git fetch --dry-run } | complete)
    let clean = ($status_out.stdout | str trim | is-empty)
    let remote_ok = (($fetch_out.stdout | str trim | is-empty) and ($fetch_out.stderr | str trim | is-empty))
    {
        clean: $clean
        branch: (git branch --show-current | str trim)
        remote_ok: $remote_ok
    }
}

export def "git latest-tag" [dir: path]: nothing -> string {
    cd $dir
    let result = do { git describe --tags --abbrev=0 } | complete
    if ($result.exit_code == 0) {
        $result.stdout | str trim
    } else {
        null
    }
}

export def "git all-tags" [dir: path]: nothing -> list<string> {
    cd $dir
    git tag --sort=-version:refname | lines
}

export def "git commit-count-since" [dir: path, tag: string]: nothing -> int {
    cd $dir
    let range = if $tag != null { $"($tag)..HEAD" } else { "HEAD" }
    git log $range --oneline | lines | length
}

export def "git parse-commits-since" [dir: path, tag: string]: nothing -> list<record<type: string, scope: string, desc: string, breaking: bool>> {
    cd $dir
    let range = if $tag != null { $"($tag)..HEAD" } else { "HEAD" }
    let messages = git log $range --pretty=format:"%s---BODY---%b---END---" | lines

    $messages | each {|msg|
        let parts = $msg | split row "---BODY---"
        let subject = $parts | first | str trim
        let body = if ($parts | length) > 1 { $parts | last | split row "---END---" | first | str trim } else { "" }

        let parsed = $subject | parse --regex '(?P<type>[a-z]+)(?:\((?P<scope>[^)]+)\))?(!)?\s*:\s*(?P<desc>.*)'
        if ($parsed | is-empty) {
            { type: "other", scope: "", desc: $subject, breaking: false }
        } else {
            let p = $parsed | first
            let bang = $p | get -o "!"
            let is_breaking = ($bang | default "" | str trim) == "!" or ($body | str contains "BREAKING CHANGE")
            { type: $p.type, scope: ($p.scope | default ""), desc: $p.desc, breaking: $is_breaking }
        }
    }
}

export def "git summarize-commits" [commits: list<record>]: nothing -> string {
    if ($commits | is-empty) { return "no commits" }

    let breaking_count = $commits | where breaking | length
    let grouped = $commits
        | where not breaking
        | group-by type
        | transpose type items
        | each {|g| $"($g.items | length) ($g.type)" }
        | str join ", "

    if $breaking_count > 0 {
        $"($breaking_count) breaking, ($grouped)"
    } else if ($grouped | is-empty) {
        $"($commits | length) commits"
    } else {
        $grouped
    }
}

export def "git current-branch" [dir: path]: nothing -> string {
    cd $dir
    git branch --show-current | str trim
}

export def "git is-clean" [dir: path]: nothing -> bool {
    cd $dir
    (git status --porcelain | str trim | is-empty)
}
