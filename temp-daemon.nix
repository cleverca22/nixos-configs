{ config, lib, inputs, pkgs, ... }:

let
  cfg = config.services.temp-daemon;
in {
  options = {
    services.temp-daemon = {
      enable = lib.mkEnableOption "enable temp-daemon";
      port = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
  config = {
    age.secrets = {
      temp-daemon = {
        file = ./secrets/temp-daemon.age;
        owner = "temp-daemon";
      };
    };
    systemd.services.temp-daemon = {
      preStart = ''
        stty < ${cfg.port} raw -echo 9600
        chown temp-daemon ${cfg.port}
      '';
      serviceConfig = {
        ExecStart = "${inputs.temp-daemon.packages.x86_64-linux.default}/bin/temp_daemon ${cfg.port}";
        PermissionsStartOnly = true;
        User = "temp-daemon";
        WorkingDirectory = "/var/lib/temp-daemon";
        EnvironmentFile = config.age.secrets.temp-daemon.path;
      };
      wantedBy = [ "multi-user.target" ];
    };
    users.users.temp-daemon = {
      createHome = true;
      group = "temp-daemon";
      home = "/var/lib/temp-daemon";
      isSystemUser = true;
    };
    users.groups.temp-daemon = {};
  };
}
