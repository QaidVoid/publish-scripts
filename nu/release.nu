#!/usr/bin/env nu
# publish-scripts — unified release CLI for GitHub projects.
#
# Usage:
#   nu release.nu <project> [flags]
#   nu release.nu status
#   nu release.nu init <project>
#   nu release.nu rollback <project>

source commands/release_project.nu
source commands/release_status.nu
source commands/release_init.nu
source commands/release_rollback.nu

const VERSION = "0.1.0"

def main [
    ...args: string
    --bump: string = ""
    --crate: string = ""
    --dry-run
    --changelog-only
    --skip-preflight
    --yes
    --version (-v)
    --help (-h)
]: nothing -> nothing {
    if $help {
        print $"
publish-scripts — unified release CLI

USAGE:
  nu release.nu [FLAGS] <project>
  nu release.nu status
  nu release.nu init <project>
  nu release.nu rollback <project>

FLAGS:
  --bump <level>      Override bump: major, minor, patch, or exact version (e.g. 1.5.0)
  --crate <name>      Target a specific crate in a workspace
  --dry-run           Show what would happen without doing it
  --changelog-only    Only generate the changelog
  --skip-preflight    Skip preflight checks
  --yes               Skip all confirmation prompts
  --version, -v       Print version
  --help, -h          Print this help

EXAMPLES:
  nu release.nu ghpulse                     Interactive release for ghpulse
  nu release.nu compak --bump minor          Force minor bump
  nu release.nu onelf --crate onelf-preload  Release one crate in workspace
  nu release.nu status                       Show all projects release readiness
  nu release.nu init my-new-project          Add a new project to the registry
  nu release.nu netinject --dry-run          Preview what would happen
"
        return
    }
    if $version {
        print $VERSION
        return
    }

    let subcommand = $args | first | default ""

    match $subcommand {
        "status" => {
            release-status run
        }
        "init" => {
            let project = $args | skip 1 | first
            release-init run $project
        }
        "rollback" => {
            let project = $args | skip 1 | first
            release-rollback run $project --yes=$yes
        }
        "" => {
            # No argument — interactive project selection
            let projects = config load-projects
            let chosen = ui select-project $projects
            if $chosen != null {
                release-project run $chosen --bump=$bump --crate=$crate --dry-run=$dry_run --changelog-only=$changelog_only --skip-preflight=$skip_preflight --yes=$yes
            }
        }
        _ => {
            release-project run $subcommand --bump=$bump --crate=$crate --dry-run=$dry_run --changelog-only=$changelog_only --skip-preflight=$skip_preflight --yes=$yes
        }
    }
}
