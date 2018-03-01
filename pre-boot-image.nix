rec {
  configuration = {
  };
  eval = import <nixpkgs/nixos> { inherit configuration; };
  pkgs = import <nixpkgs> {};
  build = pkgs.runCommand "PBA" {} ''
    mkdir $out
    cp ${eval.config.system.build.kernel}/bzImage $out/
    cp ${eval.config.system.build.initialRamdisk}/initrd $out/initrd
    echo ${toString eval.config.boot.kernelParams} > $out/kernelParams
  '';
}
