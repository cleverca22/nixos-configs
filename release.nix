let
  nixosFunc = import <nixpkgs/nixos>;
  linuxPkgs = import <nixpkgs> {};
in {
  nas = (nixosFunc { configuration = ./nas.nix; }).system;
  router = (nixosFunc { configuration = ./router.nix; }).system;
  nix-tar.arm = linuxPkgs.callPackage ./arm-tar.nix {};
  software = { # things used by several machines
    inherit (linuxPkgs) plex-media-player;
  };
}
