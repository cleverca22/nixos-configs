{ config, lib, pkgs, ... }:

let
  keys = import ./keys.nix;
  builders = import ./builders.nix;
  secrets = import ./load-secrets.nix;
  sources = import ./nix/sources.nix;
  iohk-ops = sources.iohk-ops;
in {
  fileSystems = {
    # TODO move into deployment file
    "/" = {
      device = "/dev/disk/by-uuid/3c21b4a1-bc19-449b-815f-60c66ba23bdf";
      fsType = "ext4";
    };
    "/media/videos/4tb" = {
      device = "c2d:/media/videos/4tb";
      fsType = "nfs";
      options = [ "soft" ];
    };
    "/nas" = {
      device = "nas:/nas";
      fsType = "nfs";
      options = [ "soft" ];
    };
  };

  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./router.nat.nix
    ./snmpd.nix
    ./earthtools.ca.nix
    ./core.nix
    ./iohk-binary-cache.nix
    #./datadog.nix
    ./weechat.nix
    #./ntp_fix.nix
    ./nixops-managed.nix
    (iohk-ops +"/modules/monitoring-exporters.nix")
    #./jormungandr.nix
    ./exporter.nix
    #./homeserver.nix
    ./ntp_fix.nix
  ];
  programs = {
    vim.fat = false;
  };
  time.timeZone = "America/Moncton";
  documentation.info.enable = false;
  boot = {
    initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ata_piix" "usbhid" "usb_storage" ];
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
      memtest86.enable = true;
    };
  };
  networking = {
    timeServers = lib.mkOptionDefault [
      "nas"
      "amd"
      "system76"
      "c2d"
    ];
    hostName = "router";
    hostId = "136e6c46";
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 5201 33445 config.services.teamspeak3.fileTransferPort config.services.teamspeak3.queryPort 80 443 8443 ];
      allowedUDPPorts = [
        123 161 33445 config.services.teamspeak3.defaultVoicePort 53 162
        51820
      ];
      trustedInterfaces = [ "tox_master0" ];
    };
    search = [ "localnet" ];
  };
  #qemu-user.arm = true;
  services = {
    monitoring-exporters = {
      enable = true;
      metrics = true;
      logging = false;
      papertrail.enable = false;
      ownIp = "192.168.2.1";
    };
    #arcstats = true;
    extra-statsd = false;
    teamspeak3.enable = true;
    nix-serve = {
      secretKeyFile = "/etc/nix/nix-serve.sec";
      enable = false;
    };
    radvd = {
      enable = false;
      config = ''
        interface enp4s2f1 {
          AdvSendAdvert on;
          AdvHomeAgentFlag off;
          MinRtrAdvInterval 30;
          MaxRtrAdvInterval 100;
          AdvDefaultPreference high;
          prefix ${secrets.publicIpv6Prefix} {
            AdvOnLink on;
            AdvAutonomous on;
            AdvRouterAddr on;
          };
        };
      '';
    };
    avahi.enable = true;
    ntp.enable = true;
    fail2ban.enable = true;
    getty.helpLine = "[9;0][14;0]";
    toxvpn = {
      enable = true;
      localip = "192.168.123.20";
    };
    hydra = {
      enable = false;
      extraEnv.NIX_REMOTE_SYSTEMS = lib.concatStringsSep ":" [ "/etc/nix/machines" "/etc/nix/machines.provisioned" ];
      hydraURL = "https://hydra.earthtools.ca/";
      notificationSender = "clever@ext.earthtools.ca";
      minimumDiskFree = 5;
      minimumDiskFreeEvaluator = 1;
    };
    postgresql = {
      enable = false;
      package = pkgs.postgresql_15;
    };
    openssh.passwordAuthentication = false;
  };
  environment.systemPackages = with pkgs; [
    file
    iperf
    lshw
    lsof
    nmap
    nox
    pciutils
    socat
    speedtest-cli
    tcpdump
    wireshark-cli
  ];
  users.extraUsers.gits = {
    isNormalUser = true;
    uid = 1006;
    openssh.authorizedKeys.keys = with keys; [
      clever.nix2
      clever.amd clever.laptop clever.router_root
    ];
  };
  swapDevices = [
    { device = "/var/db/swap"; priority = 10; size = 1024; }
  ];
  systemd.services = {
    network-local-commands.path = with pkgs; [ iproute2 vlan ];
  };
  nixpkgs.config.allowUnfree = true;
  nix = {
    buildMachines = with builders; [ amd darwin notos ];
    extraOptions = ''
      #gc-keep-derivations = true
      #gc-keep-outputs = true
      auto-optimise-store = true
    '';
    gc = {
      automatic = true;
      dates = "*:00:00";
      options = ''--max-freed "$((10 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
    };
    settings = {
      max-jobs = 2;
      cores = 2;
    };
  };
  system.stateVersion = "20.03";
}
