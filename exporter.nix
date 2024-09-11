{ pkgs, lib, ... }:

let
  buildGoModule = attrs: pkgs.buildGoModule (attrs // {
    src = pkgs.fetchFromGitHub {
      owner = "cleverca22";
      repo = "node_exporter";
      rev = "226ba290fafac9bad4d855dab53d3f8a35a45963";
      sha256 = "sha256-j4l6ZN8ARIj8g9rcHEov6McbRXZ5vUhLkKrT/ly0iQE=";
    };
    vendorHash = "sha256-YvCYjaF6Jgkjxh80EIzxzkMjM9380/eAl1BnRBYmVsU=";
  });
in {
  nixpkgs.overlays = [
    (self: super: {
      prometheus-node-exporter = super.prometheus-node-exporter.override { inherit buildGoModule; };
    })
  ];
  services = {
    nginx = {
      appendHttpConfig = lib.mkIf false ''
        vhost_traffic_status_zone;
        server {
          listen 9113;
          location /status {
            vhost_traffic_status_display;
            vhost_traffic_status_display_format html;
          }
        }
      '';
    };
    prometheus.exporters.node = {
      enable = true;
      enabledCollectors = lib.mkForce [
        "cgroups"
        "conntrack"
        "diskstats"
        "entropy"
        "filefd"
        "filesystem"
        "interrupts"
        "loadavg"
        "meminfo"
        "netdev"
        "netstat"
        "ntp"
        "stat"
        "systemd"
        "systemd.network-metrics"
        "tcpstat"
        "time"
        "timex"
        "vmstat"
        "wifi"
        #"ksmd"
        #"logind"
        #"processes"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [ 9113 9100 9102 ];
  systemd.services = {
    "statd-exporter" = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "network.target" ];
      after = [ "network.target" ];
      script = ''
        exec ${pkgs.prometheus-statsd-exporter}/bin/statsd_bridge -statsd.listen-address ":8125" -web.listen-address ":9102" -statsd.add-suffix=false || ${pkgs.prometheus-statsd-exporter}/bin/statsd_exporter --statsd.listen-udp=":8125" --web.listen-address=":9102"
      '';
    };
    "prometheus-node-exporter" = {
      serviceConfig.ProtectHome = lib.mkForce false;
    };
  };
}
