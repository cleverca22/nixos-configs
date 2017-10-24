{ pkgs, ... }:
let
  netboot = import (pkgs.path + "/nixos/lib/eval-config.nix") {
      modules = [
        (pkgs.path + "/nixos/modules/installer/netboot/netboot-minimal.nix")
        module
      ];
    };
    module = {
      # you will want to add options here to support your filesystem
      # and also maybe ssh to let you in
      boot.supportedFilesystems = [ "zfs" ];
    };
in {
  boot.loader.grub.extraEntries = ''
    menuentry "Nixos Installer" {
      linux ($drive1)/rescue-kernel init=${netboot.config.system.build.toplevel}/init ${toString netboot.config.boot.kernelParams}
      initrd ($drive1)/rescue-initrd
    }
  '';
  boot.loader.grub.extraFiles = {
    "rescue-kernel" = "${netboot.config.system.build.kernel}/bzImage";
    "rescue-initrd" = "${netboot.config.system.build.netbootRamdisk}/initrd";
  };
}
