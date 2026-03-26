{ config, lib, pkgs, inputs, ... }:

let
in {
  imports = [
    #./rescue_boot.nix
    #./example2.nix
    #./thinkpad-ethernet-client.nix
    #./thinkpad-hostapd.nix
    #./xenon-netboot-server.nix
    ./bluetooth.nix
    ./core.nix
    ./direnv.nix
    ./docker.nix
    ./exporter.nix
    ./gpg.nix
    ./ipfs-test.nix
    ./laptop-postgres.nix
    ./sounds.nix
    ./steam.nix
    ./thinkpad-proxmox.nix
    ./thinkpad-wifi-client.nix
    ./zdb.nix
    ./zfs-patch.nix
  ];
  boot = {
    blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];
    initrd = {
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
    };
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        device = "nodev";
        efiSupport = true;
        enable = true;
        configurationLimit = 10;
      };
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams = let
      hugePageGig = 8;
    in [
      "hugepages=${toString ((hugePageGig * 1024) / 2)}"
    ];
    supportedFilesystems = [ "sshfs" ];
  };
  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ./syncplay-clients.nix {})
    #barrier
    dig
    discord
    edid-decode
    element-desktop
    eog
    ethtool
    file
    firefox
    gdb
    gimp
    git-crypt
    i2c-tools
    net-tools
    inputs.agenix.packages.${pkgs.system}.agenix
    iperf3
    josm
    jq
    kdePackages.kgpg
    lutris
    nix-diff
    openssl
    pciutils
    prismlauncher
    qrencode
    tcpdump
    unzip
    usbutils
    visualvm
    vlc
    wirelesstools
    xev
    zbar
  ];

  fileSystems = {
    "/" = {
      device = "thinkpad/root";
      fsType = "zfs";
    };

    "/home" = {
      device = "thinkpad/home";
      fsType = "zfs";
    };

    "/nix" = {
      device = "thinkpad/nix";
      fsType = "zfs";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/4687-E183";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
    "/var/lib/docker" = {
      device = "thinkpad/docker";
      fsType = "zfs";
      options = [ "nofail" ];
    };
  };
  hardware = {
    firmware = with pkgs; [ linux-firmware sof-firmware wireless-regdb ];
    alsa.enable = lib.mkForce false;
  };
  networking = {
    bonds = {
      #bond0 = {
      #  interfaces = [
      #    "wlp0s20f3"
      #    #"enp0s31f6"
      #  ];
      #  driverOptions = {
      #    mode = "active-backup";
      #  };
      #};
    };
    #defaultGateway = "10.0.0.1";
    extraHosts = ''
      10.0.0.11 nas
    '';
    firewall.allowedUDPPorts = [ config.services.toxvpn.port ];
    hostId = "5a11b73e";
    hostName = "thinkpad";
    interfaces = {
      enp0s31f6 = {
        wakeOnLan.enable = true;
      };
      #bond0 = {
      #  useDHCP = true;
      #  ipv4 = {
      #    addresses = [
      #      #{
      #      #  address = "10.0.0.112";
      #      #  prefixLength = 24;
      #      #}
      #    ];
      #  };
      #};
    };
    #nameservers = [ "10.0.0.1" ];
  };
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
      allow-import-from-derivation = true;
      substituters = [
        #"http://nas.localnet:8081"
        "https://cache.nixos.org"
        "https://runner.blockfrost.io/bin-cache"
        "https://hydra.angeldsis.com"
      ];
      trusted-public-keys = [
        "runner1:W6f2fUzWauzS9ruoN0WHFGtPJnqngUbqgD5oqCMsoJg=" # runner.blockfrost.io
        "hydra.angeldsis.com-1:7s6tP5et6L8Y6sX7XGIwzX5bnLp00MtUQ/1C9t1IBGE="
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      ];
    };
  };
  nixpkgs = {
    overlays = [
      (self: super: {
        caller-id-client = self.callPackage ./caller-id-client.nix {};
      })
    ];
  };
  programs = {
    screen = {
      screenrc = ''
        termcapinfo xterm 'hs:ts=\E]2;:fs=\007:ds=\E]2;screen\007'
      '';
    };
  };
  security = {
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
    };
  };
  services = {
    displayManager.sddm.enable = true;
    ntp.enable = true;
    openssh.settings.X11Forwarding = true;
    pipewire.enable = false;
    prometheus.exporters.smartctl.devices = [ "/dev/nvme0n1" ];
    pulseaudio.enable = true;
    samba = {
      enable = false;
      openFirewall = true;
      settings = {
        global = {
          "invalid users" = [ "root" ];
        };
        public = {
          browsable = "yes";
          comment = "public samba share";
          "guest on" = "yes";
          path = "/srv/public";
          "read only" = "no";
        };
      };
    };
    toxvpn = {
      enable = true;
      localip = "192.168.123.4";
      port = 33446;
    };
    vnstat.enable = true;
    xserver = {
      enable = true;
      desktopManager.xfce.enable = true;
    };
  };
  systemd = {
    user = {
      services = {
        caller-id-client = {
          environment.CALLERID_PW = "hunter2";
          # wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.caller-id-client}/bin/caller-id.py";
          };
        };
      };
    };
  };
  system.stateVersion = "26.05";
  time.timeZone = "America/Moncton";
  users.users.clever.extraGroups = [ config.services.kubo.group "docker" ];
  virtualisation.vswitch.enable = true;
}
