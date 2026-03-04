{ pkgs, ... }:

let
  rtorrent-exporter = pkgs.callPackage ./rtorrent_exporter.nix {};
  addr = "0.0.0.0";
  port = 9135;
  timeout = "10s";
in {
  systemd = {
    services = {
      rtorrent-exporter = {
        serviceConfig = {
          ExecStart = "${rtorrent-exporter}/bin/rtorrent-exporter --logtostderr=true --rtorrent.addr http://nas.localnet/RPC2 --telemetry.addr ${addr}:${toString port} --telemetry.timeout ${timeout} --config /tmp/rtorrent-exporter.yaml";
          Restart = "always";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}
