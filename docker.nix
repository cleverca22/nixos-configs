{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.docker-compose ];
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
    };
  };
}
