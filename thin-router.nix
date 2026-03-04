{ config, lib, pkgs, ... }:

let
  # physical port aliases
  ETH = "enp2s0";
  BOTTOM = "enp1s0f0";
  TOP = "enp1s0f1";

  # aliases by usage
  LAN = TOP;
  WAN = BOTTOM;
  localip = "47.54.160.77";
in
{
  imports = [
    ./bircd_module.nix
    ./clevers_machines.nix
    ./earthtools.ca.nix
    ./exporter.nix
    ./temp-daemon.nix
    ./zdb.nix
    ./zfs-patch.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "uas" "sd_mod" "sdhci_pci" ];
      kernelModules = [ ];
    };
    extraModprobeConfig = ''
      options ixgbe debug=16 allow_unsupported_sfp=1
    '';
    extraModulePackages = [ ];
    kernelModules = [ "kvm-intel" ];
    loader = {
      grub = {
        device = "nodev";
        efiInstallAsRemovable = false;
        efiSupport = true;
        enable = true;
        memtest86.enable = true;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  environment.systemPackages = with pkgs; [
    dig
    edid-decode
    efibootmgr
    ethtool
    irssi
    lshw
    net-tools
    pciutils
    screen
    smartmontools
    tcpdump
    usbutils
  ];
  exporters.openFirewall = false;

  fileSystems = {
    "/" = { device = "router/root"; fsType = "zfs"; };
    "/nix" = { device = "router/nix"; fsType = "zfs"; };
    "/home" = { device = "router/home"; fsType = "zfs"; };
    "/boot" = { device = "/dev/disk/by-uuid/5D1A-4005"; fsType = "vfat"; options = [ "fmask=0022" "dmask=0022" ]; };
    "/nas" = {
      device = "nas:/nas";
      fsType = "nfs";
      options = [ "soft" "nofail" ];
    };
  };

  hardware.cpu.intel.updateMicrocode = true;

  hardware.firmware = [ pkgs.linux-firmware ];
  networking = {
    defaultGateway = "192.168.2.1";
    firewall = {
      allowedTCPPorts = [
        80 443
      ];
      enable = true;
      extraCommands = lib.mkMerge [ (lib.mkAfter ''
        # redirect traffic to the public ip back to localhost
        iptables -w -t nat -A nixos-nat-pre -i ${LAN} -s 10.0.0.0/24 -d ${localip} -p tcp --dport 80 -j DNAT --to-destination 10.0.0.60
        iptables -w -t nat -A nixos-nat-pre -i ${LAN} -s 10.0.0.0/24 -d ${localip} -p tcp --dport 443 -j DNAT --to-destination 10.0.0.60
      '') ];
      interfaces = {
        ${LAN} = {
          allowedTCPPorts = [
            53
            config.services.iperf3.port
            config.services.prometheus.exporters.bind.port
            config.services.prometheus.exporters.node.port
            config.services.prometheus.exporters.smartctl.port
            9103 # zfs-frag
            49115 49116 # temp-daemon
          ];
          allowedUDPPorts = [
            53
            5353 # avahi
          ];
        };
      };
    };
    hostId = "491ddec8";
    hostName = "thin-router";
    interfaces = {
      ${LAN} = {
        useDHCP = false;
        mtu = 9000;
        ipv4.addresses = [
          {
            address = "10.0.0.60";
            prefixLength = 24;
          }
        ];
      };
      ${WAN} = {
        useDHCP = false;
        mtu = 1500;
        ipv4.addresses = [
          {
            address = "192.168.2.3";
            prefixLength = 24;
          }
        ];
      };
    };
    nat = {
      enable = true;
      externalInterface = WAN;
      forwardPorts = [
        { destination = "10.0.0.11"; sourcePort = 6991; }       # rtorrent
        { sourcePort = 25565; destination = "10.0.0.11"; }	# minecraft
        # 2nd teamspeak server
        { destination = "10.0.0.11"; sourcePort = 10012; }
        { destination = "10.0.0.11"; sourcePort = 30034; }
        { destination = "10.0.0.11"; sourcePort = 1935; }
        { destination = "10.0.0.11"; sourcePort = 32400; }
        { destination = "10.0.0.11"; sourcePort = 1337; } # syncplay
        { destination = "10.0.0.61"; sourcePort = 4400; } # bircd
        { destination = "10.0.0.11"; sourcePort = 1883; } # mqtt
      ];
      internalIPs = [
      ];
      internalInterfaces = [ LAN ];
    };
    networkmanager.enable = false;
    search = [ "localnet" ];
    timeServers = [
      "router"
      "amd"
      "c2d"
    ];
  };

  services = {
    avahi = {
      allowInterfaces = [ LAN ];
      enable = true;
      openFirewall = false;
    };
    bind = {
      ipv4Only = true;
      enable = true;
      cacheNetworks = [
        "10.0.0.0/24"
        "127.0.0.0/8"
      ];
      extraConfig = ''
        statistics-channels {
          inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
        };
      '';
      zones = [
        {
          master = true;
          name = "localnet";
          slaves = [ ];
          file = "${./localnet}";
        }
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
      ];
    };
    bircd = {
      enable = true;
    };
    fail2ban = {
      enable = true;
      ignoreIP = [ "76.112.236.206/32" ];
    };
    getty.helpLine = "[9;0][14;0]";
    iperf3 = {
      enable = true;
    };
    ntp.enable = true;
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
    prometheus.exporters = {
      bind = {
        enable = true;
        openFirewall = false;
      };
      smartctl.devices = [ "/dev/sda" ];
    };
    temp-daemon = {
      enable = true;
      port = "/dev/ttyUSB0";
    };
    toxvpn = { enable = true; localip = "192.168.123.1"; };
    vnstat.enable = true;
  };

  users.users.clever = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "25.11";
  deployment.targetHost = "10.0.0.60";
}
