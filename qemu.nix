{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.qemu-user;
  archMagics = {
    x86 = "\x03\x00";
    arm = "\x28\x00";
    x86_64 = "\x3e\x00";
    aarch64 = "\xb7\x00";
    riscv = "\xf3\x00"; # Same ID for 32 and 64 bit
  };
  makeBinfmt = interpreter: bit64: archMagic: {
    inherit interpreter;
    magicOrExtension = ''\x7fELF${if bit64 then "\x02" else "\x01"}\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\${archMagic}'';
    mask = ''\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\x00\xff\xfe\xff\xff\xff'';
  };
  arm = makeBinfmt "${pkgs.qemu-user-arm}/bin/qemu-arm" false archMagics.arm;
  x86_64 = makeBinfmt "${pkgs.qemu-user-x86}/bin/qemu-x86_64" true archMagics.x86_64;
  aarch64 = makeBinfmt "${pkgs.qemu-user-arm64}/bin/qemu-aarch64" true archMagics.aarch64;
  riscv32 = makeBinfmt "${pkgs.qemu-user-riscv32}/bin/qemu-riscv32" false archMagics.riscv;
  riscv32 = makeBinfmt "${pkgs.qemu-user-riscv64}/bin/qemu-riscv64" true archMagics.riscv;
in {
  options = {
    qemu-user = {
      arm = mkEnableOption "enable 32bit arm emulation";
      x86 = mkEnableOption "enable 64bit x86 emulation";
      aarch64 = mkEnableOption "enable 64bit arm emulation";
      riscv32 = mkEnableOption "enable 32bit risc-v emulation";
      riscv64 = mkEnableOption "enable 64bit risc-v emulation";
    };
    nix.supportedPlatforms = mkOption {
      type = types.listOf types.str;
      description = "extra platforms that nix will run binaries for";
      default = [];
    };
  };
  config = mkIf (cfg.arm || cfg.aarch64) {
    nixpkgs = {
      overlays = [ (import ./overlays/qemu-user.nix) ];
    };
    boot.binfmtMiscRegistrations =
      optionalAttrs cfg.arm { inherit arm; } //
      optionalAttrs cfg.x86 { inherit x86; } //
      optionalAttrs cfg.aarch64 { inherit aarch64; } //
      optionalAttrs cfg.riscv32 { inherit riscv32; } //
      optionalAttrs cfg.riscv64 { inherit riscv64; };
    nix.supportedPlatforms =
      (optionals cfg.arm [ "armv6l-linux" "armv7l-linux" ]) ++
      (optional cfg.x86 "x86_64-linux") ++
      (optional cfg.aarch64 "aarch64-linux") ++
      (optional cfg.riscv32 "riscv32-linux") ++
      (optional cfg.riscv64 "riscv64-linux");
    nix.package = pkgs.patchedNix;
    nix.extraOptions = ''
      build-extra-platforms = ${toString config.nix.supportedPlatforms}
    '';
    nix.sandboxPaths = [ "/run/binfmt" ] ++ 
      (optional cfg.arm "${pkgs.qemu-user-arm}") ++
      (optional cfg.x86 "${pkgs.qemu-user-x86}") ++
      (optional cfg.aarch64 "${pkgs.qemu-user-arm64}") ++
      (optional cfg.riscv32 "${pkgs.qemu-user-riscv32}") ++
      (optional cfg.riscv64 "${pkgs.qemu-user-riscv64}");
  };
}
