{ pkgs, lib, ... }:

{
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
        #"systemd"
        "conntrack"
        "diskstats"
        "entropy"
        "filefd"
        "filesystem"
        "interrupts"
        "ksmd"
        "loadavg"
        "logind"
        "meminfo"
        "netdev"
        "netstat"
        "ntp"
        "stat"
        #"systemd"
        "tcpstat"
        "time"
        "timex"
        "vmstat"
        "wifi"
        #"processes"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [ 9113 9100 9102 ];
  systemd.services."statd-exporter" = {
    wantedBy = [ "multi-user.target" ];
    requires = [ "network.target" ];
    after = [ "network.target" ];
    script = ''
      exec ${pkgs.prometheus-statsd-exporter}/bin/statsd_bridge -statsd.listen-address ":8125" -web.listen-address ":9102" -statsd.add-suffix=false || ${pkgs.prometheus-statsd-exporter}/bin/statsd_exporter --statsd.listen-udp=":8125" --web.listen-address=":9102"
    '';
  };
}
