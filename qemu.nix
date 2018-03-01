{ lib, ... }:

with lib;
{
  options = {
  };
  config = {
    nixpkgs = {
      overlays = [ (import ./overlays/qemu-user.nix) ];
    };
  };
}
