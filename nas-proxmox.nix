{ lib, inputs, ... }:

{
  imports = [
    inputs.proxmox-nixos.nixosModules.proxmox-ve
  ];
  environment.etc."network/interfaces".text = ''
    auto eth0
    iface eth0 inet static
      address 10.0.0.11/24
  '';
  nixpkgs.overlays = [inputs.proxmox-nixos.overlays.x86_64-linux];
  services = {
    openssh.settings.AcceptEnv = lib.mkForce [ "LANG" "LC_*" ];
    proxmox-ve = {
      enable = true;
      ipAddress = "10.0.0.11";
    };
  };
}
