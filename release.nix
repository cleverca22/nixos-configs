let
  nixosFunc = import <nixpkgs/nixos>;
in {
  nas = (nixosFunc { configuration = ./nas.nix; }).system;
  router = (nixosFunc { configuration = ./router.nix; }).system;
}
