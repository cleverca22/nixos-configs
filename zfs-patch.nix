{ pkgs, ... }:

let
  zfs-src = pkgs.fetchurl {
    url = "https://github.com/openzfs/zfs/archive/pull/14013/head.tar.gz";
    hash = "sha256-ShMrMFVkkuxLM7xdJkcFuaRh7fZ2BNgVNFYn6WzvUgU=";
  };
in {
  boot.kernelPackages = pkgs.linuxPackages.extend (self: super: {
    zfs_2_4 = super.zfs_2_4.overrideAttrs (old: {
      src = zfs-src;
    });
  });
  nixpkgs.overlays = [
    (self: super: {
      zfs = super.zfs_2_4.overrideAttrs (old: {
        src = zfs-src;
        prePatch = ''
          mkdir -pv lib/libshare/os/linux
          ln -sv ../../../libzfs/os/linux/libzfs_share_nfs.c lib/libshare/os/linux/nfs.c
          ln -sv ../libzfs/libzfs_share.h lib/libshare/smb.h
        '';
      });
    })
  ];
}
