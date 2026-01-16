{
  # nixops modify -d house deployments/house.nix -I nixpkgs=https://github.com/nixos/nixpkgs/archive/dae9cf6106d.tar.gz
  network = {
    enableRollback = true;
    description = "house deployment";
  };
  defaults = {
    documentation.enable = false;
    _module.args.inputs = (builtins.getFlake (toString ../.)).inputs;
  };
  nas = {
    imports = [ ../nas.nix ];
    #deployment.targetHost = "nas-deploy";
    deployment.targetHost = "10.0.0.11";
    #deployment.targetHost = "192.168.123.51";
    deployment.hasFastConnection = true;
  };
  router = {
    imports = [ ../router.nix ];
    deployment.targetHost = "10.0.0.1";
    #deployment.targetHost = "192.168.123.20";
    deployment.hasFastConnection = true;
  };
}
