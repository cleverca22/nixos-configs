{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cachecache;
  cachecacheSrc = pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "cachecache";
    rev = "bc47c1ba7f81277d539f9c81bb0dbee6ad58b01f";
    sha256 = "1rmzrr7ffb4i03qgd7rqkqfblxdr97ji5jcqxyrvldqwxpba0l42";
  };
in {
  options = {
    services.cachecache.enable = mkEnableOption "enable cachecache";
  };
  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (super: self: {
        cachecache = import cachecacheSrc;
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
