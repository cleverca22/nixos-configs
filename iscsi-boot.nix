{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.boot.initrd.iscsi;
  fileSystems = attrValues config.fileSystems ++ config.swapDevices;
  iscsiDevs = filter (dev: dev.iscsi.enable) fileSystems;
  anyiscsi = fold (j: v: v || j.iscsi.enable) false iscsiDevs;
  iscsiOptions = {
    iscsi = {
      enable = mkOption { default = false; type = types.bool; description = "The block device is backed by iscsi, adds this device as a initrd entry"; };
      host = mkOption { example = "192.168.2.61"; type = types.string; description = "the iscsi target"; };
      lun = mkOption { example = "iqn.2015-01.com.example:san.img"; type = types.string; description = "the LUN to connect"; };
    };
  };
in
{
  options = {
    fileSystems = mkOption {
      options = [ iscsiOptions ];
    };
    swapDevices = mkOption {
      options = [ iscsiOptions ];
    };
    boot.initrd.iscsi = {
      initiatorName = mkOption {
        example = "iqn.2015-09.com.example:3255a7223b2";
        type = types.string;
        description = "the initiator name used when connecting";
      };

      netDev = mkOption {
        example = "eth0";
        type = types.string;
        description = "the network device the initrd will setup for iscsi";
      };
    }; # iscsi
  }; # options
  config = mkIf anyiscsi (
    let
      ipAddress = config.networking.interfaces.${cfg.netDev}.ipAddress;
      prefixLength = config.networking.interfaces.${cfg.netDev}.prefixLength;
      defaultGateway = config.networking.defaultGateway;
    in
    {
      boot.initrd = {
        kernelModules = [ "iscsi_tcp" ];
        availableKernelModules = [ "crc32c" ];
        preLVMCommands = ''
          export PATH=$PATH:${pkgs.openiscsi.iscsistart}/bin/
          ip link set ${cfg.netDev} up
          ip addr add ${ipAddress}/${toString prefixLength} dev ${cfg.netDev}
          # todo, make this optional
          ip route add via ${defaultGateway} dev ${cfg.netDev}
        '' + concatMapStrings (dev: "iscsistart -t ${dev.iscsi.lun} -a ${dev.iscsi.host} -i ${config.boot.initrd.iscsi.initiatorName} -g 0\n") iscsiDevs;
      }; # initrd
  }); # config
}
