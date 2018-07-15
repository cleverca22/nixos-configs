{ config, lib, pkgs, ... }:

let
  keys = import ./keys.nix;
  builders = import ./builders.nix;
  secrets = import ./secrets.nix;
in {
  # TODO move into deployment file
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3c21b4a1-bc19-449b-815f-60c66ba23bdf";
    fsType = "ext4";
  };

  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./router.nat.nix
    ./snmpd.nix
    ./earthtools.ca.nix
    ./core.nix
    ./iohk-binary-cache.nix
    ./datadog.nix
    ./weechat.nix
    ./ntp_fix.nix
  ];
  programs.vim.fat = false;
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
    hostName = "router";
    hostId = "136e6c46";
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 5201 33445 config.services.teamspeak3.fileTransferPort config.services.teamspeak3.queryPort 80 ];
      allowedUDPPorts = [ 123 161 33445 config.services.teamspeak3.defaultVoicePort 53 162 ];
      trustedInterfaces = [ "tox_master0" ];
    };
    search = [ "localnet" ];
  };
  fileSystems."/media/videos/4tb/" = {
    device = "c2d:/media/videos/4tb";
    fsType = "nfs";
  };
  sound.enable = false;
  services = {
    arcstats = true;
    extra-statsd = true;
    teamspeak3.enable = true;
    nix-serve = {
      secretKeyFile = "/etc/nix/nix-serve.sec";
      enable = true;
    };
    radvd = {
      enable = true;
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
    mingetty.helpLine = "[9;0][14;0]";
    toxvpn = {
      enable = true;
      localip = "192.168.123.20";
    };
    hydra = {
      enable = true;
      extraEnv.NIX_REMOTE_SYSTEMS = lib.concatStringsSep ":" [ "/etc/nix/machines" "/etc/nix/machines.provisioned" ];
      hydraURL = "http://hydra.earthtools.ca/";
      notificationSender = "clever@ext.earthtools.ca";
      minimumDiskFree = 5;
      minimumDiskFreeEvaluator = 1;
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql94;
    };
    openssh.passwordAuthentication = false;
  };
  environment.systemPackages = with pkgs; [
    pciutils
    nox
    tcpdump
    file
    iperf
    lshw
    lsof
    nmap
    nix-repl
    socat
    ncdu
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
    network-local-commands.path = with pkgs; [ iproute vlan ];
  };
  nixpkgs.config.allowUnfree = true;
  nix = {
    maxJobs = 2;
    buildCores = 2;
    buildMachines = with builders; [ amd darwin notos ];
    extraOptions = ''
      gc-keep-derivations = true
      gc-keep-outputs = true
      auto-optimise-store = true
    '';
    gc = {
      automatic = true;
      dates = "*:00:00";
      options = ''--max-freed "$((10 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
    };
  };
  system.stateVersion = "16.03";
}
