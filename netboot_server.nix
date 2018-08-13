{ lib, config, pkgs, ... }:

with lib;

let
  nixos_release = import (pkgs.path + "/nixos/release.nix") {};
  netboot = let
    build = (import (pkgs.path + "/nixos/lib/eval-config.nix") {
      system = "x86_64-linux";
      modules = [
        (pkgs.path + "/nixos/modules/installer/netboot/netboot-minimal.nix")
        ./nix-tests/kexec/justdoit.nix
        module
      ];
    }).config.system.build;
  in pkgs.symlinkJoin {
    name = "netboot";
    paths = with build; [ netbootRamdisk kernel netbootIpxeScript ];
  };
  module = {
    kexec.justdoit = {
      luksEncrypt = true;
      rootDevice = "/dev/vda";
      swapSize = 40 * 1024;
      bootSize = 512;
    };
  };
  ipxe' = pkgs.ipxe.overrideDerivation (drv: {
    installPhase = ''
      ${drv.installPhase}
      make $makeFlags bin-x86_64-efi/ipxe.efi bin-i386-efi/ipxe.efi
      cp -v bin-x86_64-efi/ipxe.efi $out/x86_64-ipxe.efi
      cp -v bin-i386-efi/ipxe.efi $out/i386-ipxe.efi
    '';
  });
  tftp_root = pkgs.runCommand "tftproot" {} ''
    mkdir -pv $out
    cp -vi ${ipxe'}/undionly.kpxe $out/undionly.kpxe
    cp -vi ${ipxe'}/x86_64-ipxe.efi $out/x86_64-ipxe.efi
    cp -vi ${ipxe'}/i386-ipxe.efi $out/i386-ipxe.efi
  '';
  nginx_root = pkgs.runCommand "nginxroot" {} ''
    mkdir -pv $out
    cat <<EOF > $out/boot.php
    #!ipxe
    chain netboot/netboot.ipxe
    EOF
    ln -sv ${netboot} $out/netboot
  '';
  cfg = config.netboot_server;
in {
  options = {
    netboot_server = {
      network.wan = mkOption {
        type = types.str;
        description = "the internet facing IF";
        default = "wlan0";
      };
      network.lan = mkOption {
        type = types.str;
        description = "the netboot client facing IF";
        default = "enp9s0";
      };
    };
  };
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
      dhcpd4 = {
        interfaces = [ cfg.network.lan ];
        enable = true;
        extraConfig = ''
          option arch code 93 = unsigned integer 16;
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
              if option arch = 00:09 {
                filename = "x86_64-ipxe.efi";
              } else {
                filename = "undionly.kpxe";
              }
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
      interfaces = {
        ${cfg.network.lan} = {
          ip4 = [ { address = "192.168.3.1"; prefixLength = 24; } ];
        };
      };
      nat = {
        enable = true;
        externalInterface = cfg.network.wan;
        internalIPs = [ "192.168.3.0/24" ];
        internalInterfaces = [ cfg.network.lan ];
      };
    };
  };
}
