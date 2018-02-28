{ pkgs, ... }:

let
  cfg = pkgs.writeText "configuration.nix" ''
    assert builtins.trace "Hey dummy, you're on your server! Use NixOps!" false;
    {}
  '';
in {
  nix.nixPath = [
    "nixos-config=${cfg}"
    "nixpkgs=/run/current-system/nixpkgs"
  ];
  system.extraSystemBuilderCmds = ''
    ln -sv ${pkgs.path} $out/nixpkgs
  '';
}
