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
    deployment.targetHost = "nas-deploy";
    deployment.hasFastConnection = true;
    deployment.keys = {
      oauth2_proxy = {
        keyFile = ./secrets/oauth2_proxy;
        destDir = "/var/keys";
      };
    };
  };
  router = {
    imports = [ ../router.nix ];
    deployment.targetHost = "10.0.0.1";
    deployment.hasFastConnection = true;
  };
}
