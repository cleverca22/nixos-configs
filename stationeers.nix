{ pkgs, ... }:

{
  config = {
    networking.firewall.allowedUDPPorts = [ 27016 ];
    networking.firewall.allowedTCPPorts = [ 8000 ];
    systemd.services.stationeers = {
      #wantedBy = [ "multi-user.target" ];
      path = [ pkgs.steamcmd pkgs.steam-run ];
      serviceConfig = {
        User = "stationeers";
        WorkingDirectory = "/var/lib/stationeers";
        TimeoutStartSec = "5m";
      };
      preStart = ''
        steamcmd +force_install_dir /var/lib/stationeers +login anonymous +app_update 600760 -beta beta validate +quit
      '';
      script = ''
        steam-run /var/lib/stationeers/rocketstation_DedicatedServer.x86_64 -loadlatest 2022-mars mars -settings StartLocalHost true ServerPassword password ServerMaxPlayers 5 UPNPEnabled false SaveInterval 60 SunOrbitPeriod 2 AutoPauseServer false
      '';
    };
    users.users.stationeers = {
      isSystemUser = true;
      createHome = true;
      home = "/var/lib/stationeers";
      group = "stationeers";
    };
    users.groups.stationeers = {};
  };
}
