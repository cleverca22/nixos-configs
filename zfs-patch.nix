{ pkgs, ... }:

let
  zfs-src = pkgs.fetchurl {
    url = "https://github.com/openzfs/zfs/archive/pull/14013/head.tar.gz";
    hash = "sha256-EjbvAxjlMIw4W2kgHdYa9P+OMFm2b05C7iMAJoa5AAM=";
  };
in {
  boot.kernelPackages = pkgs.linuxPackages.extend (self: super: {
    zfs_2_4 = super.zfs_2_4.overrideAttrs (old: {
      src = zfs-src;
    });
    zfs_unstable = super.zfs_unstable.overrideAttrs (old: {
      src = zfs-src;
      postPatch = ''
        sed -i 's/7.1/7.0/' META
      '';
    });
  });
  boot.zfs.forceImportRoot = false;
  boot.zfs.package = pkgs.zfs_unstable;
  nixpkgs.overlays = [
    (self: super: {
      zfs_2_4 = super.zfs_2_4.overrideAttrs (old: {
        src = zfs-src;
        prePatch = ''
          mkdir -pv lib/libshare/os/linux
          ln -sv ../../../libzfs/os/linux/libzfs_share_nfs.c lib/libshare/os/linux/nfs.c
          ln -sv ../libzfs/libzfs_share.h lib/libshare/smb.h
          sed -i 's/7.1/7.0/' META
        '';
      });
      zfs_unstable = super.zfs_unstable.overrideAttrs (old: {
        src = zfs-src;
        prePatch = ''
          mkdir -pv lib/libshare/os/linux
          ln -sv ../../../libzfs/os/linux/libzfs_share_nfs.c lib/libshare/os/linux/nfs.c
          ln -sv ../libzfs/libzfs_share.h lib/libshare/smb.h
          sed -i 's/7.1/7.0/' META
        '';
      });
    })
  ];
}
