{
  services.lighttpd = {
    enable = false;
    port = 80;
    enableModules = [ "mod_proxy" ];
    extraConfig = ''
      #server.bind = "[::1]"
      server.bind = "0.0.0.0"
      $SERVER["socket"] == "[::]:80" {  }
      server.use-ipv6 = "enable"

      # proxy.server  = ( "" => ( ( "host" => "192.168.2.62", "port" => 80 ) ) )

      $HTTP["host"] == "gallery.earthtools.ca" {
        proxy.server  = ( "" => ( ( "host" => "192.168.2.61", "port" => 82 ) ) )
      }
      $HTTP["host"] == "hydra.earthtools.ca" {
        proxy.server = ( "" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )
      }
      $HTTP["host"] =~ "^(nixcache.earthtools.ca|reven.angeldsis.com)$" {
        proxy.server  = ( "" => ( ( "host" => "192.168.2.61" ) ) )
      }
      $HTTP["host"] == "cache.earthtools.ca" {
        proxy.server = ( "" => ( ( "host" => "127.0.0.1", "port" => 5000 ) ) )
      }
      $HTTP["url"] =~ "^/(export|videos|docs|nixos|docroot|hoogle|cacti)" {
        proxy.server = ( "" => (("host" => "192.168.2.61" )))
      }
      $HTTP["host"] =~ "^(fuspr.net|hydra.taktoa.me|hydra.fuspr.net|hydra.angeldsis.com)$" {
        proxy.server = ( "" => (("host" => "192.168.2.11" )))
      }
      $HTTP["host"] == "werewolf.earthtools.ca" {
        proxy.server = ( "" => (("host" => "192.168.2.32", "port" => 8080 ) ) )
      }
    '';
  };
  services.nginx = let
    mkProxy = target: {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = target;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_read_timeout 120;
          proxy_connect_timeout 120;
          proxy_send_timeout 120;
          send_timeout 120;
        '';
      };
    };
    nasProxy = mkProxy "http://10.0.0.11";
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
    virtualHosts = {
      #"fuspr.net" = nasProxy;
      #"hydra.taktoa.me" = nasProxy;
      #"hydra.fuspr.net" = nasProxy;
      "monitoring.earthtools.ca" = {
        enableACME = true;
        forceSSL = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.0.11";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
          "/grafana/api/live/ws" = {
            proxyPass = "http://10.0.0.11";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "Upgrade";
            '';
          };
        };
      };
      "hydra.angeldsis.com" = nasProxy;
      "plex.earthtools.ca" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://10.0.0.11:32400";
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
          proxyPass = "http://10.0.0.11:32400";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
          '';
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
        locations."/" = {
          proxyPass = "http://10.0.0.11:8123";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        locations."/api/websocket" = {
          proxyPass = "http://10.0.0.11:8123";
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
      "nail.earthtools.ca" = mainsite;
    };
  };
}
