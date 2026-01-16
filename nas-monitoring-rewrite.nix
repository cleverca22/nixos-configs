{ config, lib, ... }:

let
  oauthProxyConfig = ''
    auth_request /oauth2/auth;
    error_page 401 = /oauth2/sign_in?rd=$request_uri;

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
  webhost = "monitoring.earthtools.ca";
  monitoredNodes = {
    "router" = {
      hasNginx = true;
    };
    "nas" = {
      hasNginx = true;
      hasZfs = true;
    };
    "amd" = {
      hasZfs = true;
    };
    c2d = {
    };
    #"nixbox360" = {
    #};
    #"pi0" = {};
    #"pi1a" = {};
    #"pi3" = {};
    #"pi4" = {};
    #"pi4w" = {};
    #"pi5w" = {};
    "pi5e" = { pi5_voltage = true; };
    #"pi400e" = {};
    #system76 = {
    #  hasZfs = true;
    #};
    thinkpad = {
      hasZfs = true;
    };
    shitzen-nixos = {
    };
    #pi500e = {
    #};
    "mail.fuckk.lol" = {
    };
    dadnas = {
      hasZfs = false;
    };
  };
  only_rpi = n: v: v.pi5_voltage or false;
in {
  age.secrets = {
    oauth2_proxy = {
      file = ./secrets/oauth.age;
      owner = "oauth2-proxy";
    };
    hass_token = {
      file = ./secrets/hass_token.age;
      owner = "prometheus";
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 8086 ];
  services = {
    influxdb = {
      enable = true;
    };
    grafana = {
      enable = true;
      #extraOptions = { # https://grafana.com/docs/auth/auth-proxy/
      #  AUTH_PROXY_ENABLED = "true";
      #  AUTH_PROXY_AUTO_SIGN_UP = "true";
      #};
      settings = {
        "auth.proxy" = {
          enabled = true;
          header_name = "X-Email";
          header_property = "email";
          auto_sign_up = true;
          whitelist = "127.0.0.1, ::1";
        };
        server.domain = webhost;
        server.http_addr = "";
        server.root_url = "%(protocol)ss://%(domain)s/grafana/";
        users.allow_sign_up = false;
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            type = "prometheus";
            name = "prometheus";
            url = "http://localhost:9090/prometheus";
          }
          {
            type = "influxdb";
            name = "influxdb";
            url = "http://localhost:8086/";
            jsonData = {
              dbName = "meters";
            };
          }
        ];
        dashboards.settings.providers = [
          {
            name = "generic";
            options.path = ./grafana/generic;
          }
        ];
      };
    };
    oauth2-proxy = {
      cookie.refresh = "1h";
      email.domains = [ "iohk.io" ];
      enable = true;
      keyFile = config.age.secrets.oauth2_proxy.path;
      nginx = {
        domain = webhost;
        virtualHosts = {
          ${webhost} = {
          };
        };
      };
      provider = "google";
      setXauthrequest = true;
    };
    nginx = {
      enable = true;
      virtualHosts."${webhost}".locations = {
        "/grafana/".extraConfig = ''
          ${oauthProxyConfig}
          proxy_pass http://localhost:3000/;
          proxy_set_header Host $host;
          proxy_set_header REMOTE_ADDR $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
        '';
        "/grafana/api/live/ws".extraConfig = ''
          ${oauthProxyConfig}
          proxy_http_version 1.1;
          proxy_pass http://localhost:3000/api/live/ws;
          proxy_set_header Connection "Upgrade";
          proxy_set_header Host $host;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
        "/prometheus/".extraConfig = ''
          ${oauthProxyConfig}
          proxy_pass http://localhost:9090/prometheus/;
          proxy_set_header Host $host;
          proxy_set_header REMOTE_ADDR $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
        '';
        "/alertmanager/".extraConfig = oauthProxyConfig;
        "/graylog/".extraConfig = oauthProxyConfig;
      };
    };
    prometheus = {
      enable = true;
      checkConfig = "syntax-only";
      enableReload = true;
      webExternalUrl = "https://${webhost}/prometheus/";
      extraFlags = [
        "--storage.tsdb.retention.time=10y"
        #"--log.level=debug"
      ];
      scrapeConfigs = let
        pi5_voltage = {
          job_name = "pi5_voltage";
          fallback_scrape_protocol = "PrometheusText1.0.0";
          scrape_interval = "10s";
          static_configs = let
            mkPi5Voltage = host: obj: {
              targets = [ "${host}:9101" ];
              labels.alias = host;
            };
          in
            lib.mapAttrsToList mkPi5Voltage (lib.filterAttrs only_rpi monitoredNodes);
        };
        mkMinecraft = name: {
          job_name = "minecraft-${name}";
          scrape_interval = "60s";
          metrics_path = "/cc/hdd/0/${name}.txt";
          static_configs = [
            {
              targets = [
                "77.163.112.172:3876"
              ];
            }
          ];
        };
      in [
        (mkMinecraft "prom")
        (mkMinecraft "prom2")
        {
          job_name = "cachecache";
          scrape_interval = "60s";
          metrics_path = "/";
          static_configs = [ { targets = [ "nas:8080" ]; } ];
        }
        {
          job_name = "grafana";
          scrape_interval = "60s";
          metrics_path = "/metrics";
          static_configs = [ { targets = [ "localhost:3000" ]; } ];
        }
        {
          job_name = "rtorrent";
          scrape_interval = "10s";
          static_configs = [ { targets = [ "nas:9135" ]; } ];
        }
        {
          fallback_scrape_protocol = "PrometheusText1.0.0";
          job_name = "boiler";
          scrape_interval = "60s";
          metrics_path = "/";
          static_configs = [ { targets = [ "10.0.0.91:9102" ]; } ];
        }
        {
          job_name = "prometheus";
          scrape_interval = "60s";
          metrics_path = "/prometheus/metrics";
          static_configs = [
            {
              targets = [ "localhost:9090" ];
              labels.alias = "prometheus";
            }
          ];
        }
        {
          job_name = "temp_daemon";
          scrape_interval = "60s";
          static_configs = [
            {
              targets = [ "c2d:49116" ];
              labels.alias = "temp_daemon";
            }
          ];
        }
        {
          job_name = "fragmentation";
          scrape_interval = "60s";
          metrics_path = "/metrics";
          static_configs = let
            makeFragConfig = host: obj: {
              targets = [ "${host}:9103" ];
              labels.alias = host;
            };
            onlyZfs = n: v: v.hasZfs or false;
          in lib.mapAttrsToList makeFragConfig (lib.filterAttrs onlyZfs monitoredNodes);
        }
        pi5_voltage
        {
          job_name = "amdgpu";
          scrape_interval = "10s";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "amd:12913" ];
              labels.alias = "amd";
            }
          ];
        }
        {
          job_name = "faucet";
          scrape_interval = "60s";
          metrics_path = "/metrics";
          static_configs = [
            #{
            #  targets = [ "amd:8090" ];
            #  labels.alias = "amd";
            #  labels.namespace = "preview";
            #}
          ];
        }
        {
          job_name = "smartctl";
          scrape_interval = "60s";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "amd:9633" ];
              labels.alias = "amd";
            }
            {
              targets = [ "nas:9633" ];
              labels.alias = "nas";
            }
            {
              targets = [ "dadnas:9633" ];
              labels.alias = "dadnas";
            }
            {
              targets = [ "thinkpad:9633" ];
              labels.alias = "thinkpad";
            }
          ];
        }
        {
          job_name = "hass";
          scrape_interval = "60s";
          metrics_path = "/api/prometheus";
          bearer_token_file = config.age.secrets.hass_token.path;
          scheme = "http";
          static_configs = [
            {
              targets = [ "localhost:8123" ];
              labels.alias = "hass";
            }
          ];
        }
        {
          job_name = "stationeers";
          scrape_interval = "60s";
          metrics_path = "/metrics";
          scheme = "http";
          static_configs = [
            {
              targets = [
                #"amd:8000"
                #"system76:8000"
              ];
              labels.alias = "amd";
            }
          ];
        }
        {
          job_name = "node";
          scrape_interval = "60s";
          scrape_timeout = "50s";
          static_configs = let
            makeNodeConfig = key: value: {
              targets = [
                "${key}:9100"
              ];
              labels = {
                alias = key;
              } // value.labels or {};
            };
          in lib.mapAttrsToList makeNodeConfig monitoredNodes;
        }
        {
          # for hydra
          job_name = "node_statd";
          scrape_interval = "60s";
          static_configs = [
            {
              targets = [ "nas:9102" ];
              labels.alias = "nas";
            }
          ];
        }
        {
          job_name = "nginx";
          scrape_interval = "60s";
          metrics_path = "/status/format/prometheus";
          static_configs = let
            makeNodeConfig = key: value: {
              targets = [ "${key}:9113" ];
              labels = {
                alias = key;
              } // value.labels or {};
            };
            onlyNginx = n: v: v.hasNginx or false;
          in lib.mapAttrsToList makeNodeConfig (lib.filterAttrs onlyNginx monitoredNodes);
        }
      ];
    };
  };
  users.users.oauth2_proxy = {
    group = "oauth2_proxy";
    isSystemUser = true;
  };
  users.groups.oauth2_proxy = {};
}
