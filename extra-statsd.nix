{ pkgs, lib, config, ... }:

with lib;
let
  extra-statsd = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "extra-statsd";
    rev = "ac0ec9fa4a86f6bae304104dfe2c9e2c91704ddd";
    sha256 = "1ls1f9xqrrj4q07x1qmqbirnx96kz7f22bcfnfakr1gflrg0alsh";
  }) {};
in {
  options = {
    services.extra-statsd = mkEnableOption "extra-statsd";
  };
  config = mkIf config.services.extra-statsd {
    systemd.services.extra-statsd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "dd-agent.service" ];
      script = ''
        sleep 30
        exec ${extra-statsd.static}/bin/extra-statsd
      '';
    };
  };
}
