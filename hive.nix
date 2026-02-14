{ nixpkgs, ... }@inputs:

{
  defaults = {
    documentation.enable = false;
  };
  meta = {
    nixpkgs = nixpkgs.legacyPackages.x86_64-linux;
    specialArgs = {
      inherit inputs;
    };
  };

  thin-router = ./thin-router.nix;
}
