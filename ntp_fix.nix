{ ... }:

let
  overlay = self: super: {
    ntp = super.ntp.overrideAttrs (drv: {
      patches = [ (self.fetchpatch { url = "https://github.com/ntp-project/ntp/commit/881e427f3236046466bdb8235edf86e6dfa34391.patch"; sha256 = "0iqn12m7vzsblqbds5jb57m8cjs30rw8nh2xv8k2g8lbqbyk1k7s"; }) ];
    });
  };
in {
  #disabledModules = [ "services/networking/ntpd.nix" ];
  #imports = [ ./ntpd.nix ];
  nixpkgs.overlays = [ overlay ];
}
