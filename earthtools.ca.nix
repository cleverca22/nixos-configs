{ ... }:

{
  services.lighttpd = {
    enable = true;
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
}
