{ config, ... }:

{
  networking.firewall.allowedUDPPorts = [
    config.services.toxvpn.port
  ];
  nixpkgs.overlays = [
    (self: super: {
      toxvpn = super.toxvpn // { meta.mainProgram = "toxvpn"; };
    })
  ];
}
