{ pkgs, lib, ... }:

with lib;

let
  WANMASTER = "enp4s2f0";
  LAN = "enp4s2f1";
  youtube = {
    name = "youtube.com";
    slaves = [];
    file = ./youtube;
  };
  reddit = {
    name = "reddit.com";
    slaves = [];
    file = ./youtube;
  };
in {
  networking = {
    firewall = {
      enable = true;
      extraCommands = lib.mkMerge [ (lib.mkAfter ''
        iptables -w -t filter -A nixos-fw -s 192.168.2.0/24 -p udp --dport 53 -i ${LAN} -j nixos-fw-accept
        iptables -w -t filter -A nixos-fw -s 192.168.2.0/24 -p tcp --dport 53 -i ${LAN} -j nixos-fw-accept
        iptables -w -t filter -A nixos-fw -s 192.168.2.0/24 -p udp --dport 69 -i ${LAN} -j nixos-fw-accept

        iptables -w -t nat -A nixos-nat-pre -i wan -p udp -m udp --dport 40189 -j DNAT --to-destination 192.168.2.15
        iptables -w -t nat -A nixos-nat-pre -i wan -p udp -m udp --dport 9990 -j DNAT --to-destination 192.168.2.11
        # factorio
        iptables -w -t nat -A nixos-nat-pre -i tun0 -p udp -m udp --dport 34197 -j DNAT --to-destination 192.168.2.32
        iptables -w -t nat -A nixos-nat-pre -i wan -p udp -m udp --dport 34197 -j DNAT --to-destination 192.168.2.32

        iptables -w -t nat -A nixos-nat-pre -i wan -p udp -m udp --dport 162 -j DNAT --to-destination 192.168.2.2:161
        iptables -w -t nat -A nixos-nat-post -p udp -m udp --dport 161 -d 192.168.2.2 -j SNAT --to-source 192.168.2.1

        iptables -w -t nat -A nixos-nat-post -s 192.168.2.0/24 -o tun0 -j MASQUERADE
      '') ];
    };
    vlans = {
      wan = {
        interface = WANMASTER;
        id = 35;
      };
      iptv = {
        interface = WANMASTER;
        id = 34;
      };
    };
    interfaces = {
      ${WANMASTER}.useDHCP = false;
      iptv.useDHCP = false;
      wan.useDHCP = true;
      ${LAN} = {
        ipv4.addresses = [
          { address = "192.168.2.1"; prefixLength = 24; }
        ];
      };
    };
    nat = {
      enable = true;
      externalInterface = "wan";
      internalIPs = [ "192.168.2.0/24" "10.67.15.0/24" ];
      internalInterfaces = [ LAN ];
      forwardPorts = [
        { destination = "192.168.2.61"; sourcePort = 25; }	# email
        # { destination = "192.168.2.62"; sourcePort = 80; }	# http
        #{ destination = "192.168.2.61:22"; sourcePort = 2222; } # ssh to laptop
        #{ destination = "192.168.2.15"; sourcePort = 22; }
        { destination = "192.168.2.61"; sourcePort = 6990; }	# rtorrent
        { destination = "192.168.2.11"; sourcePort = 6991; }	# rtorrent
        { destination = "192.168.2.61"; sourcePort = 11194; }	# openvpn
        { sourcePort = 25565; destination = "192.168.2.32"; }	# minecraft
        { sourcePort = 45333; destination = "192.168.2.15"; } # mc test
        { sourcePort = 21025; destination = "192.168.2.11"; } # starbound
        { destination = "192.168.2.62:22"; sourcePort = 2222; }
        { destination = "192.168.2.11"; sourcePort = 58846; } # deluged
        { destination = "192.168.2.15"; sourcePort = 38009; } # temp minecraft
        { destination = "192.168.2.15"; sourcePort = 40189; } # skype
        { destination = "192.168.2.11:443"; sourcePort = 4433; }
        #{ destination = "192.168.2.11"; sourcePort = 443; }
        { destination = "192.168.2.15"; sourcePort = 1234; }
        # 2nd teamspeak server
        { destination = "192.168.2.11"; sourcePort = 10012; }
        { destination = "192.168.2.11"; sourcePort = 30034; }
        { destination = "192.168.2.11"; sourcePort = 1935; }
        { destination = "192.168.2.11"; sourcePort = 32400; }
        { destination = "192.168.2.11"; sourcePort = 1337; } # syncplay
        { destination = "192.168.2.11"; sourcePort = 3000; } # carano
      ];
    };
  };
  services = {
    ssmtp = {
      enable = true;
      hostName = "c2d.localnet";
    };
    bind = {
      enable = true;
      forwarders = [ "47.55.55.55" "142.166.166.166" ];
      cacheNetworks = [ "192.168.2.0/24" "127.0.0.0/8" ];
      zones = [
        {
          name = "localnet";
          slaves = [ ];
          file = ./localnet;
          master = true;
        }
        #youtube reddit
        {
          name = "2.168.192.in-addr.arpa";
          slaves = [ ];
          file = ./lan.reverse;
          master = true;
        }
        {
          name = "0.8.e.f.ip6.arpa";
          slaves = [ ];
          file = ./ipv6.reverse;
          master = true;
        }
        {
          name = "a.9.1.0.c.1.0.0.0.7.4.0.1.0.0.2.ip6.arpa";
          slaves = [ ];
          file = ./ipv6.reverse;
          master = true;
        }
        {
          name = "a.9.1.0.d.1.0.0.0.7.4.0.1.0.0.2.ip6.arpa";
          slaves = [ ];
          file = ./ipv6.reverse;
          master = true;
        }
      ];
    };
    dhcpd4 = {
      interfaces = [ LAN ];
      enable = true;
      machines = [
        { hostName = "ramboot"; ethernetAddress = "00:1c:23:16:4b:b3"; ipAddress = "192.168.2.10"; }
        { hostName = "nas";     ethernetAddress = "d0:50:99:7a:80:21"; ipAddress = "192.168.2.11"; }
        { hostName = "amd";     ethernetAddress = "40:16:7e:b3:32:48"; ipAddress = "192.168.2.15"; }
        { hostName = "nix1";    ethernetAddress = "92:C5:E2:BB:12:A9"; ipAddress = "192.168.2.30"; }
        { hostName = "nix2";    ethernetAddress = "5E:88:5B:D7:6E:BC"; ipAddress = "192.168.2.31"; }
        { hostName = "system76";ethernetAddress = "a0:af:bd:82:39:0d"; ipAddress = "192.168.2.32"; }
      ];
      extraConfig = ''
        option rpiboot code 43 = text;
        subnet 192.168.2.0 netmask 255.255.255.0 {
          option domain-search "localnet";
          option subnet-mask 255.255.255.0;
          option broadcast-address 192.168.2.255;
          option routers 192.168.2.1;
          option domain-name-servers 192.168.2.1;
          range 192.168.2.100 192.168.2.200;
          next-server 192.168.2.61;
          if exists user-class and option user-class = "iPXE" {
            filename "http://c2d.localnet/boot.php?mac=''${net0/mac}&asset=''${asset:uristring}&version=''${builtin/version}";
            #option root-path "iscsi:192.168.2.61:::1:iqn.2015-10.com.laptop-root";
          } else {
            filename = "undionly.kpxe";
          }
          option rpiboot "Raspberry Pi Boot   ";
        }
      '';
    };
    #openvpn.servers = optionalAttrs (builtins.pathExists ./clever_router.ovpn) {
    #justasic = {
    #config = pkgs.lib.readFile ./clever_router.ovpn;
    #};
    #};
    tftpd = {
      enable = true;
      path = "/tftproot";
    };
  };
}
