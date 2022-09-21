{ pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./iohk-binary-cache.nix
    ./docker.nix
    #./datadog.nix
    ./gpg.nix
    ./bluetooth.nix
    ./clevers_machines.nix
    ./wireshark-no-root.nix
    ./exporter.nix
  ];
  boot = {
    loader.grub = {
      configurationLimit = 20;
      device = "nodev";
      efiInstallAsRemovable = true;
      efiSupport = true;
      enable = true;
      version = 2;
    };
    initrd = {
      luks.devices.root = {
        name = "root"; device = "/dev/nvme0n1p2"; preLVM = true;
      };
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "rtsx_pci_sdmmc" ];
    };
    kernelModules = [ "kvm-intel" ];
    zfs.devNodes = "/dev"; # fixes some virtualmachine issues
    supportedFilesystems = ["nfs"];
    #kernelPackages = pkgs.linuxPackages_latest;
  };
  networking = {
    hostId = "b790d302"; # required for zfs use
    wireless = {
      enable = true;
      interfaces = [ "wlp3s0" ];
    };
    hostName = "system76";
    #extraHosts = ''
      #192.168.2.11 fuspr.net
      #192.168.123.51 hydra.angeldsis.com
    #'';
    firewall = {
      allowedTCPPorts = [ 8080 3000 25565 8082 8081 ];
      allowedUDPPorts = [
        33445 27036 27031 # steam streaming uses 27015-27030
        69 # tftpd
      ];
      trustedInterfaces = [ "tox_master0" ];
    };
  };
  fileSystems = let
    zfs = name: { device = "tank/${name}"; fsType = "zfs"; };
  in {
    "/" = zfs "root";
    "/home" = zfs "home";
    "/nix" = zfs "nix";
    "/boot" = { device = "/dev/disk/by-uuid/7DBC-2698"; fsType = "vfat"; };
    "/var/lib/docker" = zfs "docker";
  };
  swapDevices = [
    { device = "/dev/disk/by-uuid/68bce3d2-cfc5-4400-ad8c-ddb751441beb"; }
  ];
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
      secret-key-files = /etc/nix/secret-key-file
      #repeat = 2
    '';
    settings = {
      cores = 8;
      extra-sandbox-paths = [ "/etc/nsswitch.conf" "/etc/protocols" "/usr/bin/env=${pkgs.coreutils}/bin/env" ];
      max-jobs = lib.mkDefault 4;
      substituters = lib.mkForce [ "http://nas.localnet:8081/" ]; #"file:///tmp/cache" "https://hydra.angeldsis.com" ];
      trusted-public-keys = [
        "amd-nixos-1:3gYz9vAPzXyqhLNdKbmF24ARp9Iy09ixR4pQAvHJGV8="
        "hydra.mcwhirter.io:l38v9uAAXM2uasBTmarp3rWA9iSHzMYMQSrMCpiVJmQ="
        "hydra.angeldsis.com-1:7s6tP5et6L8Y6sX7XGIwzX5bnLp00MtUQ/1C9t1IBGE="
      ];
    };
  };
  nixpkgs.config = {
    allowUnfree = true;
    pulseaudio = true;
  };
  powerManagement.cpuFreqGovernor = "powersave";
  environment.systemPackages = with pkgs; [
    #androidenv.platformTools
    (hwloc.override { x11Support = true; })
    acpi
    chromium steam
    haskellPackages.aeson-diff
    midori
    mpv
    nix-diff
    obs-studio
    pavucontrol
    pciutils
    plex-media-player
    slack
    synergy
    wireshark
    xlockmore
  ];
  users.users.clever = {
    extraGroups = [ "wheel" ];
    isNormalUser = true;
  };
  hardware = {
    cpu.intel.updateMicrocode = true;
    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
    opengl.driSupport32Bit = true;
  };
  services = {
    avahi.publish.addresses = true;
    zfs.autoSnapshot.enable = true;
    ntp.enable = true;
    tcsd.enable = false;
    toxvpn = {
      enable = true;
      localip = "192.168.123.12";
    };
    openssh.enable = true;
    openssh.passwordAuthentication = false;
    xserver = {
      libinput = {
        enable = true;
        touchpad.accelSpeed = "20";
        touchpad.disableWhileTyping = true;
      };
      enable = true;
      desktopManager.xfce.enable = true;
      displayManager.sddm.enable = true;
    };
    tftpd = { enable = true; path = "/home/clever/tftp"; };
  };
  security.pam = {
    loginLimits = [
      {
        domain = "clever";
        item = "nofile";
        type = "hard";
        value = "65535";
      }
    ];
  };
  security.audit = {
    enable = false;
    rules = [ "-a task,always" ];
  };
}
