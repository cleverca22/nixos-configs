{ pkgs, lib, config, ... }:

with lib;
let
  passwords = import ./load-secrets.nix;
  keys = import ./keys.nix;
  overlay1 = self: super: {
    ntp = super.ntp.overrideAttrs (drv: {
      patches = drv.patches or [] ++ [ ./openat.patch ];
    });
  };
  sources = import ./nix/sources.nix;
  iohk-ops = sources.iohk-ops;
in {
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./nas-hydra.nix
    ./rtmp.nix
    ./nas-websites.nix
    ./iohk-binary-cache.nix
    ./snmpd.nix
    #./datadog.nix
    ./clevers_machines.nix
    ./cachecache.nix
    ./media-center.nix
    ./tgt_service.nix
    #./cardano-relay.nix
    ./nixops-managed.nix
    ./nas-monitoring.nix
    (iohk-ops + "/modules/monitoring-exporters.nix")
    ./nas-wifi.nix
  ];
  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "ohci_pci" "ehci_pci" "pata_atiixp" "usb_storage" "usbhid" "sd_mod" "nvme" ];
    loader.grub = {
      device = "/dev/sde";
      configurationLimit = 5;
    };
    kernelModules = [ "tcp_bbr" "kvm-amd" "netconsole" ];
    kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr";
    extraModprobeConfig = ''
      options netconsole netconsole=6665@192.168.2.11/enp4s0,6666@192.168.2.61/00:1c:c4:6e:00:46
    '';
  };
  environment = {
    systemPackages = with pkgs; [
      rtorrent
      socat
      sysstat
      tcpdump
      vnstat
      smartmontools
      lsof
      iotop
      nvme-cli
      pciutils usbutils # lsusb and lspci
      ethtool
    ];
  };
  fileSystems = {
    "/" = {
      device = "naspool/root";
      fsType = "zfs";
    };
    "/boot" = {
      device = "UUID=f5c56a8b-edcd-44ca-8814-490bf43ab576";
      fsType = "ext4";
    };
    "/home" = {
      device = "naspool/home";
      fsType = "zfs";
    };
    "/media/videos/4tb" = {
      device = "c2d:/media/videos/4tb";
      fsType = "nfs";
    };
    "/var/lib/deluge" = { device = "naspool/deluge"; fsType = "zfs"; };
  };
  swapDevices = [
    { device = "/dev/media/swap"; }
  ];
  networking = {
    firewall = {
      allowedTCPPorts = mkOrder 1 [
        80 443
        1337
        1935
        1936
        111 2049 # nfs
        3260
        10011 30033 30034 # ts3
        58846 8112 # deluge
        8081
        8333 # bitcoin
        6991 # rtorrent
        20048 # nfs
      ];
      allowedUDPPorts = mkOrder 1 [
        161
        111 2049 # nfs
        9987 # ts3
        9990 # ts3 2nd
        33445
      ];
    };
    nameservers = [ "192.168.2.1" ];
    search = [ "localnet" ];
    defaultGateway = "192.168.2.1";
    hostId = "491ddec8";
    hostName = "nas";
    interfaces.enp4s0.ipv4.addresses = [
      {
        address = "192.168.2.11";
        prefixLength = 24;
      }
    ];
  };
  security.audit.enable = false;
  services = {
    monitoring-exporters = {
      enable = true;
      metrics = true;
      logging = false;
      papertrail.enable = false;
      ownIp = "127.0.0.1";
    };
    tgtd = {
      enable = true;
      targets = {
        "iqn.2016-02.windows-extra" = { backingStore = "/dev/naspool/windows-extra"; index = 2; };
        "iqn.2019-01.amd-steam" = {
          backingStore = "/dev/naspool/amd-steam";
          index = 1;
        };
        "iqn.2019-03.vm-example" = {
          backingStore = "/dev/naspool/vm-example";
          index = 2;
        };
      };
    };
    cachecache.enable = true;
    locate.enable = true;
    plex = {
      enable = true;
      openFirewall = true;
    };
    arcstats = true;
    openssh = {
      enable = true;
    };
    postfix = {
      enable = true;
      relayHost = "c2d.localnet";
    };
    dd-agent = {
      nginxConfig = ''
        init_config:
        instances:
          - nginx_status_url: http://localhost/nginx_status/
      '';
    };
    nginx = {
      enable = true;
      statusPage = true;
    };
    toxvpn = {
      enable = true;
      localip = "192.168.123.51";
    };
    teamspeak3 = {
      enable = true;
      defaultVoicePort = 9990;
      fileTransferPort = 30034;
      queryPort = 10012;
    };
    ntp.enable = true;
    nfs = {
      server = {
        enable = true;
        exports = ''
          /nas c2d(rw,async,no_subtree_check,no_root_squash) 192.168.2.15(rw,sync,no_subtree_check,no_root_squash) 192.168.2.126(rw,sync,subtree_check,no_root_squash) ramboot(rw,async,subtree_check,no_root_squash) 192.168.144.3(rw,sync,subtree_check,no_root_squash) 192.168.2.100(rw,sync,no_root_squash,subtree_check) system76(rw,sync,subtree_check,root_squash) 192.168.2.162(rw,sync,subtree_check,root_squash) router(ro,async,no_subtree_check,root_squash)
          /naspool/amd-nixos amd(rw,sync,subtree_check,no_root_squash)
        '';
      };
    };
    zfs = {
      autoSnapshot = {
        enable = true;
      };
    };
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [
      #overlay1
    ];
  };
  nix = {
    binaryCaches = lib.mkForce [ "http://nas.localnet:8081" ];
    #package = pkgs.nixUnstable;
    gc = {
      automatic = true;
      dates = "0:00:00";
      options = ''--max-freed "$((32 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
    };
    buildMachines = let
      key = "/etc/nixos/keys/distro";
    in [
      { hostName = "clever@du075.macincloud.com"; systems = [ "x86_64-darwin" ]; sshKey = key; speedFactor = 1; maxJobs = 1; }
      { hostName = "builder@system76.localnet"; systems = [ "armv6l-linux" "armv7l-linux" "x86_64-linux" "i686-linux" ]; sshKey = key; maxJobs = 4; speedFactor = 1; supportedFeatures = [ "big-parallel" "nixos-test" ];}
      #{ hostName = "root@192.168.2.142"; systems = [ "armv6l-linux" "armv7l-linux" ]; sshKey = key; maxJobs = 1; speedFactor = 2; supportedFeatures = [ "big-parallel" ]; }
      { hostName = "builder@192.168.2.15"; systems = [ "i686-linux" "x86_64-linux" ]; sshKey = key; maxJobs = 1; speedFactor = 1; supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ]; }
      { hostName = "clever@aarch64.nixos.community"; systems = [ "armv7l-linux" "aarch64-linux" ]; sshKey = key; maxJobs = 1; speedFactor = 2; supportedFeatures = [ "big-parallel" ]; }
      {
        hostName = "localhost";
        mandatoryFeatures = [ "local" ];
        systems = [ "x86_64-linux" "i686-linux" ];
        maxJobs = 4;
      }
    ];
    maxJobs = 2;
    buildCores = 2;
    extraOptions = mkOrder 1 ''
      # gc-keep-derivations = true
      # gc-keep-outputs = true
      auto-optimise-store = false
      secret-key-files = /etc/nix/keys/secret-key-file
    '';
  };
  users = {
    extraUsers = {
      gits = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = with keys; [ nix2 clever.amd router.root clever.laptop clever.laptopLuks ];
      };
    };
  };
  system.stateVersion = "16.03";
  programs.vim.fat = false;
}
