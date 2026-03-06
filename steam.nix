{ pkgs, lib, ... }:

let
  overlay = self: super: {
    xdg-utils = pkgs.writeScriptBin "xdg-open" ''
      #!${pkgs.stdenv.shell}
      echo -n "xdg-open \"$1\"" > $HOME/steam.log
    '';
  };
  pkgs_steam = pkgs.extend overlay;
  always = {
    environment.systemPackages = [
      pkgs_steam.steam pkgs.steamcmd pkgs.steam-run
      pkgs_steam.lutris-free
      pkgs.opencomposite
    ];
    fileSystems."/home/clever/.local/share/Steam/userdata/8297027/gamerecordings" = { device = "amd/nosnap"; fsType = "zfs"; };
    hardware.graphics.enable32Bit = true;
    nixpkgs.overlays = [ overlay ];

    services = {
      monado = {
        defaultRuntime = true;
        enable = true;
        highPriority = true;
      };
      pulseaudio.support32Bit = true;
    };

    systemd.user.services.monado.environment = {
      STEAMVR_LH_ENABLE = "0";
      XRT_COMPOSITOR_COMPUTE = "1";
      U_PACING_COMP_MIN_TIME_MS = "5";
      GALLIUM_HUD = "cpu,fps,frametime;draw-calls";
    };
  };
  recording = {
    services.nginx = {
      enable = true;
      virtualHosts."amd" = {
        locations."/recordings/" = {
          alias = "/home/clever/.local/share/Steam/userdata/8297027/gamerecordings/";
          extraConfig = ''
            autoindex on;
          '';
        };
      };
    };
    systemd.services.nginx.serviceConfig.ProtectHome = false;
  };
in
{
  config = lib.mkMerge [
    always
    (lib.mkIf true recording)
  ];
}
