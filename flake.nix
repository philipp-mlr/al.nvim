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
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      perSystem = {pkgs, ...}: {
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
      };
    };
}
