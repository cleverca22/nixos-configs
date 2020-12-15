{ lib, config, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.nix;
in {
  options.nix = {
    min-free = mkOption {
      type = types.int;
      default = 3;
    };
    max-free = mkOption {
      type = types.int;
      default = 6;
    };
    min-free-collection = mkEnableOption "min-free based garbage collection";
  };
  config = mkIf cfg.min-free-collection {
    nix.extraOptions = ''
      min-free = ${toString (1024*1024*1024*cfg.min-free)}
      max-free = ${toString (1024*1024*1024*cfg.max-free)}
    '';
  };
}
