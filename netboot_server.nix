{ pkgs, ... }:

let
  nixos_release = import (pkgs.path + "/nixos/release.nix") {};
  netboot = nixos_release.netboot.x86_64-linux;
  tftp_root = pkgs.runCommand "tftproot" {} ''
    mkdir -pv $out
    cp -vi ${pkgs.ipxe}/undionly.kpxe $out/undionly.kpxe
  '';
  nginx_root = pkgs.runCommand "nginxroot" {} ''
    mkdir -pv $out
    cat <<EOF > $out/boot.php
    chain netboot/netboot.ipxe
    EOF
    ln -sv ${netboot} $out/netboot
  '';
in {
  options = {};
  config = {
    services = {
      nginx = {
        enable = true;
        virtualHosts = {
          "192.168.3.1" = {
            root = nginx_root;
          };
        };
      };
      dhcpd = {
        interfaces = [ "enp9s0" ];
        enable = true;
        extraConfig = ''
          subnet 192.168.3.0 netmask 255.255.255.0 {
            option domain-search "localnetboot";
            option subnet-mask 255.255.255.0;
            option broadcast-address 192.168.3.255;
            option routers 192.168.3.1;
            option domain-name-servers 192.168.3.1, 8.8.8.8, 8.8.4.4;
            range 192.168.3.100 192.168.3.200;
            next-server 192.168.3.1;
            if exists user-class and option user-class = "iPXE" {
              filename "http://192.168.3.1/boot.php?mac=''${net0/mac}&asset=''${asset:uristring}&version=''${builtin/version}";
            } else {
              filename = "undionly.kpxe";
            }
          }
        '';
      };
      tftpd = {
        enable = true;
        path = tftp_root;
      };
      bind = {
        enable = true;
        cacheNetworks = [ "192.168.3.0/24" "127.0.0.0/8" ];
      };
    };
    networking = {
      nat = {
        enable = true;
        externalInterface = "wlan0";
        internalIPs = [ "192.168.3.0/24" ];
        internalInterfaces = [ "enp9s0" ];
      };
    };
  };
}
