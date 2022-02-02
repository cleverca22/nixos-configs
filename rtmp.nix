{ pkgs, ... }:

let
  rtmpOverlay = self: super: {
    nginxMainline = super.nginxMainline.override (oldAttrs: {
      modules = oldAttrs.modules ++ [ super.nginxModules.rtmp ];
    });
    #nginxStable = super.nginxStable.override (oldAttrs: {
    #  modules = oldAttrs.modules ++ [ super.nginxModules.rtmp ];
    #});
  };
in {
  config = {
    nixpkgs.overlays = [ rtmpOverlay ];
    systemd.services.nginx.preStart = ''
      mkdir -p /tmp/{hls,dash}
    '';
    services.nginx = {
      virtualHosts = let
        common = {
          locations = {
            "/hls" = {
              root = "/tmp";
            };
          };
        };
      in {
        "fuspr.net" = common;
        "nas.localnet" = common;
      };
      appendConfig = ''
        rtmp {
          server {
            listen 1935;
            chunk_size 4096;
            application live {
              live on;
              record off;
              hls on;
              hls_path /tmp/hls;
              # hls_fragment 3;
              # hls_playlist_length 60;
              dash on;
              dash_path /tmp/dash;
            }
          }
        }
      '';
      appendHttpConfig = ''
        server {
          listen 1936;
          location /stat {
            rtmp_stat all;
          }
          location /hls {
            types {
              application/vnd.apple.mpegurl m3u8;
              video/mp2t ts;
            }
            root /tmp;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
          }
          location /dash {
            root /tmp;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
          }
        }
      '';
    };
  };
}
