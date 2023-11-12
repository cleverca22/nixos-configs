{ config, pkgs, lib, ... }:

let
  secrets = import ./load-secrets.nix;
  sources = import ./nix/sources.nix;
  iohk-ops = sources.iohk-ops;
  cfg = config.services.monitoring-services;
  monitoredNodeOptions = { name, config, ... }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
      };
      labels = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Labels to add in prometheus";
      };
      hasNginx = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "if nginx stats should be scraped";
      };
    };
    config = {
      name = lib.mkDefault name;
    };
  };
in {
  options = {
    services.monitoring-services = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      monitoredNodes = lib.mkOption {
        type = lib.types.loaOf (lib.types.submodule monitoredNodeOptions);
        default = {};
        description = ''
          Attribute set of Nodes to be monitored.
        '';
        example = {
          c-a-1 = {
            hasNginx = false;
            labels.role = "core";
          };
        };
      };
      webhost = lib.mkOption {
        type = lib.types.str;
        example = "monitoring.lan";
      };
    };
  };
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      #environment.systemPackages = with pkgs; [ goaccess ];
      services.prometheus.scrapeConfigs = [
        #{
        #  job_name = "node-test";
        #  scrape_interval = "10s";
        #  metrics_path = "/";
        #  static_configs = [
        #    {
        #      targets = [ "192.168.2.15:8000" ];
        #    }
        #  ];
        #}
        #{
        #  job_name = "jormungandr";
        #  scrape_interval = "10s";
        #  metrics_path = "/metrics";
        #  static_configs = [
        #    { targets = [ "192.168.2.1:8000" ]; }
        #  ];
        #}
        #{
        #  job_name = "exporter";
        #  scrape_interval = "10s";
        #  metrics_path = "/";
        #  static_configs = [ { targets = [ "amd.localnet:8080" ]; } ];
        #}
      ];
      services.monitoring-services = {
        # enable = true;
        webhost = "monitoring.earthtools.ca";
      };
      services.nginx = {
        enable = true;
        commonHttpConfig = ''
          log_format x-fwd '$remote_addr - $remote_user [$time_local] ' '"$request" $status $body_bytes_sent ' '"$http_referer" "$http_user_agent" "$http_x_forwarded_for"';
          access_log syslog:server=unix:/dev/log x-fwd;
        '';
        virtualHosts = {
          "${cfg.webhost}" = {
            locations = {
              "/" = let
                monitoringHtml = ''
                   Monitoring<br>
                  <span style=font-size:65%><a href=/grafana/ target=_blank class=cardano style="color: #ddc6f2">Grafana</a></span><br>
                  <span style=font-size:65%><a href=/prometheus/ target=_blank class=cardano style="color: #ddc6f2">Prometheus</a></span><br>
                '';
                indexFile = pkgs.substituteAll {
                    src = ./nginx/monitoring-index-template.html;
                    inherit monitoringHtml;
                  };
                rootDir = pkgs.runCommand "nginx-root-dir" {} ''
                  mkdir $out
                  cd $out
                  cp -v ${indexFile} index.html
                '';
              in {
                extraConfig = ''
                  etag off;
                  add_header etag "\"${builtins.substring 11 32 rootDir}\"";
                  root ${rootDir};
                '';
              };
            };
          };
        };
      };
    }
    (lib.mkIf true {
      services = {
        #grafana.extraOptions = {
          #AUTH_GOOGLE_ENABLED = "true";
          #AUTH_GOOGLE_CLIENT_ID = cfg.oauth.clientID;
          #AUTH_GOOGLE_CLIENT_SECRET = cfg.oauth.clientSecret;
        #};
        prometheus.exporters = {
          blackbox = {
            enable = true;
            configFile = pkgs.writeText "blackbox-exporter.yaml" (builtins.toJSON {
              modules = {
                https_2xx = {
                  prober = "http";
                  timeout = "5s";
                  http = {
                    fail_if_not_ssl = true;
                  };
                };
                htts_2xx = {
                  prober = "http";
                  timeout = "5s";
                };
                ssh_banner = {
                  prober = "tcp";
                  timeout = "10s";
                  tcp = {
                    query_response = [ { expect = "^SSH-2.0-"; } ];
                  };
                };
                tcp_v4 = {
                  prober = "tcp";
                  timeout = "5s";
                  tcp = {
                    preferred_ip_protocol = "ip4";
                  };
                };
                tcp_v6 = {
                  prober = "tcp";
                  timeout = "5s";
                  tcp = {
                    preferred_ip_protocol = "ip6";
                  };
                };
                icmp_v4 = {
                  prober = "icmp";
                  timeout = "60s";
                  icmp = {
                    preferred_ip_protocol = "ip4";
                  };
                };
                icmp_v6 = {
                  prober = "icmp";
                  timeout = "5s";
                  icmp = {
                    preferred_ip_protocol = "ip6";
                  };
                };
              };
            });
          };
        };
        prometheus.alertmanager = {
          enable = false;
          configuration = {
            route = {
              group_by = [ "alertname" "alias" ];
              group_wait = "30s";
              group_interval = "2m";
              receiver = "team-pager";
              routes = cfg.alertmanager.extraRoutes ++ [
                {
                  match = {
                    severity = "page";
                  };
                  receiver = "team-pager";
                }
              ] ++ (if (cfg.deadMansSnitch.pingUrl != null) then [{
                  match = {
                    alertname = "DeadMansSnitch";
                  };
                  repeat_interval = "5m";
                  receiver = "deadmanssnitch";
                }] else []);
            };
            receivers = cfg.alertmanager.extraReceivers ++ [
              {
                name = "team-pager";
                pagerduty_configs = [
                  {
                    service_key = cfg.pagerDuty.serviceKey;
                  }
                ];
              }
              ] ++ (if (cfg.deadMansSnitch.pingUrl != null) then [
              {
                name = "deadmanssnitch";
                webhook_configs = [{
                  send_resolved = false;
                  url = cfg.deadMansSnitch.pingUrl;
                }];
              }
            ] else []);
          };
        };
      };
    })
  ]);
}
