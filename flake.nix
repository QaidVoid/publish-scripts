{
  description = "Unified release scripts for GitHub projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      runtimeDeps = with pkgs; [
        git-cliff
        github-cli
        jq
        git
        gnused
      ];

    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nushell
        ] ++ runtimeDeps;

        shellHook = ''
          echo "publish-scripts dev shell"
          echo "Run: release status"
        '';
      };

      packages.${system}.default = pkgs.runCommandLocal "publish-scripts" {
        src = self;
      } ''
        mkdir -p $out/bin
        cat > $out/bin/release << 'WRAPPER'
        #!/usr/bin/env bash
        set -euo pipefail
        export PATH="${pkgs.lib.makeBinPath (with pkgs; [ nushell ] ++ runtimeDeps)}:$PATH"
        exec nu "${self}/nu/release.nu" "$@"
        WRAPPER
        chmod +x $out/bin/release
      '';
    };
}
