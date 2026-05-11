# release init <repo> — bootstrap a new project into projects.toml.

source ../lib/config.nu
source ../lib/ui.nu

export def "release-init run" [name: string]: nothing -> nothing {
    if (config exists $name) {
        ui warn $"Project '($name)' already exists in projects.toml."
        return
    }

    let dir = config local-path $name
    if not ($dir | path exists) {
        ui error $"Directory not found: ($dir)"
        ui info $"Clone the repo first, or make sure it's at ~/dev/personal/($name)"
        return
    }

    cd $dir

    # Auto-detect language
    let lang = if ($dir | path join "Cargo.toml" | path exists) {
        "rust"
    } else if ($dir | path join "package.json" | path exists) {
        "typescript"
    } else if ($dir | path join "go.mod" | path exists) {
        "go"
    } else if ($dir | path join "build.zig.zon" | path exists) {
        "zig"
    } else {
        "shell"
    }

    # Detect workspace for Rust
    let proj_type = if $lang == "rust" {
        let content = open --raw ($dir | path join "Cargo.toml")
        if ($content | str contains "[workspace]") { "workspace" } else { "package" }
    } else {
        "package"
    }

    # Detect tag prefix from existing tags
    let tags = try { ^git tag --sort=-version:refname | lines } catch { [] }
    let tag_prefix = if ($tags | is-empty) {
        "v"
    } else {
        let latest = $tags | first
        if ($latest | str starts-with "v") { "v" } else { "" }
    }

    print ""
    ui header $"Auto-detected project: ($name)"
    print $"  Language:   ($lang)"
    print $"  Type:       ($proj_type)"
    print $"  Tag prefix: '($tag_prefix)'"
    print $"  Directory:  ($dir)"
    print ""

    if not (ui confirm "Add this project to projects.toml?") {
        return
    }

    let config_path = config root | path join "projects.toml"

    let toml_entry = if $proj_type == "workspace" {
        $"\n[projects.($name)]\nlang = \"($lang)\"\ntype = \"workspace\"\ntag_prefix = \"($tag_prefix)\"\n"
    } else {
        $"\n[projects.($name)]\nlang = \"($lang)\"\ntag_prefix = \"($tag_prefix)\"\n"
    }

    open --raw $config_path | append $toml_entry | save --force $config_path
    ui success $"Project '($name)' added to projects.toml"
}
