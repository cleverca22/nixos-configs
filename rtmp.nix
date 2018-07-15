{ pkgs, ... }:

let
  nginxWithModules = modules: pkgs.nginx.override { inherit modules; };
  nginxWithRTMP = with pkgs.nginxModules; nginxWithModules [ rtmp ];
in {
  config = {
    systemd.services.nginx.preStart = ''
      mkdir -p /tmp/streaming/{hls,dash}
    '';
    services.nginx = {
      package = nginxWithRTMP;
      virtualHosts = let
        common = {
          locations = {
            "/hls" = {
              root = "/tmp/streaming";
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
              hls_path /tmp/streaming/hls;
              # hls_fragment 3;
              # hls_playlist_length 60;
              dash on;
              dash_path /tmp/streaming/dash;
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
            root /tmp/streaming;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
          }
          location /dash {
            root /tmp/streaming;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
          }
        }
      '';
    };
  };
}
