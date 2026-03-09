{ lib, ... }:

{
  imports = [
    ./server-side.nix
  ];
  services = {
    anubis = {
      instances = {
        hydra = {
          settings = {
            BIND = "127.0.0.1:8080";
            BIND_NETWORK = "tcp";
            METRICS_BIND = "0.0.0.0:8081";
            METRICS_BIND_NETWORK = "tcp";
            SERVE_ROBOTS_TXT = true;
            TARGET = "http://nas.localnet";
          };
        };
      };
    };
    nginx = let
      mkProxy = target: {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = target;
          extraConfig = ''
            proxy_connect_timeout 120;
            proxy_http_version 1.1;
            proxy_read_timeout 120;
            proxy_send_timeout 120;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            send_timeout 120;
          '';
        };
      };
      nasProxy = mkProxy "http://nas";
      mainsite = {
          enableACME = true;
          listen = [
            {
              port = 80;
              ssl = false;
              addr = "0.0.0.0";
            }
            {
              port = 443;
              ssl = true;
              addr = "0.0.0.0";
            }
            {
              port = 8443;
              ssl = true;
              addr = "0.0.0.0";
            }
          ];
          #enableSSL = false;
          forceSSL = true;
          locations = {
            #"/export".proxyPass = "http://192.168.2.61";
            #"/videos".proxyPass = "http://10.0.0.61";
            "/hls".proxyPass = "http://nas.localnet";
            "/dash".proxyPass = "http://nas.localnet";
            "/old-private/".proxyPass = "http://nas.localnet/private/";
            "/private/nas-youtube/psyculturists/" = {
              root = "/nas/private/";
              extraConfig = ''
                rewrite ^ /no-more-vods.png break;
              '';
            };
            "/private/" = {
              alias = "/nas/private/";
              index = "index.htm";
              extraConfig = ''
                autoindex on;
                autoindex_exact_size off;
              '';
            };
            "/recordings/" = {
              proxyPass = "http://amd.localnet/recordings/";
            };
            #"/send-money".proxyPass = "http://system76:1234";
            #"/get-site-key".proxyPass = "http://system76:1234";
            #"/basic-faucet".proxyPass = "http://system76:1234";
            "/icons".proxyPass = "http://192.168.2.61";
            "/docs".proxyPass = "http://192.168.2.61";
            "/nixos".proxyPass = "http://192.168.2.61";
            "/docroot".proxyPass = "http://192.168.2.61";
            "/hoogle".proxyPass = "http://192.168.2.61";
            "/cacti".proxyPass = "http://192.168.2.61";
          };
        };
    in {
      enable = true;
      validateConfigFile = true;
      upstreams = {
        nas = {
          extraConfig = ''
            keepalive 60;
          '';
          servers = {
            "10.0.0.11" = {
            };
          };
        };
        plex = {
          extraConfig = ''
            keepalive 60;
          '';
          servers = {
            "10.0.0.11:32400" = {
            };
          };
        };
        jellyfin = {
          extraConfig = "keepalive 60;";
          servers."10.0.0.11:8096" = {};
        };
        hass = {
          extraConfig = "keepalive 60;";
          servers."10.0.0.11:8123" = {};
        };
      };
      virtualHosts = {
        #"fuspr.net" = nasProxy;
        #"hydra.taktoa.me" = nasProxy;
        #"hydra.fuspr.net" = nasProxy;
        "monitoring.earthtools.ca" = {
          enableACME = true;
          forceSSL = true;
          extraConfig = ''
            access_log /var/log/nginx/monitoring.earthtools.ca/access.log;
          '';
          locations = {
            "/" = {
              proxyPass = "http://nas";
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_read_timeout 120;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
              '';
            };
            "/grafana/api/live/ws" = {
              proxyPass = "http://nas";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_set_header Host $host;
              '';
            };
            "/prometheus/api/v1/notifications/live" = {
              proxyPass = "http://nas";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_set_header Host $host;
              '';
            };
          };
        };
        "hydra.angeldsis.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080";
            extraConfig = ''
              proxy_connect_timeout 120;
              proxy_http_version 1.1;
              proxy_read_timeout 120;
              proxy_send_timeout 120;
              proxy_set_header Connection "";
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Real-Ip $proxy_add_x_forwarded_for;
              send_timeout 120;
            '';
          };
          extraConfig = ''
            access_log /var/log/nginx/hydra.angeldsis.com/access.log;
          '';
        };
        "grocy.earthtools.ca" = nasProxy // {
          extraConfig = ''
            access_log /var/log/nginx/grocy.earthtools.ca/access.log;
          '';
        };
        "plex.earthtools.ca" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://plex";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_read_timeout 120;
              proxy_connect_timeout 120;
              proxy_send_timeout 120;
              send_timeout 120;
            '';
          };
          locations."/:/websockets/" = {
            proxyPass = "http://plex";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "Upgrade";
            '';
          };
        };

        "jellyfin.earthtools.ca" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://jellyfin";
              proxyWebsockets = false;
              extraConfig = ''
                proxy_http_version 1.1;
                proxy_read_timeout          600;
                proxy_send_timeout          300;
                proxy_set_header Connection "";
                proxy_set_header Host $host;
              '';
            };
            "/socket" = {
              proxyPass = "http://jellyfin";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_set_header Host $host;
              '';
            };
          };
        };

        "nixcache.earthtools.ca" = mkProxy "http://192.168.2.61";
        "reven.angeldsis.com" = mkProxy "http://192.168.2.61";

        "gallery.earthtools.ca" = mkProxy "http://10.0.0.61:82";

        "hydra.earthtools.ca" = {
          globalRedirect = "hydra.angeldsis.com";
          enableACME = true;
        };

        #"cache.earthtools.ca" = mkProxy "http://127.0.0.1:5000";
        "hass.earthtools.ca" = {
          enableACME = true;
          forceSSL = true;
          extraConfig = ''
            access_log /var/log/nginx/hass.earthtools.ca/access.log;
          '';
          locations."/" = {
            proxyPass = "http://hass";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Connection "";
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
          locations."/api/websocket" = {
            proxyPass = "http://hass";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "Upgrade";
            '';
          };
        };

        "ext.earthtools.ca" = mainsite;
        #"nail.earthtools.ca" = mainsite;
      };
    };
  };
}
