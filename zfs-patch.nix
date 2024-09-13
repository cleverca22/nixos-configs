{ pkgs, ... }:

let
  zfs-src = pkgs.fetchurl {
    url = "https://github.com/openzfs/zfs/archive/pull/14013/head.tar.gz";
    hash = "sha256-C+1fxxLSKLh0pOY/f7BguYlfbsyxiyKuk2lAkJMkFfE=";
  };
in {
  boot.kernelPackages = pkgs.linuxPackages_5_15.extend (self: super: {
    zfs_2_2 = super.zfs_2_2.overrideAttrs (old: {
      src = zfs-src;
    });
  });
  nixpkgs.overlays = [
    (self: super: {
      zfs = super.zfs.overrideAttrs (old: {
        src = zfs-src;
      });
    })
  ];
}
