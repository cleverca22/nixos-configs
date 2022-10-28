{ pkgs, ... }:

let
  zfs-src = pkgs.fetchurl {
    url = "https://github.com/openzfs/zfs/archive/pull/14013/head.tar.gz";
    hash = "sha256-+ACYzJlKxUmdJnEe17wy7G8RFbxUPIQC2OaEjSOGhE4=";
  };
in {
  boot.kernelPackages = pkgs.linuxPackages.extend (self: super: {
    zfs = super.zfs.overrideAttrs (old: {
      src = zfs-src;
    });
  });
}
