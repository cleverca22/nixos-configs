{ pkgs, ... }:

let
  zfs-src = pkgs.fetchurl {
    url = "https://github.com/openzfs/zfs/archive/pull/14013/head.tar.gz";
    hash = "sha256-tGbk4m5G7jJjf3bSd01BZWq2PFnUwYDMKx17tQ23iSU=";
  };
in {
  boot.kernelPackages = pkgs.linuxPackages.extend (self: super: {
    zfs_2_3 = super.zfs_2_3.overrideAttrs (old: {
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
