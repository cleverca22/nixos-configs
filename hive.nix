{ nixpkgs, ... }:

{
  defaults = {
    documentation.enable = false;
    _module.args.inputs = (builtins.getFlake (toString ../.)).inputs;
  };
  meta = {
    nixpkgs = nixpkgs.legacyPackages.x86_64-linux;
  };

  thin-router = ./thin-router.nix;
}
