{ config, pkgs, ... }:

let
  # physical port aliases
  ETH = "enp2s0";
  BOTTOM = "enp1s0f0";
  TOP = "enp1s0f1";

  # aliases by usage
  LAN = ETH;
  WAN = BOTTOM;
in
{
  imports = [
    ./bircd_module.nix
    ./clevers_machines.nix
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
      options ixgbe debug=16 allow_unsupported_sfp=1,1
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
    lshw
    net-tools
    pciutils
    screen
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
      enable = true;
      interfaces = {
        ${LAN} = {
          allowedTCPPorts = [
            53
            config.services.prometheus.exporters.bind.port
            config.services.prometheus.exporters.smartctl.port
            config.services.prometheus.exporters.node.port
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
        mtu = 1500;
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
    vnstat.enable = true;
    xserver = {
      enable = false;
      displayManager.lightdm.enable = false;
      desktopManager.xfce.enable = false;
    };
  };

  users.users.clever = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "25.11";
  deployment.targetHost = "10.0.0.60";
}
