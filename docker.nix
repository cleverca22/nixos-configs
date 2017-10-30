{ ... }:

{
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
    };
  };
}
