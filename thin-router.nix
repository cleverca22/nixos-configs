{ pkgs, ... }:

{
  imports = [
    ./bircd_module.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "uas" "sd_mod" "sdhci_pci" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiInstallAsRemovable = false;
        efiSupport = true;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems = {
    "/" = { device = "router/root"; fsType = "zfs"; };
    "/nix" = { device = "router/nix"; fsType = "zfs"; };
    "/home" = { device = "router/home"; fsType = "zfs"; };
    "/boot" = { device = "/dev/disk/by-uuid/5D1A-4005"; fsType = "vfat"; options = [ "fmask=0022" "dmask=0022" ]; };
  };

  environment.systemPackages = with pkgs; [
    efibootmgr
    lshw
    net-tools
    pciutils
    screen
    usbutils
  ];

  hardware.cpu.intel.updateMicrocode = true;

  networking = {
    defaultGateway = "10.0.0.1";
    hostId = "491ddec8";
    hostName = "thin-router";
    interfaces = {
      enp1s0 = {
        useDHCP = false;
        mtu = 1500;
        ipv4.addresses = [
          {
            address = "10.0.0.60";
            prefixLength = 24;
          }
        ];
      };
    };
    nameservers = [ "10.0.0.1" ];
    networkmanager.enable = false;
    search = [ "localnet" ];
  };

  services = {
    bircd = {
      enable = true;
    };
    openssh.enable = true;
    xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.xfce.enable = true;
    };
  };

  users.users.clever = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "25.11";
  deployment.targetHost = "10.0.0.60";
}
