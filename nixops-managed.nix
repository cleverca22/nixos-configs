{ pkgs, ... }:

let
  cfg = pkgs.writeText "configuration.nix" ''
    assert builtins.trace "Hey dummy, you're on your server! Use NixOps!" false;
    {}
  '';
in {
  nixpkgs.overlays = [ (import ./overlays/qemu) ];
  nix.nixPath = [
    "nixos-config=${cfg}"
    "nixpkgs=/run/current-system/nixpkgs"
    "nixpkgs-overlays=/run/current-system/overlays"
  ];
  system.extraSystemBuilderCmds = ''
    ln -sv ${pkgs.path} $out/nixpkgs
    ln -sv ${./overlays} $out/overlays
  '';
}
