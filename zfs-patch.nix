{ pkgs, lib, ... }:

let
  zfs-src = pkgs.fetchurl {
    url = "https://github.com/openzfs/zfs/archive/pull/14013/head.tar.gz";
    hash = "sha256-fYoXz/Ex4AXBQ5vQY32Va7Mg7kmObHCui1KDyhYVCa4=";
  };
in {
  boot.kernelPackages = pkgs.linuxPackages.extend (self: super: {
    zfs_unstable = (self.callPackage "${pkgs.path}/pkgs/os-specific/linux/zfs/generic.nix" {
      kernel = self.kernel;
      configFile = "kernel";
    } {
      kernelModuleAttribute = "zfs_unstable";
      kernelMinSupportedMajorMinor = "4.18";
      kernelMaxSupportedMajorMinor = "7.1";
      tests = {};
      hash = lib.fakeHash;
      version = "2.4.4";
    }).overrideAttrs (old: {
      src = zfs-src;
      postPatch = ":";
    });
  });
  boot.zfs.forceImportRoot = false;
  boot.zfs.package = pkgs.zfs_unstable;
  nixpkgs.overlays = [
    (self: super: {
      zfs_unstable = (self.callPackage "${self.path}/pkgs/os-specific/linux/zfs/generic.nix" {
        configFile = "user";
      } {
        kernelModuleAttribute = "zfs_unstable";
        kernelMinSupportedMajorMinor = "4.18";
        kernelMaxSupportedMajorMinor = "7.1";
        tests = {};
        hash = lib.fakeHash;
        version = "2.4.4";
      }).overrideAttrs (old: {
        src = zfs-src;
        postPatch = ''
          patchShebangs --build scripts
          substituteInPlace ./contrib/initramfs/Makefile.am --replace-fail "/usr/share/initramfs-tools" "$out/usr/share/initramfs-tools"
          substituteInPlace ./config/user-systemd.m4    --replace-fail "/usr/lib/modules-load.d" "$out/etc/modules-load.d"
          substituteInPlace ./config/zfs-build.m4       --replace-fail "\$sysconfdir/init.d"     "$out/etc/init.d" --replace-fail "/etc/default"            "$out/etc/default"
          substituteInPlace ./config/zfs-build.m4       --replace-fail "bashcompletiondir=/etc/bash_completion.d" "bashcompletiondir=$out/share/bash-completion/completions"
        '';
      });
    })
  ];
}
