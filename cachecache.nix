{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cachecache;
  cachecacheSrc = pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "cachecache";
    rev = "37959a2dcce5c93bf424da899d3d5eaf2b3f1768";
    sha256 = "1d92agrsgs1g05ps3l7wbbib9knq86gq335k5kakzl9rlzdaj4z0";
  };
in {
  options = {
    services.cachecache.enable = mkEnableOption "enable cachecache";
  };
  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (super: self: {
        cachecache = pkgs.callPackage cachecacheSrc {};
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
