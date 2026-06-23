{ config, lib, inputs, ... }:

{
  options = {
  };
  config = lib.mkIf true {
    systemd.services.latency-tracker = {
      environment.CONFIG_FILE = builtins.toFile "config.json" (builtins.toJSON [
        "10.0.0.1"
        "10.0.0.11"
        "10.0.0.112"
        "10.0.0.60"
        "10.0.0.61"
        #"10.6.0.1"
        "10.6.0.4"
        "10.6.0.5"
        "192.99.15.220"
        "192.168.2.1"
      ]);
      serviceConfig = {
        ExecStart = "${inputs.latency-tracker.packages.x86_64-linux.default}/bin/latency-tracker";
        Type = "notify";
        WatchdogSec = "120";
        Restart = "always";
        Nice = -15;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
