{ pkgs, lib, ... }:

let
  vc4_mesa = pkgs.mesa.override { galliumDrivers = [ "radeonsi" "vc4" "v3d" "swrast" ]; };
  pkgs_i686 = pkgs.pkgsi686Linux;
  foo = pkgs_i686.mesa_noglu.overrideDerivation (oldAttrs: {
    src = /home/clever/x/mesa-11.2.2;
    dontStrip = true;
  });
  flake = builtins.getFlake (toString ./.);
in {
  imports = [
    ./auto-gc.nix
    ./docker.nix
    ./exporter.nix
    ./wireshark-no-root.nix
    ./zdb.nix
    ./zfs-patch.nix
    #./radeon-exporter.nix
    ./amdgpu.nix
    ./rpi-udev.nix
    ./core.nix
    ./steam.nix
  ];
  boot = {
    binfmt = {
      emulatedSystems = [
        "armv7l-linux"
      ];
    };
    blacklistedKernelModules = [
      #"radeon"
      #"amdgpu"
    ];
    #crashDump.enable = true;
    crashDump.reservedMemory = "1024M";
    extraModprobeConfig = ''
      options snd_hda_intel enable=1,0
      install dccp /run/current-system/sw/bin/false
    '';
    #extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    initrd.availableKernelModules = [ "nvme" ];
    #kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "pcspkr" ];
    #kernelPackages = pkgs.linuxPackages_5_15;
    #kernelPackages = pkgs.linuxPackages.extend (self: super: {
    #  zfs-unused = super.zfs.overrideAttrs (old: {
    #    patches = old.patches ++ [
    #      (pkgs.fetchurl {
    #        url = "https://github.com/openzfs/zfs/commit/18ce2f2d742cab4616efbbfde6345bebd42e9b7c.patch";
    #        sha256 = "1r1ya4y6pds51kz997kwgqbq7gi509ckwjsxxijp6d683x4vpmx9";
    #      })
    #    ];
    #  });
    #});
    kernelParams = [
      "audit=0"
      "boot.shell_on_fail"
      "zfs.zfs_flags=0x10"
      #"amdgpu.cik_support=0"
      #"amdgpu.dpm=0"
      #"amdgpu.si_support=0"
      #"console=hvc0"
      #"idle=nomwait"
      #"isolcpus=0"
      #"memtest=10"
      #"netconsole=6665@192.168.2.15/enp3s0,6666@192.168.2.61/00:1c:c4:6e:00:46"
      #"radeon.cik_support=1"
      #"radeon.si_support=1"
      #"spl.spl_taskq_thread_bind=1"
      #"vm.min_free_kbytes=4194304"
      #"zfs.zio_taskq_batch_pct=50"
    ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
        #efiSysMountPoint = "/boot/EFI/";
      };
      grub = {
        #efiInstallAsRemovable = false;
        #efiSupport = true;
        device = "nodev";
        enable = true;
        extraEntries = ''
          menuentry "Windows 7" {
            insmod part_msdos
            insmod chain
            set root="hd1,msdos1"
            chainloader +1
          }
        '';
        memtest86.enable = true;
        #version = 2;
      };
    };
    tmp.useTmpfs = false;
    supportedFilesystems = [ "xfs" ];
    #zfs.enableUnstable = true;
  };
  environment.systemPackages = with pkgs; [
    vulkan-tools
    renderdoc
    #audacity
    #diffoscope
    #lutris
    #tigervnc
    #youtube-dl
    (hwloc.override { x11Support = true; })
    acpi
    asciinema
    flake.inputs.zfs-utils.packages.x86_64-linux.gang-finder
    bat
    bind.dnsutils
    chromium
    ddd
    discord
    git-lfs
    dos2unix
    efibootmgr
    evince
    evtest
    file
    gimp
    #gist
    gitAndTools.gitFull
    glxinfo
    gnome3.eog
    gnome3.file-roller
    #gnome3.gedit
    #gnuradio
    graphviz
    #gtkwave
    hping
    iftop
    iperf
    jq
    #kgpg
    (mcomix3.override { pdfSupport = false; })
    audacity
    obs-studio
    magic-wormhole
    pulseview
    moreutils # ts
    mpv
    niv
    nix-diff
    nix-du
    nmap
    #obs-studio
    paper-icon-theme
    pavucontrol gdb file psmisc
    plex-media-player
    psmisc
    pv
    pwgen
    python3Packages.binwalk
    #remmina
    #saleae-logic-2
    socat
    #stellarium
    (pkgs.callPackage ./syncplay.nix {})
    synergy
    sysstat pciutils vlc ffmpeg mkvtoolnix smartmontools
    tcpdump
    teamspeak_client
    valgrind
    wget usbutils nox rxvt_unicode polkit_gnome
    xorg.xev vnstat unrar unzip openssl xrestop zip ntfs3g
    xscreensaver wireshark-qt ncdu
    yt-dlp
    zgrviewer
  ];
  fileSystems = {
    "/"     = { device = "amd/root"; fsType = "zfs"; };
    "/boot" = { device = "UUID=5f5946ad-5d9c-42d9-97ef-adfae2e6cc20"; fsType = "ext4"; };
    "/home" = { device = "amd/home"; fsType = "zfs"; };
    "/home/clever/dedup" = { device = "amd/dedup"; fsType = "zfs"; };
    "/home/clever/iohk" = { device = "amd/iohk"; fsType = "zfs"; };
    "/home/clever/Games" = { device = "amd/games"; fsType = "zfs"; };
    "/home/clever/apps" = { device = "amd/clever-apps"; fsType = "zfs"; };
    "/nix"  = { device = "amd/nix";  fsType = "zfs"; options = [ "noatime" ]; };
    "/media/videos/4tb" = { device="c2d:/media/videos/4tb"; fsType = "nfs"; options=[ "noauto" ]; };
    "/var/lib/systemd/coredump" = { device = "amd/coredumps"; fsType = "zfs"; };
    "/nas" = {
      device = "nas:/nas";
      fsType = "nfs";
      options= [ "x-systemd.automount" "noauto" "soft" ];
    };
    #"/boot/EFI" = { device = "UUID=0ECD-75E7"; fsType = "vfat"; };
    #"/media/Music/" = { device = "192.168.123.32:/mnt/Music/"; fsType = "nfs"; };
  };
  hardware = {
    cpu.intel.updateMicrocode = true;
    bluetooth.enable = true;
    opengl = {
      driSupport32Bit = true;

      #extraPackages = [ pkgs.libGL pkgs.amdappsdk ];
      #extraPackages32 = [ pkgs_i686.libGL ];
      #package32 = pkgs.buildEnv {
      #  name = "custom-hack";
      #  paths = [
      #    foo foo.drivers
      #  ];
      #};

      #package = pkgs.buildEnv {
      #  name = "vc4_radeon_mesa";
      #  paths = [ vc4_mesa vc4_mesa.drivers ];
      #};
    };
  };
  networking = {
    timeServers = [
      "router"
      "nas"
      "c2d"
      "system76"
    ];
    firewall.enable = false;
    hostId = "fe1f6cbf";
    hostName = "amd-nixos";
    bridges = {
      br0 = {
        interfaces = [
          "enp8s0"
          "tap0"
        ];
      };
    };
    defaultGateway = "10.0.0.1";
    nameservers = [ "10.0.0.1" ];
    search = [ "localnet" ];
    interfaces = let
      tap0 = {
        virtualType = "tap";
        mtu = 9000;
        virtual = true;
        virtualOwner = "clever";
      };
    in {
      inherit tap0;
      enp8s0 = {
        mtu = 9000;
      };
      br0 = {
        mtu = 9000;
        ipv4.addresses = [
          {
            address = "10.0.0.15";
            prefixLength = 24;
          }
        ];
      };
    };
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
      git.svnSupport = false;
      sqlite.interactive = true;
    };
    overlays = [
      (self: super: {
        tesseract = null;
        pymupdf = null;
      })
      #(import ./overlays/plex)
    ];
  };
  nix = {
    buildMachines = [
      #{ sshUser = "pi"; hostName = "192.168.2.178"; maxJobs = 3; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; }
      #{ sshUser = "pi"; hostName = "pi400e"; maxJobs = 3; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; }
      #{ sshUser = "clever"; hostName = "pi5e"; maxJobs = 3; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; }
      #{ sshUser = "root"; hostName = "pi4"; maxJobs = 4; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; supportedFeatures = [ "big-parallel" ]; }
      #{ sshUser = "root"; hostName = " 192.168.2.32"; maxJobs = 3; system = "x86_64-lunux"; sshKey = "/etc/nixos/keys/distro"; }
      { sshUser = "clever"; hostName = "aarch64.nixos.community"; maxJobs = 32; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; }
    ];
    sshServe = {
      enable = true;
      keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCTVNUhtfjhA70isOcv/36qvN92LT29JnNOJqtMgb8puuTVf7C/kpl8UHXruPt8T1SW/h/O1v+qCCyQpZ920ozJQC6/Z27EwNBlzpi52Ljl0BX7HlKTK+maJSAOdlC4ofWruIQyIT0DXDJXbvHFqJKH4ubQKw78nn9WKFfE3xHVs6LiBXEi+tkKDxnFxEVWpgauXwK5FEQkEFD3NL9qnNiQ3icq+cM+BnTxrZRVKHBwL5YGn727ckrPSVq7rY4w2Mwm+vGb9+SkxP6GTxiaj6Xqx5ivgccbkgPP8vYyYFazhUb/Q3dTtLQ48ovspeDHEe2iX2LRVru9xSipTX5AzSSo7p6MFTkkI8yYoIBCk0tR02alCE2gyM98HGojiYj7VS/pAwJoYWNVHflUHD9olh+Hvsf6Jg+Z5vEALbHfcBRY2r01bQzXidCFxuXVRsD8fECkMB27mS+BmwXuwzf/y5WCpeWtDBDbgUHUAYYBOi5BnaZdoxbudNWPECOPDUPcrxk= root@nas"
      ];
    };
    distributedBuilds = true;
    extraOptions = ''
      allowed-uris = https://github.com/NixOS/nixpkgs/archive https://github.com/input-output-hk/nixpkgs/archive/6a8a0e57b1ea8bb771a54da66a4b5737de7048c3.tar.gz https://github.com/input-output-hk/nixpkgs/archive/3ff97c12fa19a197eb8ddee634ff2f3d4f02ad31.tar.gz
      builders-use-substitutes = true
      experimental-features = nix-command flakes
      #repeat = 1
      secret-key-files = /etc/nix/signing.sec
    '';
    max-free = 10;
    min-free = 3;
    min-free-collection = true;
    settings = {
      auto-optimise-store = true;
      cores = 20;
      max-jobs = 20;
      sandbox = "relaxed";
      substituters = [
        "http://cache.earthtools.ca"
        "http://nas.localnet:8081"
        #"http://nixcache.localnet"
        #"https://cache.nixos.org"
        #"https://hydra.mantis.ist/"
      ];
      trusted-binary-caches = [ "http://nas.localnet:8081" "https://hydra.iohk.io" "https://hydra.angeldsis.com" "https://cache.nixos.org" ];
      trusted-public-keys = [
        "amd-1:8E8Dz+Vc/6+8SePHMrJxe92IUYHBdv5pbI7YLnJH6Ek="
        "c2d.localnet-1:YTVKcy9ZO3tqPNxRqeYEYxSpUH5C8ykZ9ImUKuugf4c="
        "hydra.angeldsis.com-1:7s6tP5et6L8Y6sX7XGIwzX5bnLp00MtUQ/1C9t1IBGE="
        "hydra.iohk.io-1:chtUuea0mkt7j3Q3ESvfJUeqTNNPspSO//Yl6O00p/Y="
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "hydra.mantis.ist-1:4LTe7Q+5pm8+HawKxvmn2Hx0E3NbkYjtf1oWv+eAmTo="
        "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
        "pi400-1:ztZan3WJEeP0fadXKUv7+nCKb5p8nTIQi5hlXas0MmQ="
        "system76.angeldsis.com-1:i4B5E/GGgkb6TeOOhG81KDFduU5DItyaax3azSLUJRM="
        #"manveru.cachix.org-1:L5nJHSinfA2K5dDCG3KAEadwf/e3qqhuBr7yCwSksXo="
      ];
      trusted-users = [ "builder" "clever" "root" ];
    };
  };
  programs = {
    screen.screenrc = ''
      defscrollback 5000
      caption always
      #termcapinfo xterm 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'
      #term xterm-256color
      #defbce "on"
      # fixes terminfo bugs involing tsl=
      termcapinfo xterm 'hs:ts=\E]2;:fs=\007:ds=\E]2;screen\007'
    '';
    ssh = let
      amd = { publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhJRINrY5cFcqZ76GsAK7FU+wQhErlS6APdOIm7xcnW"; };
      router = { publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSvyvC18BHfivZJDhWSm7VU3kEElfNfMIfeohkil614"; };
      system76 = { publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtWMQ3F30gczudsr38Tw9yARsUMZbmvD4llnZq3K68u"; };
    in {
      knownHosts = {
        "amd.localnet" = amd;
        "router.localnet" = router;
        "system76" = system76;
        "system76.localnet" = system76;
      };
    };
    vim.fat = true;
  };
  security = {
    #rtkit.enable = lib.mkForce false;
  };
  services = {
    iscsid.enable = true;
    locate = {
      enable = true;
      package = pkgs.mlocate;
      localuser = null;
    };
    #mongodb.enable = true;
    memcached.enable = false;
    ntp.enable = true;
    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };
    prometheus.exporters = {
      smartctl = {
        enable = true;
        devices = [ "/dev/nvme0" "/dev/nvme1" "/dev/sda" "/dev/sdb" ];
        port = 9633;
      };
    };
    #toxvpn.port = 33450;
    toxvpn.enable = true;
    toxvpn.localip = "192.168.123.11";
    trezord.enable = true;
    tor = {
      enable = false;
      client = {
        enable = false;
        #privoxy.enable = true;
      };
    };
    udev = {
      packages = [ pkgs.ledger-udev-rules pkgs.trezor-udev-rules ];
      extraRules = ''
        SUBSYSTEM=="nvme", KERNEL=="nvme[0-9]*", GROUP="disk"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0a5c", ATTRS{idProduct}=="2711|2763|2764", GROUP="wheel"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="2d00", GROUP="wheel"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="2d01", GROUP="wheel"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="A8V93XJN", SYMLINK+="ttyftdi", OWNER="clever"
      '';
    };
    xserver = {
      #xkbOptions = "caps:shiftlock";
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager = {
        gnome.enable = false;
        xfce.enable = true;
        xterm.enable = false;
      };
      videoDrivers = [
        #"amdgpu"
        #"radeon"
      ];
      #useGlamor = false;
      #deviceSection = ''Option "NoAccel" "true"'';
    };
    zfs.autoSnapshot.enable = true;
  };
  swapDevices = [
    #{ device = "/dev/nvme0n1p3"; priority = 10; }
    #{ device = "/dev/disk/by-partlabel/swap1"; priority = 10; }
    #{ device = "/dev/disk/by-partlabel/swap2"; priority = 10; }
    #{ device = "/dev/disk/by-uuid/ea242aa4-59c5-4597-a5a5-e2874318aca2"; priority = 10; }
    #{ device = "/dev/disk/by-uuid/3fdb005c-97e7-4dfb-9a3f-71748d714ae4"; priority = 9; }
  ];
  system.stateVersion = "24.05";
  time = {
    hardwareClockInLocalTime = true;
  };
  users.extraUsers = {
    builder = {
      uid = 1001;
      isNormalUser = true;
    };
    clever = {
      home = "/home/clever";
      isNormalUser = true;
      extraGroups = [ "wheel" "wireshark" "vboxusers" "docker" ];
      uid = 1000;
    };
  };
  fonts = {
    fontDir.enable = true;
    #enableCoreFonts = true;
    #fontconfig.ultimate.substitutions = "ms";
    packages = with pkgs; [
      unifont
      #noto-fonts
      noto-fonts-cjk
      #nerdfonts
    ];
  };
  virtualisation = {
    anbox.enable = false;
    virtualbox.host = {
      enable = false;
    };
  };
  fileSystems."/home/clever/VirtualBox\\040VMs" = { fsType = "zfs"; device = "amd/vbox"; };
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  systemd.coredump = {
    enable = true;
    extraConfig = "ExternalSizeMax=${toString (8 * 1024 * 1024 * 1024)}";
  };
}
