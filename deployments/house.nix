{
  # nixops modify -d house deployments/house.nix -I nixpkgs=https://github.com/nixos/nixpkgs/archive/dae9cf6106d.tar.gz
  network = {
    enableRollback = true;
    description = "house deployment";
  };
  defaults = {
    documentation.enable = false;
  };
  nas = {
    imports = [ ../nas.nix ];
    deployment.targetHost = "192.168.2.11";
  };
  router = {
    imports = [ ../router.nix ];
    deployment.targetHost = "192.168.2.1";
  };
}
