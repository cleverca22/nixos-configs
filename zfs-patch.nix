{ pkgs, ... }:

let
  zfs-src = pkgs.fetchurl {
    url = "https://github.com/openzfs/zfs/archive/pull/14013/head.tar.gz";
    hash = "sha256-3rFAMoEjnB+cHLHsLZMGFCzr2yY/63nAj9RpRO1FueQ=";
  };
in {
  boot.kernelPackages = pkgs.linuxPackages_5_15.extend (self: super: {
    zfs = super.zfs.overrideAttrs (old: {
      src = zfs-src;
    });
  });
}
