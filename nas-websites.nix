{ ... }:

let
  remy_hydra = {
    locations."/".extraConfig = ''
      proxy_pass http://192.168.200.1/;
      proxy_set_header Host $host;
    '';
  };
in {
  services.nginx = {
    eventsConfig = "worker_connections 1024;";
    appendConfig = ''
      worker_processes 4;
      worker_rlimit_nofile 2048;
    '';
    virtualHosts = {
      "hydra.taktoa.me" = remy_hydra;
      "hydra.fuspr.net" = remy_hydra;
      "fuspr.net" = {
        locations."/".root = "/var/www/fuspr";
      };
    };
  };
}
