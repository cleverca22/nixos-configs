{ ... }:

{
  imports = [ ./clevers_machines.nix ./snmpd.nix ];
  boot.loader.grub = {
    device = "/dev/sda";
    copyKernels = true;
  };
  swapDevices = [ { device = "/dev/sda2"; } ];
  programs = {
    man.enable = false;
    info.enable = false;
  };
  nixpkgs.system = "i686-linux";
  networking = {
    wireless = {
      enable = true;
      interfaces = [ "wlp1s0" ];
    };
    firewall = {
      allowedUDPPorts = [ 33445 ];
    };
  };
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  services = {
    nixosManual.enable = false;
    toxvpn = {
      enable = true;
    };
  };
}
