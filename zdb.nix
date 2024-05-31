{ pkgs, ... }:

let
  flake = builtins.getFlake (toString ./.);
  zfs-utils = flake.inputs.zfs-utils;
in {
  systemd = {
    services.zfs-fragmentation = {
      serviceConfig.ExecStart = "${zfs-utils.packages.x86_64-linux.zfs-fragmentation}/bin/zfs-fragmentation";
      wantedBy = [ "multi-user.target" ];
    };
  };
  networking.firewall.allowedTCPPorts = [ 9103 ];
}
