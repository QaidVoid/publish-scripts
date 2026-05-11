# release <project> — the full 9-step release workflow.

source ../lib/semver.nu
source ../lib/config.nu
source ../lib/ui.nu
source ../lib/git.nu
source ../lib/changelog.nu
source ../lib/github.nu
source ../lib/version-bump/rust.nu
source ../lib/version-bump/node.nu
source ../lib/version-bump/zig.nu
source ../lib/version-bump/golang.nu

export def "release-project run" [
    project: string
    --bump: string = ""
    --crate: string = ""
    --dry-run
    --changelog-only
    --skip-preflight
    --yes
]: nothing -> nothing {

    # ── Step 1: Resolve Project ──────────────────────────────

    ui header $"Resolving project: ($project)"
    let cfg = config resolve $project
    let dir = config local-path $project

    if not ($dir | path exists) {
        ui error $"Project directory not found: ($dir)"
        return
    }

    cd $dir
    ui info $"Path: ($dir)"
    ui info $"Language: ($cfg.lang)"

    let is_workspace = ($cfg | get -o type) == "workspace"

    # ── Step 2: Preflight Checks ─────────────────────────────

    if not $skip_preflight {
        ui header "Preflight checks"
        let checks = git preflight $dir
        ui show-preflight $checks

        if not $checks.clean {
            ui warn "Working tree has uncommitted changes."
            if not ($yes or (ui confirm "Continue anyway?" false)) {
                return
            }
        }

        let allowed_branches = ["main" "master"]
        if ($checks.branch not-in $allowed_branches) {
            ui warn $"Not on main/master (on ($checks.branch))."
            if not ($yes or (ui confirm "Continue anyway?" false)) {
                return
            }
        }
    }

    # ── Step 3: Detect Changes → Suggest Bump ────────────────

    ui header "Detecting changes"
    let latest_tag = git latest-tag $dir

    if $latest_tag != null {
        ui info $"Latest tag: ($latest_tag)"
    } else {
        ui info "No previous tags found — will create first release."
    }

    let commits = git parse-commits-since $dir $latest_tag
    let commit_count = $commits | length

    if $commit_count == 0 {
        ui warn "No new commits since last tag. Nothing to release."
        return
    }

    let summary = git summarize-commits $commits
    ui info $"($commit_count) commits: ($summary)"

    let suggestion = if ($bump | is-not-empty) {
        if (semver valid $bump) { "custom" } else { $bump }
    } else {
        semver suggest-bump $commits
    }

    let current_version = if $latest_tag != null {
        let prefix = $cfg | get -o tag_prefix | default ""
        semver strip-prefix $latest_tag $prefix
    } else {
        match $cfg.lang {
            "rust" => { rust current-version $dir | default "0.0.0" }
            "typescript" => { node current-version $dir | default "0.0.0" }
            "zig" => { zig current-version $dir | default "0.0.0" }
            _ => { "0.1.0" }
        }
    }

    let new_version = if ($bump | is-not-empty) and (semver valid $bump) {
        $bump
    } else if $yes {
        semver bump $current_version $suggestion
    } else {
        ui select-bump $current_version $suggestion $summary
    }

    if $new_version == null {
        ui info "Cancelled."
        return
    }

    let tag_prefix = $cfg | get -o tag_prefix | default ""
    let full_tag = if ($crate | is-not-empty) and $is_workspace {
        $"($crate)-($tag_prefix)($new_version)"
    } else {
        semver format $new_version $tag_prefix
    }

    ui info $"New version: ($current_version) → ($new_version)"
    ui info $"Tag: ($full_tag)"

    # Build the commit message (avoids Nu parsing "chore(release)" as a command)
    let commit_prefix = "chore"
    let commit_msg = $"($commit_prefix)\(release\): ($full_tag)"

    # ── Step 4: Version Bump ─────────────────────────────────

    if not $changelog_only and ($cfg.lang != "go") and ($cfg.lang != "shell") {
        ui header "Bumping version"
        if $dry_run {
            ui dry-run $"Would bump ($cfg.lang) version to ($new_version)"
        } else {
            match $cfg.lang {
                "rust" => { rust bump $dir $new_version $is_workspace }
                "typescript" => { node bump $dir $new_version }
                "zig" => { zig bump $dir $new_version }
                _ => { ui warn $"No bump handler for ($cfg.lang)" }
            }
            ui success $"Version bumped to ($new_version)"
        }
    }

    # ── Step 5: Generate Changelog ───────────────────────────

    ui header "Generating changelog"
    let cliff_config = changelog resolve-config $dir
    ui info $"Using cliff config: ($cliff_config)"

    if $dry_run {
        ui dry-run $"Would run: git-cliff --tag ($full_tag) -o CHANGELOG.md"
    } else {
        changelog generate $dir $full_tag $cliff_config
        ui success "CHANGELOG.md generated"
    }

    let notes = changelog preview $dir $full_tag $cliff_config
    print ""
    print $"(ansi attr_bold)── Release Notes Preview ──(ansi reset)"
    print $notes
    print ""

    if $changelog_only {
        ui info "Changelog-only mode. Done."
        return
    }

    if not ($yes or (ui confirm "Proceed with release?")) {
        ui info "Cancelled."
        return
    }

    # ── Step 6: Commit + Tag ─────────────────────────────────

    ui header "Committing and tagging"
    if $dry_run {
        ui dry-run $"Would commit: ($commit_msg)"
        ui dry-run $"Would tag: ($full_tag)"
    } else {
        ^git add -A
        ^git commit -m $commit_msg
        ^git tag -a $full_tag -m $full_tag
        ui success $"Committed and tagged ($full_tag)"
    }

    # ── Step 7: Push ─────────────────────────────────────────

    ui header "Pushing to remote"
    let branch = git current-branch $dir

    if $dry_run {
        ui dry-run $"Would push to origin ($branch) with tag ($full_tag)"
    } else if ($yes or (ui confirm $"Push to origin ($branch) with tag ($full_tag)?")) {
        ^git push origin $branch --tags
        ui success "Pushed to remote"
    } else {
        ui warn "Push skipped. Tag and commit are local only."
        ui info $"To push manually: git push origin ($branch) --tags"
        return
    }

    # ── Step 8: GitHub Release ───────────────────────────────

    let do_github = $cfg | get -o github_release | default true
    if $do_github {
        ui header "Creating GitHub release"
        if $dry_run {
            ui dry-run $"Would create GitHub release for ($full_tag)"
        } else {
            github create-release $full_tag $notes
            ui success $"GitHub release created: ($full_tag)"
        }
    }

    # ── Step 9: Post-Release ─────────────────────────────────

    let do_publish = $cfg | get -o publish | default false
    if $do_publish and not $dry_run {
        ui header "Publishing"
        match $cfg.lang {
            "rust" => {
                if ($yes or (ui confirm "Run cargo publish?")) {
                    ^cargo publish --allow-dirty
                    ui success "Published to crates.io"
                }
            }
            "typescript" => {
                if ($yes or (ui confirm "Run npm publish?")) {
                    ^npm publish
                    ui success "Published to npm"
                }
            }
            _ => {
                ui info $"No publish action for ($cfg.lang)"
            }
        }
    }

    print ""
    ui success $"Release ($full_tag) complete!"
}
