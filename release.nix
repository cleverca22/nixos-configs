let
  nixosFunc = import <nixpkgs/nixos>;
  linuxPkgs = import <nixpkgs> {};
  sources = import ./nix/sources.nix;
in {
  nas = (nixosFunc { configuration = ./nas.nix; }).system;
  router = (nixosFunc { configuration = ./router.nix; }).system;
  system76 = (nixosFunc { configuration = ./system76.nix; }).system;
  nix-tar.arm = linuxPkgs.callPackage ./arm-tar.nix {};
  software = { # things used by several machines
    inherit (linuxPkgs) plex-media-player rtorrent;
    #arcstats = linuxPkgs.callPackage sources.arcstats {};
  };
}
