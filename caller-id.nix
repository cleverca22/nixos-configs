{ pkgs, ... }:

let
  callerid = pkgs.runCommandCC "callerid" { buildInputs = [ pkgs.mosquitto ]; } ''
    mkdir -pv $out/bin/
    gcc ${./caller-id.c} -o $out/bin/caller-id -Wall -lmosquitto
  '';
in {
  config = {
    systemd.services.caller-id = {
      environment.PW = "hunter2";
      serviceConfig = {
        ExecStart = "${callerid}/bin/caller-id -s nas.localnet -u callerid -p PW -m /dev/ttyS0";
        Restart = "always";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
