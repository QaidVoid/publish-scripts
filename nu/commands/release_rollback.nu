# release rollback <project> — undo the last release.

source ../lib/config.nu
source ../lib/ui.nu
source ../lib/git.nu
source ../lib/github.nu

export def "release-rollback run" [
    project: string
    --yes
]: nothing -> nothing {
    let cfg = config resolve $project
    let dir = config local-path $project

    if not ($dir | path exists) {
        ui error $"Project directory not found: ($dir)"
        return
    }

    cd $dir

    let latest = git latest-tag $dir
    if $latest == null {
        ui error "No tags found — nothing to rollback."
        return
    }

    ui warn $"This will undo release ($latest):"
    print "  - Delete the GitHub release"
    print "  - Delete the remote tag"
    print "  - Delete the local tag"
    print "  - Revert the release commit (HEAD~1)"
    print ""

    if not ($yes or (ui confirm $"Rollback release ($latest)?" false)) {
        return
    }

    # Delete GitHub release
    try {
        github delete-release $latest
        ui success "GitHub release deleted"
    } catch { |e|
        ui warn $"Could not delete GitHub release: ($e.msg)"
    }

    # Delete remote tag
    try {
        ^git push origin $":($latest)"
        ui success "Remote tag deleted"
    } catch { |e|
        ui warn "Could not delete remote tag"
    }

    # Delete local tag
    try {
        ^git tag -d $latest
        ui success "Local tag deleted"
    } catch { |e|
        ui warn "Could not delete local tag"
    }

    # Revert the release commit
    try {
        ^git reset --hard HEAD~1
        ui success "Release commit reverted"
    } catch { |e|
        ui warn "Could not revert commit"
    }

    print ""
    ui success $"Rollback of ($latest) complete."
    ui info "You may need to manually fix version files and CHANGELOG.md."
}
