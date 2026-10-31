{ lib, inputs, ... }:

{
  imports = [
    inputs.proxmox-nixos.nixosModules.proxmox-ve
  ];
  environment.etc."network/interfaces".text = ''
    auto br0
    iface br0 inet static
      address 10.0.0.15/24

    auto wg0
    iface wg0 inet static
      address 10.6.0.2/16
  '';
  nixpkgs.overlays = [
    inputs.proxmox-nixos.overlays.x86_64-linux
    (self: super: {
      pve-manager = super.pve-manager.override { busybox = self.coreutils; };
    })
  ];
  services = {
    openssh.settings.AcceptEnv = lib.mkForce [ "LANG" "LC_*" ];
    proxmox-ve = {
      enable = true;
      ipAddress = "10.0.0.15";
      bridges = [ "br0" ];
    };
  };
  systemd = {
    services = {
      pvedaemon = {
        path = [ inputs.proxmox-nixos.packages.x86_64-linux.pve-storage ];
      };
    };
  };
}
