{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cachecache;
  sources = import ./nix/sources.nix;
in {
  options = {
    services.cachecache.enable = mkEnableOption "enable cachecache";
  };
  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (super: self: {
        cachecache = pkgs.callPackage sources.cachecache {};
      })
    ];
    users.users.cachecache = {
      home = "/var/lib/cachecache";
      isSystemUser = true;
      createHome = true;
    };
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
