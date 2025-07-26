{
  description = "AL.nvim - Neovim plugin for AL language support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" "x86_64-windows" "aarch64-windows"];

      perSystem = {
        pkgs,
        system,
        ...
      }: let
        platform =
          if system == "x86_64-linux" || system == "aarch64-linux"
          then "linux"
          else if system == "x86_64-darwin" || system == "aarch64-darwin"
          then "darwin"
          else if system == "x86_64-windows" || system == "aarch64-windows"
          then "win32"
          else throw "Unsupported system: ${system}";
      in {
        packages.default = pkgs.vimUtils.buildVimPlugin {
          pname = "al-nvim";
          version = "unstable";
          src = self;
          dependencies = with pkgs.vimPlugins; [
            nui-nvim
            nvim-dap
            nvim-nio
            nvim-dap-virtual-text
            noice-nvim
          ];
          nvimSkipModule = [
            "al.luasnippets.al.trigger"
            "al.luasnippets.al.procedure"
            "al.luasnippets.al.report-column"
            "al.luasnippets.al.report"
            "al.luasnippets.al.report-dataitem"
            "al.luasnippets.al.report-layout"
            "al.debugger"
          ];
        };

        packages.al-vscode = pkgs.buildFHSEnv {
          name = "al-vscode";
          version = "unstable";
          src = self;
          targetPkgs = pkgs:
            with pkgs; [
              glibc
              zlib
              libuuid
              icu
              curl
              openssl
              libkrb5
            ];

          runScript = ''
            #!/usr/bin/env bash
            set -euo pipefail

            EXT_BASE="$HOME/.vscode/extensions"
            LINK_DIR="$HOME/.al-vscode"
            SYMLINK="$LINK_DIR/al-language-server"

            EXT_DIR=$(find "$EXT_BASE" -maxdepth 1 -type d -name 'ms-dynamics-smb.al-*' | sort | tail -n1)

            if [ -z "$EXT_DIR" ]; then
              echo "❌ No AL extension found in $EXT_BASE" >&2
              exit 1
            fi

            # Make sure ~/.al-vscode exists
            mkdir -p "$LINK_DIR"

            # Symlink if not already there or points to the wrong place
            if [ ! -e "$SYMLINK" ] || [ "$(readlink "$SYMLINK")" != "$EXT_DIR/bin/${platform}" ]; then
              ln -sf "$EXT_DIR/bin/${platform}" "$SYMLINK"
            fi

            HOST_BINARY="$SYMLINK/Microsoft.Dynamics.Nav.EditorServices.Host"

            if [ ! -x "$HOST_BINARY" ]; then
              echo "❌ AL Language Server binary not found or not executable: $HOST_BINARY" >&2
              exit 1
            fi

            echo "▶️ Running AL Language Server via symlink: $HOST_BINARY"
            exec "$HOST_BINARY" "$@"
          '';
        };
      };
    };
}
