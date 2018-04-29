{ pkgs, ... }:

let
  arcstats = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "arcstats";
    rev = "0f84957053bbbd62b753189b779767c5fd863e98";
    sha256 = "1126685cjskf65jwd2jddr7wiknr9nw9afm4ajrf6ss292yicwsb";
  }) {};
in {
  systemd.services.arcstats = {
    description = "net-snmp daemon";
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${arcstats}/bin/arcstats
    '';
    serviceConfig = {
      After = [ "dd-agent.service" ];
    };
  };
}
