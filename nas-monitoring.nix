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
      enableACME = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      metrics = lib.mkOption {
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
      oauth = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable OAuth authication for all monitoring services.";
        };
        provider = lib.mkOption {
          type = lib.types.enum [ "google" "github" "azure" "gitlab" "linkedin" "myusa" ];
          default = "google";
        };
        emailDomain = lib.mkOption {
          type = lib.types.str;
          example = "iohk.io";
        };
        clientID = lib.mkOption {
          type = lib.types.str;
          example = "123456.apps.googleusercontent.com";
        };
        clientSecret = lib.mkOption {
          type = lib.types.str;
        };
        cookie.secret = lib.mkOption {
          type = lib.types.str;
        };
      };
    };
  };
  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.oauth.enable (let
      oauthProxyConfig = ''
        auth_request /oauth2/auth;
        error_page 401 = /oauth2/sign_in;

        # pass information via X-User and X-Email headers to backend,
        # requires running with --set-xauthrequest flag
        auth_request_set $user   $upstream_http_x_auth_request_user;
        auth_request_set $email  $upstream_http_x_auth_request_email;
        proxy_set_header X-User  $user;
        proxy_set_header X-Email $email;

        # if you enabled --cookie-refresh, this is needed for it to work with auth_request
        auth_request_set $auth_cookie $upstream_http_set_cookie;
        add_header Set-Cookie $auth_cookie;
      '';
    in {
      services = {
        oauth2_proxy = {
          enable = true;
          inherit (cfg.oauth) clientID clientSecret cookie provider;
          email.domains = [ cfg.oauth.emailDomain ];
          nginx.virtualHosts = [ cfg.webhost ];
          setXauthrequest = true;
        };
        nginx.virtualHosts."${cfg.webhost}".locations = {
          "/grafana/".extraConfig = oauthProxyConfig;
          "/prometheus/".extraConfig = oauthProxyConfig;
          "/alertmanager/".extraConfig = oauthProxyConfig;
          "/graylog/".extraConfig = oauthProxyConfig;
        };
      };
    }))
    {
      networking.firewall.allowedTCPPorts = [ 80 ];
      environment.systemPackages = with pkgs; [ goaccess ];
      services.prometheus2.scrapeConfigs = [
        {
          job_name = "node-test";
          scrape_interval = "10s";
          metrics_path = "/";
          static_configs = [
            {
              targets = [ "192.168.2.15:8000" ];
            }
          ];
        }
        {
          job_name = "jormungandr";
          scrape_interval = "10s";
          metrics_path = "/metrics";
          static_configs = [
            { targets = [ "192.168.2.1:8000" ]; }
          ];
        }
        {
          job_name = "jormungandr-sam";
          scrape_interval = "10s";
          metrics_path = "/sam-metrics";
          static_configs = [
            { targets = [ "192.168.2.15:80" ]; }
          ];
        }
        {
          job_name = "exporter";
          scrape_interval = "10s";
          metrics_path = "/";
          static_configs = [ { targets = [ "amd.localnet:8080" ]; } ];
        }
        {
          job_name = "cachecache";
          scrape_interval = "10s";
          metrics_path = "/";
          static_configs = [ { targets = [ "127.0.0.1:8080" ]; } ];
        }
      ];
      services.monitoring-services = {
        # enable = true;
        enableACME = false;
        metrics = true;
        oauth = {
          enable = true;
          emailDomain = "iohk.io";
          inherit (secrets.oauth) clientID clientSecret cookie;
        };
        webhost = "monitoring.earthtools.ca";
        monitoredNodes = {
          "router.localnet" = {
            hasNginx = true;
          };
          "nas" = {
            hasNginx = true;
          };
          "amd.localnet" = {};
        };
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
                  ${if cfg.metrics then ''
                    <span style=font-size:65%><a href=/grafana/ target=_blank class=cardano style="color: #ddc6f2">Grafana</a></span><br>
                    <span style=font-size:65%><a href=/prometheus/ target=_blank class=cardano style="color: #ddc6f2">Prometheus</a></span><br>
                  '' else ''
                    <span style=font-size:65%>Grafana (Disabled)</span><br>
                    <span style=font-size:65%>Prometheus (Disabled)</span><br>
                  ''}
                  ${if config.services.prometheus.alertmanager.enable then ''
                    <span style=font-size:65%><a href=/alertmanager/ target=_blank class=cardano style="color: #ddc6f2">Alertmanager</a></span><br>
                  '' else ''
                    <span style=font-size:65%>Alertmanager (Disabled)</span><br>
                  ''}
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
    (lib.mkIf cfg.enableACME {
      networking.firewall.allowedTCPPorts = [ 443 ];
      services.nginx.virtualHosts."${cfg.webhost}" = {
        enableACME = true;
        forceSSL = true;
      };
    })

    (lib.mkIf true {
      services.grafana.extraOptions = {
        # https://grafana.com/docs/auth/auth-proxy/
        AUTH_PROXY_ENABLED = "true";
        AUTH_PROXY_HEADER_NAME = "X-Email";
        AUTH_PROXY_HEADER_PROPERTY = "email";
        AUTH_PROXY_AUTO_SIGN_UP = "true";
        AUTH_PROXY_WHITELIST = "127.0.0.1, ::1"; # only trust nginx to claim usernames
      };
    })
    (lib.mkIf cfg.metrics {
      services = {
        nginx = {
          enable = true;
          virtualHosts."${cfg.webhost}".locations = {
            "/grafana/".extraConfig = ''
              proxy_pass http://localhost:3000/;
              proxy_set_header Host $host;
              proxy_set_header REMOTE_ADDR $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto https;
            '';
            "/prometheus/".extraConfig = ''
              proxy_pass http://localhost:9090/prometheus/;
              proxy_set_header Host $host;
              proxy_set_header REMOTE_ADDR $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto https;
            '';
            "/alertmanager/".extraConfig = ''
              proxy_pass http://localhost:9093/;
              proxy_set_header Host $host;
              proxy_set_header REMOTE_ADDR $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto https;
            '';
          };
        };
        grafana = {
          enable = true;
          users.allowSignUp = false;
          addr = "";
          domain = "${cfg.webhost}";
          rootUrl = "%(protocol)ss://%(domain)s/grafana/";
          extraOptions = lib.mkIf cfg.oauth.enable {
            AUTH_GOOGLE_ENABLED = "true";
            AUTH_GOOGLE_CLIENT_ID = cfg.oauth.clientID;
            AUTH_GOOGLE_CLIENT_SECRET = cfg.oauth.clientSecret;
          };
          provision = {
            enable = true;
            datasources = [
              {
                type = "prometheus";
                name = "prometheus";
                url = "http://localhost:9090/prometheus";
              }
            ];
            dashboards = [
              {
                name = "generic";
                options.path = ./grafana/generic;
              }
            ];
          };
          security = {
            adminUser = "admin";
            adminPassword = secrets.grafanaCreds.password;
          };
        };
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
        prometheus = {
          enable = true;
          webExternalUrl = "https://${cfg.webhost}/prometheus/";
          extraFlags = [
            "--storage.tsdb.retention=8760h"
          ];

          rules = [ (builtins.toJSON {
              groups = [
                {
                  name = "alerting-pipeline";
                  rules = [
                    {
                      alert = "DeadMansSnitch";
                      expr = "vector(1)";
                      labels = {
                        severity = "critical";
                      };
                      annotations = {
                        summary = "Alerting DeadMansSnitch.";
                        description = "This is a DeadMansSnitch meant to ensure that the entire Alerting pipeline is functional.";
                      };
                    }
                  ];
                }
                {
                  name = "system";
                  rules = [
                    {
                      alert = "node_down";
                      expr = "up == 0";
                      for = "5m";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: Node is down.";
                        description = "{{$labels.alias}} has been down for more than 5 minutes.";
                      };
                    }
                    {
                      alert = "node_systemd_service_failed";
                      expr = "node_systemd_unit_state{state=\"failed\"} == 1";
                      for = "4m";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: Service {{$labels.name}} failed to start.";
                        description = "{{$labels.alias}} failed to (re)start service {{$labels.name}}.";
                      };
                    }
                    {
                      alert = "node_filesystem_full_90percent";
                      expr = "sort(node_filesystem_free_bytes{device!=\"ramfs\"} < node_filesystem_size_bytes{device!=\"ramfs\"} * 0.1) / 1024^3";
                      for = "5m";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: Filesystem is running out of space soon.";
                        description = "{{$labels.alias}} device {{$labels.device}} on {{$labels.mountpoint}} got less than 10% space left on its filesystem.";
                      };
                    }
                    {
                      alert = "node_filesystem_full_in_4h";
                      expr = "predict_linear(node_filesystem_free_bytes{device!=\"ramfs\",device!=\"tmpfs\",fstype!=\"autofs\",fstype!=\"cd9660\"}[4h], 4*3600) <= 0";
                      for = "5m";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: Filesystem is running out of space in 4 hours.";
                        description = "{{$labels.alias}} device {{$labels.device}} on {{$labels.mountpoint}} is running out of space of in approx. 4 hours";
                      };
                    }
                    {
                      alert = "node_filedescriptors_full_in_3h";
                      expr = "predict_linear(node_filefd_allocated[1h], 3*3600) >= node_filefd_maximum";
                      for = "20m";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}} is running out of available file descriptors in 3 hours.";
                        description = "{{$labels.alias}} is running out of available file descriptors in approx. 3 hours";
                      };
                    }
                    {
                      alert = "node_load1_90percent";
                      expr = "node_load1 / on(alias) count(node_cpu_seconds_total{mode=\"system\",role!=\"mac-host\",role!=\"build-slave\"}) by (alias) >= 0.9";
                      for = "1h";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: Running on high load.";
                        description = "{{$labels.alias}} is running with > 90% total load for at least 1h.";
                      };
                    }
                    {
                      alert = "node_cpu_util_90percent";
                      expr = "100 - (avg by (alias) (irate(node_cpu_seconds_total{mode=\"idle\",role!=\"mac-host\",role!=\"build-slave\"}[5m])) * 100) >= 90";
                      for = "1h";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: High CPU utilization.";
                        description = "{{$labels.alias}} has total CPU utilization over 90% for at least 1h.";
                      };
                    }
                    {
                      alert = "node_ram_using_99percent";
                      expr = "node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes < node_memory_MemTotal_bytes * 0.01";
                      for = "30m";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: Using lots of RAM.";
                        description = "{{$labels.alias}} is using at least 90% of its RAM for at least 30 minutes now.";
                      };
                    }
                    {
                      alert = "node_swap_using_80percent";
                      expr = "node_memory_SwapTotal_bytes - (node_memory_SwapFree_bytes + node_memory_SwapCached_bytes) > node_memory_SwapTotal_bytes * 0.8";
                      for = "10m";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: Running out of swap soon.";
                        description = "{{$labels.alias}} is using 80% of its swap space for at least 10 minutes now.";
                      };
                    }
                    {
                      alert = "node_time_unsync";
                      expr = "abs(node_timex_offset_seconds) > 0.500 or node_timex_sync_status != 1";
                      for = "1m";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: Clock out of sync with NTP";
                        description = "{{$labels.alias}} Local clock offset is too large or out of sync with NTP";
                      };
                    }
                    {
                      alert = "http_high_internal_error_rate";
                      expr = "rate(nginx_vts_server_requests_total{code=\"5xx\"}[5m]) * 50 > on(alias, host) rate(nginx_vts_server_requests_total{code=\"2xx\"}[5m])";
                      for = "15m";
                      labels = {
                        severity = "page";
                      };
                      annotations = {
                        summary = "{{$labels.alias}}: High http internal error (code 5xx) rate";
                        description = "{{$labels.alias}}  number of correctly served requests is less than 50 times the number of requests aborted due to an internal server error";
                      };
                    }
                  ];
                }
              ];
            })];
          scrapeConfigs = [
            {
              job_name = "prometheus";
              scrape_interval = "5s";
              metrics_path = "/prometheus/metrics";
              static_configs = [
                {
                  targets = [
                    "localhost:9090"
                  ];
                  labels = { alias = "prometheus"; };
                }
              ];
            }
            {
              job_name = "node";
              scrape_interval = "10s";
              static_configs = let
                makeNodeConfig = key: value: {
                  targets = [ "${key}:9100" "${key}:9102" ];
                  labels = {
                    alias = key;
                  } // value.labels;
                };
              in lib.mapAttrsToList makeNodeConfig cfg.monitoredNodes;
            }
            {
              job_name = "nginx";
              scrape_interval = "5s";
              metrics_path = "/status/format/prometheus";
              static_configs = let
                makeNodeConfig = key: value: {
                  targets = [ "${key}:9113" ];
                  labels = {
                    alias = key;
                  } // value.labels;
                };
                onlyNginx = n: v: v.hasNginx;
              in lib.mapAttrsToList makeNodeConfig (lib.filterAttrs onlyNginx cfg.monitoredNodes);
            }
          ];
        };
      };
    })
  ]);
}
