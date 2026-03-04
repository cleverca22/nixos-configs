{ inputs, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cachecache;
in {
  options = {
    services.cachecache.enable = mkEnableOption "enable cachecache";
  };
  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (super: self: {
        cachecache = inputs.cachecache.packages.x86_64-linux.cachecache;
      })
    ];
    users.users.cachecache = {
      home = "/var/lib/cachecache";
      isSystemUser = true;
      createHome = true;
      group = "cachecache";
    };
    users.groups.cachecache = {};
    systemd.services.cachecache = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.cachecache ];
      script = ''
        exec cachecache
      '';
      serviceConfig = {
        User = "cachecache";
        WorkingDirectory = config.users.users.cachecache.home;
      };
    };
  };
}
