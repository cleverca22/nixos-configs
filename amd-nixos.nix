{ pkgs, lib, config, ... }:

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
    # ./amd-wg.nix
    # ./psql_test.nix
    # ./radeon-exporter.nix
    # ./zfs-patch.nix
    ./amdgpu.nix
    ./auto-gc.nix
    ./core.nix
    ./docker.nix
    ./exporter.nix
    ./ipfs.nix
    ./pipewire.nix
    ./rpi-udev.nix
    ./steam.nix
    ./wireshark-no-root.nix
    ./zdb.nix
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
      "dvb_usb_rtl28xxu"
    ];
    #crashDump.enable = true;
    crashDump.reservedMemory = "1024M";
    extraModprobeConfig = ''
      install dccp /run/current-system/sw/bin/false
    '';
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
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
      "zfs.zfs_active_allocator=cursor"
      # drivers/gpu/drm/amd/amdgpu/amdgpu_device.c
      # increases the timeout of GFX jobs
      "amdgpu.lockup_timeout=5000"
      #"amdgpu.ppfeaturemask=0xffffffff"
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
          menuentry "Windows 7 - legacy chain" {
            insmod part_msdos
            insmod chain
            set root="hd1,msdos1"
            chainloader +1
          }

          menuentry "Windows 7 - NTLDR" {
            insmod part_msdos
            insmod ntfs
            insmod ntldr
            search --set=root --label "System Reserved" --hint hd1,msdos1
            ntldr /bootmgr
          }
        '';
        memtest86.enable = true;
        #version = 2;
      };
    };
    tmp.useTmpfs = false;
    supportedFilesystems = [
      "xfs"
      "cifs"
    ];
    #zfs.enableUnstable = true;
  };
  environment.systemPackages = with pkgs; [
    #audacity
    #diffoscope
    #gist
    #gnome3.gedit
    #gtkwave
    #remmina
    #saleae-logic-2
    #stellarium
    #tigervnc
    #youtube-dl
    (hwloc.override { x11Support = true; })
    (mcomix.override { pdfSupport = false; })
    (pkgs.callPackage ./syncplay-clients.nix {})
    acpi
    #config.boot.kernelPackages.perf
    #(discord.override { withVencord = true; })
    ((discord.override { withVencord = true; }).overrideAttrs {
      src = fetchurl {
        url = "https://stable.dl2.discordapp.net/apps/linux/0.0.106/discord-0.0.106.tar.gz";
        hash = "sha256-FqY2O7EaEjV0O8//jIW1K4tTSPLApLxAbHmw4402ees=";
      };
    })
    #apktool
    #barrier
    #ffmpeg
    #lutris-free
    #renderdoc
    #synergy
    #teamspeak_client
    #xsane
    adwaita-qt
    adwaita-qt6
    appimage-run
    asciinema
    audacity
    bat
    bind.dnsutils
    binwalk
    bustle
    chromium
    cnping
    corectrl
    d-spy
    ddd
    dos2unix
    efibootmgr
    element-desktop
    eog
    evince
    evtest
    file
    file-roller
    firefox
    flake.inputs.zfs-utils.packages.x86_64-linux.gang-finder
    flake.inputs.zfs-utils.packages.x86_64-linux.txg-watcher
    flashrom
    gimp
    git-crypt
    git-lfs
    gparted
    gramps
    graphviz
    #handbrake
    helvum
    hping
    iftop
    iperf
    jq
    kdePackages.kgpg
    lshw
    magic-wormhole
    mesa-demos
    mkvtoolnix
    moreutils # ts
    mpv
    nettools
    niv
    nix-diff
    nix-du
    nmap
    obs-studio
    paper-icon-theme
    pavucontrol gdb file psmisc
    perf
    perlPackages.AppClusterSSH
    plex-desktop
    polkit_gnome
    prismlauncher
    psmisc
    pulseview
    pv
    pwgen
    qview
    rtl-sdr
    rxvt-unicode-unwrapped
    smartmontools
    socat
    sysstat pciutils vlc
    tcpdump
    valgrind
    vesktop
    vulkan-tools
    wget usbutils nox
    xorg.xev unrar unzip openssl xrestop zip ntfs3g
    xscreensaver wireshark-qt ncdu
    yt-dlp
    zgrviewer

    # import -silent -window root bmp:- | zbarimg -
    # qrcode scanning
    # zbarcam
    zbar cobang #qrscan
  ];
  fileSystems = {
    "/"     = { device = "amd/root"; fsType = "zfs"; };
    #"/160g" = { label = "160g-linux"; fsType = "ext4"; };
    "/boot" = { device = "UUID=5f5946ad-5d9c-42d9-97ef-adfae2e6cc20"; fsType = "ext4"; };
    "/home" = { device = "amd/home"; fsType = "zfs"; };
    "/home/clever/Games" = { device = "amd/games"; fsType = "zfs"; };
    "/home/clever/apps" = { device = "amd/clever-apps"; fsType = "zfs"; };
    "/home/clever/dedup" = { device = "amd/dedup"; fsType = "zfs"; };
    "/home/clever/iohk" = { device = "amd/iohk"; fsType = "zfs"; };
    "/media/videos/4tb" = { device="c2d:/media/videos/4tb"; fsType = "nfs"; options=[ "noauto" ]; };
    "/nix"  = { device = "amd/nix";  fsType = "zfs"; options = [ "noatime" ]; };
    "/nas" = {
      device = "nas:/nas";
      fsType = "nfs";
      options= [ "x-systemd.automount" "noauto" "soft" ];
    };
    "/var/lib/systemd/coredump" = { device = "amd/coredumps"; fsType = "zfs"; };
    #"/boot/EFI" = { device = "UUID=0ECD-75E7"; fsType = "vfat"; };
    #"/media/Music/" = { device = "192.168.123.32:/mnt/Music/"; fsType = "nfs"; };
  };
  hardware = {
    sane = {
      #enable = true;
      extraBackends = [ pkgs.sane-backends ];
    };
    bluetooth.enable = false;
    cpu.intel.updateMicrocode = true;
    opengl = {
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
    pulseaudio.enable = false;
  };
  networking = {
    bridges = {
      br0 = {
        interfaces = [
          "enp8s0"
          "tap0"
        ];
      };
    };
    defaultGateway = "10.0.0.1";
    dhcpcd.enable = false;
    extraHosts = ''
      192.168.2.11  hydra.taktoa.me deluge.earthtools.ca fuspr.net
      127.0.0.1 cacti.earthtools.ca old.explorer.angeldsis.com
      10.8.0.1  cert.root.vem
      #192.168.2.1   ext.earthtools.ca reven.angeldsis.com repo.angeldsis.com gallery.earthtools.ca
      #167.114.21.160 angeldsis.com
    '';
    firewall.enable = false;
    hostId = "fe1f6cbf";
    hostName = "amd-nixos";
    interfaces = let
      tap0 = {
        virtualType = "tap";
        mtu = 9000;
        virtual = true;
        virtualOwner = "clever";
      };
      tox_master0 = {
        virtualType = "tun";
        mtu = 1500;
        virtual = true;
        virtualOwner = "clever";
      };
    in {
      inherit tap0;
      #inherit tox_master0;
      enp8s0 = {
        mtu = 1500;
        wakeOnLan.enable = true;
      };
      br0 = {
        mtu = 1500;
        ipv4.addresses = [
          {
            address = "10.0.0.15";
            prefixLength = 24;
          }
        ];
      };
    };
    nameservers = [ "10.0.0.1" ];
    search = [ "localnet" ];
    timeServers = [
      "router"
      "nas"
      "c2d"
    ];
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
        caller-id-client = self.callPackage ./caller-id-client.nix {};
        obs-studio = super.obs-studio.override { browserSupport = false; };
      })
    ];
  };
  nix = {
    buildMachines = [
      #{ sshUser = "pi"; hostName = "192.168.2.178"; maxJobs = 3; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; }
      #{ sshUser = "pi"; hostName = "pi400e"; maxJobs = 3; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; }
      { sshUser = "clever"; hostName = "pi5e"; maxJobs = 3; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; supportedFeatures = [ "big-parallel" ]; }
      #{ sshUser = "root"; hostName = "pi4"; maxJobs = 4; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; supportedFeatures = [ "big-parallel" ]; }
      #{ sshUser = "root"; hostName = " 192.168.2.32"; maxJobs = 3; system = "x86_64-lunux"; sshKey = "/etc/nixos/keys/distro"; }
      #{ sshUser = "clever"; hostName = "aarch64.nixos.community"; maxJobs = 32; system = "aarch64-linux,armv7l-linux"; sshKey = "/etc/nixos/keys/distro"; supportedFeatures = [ "big-parallel" ]; }
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
      cores = 10;
      max-jobs = 4;
      sandbox = "relaxed";
      substituters = [
        #"http://cache.earthtools.ca"
        "http://nas.localnet:8081"
        "https://runner.blockfrost.io/bin-cache"
        #"http://nixcache.localnet"
        #"https://cache.nixos.org"
        #"https://hydra.mantis.ist/"
      ];
      trusted-binary-caches = [ "http://nas.localnet:8081" "https://hydra.iohk.io" "https://hydra.angeldsis.com" "https://cache.nixos.org" ];
      trusted-public-keys = [
        "amd-1:8E8Dz+Vc/6+8SePHMrJxe92IUYHBdv5pbI7YLnJH6Ek="
        "c2d.localnet-1:YTVKcy9ZO3tqPNxRqeYEYxSpUH5C8ykZ9ImUKuugf4c="
        "runner1:W6f2fUzWauzS9ruoN0WHFGtPJnqngUbqgD5oqCMsoJg=" # runner.blockfrost.io
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
    bash.completion.enable = true;
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
      startAgent = false;
    };
    vim.fat = true;
  };
  qemu-user = {
    arm = false;
    aarch64 = false;
    #riscv64 = true;
  };
  security = {
    audit.enable = false;
    pam = {
      loginLimits = [
        # https://github.com/lutris/docs/blob/master/HowToEsync.md
        {
          domain = "clever";
          item = "nofile";
          type = "hard";
          value = "524288";
        }
      ];
      services.hsdm = { allowNullPassword = true; startSession = true; };
    };
    rtkit.enable = lib.mkForce false;
  };
  services = {
    i2pd = {
      bandwidth = 1024;
      enable = false;
      proto.http.enable = true;
      proto.i2cp.enable = true;
    };
    iscsid.enable = true;
    kmscon = {
      enable = true;
      extraConfig = ''
        font-name=Inconsolata
        font-engine=pango
      '';
    };
    lact = {
      enable = true;
    };
    locate = {
      enable = true;
      package = pkgs.mlocate;
      #localuser = null;
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
    tor = {
      enable = false;
      client = {
        enable = false;
        #privoxy.enable = true;
      };
    };
    toxvpn = {
      enable = true;
      localip = "192.168.123.11";
      #port = 33450;
    };
    trezord.enable = true;
    udev = {
      packages = [
        pkgs.ledger-udev-rules
        pkgs.trezor-udev-rules
        #(import /home/clever/apps/cnlohr/ch32v003fun/minichlink)
      ];
      extraRules = ''
        SUBSYSTEM=="nvme", KERNEL=="nvme[0-9]*", GROUP="disk"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0a5c", ATTRS{idProduct}=="2711|2763|2764", GROUP="wheel"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="2d00", GROUP="wheel"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="2d01", GROUP="wheel"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="A8V93XJN", SYMLINK+="ttyftdi", OWNER="clever"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0003|000a|000c", GROUP="wheel"

        SUBSYSTEM=="usbmon", GROUP="wireshark", MODE="0660"

        # ftdi
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", GROUP="wheel"

        # pico wifi jtag
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0009", SYMLINK+="tty-%E{ID_SERIAL_SHORT}-%E{ID_USB_INTERFACE_NUM}", GROUP="wheel"
        # https://github.com/BogdanTheGeek/ch32v003-daplink
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="d003", GROUP="wheel"
        # 003 esp programmer
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="4004", GROUP="wheel"
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
    vnstat.enable = true;
    zfs.autoSnapshot.enable = true;
  };
  swapDevices = [
    #{ device = "/dev/nvme0n1p3"; priority = 10; }
    #{ device = "/dev/disk/by-partlabel/swap1"; priority = 10; }
    #{ device = "/dev/disk/by-partlabel/swap2"; priority = 10; }
    { device = "/dev/disk/by-uuid/ea242aa4-59c5-4597-a5a5-e2874318aca2"; priority = 10; }
    { device = "/dev/disk/by-uuid/3fdb005c-97e7-4dfb-9a3f-71748d714ae4"; priority = 9; }
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
      extraGroups = [ "wheel" "wireshark" "vboxusers" "docker" "dialout" ];
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
      noto-fonts-cjk-sans
      #nerdfonts
    ];
  };
  virtualisation = {
    # anbox.enable = false;
    virtualbox.host = {
      #enable = true;
    };
  };
  fileSystems."/home/clever/VirtualBox\\040VMs" = { fsType = "zfs"; device = "amd/vbox"; };
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  systemd.coredump = {
    enable = true;
    extraConfig = "ExternalSizeMax=${toString (8 * 1024 * 1024 * 1024)}";
  };
}
