{ pkgs, lib, config, ... }:

with lib;
let
  arcstats = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "arcstats";
    rev = "0f84957053bbbd62b753189b779767c5fd863e98";
    sha256 = "1126685cjskf65jwd2jddr7wiknr9nw9afm4ajrf6ss292yicwsb";
  }) {};
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
