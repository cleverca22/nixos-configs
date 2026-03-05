{ config, lib, pkgs, inputs, ... }:

let
  #flake = builtins.getFlake (toString ./.);
  #zfs-utils = builtins.getFlake "github:cleverca22/zfs-utils/master";
  #zfs-utils = flake.inputs.zfs-utils;
  zfs-utils = inputs.zfs-utils;
in {
  systemd = {
    services.zfs-fragmentation = {
      serviceConfig.ExecStart = "${zfs-utils.packages.x86_64-linux.zfs-fragmentation}/bin/zfs-fragmentation";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Restart = "always";
    };
  };
  networking.firewall.allowedTCPPorts = lib.mkIf config.exporters.openFirewall [ 9103 ];
}
