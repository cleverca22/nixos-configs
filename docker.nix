{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.docker-compose ];
  fileSystems."/var/lib/docker" = { fsType = "zfs"; device = "amd/docker"; };
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
    };
  };
}
