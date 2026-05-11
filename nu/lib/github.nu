# GitHub release operations via `gh`.

export def "github create-release" [
    tag: string
    notes: string
    --repo: string = ""
    --prerelease
    --draft
    --title: string = ""
]: nothing -> nothing {
    let title = if ($title | is-empty) { $tag } else { $title }
    let notes_file = mktemp
    $notes | save --force $notes_file
    mut cmd = [gh release create $tag --title $title]
    $cmd = $cmd | append ["--notes-file" $notes_file]
    if ($repo | is-not-empty) { $cmd = $cmd | append ["--repo" $repo] }
    if $prerelease { $cmd = $cmd | append "--prerelease" }
    if $draft { $cmd = $cmd | append "--draft" }
    ^...$cmd
    rm $notes_file
}

export def "github upload-assets" [
    tag: string
    assets: list<path>
    --repo: string = ""
]: nothing -> nothing {
    mut cmd = [gh release upload $tag]
    $cmd = $cmd | append $assets
    if ($repo | is-not-empty) { $cmd = $cmd | append ["--repo" $repo] }
    ^...$cmd
}

export def "github delete-release" [
    tag: string
    --repo: string = ""
]: nothing -> nothing {
    mut cmd = [gh release delete $tag --yes]
    if ($repo | is-not-empty) { $cmd = $cmd | append ["--repo" $repo] }
    ^...$cmd
    # Also remove the local and remote tag
    git tag -d $tag
    git push origin $":($tag)"
}

export def "github list-releases" [
    --repo: string = ""
    --limit: int = 10
]: nothing -> table {
    mut cmd = [gh release list --limit $limit --json tagName,isLatest,createdAt,isPrerelease]
    if ($repo | is-not-empty) { $cmd = $cmd | append ["--repo" $repo] }
    ^...$cmd | from json
}
