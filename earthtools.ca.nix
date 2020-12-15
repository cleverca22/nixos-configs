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
        '';
      };
    };
    nasProxy = mkProxy "http://192.168.2.11";
  in {
    enable = true;
    virtualHosts = {
      #"fuspr.net" = nasProxy;
      #"hydra.taktoa.me" = nasProxy;
      #"hydra.fuspr.net" = nasProxy;
      "monitoring.earthtools.ca" = nasProxy;
      "hydra.angeldsis.com" = nasProxy;
      "plex.earthtools.ca" = mkProxy "http://192.168.2.11:32400";

      "nixcache.earthtools.ca" = mkProxy "http://192.168.2.61";
      "reven.angeldsis.com" = mkProxy "http://192.168.2.61";

      "gallery.earthtools.ca" = mkProxy "http://192.168.2.61:82";

      "hydra.earthtools.ca" = {
        globalRedirect = "hydra.angeldsis.com";
        enableACME = true;
      };

      "cache.earthtools.ca" = mkProxy "http://127.0.0.1:5000";

      "ext.earthtools.ca" = {
        enableACME = true;
        #enableSSL = false;
        forceSSL = true;
        locations = {
          #"/export".proxyPass = "http://192.168.2.61";
          "/videos".proxyPass = "http://192.168.2.61";
          "/icons".proxyPass = "http://192.168.2.61";
          "/docs".proxyPass = "http://192.168.2.61";
          "/nixos".proxyPass = "http://192.168.2.61";
          "/docroot".proxyPass = "http://192.168.2.61";
          "/hoogle".proxyPass = "http://192.168.2.61";
          "/cacti".proxyPass = "http://192.168.2.61";
        };
      };
    };
  };
}
