{ lib, inputs, ... }:

{
  imports = [
    inputs.proxmox-nixos.nixosModules.proxmox-ve
  ];
  environment.etc."network/interfaces".text = ''
    auto wlp0s20f3
    iface wlp0s20f3 inet static
      address 10.0.0.112/24
  '';
  nixpkgs.overlays = [inputs.proxmox-nixos.overlays.x86_64-linux];
  services = {
    openssh.settings.AcceptEnv = lib.mkForce [ "LANG" "LC_*" ];
    proxmox-ve = {
      enable = true;
      ipAddress = "10.0.0.112";
    };
  };
}
