{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cachecache;
  cachecacheSrc = pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "cachecache";
    rev = "09e6d02cd4cf9b9554df92e0be9552686dd1827d";
    sha256 = "1ldyz5m72agdkwybdiclp701s8fyla5kdnqgwma4jzbb2ln3n17p";
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
