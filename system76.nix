{ pkgs, lib, ... }:

let
  nixMasterSrc = pkgs.fetchFromGitHub {
    owner = "nixos";
    repo = "nix";
    rev = "69c6fb12eea414382f0b945c0d6c574c43c7c9a3";
    hash = "sha256:1nybwpkd8h4wg1i5f98p0wkz6242pbm5sihvgw7sjym59ja0srl1";
  };
  nixMaster = (import "${nixMasterSrc}").defaultPackage.x86_64-linux;
in {
  imports = [
    #./datadog.nix
    #./taktoa-hercules.nix
    ./bluetooth.nix
    ./clevers_machines.nix
    ./direnv.nix
    #./docker.nix
    ./exporter.nix
    ./gpg.nix
    ./iohk-binary-cache.nix
    ./ntp_fix.nix
    ./wireshark-no-root.nix
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./zfs-patch.nix
    ./zdb.nix
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
        allowDiscards = true;
        device = "/dev/nvme0n1p2";
        name = "root";
        preLVM = true;
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
      allowedTCPPorts = [
        8080 3000 25565 8082 8081
        32433 # plex-media-player
      ];
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
    "/home/clever/disk-images" = zfs "disk-images";
    #"/nas" = { device = "nas:/nas"; fsType = "nfs"; options = [ "x-systemd.automount" "noauto" "soft" ]; };
  };
  swapDevices = [
    { device = "/dev/disk/by-uuid/68bce3d2-cfc5-4400-ad8c-ddb751441beb"; }
  ];
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
      secret-key-files = /etc/nix/secret-key-file
      experimental-features = nix-command flakes
      #repeat = 2
      auto-optimise-store = true
    '';
    settings = {
      cores = 8;
      trusted-users = [ "clever" ];
      extra-sandbox-paths = [ "/etc/nsswitch.conf" "/etc/protocols" "/usr/bin/env=${pkgs.coreutils}/bin/env" ];
      max-jobs = lib.mkDefault 4;
      substituters = lib.mkForce [ "http://nas.localnet:8081/" ]; #"file:///tmp/cache" "https://hydra.angeldsis.com" ];
      trusted-public-keys = [
        "amd-nixos-1:3gYz9vAPzXyqhLNdKbmF24ARp9Iy09ixR4pQAvHJGV8="
        "hydra.mcwhirter.io:l38v9uAAXM2uasBTmarp3rWA9iSHzMYMQSrMCpiVJmQ="
        "hydra.angeldsis.com-1:7s6tP5et6L8Y6sX7XGIwzX5bnLp00MtUQ/1C9t1IBGE="
      ];
    };
    #package = nixMaster;
    buildMachines = [
      { hostName = "clever@aarch64.nixos.community"; systems = [ "aarch64-linux" ]; sshKey = "/etc/nixos/keys/distro"; maxJobs = 10; speedFactor = 2; supportedFeatures = [ "big-parallel" ]; }
      {
        hostName = "mac-mini-1";
        systems = [ "x86_64-darwin" ];
        maxJobs = 1;
      }
    ];
  };
  nixpkgs.config = {
    allowUnfree = true;
    pulseaudio = true;
  };
  programs = {
    vim.fat = false;
    screen.screenrc = ''
      termcapinfo xterm-256color 'hs:ts=\E]2;:fs=\007:ds=\E]2;screen\007'
    '';
  };
  powerManagement.cpuFreqGovernor = "powersave";
  environment.systemPackages = with pkgs; [
    #androidenv.platformTools
    #obs-studio
    #slack
    #xlockmore
    (haskell.lib.justStaticExecutables haskellPackages.aeson-diff)
    (hwloc.override { x11Support = true; })
    acpi
    chromium
    ddrescue
    dtc
    efibootmgr
    evince
    evtest
    file
    gdb
    gist
    gnome.eog
    iftop
    iperf
    irssi
    jq
    lsof
    midori
    mosh
    mpv
    niv
    nix-diff
    nmap
    pavucontrol
    pciutils
    pigz
    plex-media-player
    pv
    pwgen
    rtorrent
    socat
    synergy
    sysstat
    teamspeak_client
    usbutils
    vlc
    wget
    wireshark
  ];
  users.users.clever = {
    extraGroups = [ "wheel" ];
    isNormalUser = true;
  };
  hardware = {
    cpu.intel.updateMicrocode = true;
    pulseaudio = {
      enable = true;
    };
  };
  sound.enable = true;
  services = {
    arcstats = false;
    avahi.publish.addresses = true;
    blueman.enable = true;
    iscsid.enable = true;
    udev = {
      extraRules = ''
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0a5c", ATTRS{idProduct}=="2711|2764", GROUP="wheel"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="A8V93XJN", SYMLINK+="ttyftdi", OWNER="clever"
      '';
    };
    ntp.enable = true;
    openssh.enable = true;
    openssh.forwardX11 = true;
    openssh.passwordAuthentication = false;
    tcsd.enable = false;
    tftpd = { enable = true; path = "/home/clever/tftp"; };
    toxvpn = {
      enable = true;
      localip = "192.168.123.12";
    };
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
    zfs.autoSnapshot.enable = true;
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
