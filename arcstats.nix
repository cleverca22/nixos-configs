{ pkgs, lib, config, ... }:

with lib;
let
  sources = import ./nix/sources.nix;
  arcstats = pkgs.callPackage sources.arcstats {};
in {
  options = {
    services.arcstats = mkEnableOption "arcstats";
  };
  config = mkIf config.services.arcstats {
    systemd.services.arcstats = {
      description = "arcstats daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "dd-agent.service" ];
      serviceConfig.ExecStart = "${arcstats}/bin/arcstats";
    };
  };
}
