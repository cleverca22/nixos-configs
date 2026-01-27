{ pkgs, config, ... }:

let
  secrets = import ./load-secrets.nix;
  keys = import ./keys.nix;
in {
  imports = [
    ./vim.nix
    #./iscsi-boot.nix
    ./iscsi_module.nix
    ./qemu.nix
    ./arcstats.nix
    ./extra-statsd.nix
    ./auto-gc.nix
    ./coredump.nix
  ];

  environment.systemPackages = with pkgs; [
    (if config.services.xserver.enable then gitFull else git)
    #utillinuxCurses
    (pkgs.makeDesktopItem { name = "screen"; exec = "${pkgs.xterm}/bin/xterm -e ${pkgs.screen}/bin/screen -xRR"; desktopName = "Screen"; genericName = "screen"; categories = [ "System" "TerminalEmulator" ]; })
    bat
    ncdu
    psmisc
    sqlite-interactive
    util
    util-linuxCurses
  ];
  boot = {
    blacklistedKernelModules = [ "dccp" ];
    kernelParams = [
      "sysrq_always_enabled"
      "zfs.zfs_metaslab_try_hard_before_gang=1"
    ];
  };
  nixpkgs = {
    config = {
      sqlite.interactive = true;
      allowUnfree = true;
      allowBroken = true;
      vim.ruby = false;
    };
    overlays = [
      (self: super: {
        util = self.callPackage ./util.nix {};
        mbrola-voices = super.mbrola-voices.override { languages = [ "en1" ]; };
        toxvpn = (builtins.getFlake "github:cleverca22/toxvpn/1830f9b8c12b4c5ef36b1f60f7e600cd1ecf4ccf").packages.x86_64-linux.default;
      })
    ];
  };
  programs = {
    screen.enable = true;
    screen.screenrc = ''
      defscrollback 5000
      caption always
      #termcapinfo xterm 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'
      # fixes terminfo bugs involing tsl=
      termcapinfo xterm 'hs:ts=\E]2;:fs=\007:ds=\E]2;screen\007'
      #defbce "on"
      maptimeout 5
    '';
    ssh = {
      extraConfig = ''
        ServerAliveInterval 60
      '';
      knownHosts = let
        router = { publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSvyvC18BHfivZJDhWSm7VU3kEElfNfMIfeohkil614"; };
        amd = { publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhJRINrY5cFcqZ76GsAK7FU+wQhErlS6APdOIm7xcnW"; };
        system76 = { publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtWMQ3F30gczudsr38Tw9yARsUMZbmvD4llnZq3K68u"; };
      in {
        "192.168.2.1" = router;
        "router.localnet" = router;
        "192.168.2.15" = amd;
        "amd.localnet" = amd;
        "system76" = system76;
        "system76.localnet" = system76;
        "c2d.localnet" = { publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAeIKSyO23iQey8rfwqYdRrcn2sY/Uxcy/OogAZKYNBAeLdwWDmX73d/TZA/rLJtImKPjZYl1VyCIylnNaogvNs="; };
        "andoria.angeldsis.com" = { publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHX1VUOiMc14jztdHArChYyUaLlTygtUSuH7qU+SD8DqnCmlmbTgeuRDEnsMCBGfWIRSftGi1VG7gC5cZwQxsiY="; };
        "github.com" = { publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="; };
        "du075.macincloud.com" = { publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrJvUu+5o75C8Sf27LWf0GNyb96iBQ6znoy8YmPeoVecpsEgj1KoW+NyZSkEgB1PQA/SBYpHVQRGFfxP0WI8H0kVfJX2wf89oY5m3XJDj/B6JnFo0tpJFhdnidSehFAPm5eja93osKpJDMgtt9F31PjmuOiYS/sTtZsyz/KzoUd2mekdlowvyQA5Fw93sC2lNrKyGsD6y7O5ft9YmyNn43s7g+2f2qBLF4miPgYECJ0AaNq1NBzrmxeDBxCvrMAZe4ZFnHx/g8oy+D4eZm+J2kc8ZMIa57dqua4Y3rm9o+Uej/8sBPcp7Kczf5eAS5f9+lLaATuLDTyFKLNLItU5kX"; };
        "aarch64.nixos.community" = { publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds"; };
        "pi5w" = { publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgqVYJn5wzz8bfVwWCtvUB6YsTNUlKzPA/IHhEJ78LF"; };
      };
    };
  };
  users = {
    users = {
      root.openssh.authorizedKeys.keys = with keys; [
        dual.distro
        clever.amd
        clever.laptopLuks
      ];
      builder = {
        uid = 1001;
        isNormalUser = true;
        openssh.authorizedKeys.keys = with keys; [
          dual.distro
          #clever.amd
          clever.nix1
          router_distro
          clever.nix2
          clever.amd_distro
          clever.nas_distro
          clever.hydra
        ];
      };
      clever = {
        isNormalUser = true;
        uid = 1000;
        initialHashedPassword = secrets.hashedPw;
        openssh.authorizedKeys.keys = with keys; [
          clever.amd clever.ramboot clever.laptop
        ];
        extraGroups = [ "wheel" "wireshark" "vboxusers" "ipfs" ];
      };
    };
  };
  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
      };
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
  };
  networking = {
    extraHosts = ''
      10.42.1.5 nixbox360
    '';
  };
  nix = {
    min-free-collection = true;
    distributedBuilds = true;
    settings = {
      substituters = [
        #"http://nixcache.localnet"
        #"https://cache.nixos.org"
        "https://hydra.angeldsis.com"
      ];
      trusted-public-keys = [
        "c2d.localnet-1:YTVKcy9ZO3tqPNxRqeYEYxSpUH5C8ykZ9ImUKuugf4c="
        #"hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
        "amd-1:8E8Dz+Vc/6+8SePHMrJxe92IUYHBdv5pbI7YLnJH6Ek="
      ];
      trusted-users = [ "builder" ];
    };
  };
  #system.extraSystemBuilderCmds = ''
  #  ln -sv ${./.} $out/nixcfg
  #'';
  security.acme.defaults.email = "cleverca22@gmail.com";
  security.acme.acceptTerms = true;
}
