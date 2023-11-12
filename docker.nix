{ pkgs, ... }:

{
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
    };
  };
  environment.systemPackages = [ pkgs.docker-compose ];
}
