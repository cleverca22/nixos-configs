{
  pi2 = {
    nixpkgs.system = "armv7l-linux";
    fileSystems."/" = {
      device = "/dev/sda";
      fsType = "ext4";
    };
    boot.loader.grub.enable = false;
  };
}
