# release status — dashboard showing all projects and their release readiness.

source ../lib/semver.nu
source ../lib/config.nu
source ../lib/git.nu

export def "release-status run" []: nothing -> nothing {
    let projects = config load-projects
    let separator = "─" | fill -c "─" -w 78

    print ""
    print $"  (ansi green_bold)PROJECT       CURRENT     UNRELEASED                              SUGGESTED(ansi reset)"
    print $"  (ansi d)($separator)(ansi reset)"

    for proj in $projects {
        let dir = config local-path $proj.name

        if not ($dir | path exists) {
            let name_col = $proj.name | fill -w 14
            let lang_col = $proj.lang | fill -w 12
            print $"  ($name_col)($lang_col)(ansi d)not cloned(ansi reset)"
            continue
        }

        let latest_tag = git latest-tag $dir
        let current_display = if $latest_tag != null { $latest_tag } else { "—" }

        let commits = try {
            cd $dir
            git parse-commits-since $dir $latest_tag
        } catch {
            []
        }
        let commit_count = $commits | length

        let unreleased_display = if $commit_count == 0 {
            "clean"
        } else {
            git summarize-commits $commits
        }

        let suggested = if $commit_count == 0 {
            "—"
        } else {
            let suggestion = semver suggest-bump $commits
            let prefix = $proj | get -o tag_prefix | default ""
            if $latest_tag != null {
                let current = semver strip-prefix $latest_tag $prefix
                semver format (semver bump $current $suggestion) $prefix
            } else {
                semver format "0.1.0" $prefix
            }
        }

        let name_col = $proj.name | fill -w 14
        let current_col = $current_display | fill -w 12
        let unreleased_col = $unreleased_display | fill -w 40

        if $commit_count == 0 {
            print $"  ($name_col)($current_col)(ansi d)($unreleased_col)(ansi d)($suggested)(ansi reset)"
        } else {
            print $"  ($name_col)($current_col)(ansi yellow)($unreleased_col)(ansi green_bold)($suggested)(ansi reset)"
        }
    }

    print ""
}
