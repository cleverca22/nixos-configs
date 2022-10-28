{ lib, ... }:

let
  secrets = import ./load-secrets.nix;
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
  webhost = "monitoring.earthtools.ca";
  monitoredNodes = {
    "router.localnet" = {
      hasNginx = true;
    };
    "nas" = {
      hasNginx = true;
    };
    "amd.localnet" = {};
    #"pi0" = {};
    #"pi1a" = {};
    #"pi3" = {};
    #"pi4" = {};
    #"pi400" = {};
    #"pi400e" = {};
    system76 = {};
  };
in {
  networking.firewall.allowedTCPPorts = [ 80 ];
  services = {
    grafana = {
      enable = true;
      users.allowSignUp = false;
      addr = "";
      domain = "${webhost}";
      rootUrl = "%(protocol)ss://%(domain)s/grafana/";
      extraOptions = { # https://grafana.com/docs/auth/auth-proxy/
        AUTH_PROXY_ENABLED = "true";
        AUTH_PROXY_HEADER_NAME = "X-Email";
        AUTH_PROXY_HEADER_PROPERTY = "email";
        AUTH_PROXY_AUTO_SIGN_UP = "true";
        AUTH_PROXY_WHITELIST = "127.0.0.1, ::1"; # only trust nginx to claim usernames
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
    oauth2_proxy = {
      email.domains = [ "iohk.io" ];
      enable = true;
      inherit (secrets.oauth) clientID clientSecret cookie;
      nginx.virtualHosts = [ webhost ];
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
      webExternalUrl = "https://${webhost}/prometheus/";
      extraFlags = [
        "--storage.tsdb.retention=${toString (365 * 24)}h"
      ];
      scrapeConfigs = [
        {
          job_name = "cachecache";
          scrape_interval = "60s";
          metrics_path = "/";
          static_configs = [ { targets = [ "127.0.0.1:8080" ]; } ];
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
          static_configs = [
            {
              targets = [ "nas:9103" ];
              labels.alias = "nas";
            }
            {
              targets = [ "system76:9103" ];
              labels.alias = "system76";
            }
          ];
        }
        {
          job_name = "hass";
          scrape_interval = "300s";
          metrics_path = "/api/prometheus";
          bearer_token = secrets.hass_token;
          scheme = "http";
          static_configs = [
            {
              targets = [ "localhost:8123" ];
            }
          ];
        }
        {
          job_name = "node";
          scrape_interval = "60s";
          static_configs = let
            makeNodeConfig = key: value: {
              targets = [
                "${key}:9100"
                "${key}:9102"
              ];
              labels = {
                alias = key;
              } // value.labels or {};
            };
          in lib.mapAttrsToList makeNodeConfig monitoredNodes;
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
  users.users.oauth2_proxy.group = "oauth2_proxy";
  users.groups.oauth2_proxy = {};
}
