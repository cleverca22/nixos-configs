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
  #nix-src = builtins.fetchTarball "https://github.com/nixos/nix/archive/374fe49ff78c13457c6cfe396f9ed0cb986c903b.tar.gz";
  #nix-flake = builtins.getFlake "github.com:cleverca22/nix?rev=374fe49ff78c13457c6cfe396f9ed0cb986c903b";
  #nix-flake = builtins.getFlake (builtins.unsafeDiscardStringContext nix-src);
  #nix = nix-flake.defaultPackage.x86_64-linux;
  flake = builtins.getFlake (toString ./.);
in {
  imports = [
    #./cardano-relay.nix
    #./datadog.nix
    #./nas-wifi.nix
    (iohk-ops + "/modules/monitoring-exporters.nix")
    ./cachecache.nix
    ./clevers_machines.nix
    ./exporter.nix
    ./home-assistant.nix
    ./iohk-binary-cache.nix
    ./media-center.nix
    ./nas-hydra.nix
    ./nas-monitoring-rewrite.nix
    ./nas-monitoring.nix
    ./nas-websites.nix
    ./nixops-managed.nix
    ./rtmp.nix
    ./snmpd.nix
    ./syncplay.nix
    ./tgt_service.nix
    ./zdb.nix
    ./zfs-patch.nix
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];
  boot = {
    initrd.availableKernelModules = [
      "ahci"          # SATA
      "ehci_pci"      # USB
      "nvme"
      "ohci_pci"      # USB
      "sd_mod"
      "usb_storage"
      "usbhid"
      "xhci_pci"      # USB
      "mpt3sas" "raid_class" "scsi_transport_sas" # SAS
      #"rr3740a"
    ];
    loader.grub = {
      device = "/dev/sdf";
      configurationLimit = 1;
    };
    kernelModules = [ "tcp_bbr" "kvm-amd" ];
    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
      "fs.inotify.max_user_watches" = "100000";
    };
    extraModprobeConfig = ''
      options netconsole netconsole=6665@192.168.2.11/eth0,6666@192.168.2.61/00:1c:c4:6e:00:46
    '';
    kernelParams = [
      #"maxcpus=1"
      "zfs.zfs_active_allocator=cursor"
    ];
    extraModulePackages = [
      #config.boot.kernelPackages.rr3740a
    ];
  };
  environment = {
    systemPackages = with pkgs; [
      ethtool
      file
      flake.inputs.zfs-utils.packages.x86_64-linux.gang-finder
      flake.inputs.zfs-utils.packages.x86_64-linux.txg-watcher
      gdb
      iotop
      jq
      lsof
      nvme-cli
      pciutils usbutils # lsusb and lspci
      pv
      rtorrent
      smartmontools
      socat
      sysstat
      tcpdump
      tgt
      vnstat
    ];
  };
  fileSystems = {
    "/" = { device = "naspool/root"; fsType = "zfs"; };
    "/boot" = { device = "UUID=f5c56a8b-edcd-44ca-8814-490bf43ab576"; fsType = "ext4"; };
    "/home" = { device = "naspool/home"; fsType = "zfs"; };
    "/home/clever/downloading" = { device = "naspool/downloading"; fsType = "zfs"; };
    "/media/videos/4tb" = { device = "c2d:/media/videos/4tb"; fsType = "nfs"; options = [ "soft" ]; };
    "/nix" = { device = "naspool/nix"; fsType = "zfs"; };
    "/var/lib/deluge" = { device = "naspool/deluge"; fsType = "zfs"; };
    #"/zfs-defrag" = { device = "/dev/media/zfs-defrag"; fsType = "ext4"; };
  };
  hardware = {
    bluetooth.enable = false;
  };
  swapDevices = [
    { device = "/dev/media/swap"; }
  ];
  networking = {
    timeServers = [
      "router"
      "amd"
      "system76"
      "c2d"
    ];
    defaultGateway = "10.0.0.1";
    firewall = {
      allowedTCPPorts = [
        80 443
        1337
        1935 1936 # rtmp.nix
        111 2049 # nfs
        3260
        10011 30033 30034 # ts3
        58846 8112 # deluge
        8081
        8333 # bitcoin
        6991 # rtorrent
        20048 # nfs
      ];
      allowedUDPPorts = [
        161
        123 # ntp
        111 2049 # nfs
        9987 # ts3
        9990 # ts3 2nd
        33445
      ];
    };
    hostId = "491ddec8";
    hostName = "nas";
    nameservers = [ "10.0.0.1" ];
    search = [ "localnet" ];
    interfaces.eth0 = {
      useDHCP = true;
      mtu = 1500;
      #ipv4.addresses = [
      #  {
      #    address = "10.0.0.11";
      #    prefixLength = 24;
      #  }
      #];
    };
    usePredictableInterfaceNames = false;
  };
  security.audit.enable = false;
  services = {
    arcstats = false;
    cachecache.enable = true;
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
        #"iqn.2019-01.amd-steam" = { backingStore = "/dev/naspool/amd-steam"; index = 1; };
        "iqn.2020-12.amd-steam-xfs" = { backingStore = "/dev/zvol/naspool/amd-steam-xfs"; index = 2; };
        #"iqn.2021-08.com.example:pi400.img" = { backingStore = "/dev/naspool/rpi/netboot-1"; index=3; };
        #"iqn.2019-03.vm-example" = {
        #  backingStore = "/dev/naspool/vm-example";
        #  index = 2;
        #};
        #"iqn.2016-02.windows-extra" = { backingStore = "/dev/naspool/windows-extra"; index = 4; };
        "iqn.2022-10.huge" = { backingStore = "/dev/zvol/naspool/huge"; index = 5; blockSize = 4096; };
      };
    };
    locate.enable = false;
    nfs = {
      server = {
        enable = true;
        exports = ''
          /nas 10.0.0.106(rw,sync,subtree_check,root_squash)
          /nas amd(insecure,rw,sync,no_subtree_check,no_root_squash)
          /nas c2d(rw,async,no_subtree_check,no_root_squash) 192.168.2.126(rw,sync,subtree_check,no_root_squash) 192.168.144.3(rw,sync,subtree_check,no_root_squash) 192.168.2.100(rw,sync,no_root_squash,subtree_check) system76(rw,sync,subtree_check,root_squash) 192.168.2.162(rw,sync,subtree_check,root_squash)
          /nas pi5w(rw,async,subtree_check,no_root_squash)
          /nas router(rw,async,no_subtree_check,no_root_squash)
          /naspool/amd-nixos amd(rw,sync,subtree_check,no_root_squash)

          /nas 10.0.0.110(rw,async,no_subtree_check,no_root_squash)
        '';
      };
    };
    nginx = {
      enable = true;
      statusPage = true;
      appendHttpConfig = ''
        charset UTF-8;
      '';
      virtualHosts = {
        "nas.localnet" = {
          locations = {
            "/RPC2" = {
              extraConfig = ''
                scgi_pass   127.0.0.1:5000;
                #include     scgi_vars;
                #scgi_var    SCRIPT_NAME  /RPC2;
              '';
            };
            "/private/" = {
              alias = "/nas/private/";
              index = "index.htm";
              extraConfig = ''
                autoindex on;
                autoindex_exact_size off;
              '';
            };
          };
        };
      };
    };
    ntp.enable = true;
    plex = {
      enable = true;
      openFirewall = true;
    };
    postfix = {
      enable = true;
      settings.main.relayhost = "c2d.localnet:25";
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
    prometheus.exporters = {
      smartctl = {
        enable = true;
        port = 9633;
        devices = [ "/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/sde" "/dev/sdf" ];
      };
    };
    udev = {
      extraRules = ''
        SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="28:c2:dd:14:8b:3d", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="wlp*", NAME="wlan0"
        SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="d0:50:99:7a:80:21", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="enp*", NAME="eth0"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", SYMLINK+="ttyzigbee", OWNER="hass"
      '';
    };
    vnstat.enable = true;
    zfs = {
      autoSnapshot = {
        enable = true;
      };
    };
  };
  nix = {
    #package = pkgs.nixUnstable;
    #package = nix;
    gc = {
      automatic = true;
      dates = "0:00:00";
      options = ''--max-freed "$((32 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
    };
    buildMachines = let
      key = "/etc/nixos/keys/distro";
      builders = import ./builders.nix;
    in [
      #{ hostName = "clever@du075.macincloud.com"; systems = [ "x86_64-darwin" ]; sshKey = key; speedFactor = 1; maxJobs = 1; }
      #{ hostName = "root@192.168.2.140"; systems = [ "armv6l-linux" "armv7l-linux" ]; sshKey = key; maxJobs = 1; speedFactor = 2; supportedFeatures = [ "big-parallel" ]; }
      #{ hostName = "builder@192.168.2.15"; systems = [ "i686-linux" "x86_64-linux" ]; sshKey = key; maxJobs = 1; speedFactor = 1; supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ]; }
      #{ hostName = "clever@aarch64.nixos.community"; systems = [ "armv7l-linux" "aarch64-linux" ]; sshKey = key; maxJobs = 1; speedFactor = 2; supportedFeatures = [ "big-parallel" ]; }
      #builders.rpi4
      #builders.pi400
      #{ hostName = "localhost"; mandatoryFeatures = [ "local" ]; systems = [ "x86_64-linux" "i686-linux" ]; maxJobs = 4; }
      { hostName = "clever@pi5w"; supportedFeatures = [ "big-parallel" ]; systems = [ "aarch64-linux" ]; maxJobs = 4; sshKey = key; }
      builders.system76
      #builders.amd
      #{ hostName = "root@10.0.0.171"; supportedFeatures = []; systems = [ "powerpc64-linux" ]; maxJobs = 1; sshKey = key; }
      { hostName = "root@10.42.1.5"; supportedFeatures = [ "big-parallel" ]; systems = [ "powerpc64-linux" ]; maxJobs = 1; sshKey = key; }
      #{ hostName = "root@10.42.1.6"; supportedFeatures = []; systems = [ "powerpc64-linux" ]; maxJobs = 1; sshKey = key; }
    ];
    settings = {
      max-jobs = 2;
      cores = 2;
      substituters = lib.mkForce [
        "http://nas.localnet:8081"
        #"ssh://nix-ssh@amd"
      ];
    };
    extraOptions = mkAfter ''
      gc-keep-derivations = true
      keep-outputs = false
      auto-optimise-store = false
      secret-key-files = /etc/nix/keys/secret-key-file
    '';
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [
      overlay1
    ];
  };
  programs.vim.fat = false;
  users = {
    extraUsers = {
      gits = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = with keys; [ nix2 clever.amd router.root clever.laptop clever.laptopLuks ];
      };
    };
  };
  system.stateVersion = "16.03";
}
