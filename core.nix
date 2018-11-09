{ pkgs, config, ... }:

let
  secrets = import ./load-secrets.nix;
  keys = import ./keys.nix;
  util = pkgs.callPackage ./util.nix {};
in {
  imports = [
    ./vim.nix
    ./iscsi-boot.nix
    ./iscsi_module.nix
    ./qemu.nix
    ./arcstats.nix
    ./extra-statsd.nix
  ];

  environment.systemPackages = with pkgs; [
    sqlite-interactive screen
    util
    utillinuxCurses psmisc
    (if config.services.xserver.enable then gitAndTools.gitFull else git)
    ncdu
    (pkgs.makeDesktopItem { name = "screen"; exec = "${pkgs.xterm}/bin/xterm -e ${pkgs.screen}/bin/screen -xRR"; desktopName = "Screen"; genericName = "screen"; categories = "System;TerminalEmulator;"; })
  ];
  boot.blacklistedKernelModules = [ "dccp" ];
  nixpkgs = {
    config = {
      sqlite.interactive = true;
      allowUnfree = true;
      vim.ruby = false;
    };
  };
  programs = {
    screen.screenrc = ''
      defscrollback 5000
      caption always
      termcapinfo xterm 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'
      defbce "on"
    '';
    ssh = {
      extraConfig = ''
        ServerAliveInterval 60
      '';
      knownHosts = [
        { hostNames = [ "192.168.2.1" "router.localnet" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSvyvC18BHfivZJDhWSm7VU3kEElfNfMIfeohkil614"; }
        { hostNames = [ "192.168.2.15" "amd.localnet" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhJRINrY5cFcqZ76GsAK7FU+wQhErlS6APdOIm7xcnW"; }
        { hostNames = [ "192.168.2.30" "nix1.localnet" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3cnHv8e6v3mQvVLc7f7YgbeHKqQY2UtySeNL8Ew4ro"; }
        { hostNames = [ "192.168.2.31" "nix2.localnet" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGG8XsjV3ufF2+SWc1isnYqry3tdIqA01GA4d+SSak/F"; }
        { hostNames = [ "c2d.localnet" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAeIKSyO23iQey8rfwqYdRrcn2sY/Uxcy/OogAZKYNBAeLdwWDmX73d/TZA/rLJtImKPjZYl1VyCIylnNaogvNs="; }
        { hostNames = [ "192.168.123.24" "gamah" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJpj4w4nvVhxRlJOsdn1anlOjpmwgeAZqRAhYwtg3RY96Dv3gDnJTsOU5z4DoKOVq5YNfeTGI5HJTGZuV6BSik0="; }
        { hostNames = [ "andoria.angeldsis.com" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHX1VUOiMc14jztdHArChYyUaLlTygtUSuH7qU+SD8DqnCmlmbTgeuRDEnsMCBGfWIRSftGi1VG7gC5cZwQxsiY="; }
        { hostNames = [ "github.com" ]; publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="; }
        { hostNames = [ "192.168.2.126" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBP6N2+bk6PLYUn0d0ZnEmPCFj8KeCJM8g9PCgBCMr6WkzFF1o6iWfXaJRdjPEnQExj3rOc5M8i2rUWLF14FyzdI="; }
        { hostNames = [ "ramboot.localnet" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAEXgceb4J6/jhgp8C2JEeUJq2QB5GCXSQLOSgTck9M4"; }
        { hostNames = [ "192.168.2.142" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILK7lvb7j1bjsb0phCP7vHPVi5jfDcjPWRv94iA1Y8Xv"; }
        { hostNames = [ "du075.macincloud.com" ]; publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrJvUu+5o75C8Sf27LWf0GNyb96iBQ6znoy8YmPeoVecpsEgj1KoW+NyZSkEgB1PQA/SBYpHVQRGFfxP0WI8H0kVfJX2wf89oY5m3XJDj/B6JnFo0tpJFhdnidSehFAPm5eja93osKpJDMgtt9F31PjmuOiYS/sTtZsyz/KzoUd2mekdlowvyQA5Fw93sC2lNrKyGsD6y7O5ft9YmyNn43s7g+2f2qBLF4miPgYECJ0AaNq1NBzrmxeDBxCvrMAZe4ZFnHx/g8oy+D4eZm+J2kc8ZMIa57dqua4Y3rm9o+Uej/8sBPcp7Kczf5eAS5f9+lLaATuLDTyFKLNLItU5kX"; }
        { hostNames = [ "system76" "system76.localnet" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtWMQ3F30gczudsr38Tw9yARsUMZbmvD4llnZq3K68u"; }
      ];
    };
  };
  users = {
    extraUsers = {
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
        extraGroups = [ "wheel" "wireshark" "vboxusers" ];
      };
    };
    extraGroups = {
      wireshark.gid = 500;
    };
  };
  services = {
    openssh = {
      enable = true;
      permitRootLogin = "yes";
    };
    avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        workstation = true;
      };
    };
  };
  nix = {
    extraOptions = ''
      min-free = ${toString (1024*1024*1024*3)}
      max-free = ${toString (1024*1024*1024*6)}
    '';

    distributedBuilds = true;
    trustedUsers = [ "builder" ];
    binaryCaches = [
      "http://cache.earthtools.ca"
      "http://nixcache.localnet"
      "https://cache.nixos.org"
    ];
    binaryCachePublicKeys = [
      "c2d.localnet-1:YTVKcy9ZO3tqPNxRqeYEYxSpUH5C8ykZ9ImUKuugf4c="
      "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
    ];
  };
  system.extraSystemBuilderCmds = ''
    ln -sv ${./.} $out/nixcfg
  '';
}
