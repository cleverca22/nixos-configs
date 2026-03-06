{ config, pkgs, lib, ... }:

with lib;

# bind and dhcpd need to test config files at build time
let
  WAN     = "enp4s2f0";
  LAN_A     = "enp4s2f1";
  LAN_B     = "enp3s3";
  LAN = "br0";
  loggers = [
    {
      name = "kea-dhcp6";
      output_options = [ { output = "stdout"; }];
      severity = "DEBUG";
      debuglevel = 99;
    }
  ];
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
  localip = "47.54.160.77";
  mkReservation = k: v: {
    hw-address = v.mac;
    ip-address = v.ip;
    hostname = k;
  };
in {
  networking = {
    defaultGateway = "192.168.2.1";
    firewall = {
      enable = true;
      extraCommands = lib.mkMerge [ (lib.mkAfter ''
        #iptables -w -t filter -A nixos-fw -s 192.168.2.0/24 -p tcp --dport 3001 -i ${LAN} -j nixos-fw-accept # allow jormungandr api on lan
        #iptables -w -t filter -A nixos-fw -s 192.168.2.0/24 -p tcp --dport 8000 -i ${LAN} -j nixos-fw-accept # allow jormungandr exporter

        #iptables -w -t nat -A nixos-nat-pre -i ${WAN} -p udp -m udp --dport 27016 -j DNAT --to-destination 192.168.2.15 # stationeers game port

        #iptables -w -t nat -A nixos-nat-pre -i ${WAN} -p udp -m udp --dport 40189 -j DNAT --to-destination 192.168.2.15
        #iptables -w -t nat -A nixos-nat-pre -i ${WAN} -p udp -m udp --dport 9990 -j DNAT --to-destination 192.168.2.11
        #iptables -w -t nat -A nixos-nat-pre -i ${WAN} -p udp -m udp --dport 51820 -j DNAT --to-destination 192.168.2.15 # amd wireguard
        #iptables -w -t nat -A nixos-nat-pre -i ${WAN} -p udp -m udp --dport 51821 -j DNAT --to-destination 192.168.2.15 # amd wireguard
        iptables -w -t nat -A nixos-nat-pre -i ${WAN} -p udp -m udp --dport 5100 -j DNAT --to-destination 10.0.0.15 # elite dangerous
        # factorio
        #iptables -w -t nat -A nixos-nat-pre -i tun0 -p udp -m udp --dport 34197 -j DNAT --to-destination 192.168.2.15
        #iptables -w -t nat -A nixos-nat-pre -i ${WAN} -p udp -m udp --dport 34197 -j DNAT --to-destination 192.168.2.15

        #iptables -w -t nat -A nixos-nat-pre -i ${WAN} -p udp -m udp --dport 162 -j DNAT --to-destination 192.168.2.2:161
        #iptables -w -t nat -A nixos-nat-post -p udp -m udp --dport 161 -d 192.168.2.2 -j SNAT --to-source 192.168.2.1

        #iptables -w -t nat -A nixos-nat-post -s 192.168.2.0/24 -o tun0 -j MASQUERADE

        # redirect traffic to the public ip back to localhost
        iptables -w -t nat -A nixos-nat-pre -i ${LAN} -s 10.0.0.0/24 -d ${localip} -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1
        iptables -w -t nat -A nixos-nat-pre -i ${LAN} -s 10.0.0.0/24 -d ${localip} -p tcp --dport 443 -j DNAT --to-destination 10.0.0.1
        #iptables -w -t nat -A nixos-nat-pre -i ${LAN} -s 10.0.0.0/24 -d ${localip} -p tcp --dport 32400 -j DNAT --to-destination 10.0.0.1:80
      '') ];
      interfaces = {
        ${LAN} = {
          allowedTCPPorts = [
            53
            config.services.prometheus.exporters.bind.port
            config.services.prometheus.exporters.smartctl.port
            config.services.prometheus.exporters.node.port
          ];
          allowedUDPPorts = [
            53
            69 # tftp
          ];
        };
      };
    };
    bridges = {
      br0 = {
        interfaces = [
          LAN_A
          LAN_B
        ];
        rstp = false;
      };
    };
    interfaces = {
      ${WAN} = {
        #useDHCP = true;
        ipv4 = {
          addresses = [
            { address = "192.168.2.12"; prefixLength = 24; }
          ];
        };
      };
      ${LAN} = {
        ipv4 = {
          #routes = [
          #  {
          #    address = "192.168.3.0";
          #    prefixLength = 24;
          #    via = "192.168.2.11";
          #  }
          #];
          addresses = [
            { address = "10.0.0.1"; prefixLength = 24; }
          ];
        };
      };
    };
    nat = {
      enable = true;
      externalInterface = WAN;
      internalIPs = [
        "192.168.2.0/24"
        "192.168.20.0/24"
        "10.67.15.0/24"
        "10.2.0.2/32"
      ];
      internalInterfaces = [ LAN ];
      forwardPorts = [
        #{ destination = "10.0.0.61"; sourcePort = 25; }         # email
        # { destination = "192.168.2.62"; sourcePort = 80; }	# http
        #{ destination = "192.168.2.61:22"; sourcePort = 2222; } # ssh to laptop
        #{ destination = "192.168.2.15"; sourcePort = 22; }
        #{ destination = "192.168.2.61"; sourcePort = 6990; }	# rtorrent
        { destination = "10.0.0.11"; sourcePort = 6991; }       # rtorrent
        #{ destination = "192.168.2.61"; sourcePort = 11194; }	# openvpn
        { sourcePort = 25565; destination = "10.0.0.11"; }	# minecraft
        #{ sourcePort = 45333; destination = "192.168.2.15"; } # mc test
        #{ sourcePort = 21025; destination = "192.168.2.11"; } # starbound
        #{ destination = "192.168.2.62:22"; sourcePort = 2222; }
        #{ destination = "192.168.2.11"; sourcePort = 58846; } # deluged
        #{ destination = "192.168.2.15"; sourcePort = 38009; } # temp minecraft
        #{ destination = "192.168.2.15"; sourcePort = 40189; } # skype
        #{ destination = "192.168.2.11:443"; sourcePort = 4433; }
        #{ destination = "192.168.2.11"; sourcePort = 443; }
        #{ destination = "192.168.2.15"; sourcePort = 1234; }
        # 2nd teamspeak server
        { destination = "10.0.0.11"; sourcePort = 10012; }
        { destination = "10.0.0.11"; sourcePort = 30034; }
        { destination = "10.0.0.11"; sourcePort = 1935; }
        { destination = "10.0.0.11"; sourcePort = 32400; }
        { destination = "10.0.0.11"; sourcePort = 1337; } # syncplay
        #{ destination = "192.168.2.11"; sourcePort = 3000; } # carano
        #{ destination = "192.168.2.15"; sourcePort = 27016; } # stationeers game UDP
        #{ destination = "192.168.2.15"; sourcePort = 27015; } # stationeers update
        #{ destination = "10.0.0.112"; sourcePort = 8080; } # ip webcam on phone
        { destination = "10.0.0.61"; sourcePort = 4400; } # bircd
        #{ destination = "10.0.0.11"; sourcePort = 4001; } # ipfs
        { destination = "10.0.0.11"; sourcePort = 1883; } # mqtt
      ];
    };
  };
  services = {
    bind = {
      ipv4Only = true;
      enable = true;
      #forwarders = [
        #"47.55.55.55" "142.166.166.166"
        #"8.8.8.8"
        #"192.168.2.1"
      #];
      cacheNetworks = [
        #"192.168.2.0/24"
        #"192.168.3.0/24"
        "127.0.0.0/8"
        "10.0.0.0/24"
      ];
      extraConfig = ''
        statistics-channels {
          inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
        };
      '';
      extraOptions = ''
        #dnssec-enable yes;
        dnssec-validation no;
        #dnssec-lookaside auto;
      '';
      zones = [
        {
          master = true;
          name = "localnet";
          slaves = [ ];
          file = "${./localnet}";
        }
        #{
        #  master = true;
        #  name = "fw-download-alias1.raspberrypi.com";
        #  slaves = [ ];
        #  file = "${./rpi.zone}";
        #}
        #youtube reddit
        {
          master = true;
          name = "0.0.10.in-addr.arpa";
          slaves = [ ];
          file = "${./lan.reverse}";
        }
        {
          master = true;
          name = "0.8.e.f.ip6.arpa";
          slaves = [ ];
          file = "${./ipv6.reverse}";
        }
        {
          master = true;
          name = "a.9.1.0.c.1.0.0.0.7.4.0.1.0.0.2.ip6.arpa";
          slaves = [ ];
          file = "${./ipv6.reverse}";
        }
        {
          master = true;
          name = "a.9.1.0.d.1.0.0.0.7.4.0.1.0.0.2.ip6.arpa";
          slaves = [ ];
          file = "${./ipv6.reverse}";
        }
      ];
      #openFirewall = false;
    };
    kea.dhcp4 = {
      enable = true;
      settings = {
        interfaces-config.interfaces = [
          LAN
        ];
        lease-database = {
          name = "/var/lib/kea/dhcp4.leases";
          persist = true;
          type = "memfile";
        };
        option-def = [
          {
            name = "rpiboot";
            code = 43;
            #space = "dhcp4";
            #csv-format = false;
            type = "string";
            #data = "Raspberry Pi Boot   ";
          }
        ];
        rebind-timer = 3600 * 10;
        renew-timer = 3600;
        #inherit loggers;
        valid-lifetime = 3600 * 24;
        client-classes = [
          {
            name = "rpi_class";
            boot-file-name = "bar.bin";
            test = "substring(pkt4.mac, 0, 3) == 0xb827eb";
          }
        ];
        subnet4 = [
          {
            id = 1;
            subnet = "10.0.0.0/24";
            pools = [
              {
                pool = "10.0.0.100 - 10.0.0.200";
              }
            ];
            next-server = "10.0.0.1";
            option-data = [
              {
                name = "routers";
                data = "10.0.0.60";
              }
              {
                name = "boot-file-name";
                data = "test.bin";
              }
              #{
              # bitfield, 1 means use filename from option-data, 2 means use sname from option data
              #  name = "dhcp-option-overload";
              #  data = "0";
              #}
              {
                name = "domain-name-servers";
                data = "10.0.0.60";
              }
              {
                name = "domain-search";
                data = "localnet";
              }
              {
                name = "rpiboot";
                data = "Raspberry Pi Boot1337";
              }
            ];
            reservations = lib.mapAttrsFlatten mkReservation (import ./lan.nix);
          }
        ];
      };
    };
    #dhcpd4 = {
      #extraConfig = ''
      #  subnet 10.0.0.0 netmask 255.255.255.0 {
      #    if exists user-class and option user-class = "iPXE" {
      #      filename "http://c2d.localnet/boot.php?mac=''${net0/mac}&asset=''${asset:uristring}&version=''${builtin/version}";
      #      #option root-path "iscsi:192.168.2.61:::1:iqn.2015-10.com.laptop-root";
      #    } else {
      #      filename = "undionly.kpxe";
      #    }
      #    option rpiboot "Raspberry Pi Boot   ";
      #  }
      #'';
    #};
    #openvpn.servers = optionalAttrs (builtins.pathExists ./clever_router.ovpn) {
    #justasic = {
    #config = pkgs.lib.readFile ./clever_router.ovpn;
    #};
    #};
    prometheus = {
      exporters = {
        bind = {
          enable = true;
          openFirewall = false;
        };
      };
    };
    tftpd = {
      enable = true;
      path = "/tftproot";
    };
  };
}
