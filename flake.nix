{
  description = "AL.nvim - Neovim plugin for AL language support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = import nixpkgs {system = builtins.currentSystem;};
  in {
    packages.al-nvim = pkgs.vimUtils.buildVimPlugin {
      pname = "al-nvim";
      version = "unstable";
      src = ./.;
      dependencies = with pkgs.vimPlugins; [
        nui-nvim
        nvim-dap
        nvim-nio
        nvim-dap-virtual-text
      ];
      meta = with pkgs.lib; {
        description = "A Neovim plugin for AL language support in Microsoft Dynamics 365 Business Central development.";
        homepage = "https://github.com/philipp-mlr/al.nvim";
        license = licenses.mit;
        maintainers = with maintainers; [abonckus];
      };
    };

    defaultPackage = self.packages.al-nvim;
  };
}
