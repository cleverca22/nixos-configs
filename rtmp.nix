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
            # https://ext.earthtools.ca/hls/nixnothing.m3u8
            # this url now works in cytube
            "/hls" = {
              root = "/tmp";
              extraConfig = ''
                add_header 'Access-Control-Allow-Origin' "https://cytu.be" always;
                add_header Cache-Control no-cache;
                add_header Access-Control-Allow-Origin *;
              '';
            };
            "/dash" = {
              root = "/tmp";
              extraConfig = ''
                types {
                  application/vnd.apple.mpegurl m3u8;
                  application/dash+xml mpd;
                  video/mp2t ts;
                }
                add_header Cache-Control no-cache;
                add_header Access-Control-Allow-Origin *;
              '';
            };
          };
        };
      in {
        "ext.earthtools.ca" = common;
        "nas.localnet" = common;
      };
      appendConfig = ''
        rtmp {
          server {
            listen 1935;
            chunk_size 4096;
            on_connect http://c2d.localnet/rtmp_hook.php;
            application live {
              live on;
              record off;
              hls on;
              hls_path /tmp/hls;
              # hls_fragment 3;
              # hls_playlist_length 60;
              dash on;
              dash_path /tmp/dash;
              on_publish http://c2d.localnet/rtmp_hook.php;
              on_done http://c2d.localnet/rtmp_hook.php;
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
          }
        }
      '';
    };
  };
}
