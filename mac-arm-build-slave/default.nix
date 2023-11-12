let
  linux_pkgs = import <nixpkgs> { system = "x86_64-linux"; config = {}; overlays = []; };
  host_pkgs = import <nixpkgs> { config = {}; overlays = []; };
  inherit (linux_pkgs) lib;
in lib.fix (self: {
  configuration = { ... }: {
    imports = [
      (linux_pkgs.path + "/nixos/modules/installer/netboot/netboot-minimal.nix")
      ../qemu.nix
    ];
    qemu-user = {
      arm = true;
      aarch64 = true;
    };
    systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
    users.users.root.openssh.authorizedKeys.keys = [ (builtins.readFile ~/.ssh/id_rsa.pub) ];
  };
  config = (import <nixpkgs/nixos> { system = "x86_64-linux"; configuration = self.configuration; }).config;
  go = host_pkgs.writeScript "go" ''
    #!${host_pkgs.stdenv.shell}
    ${host_pkgs.qemu}/bin/qemu-system-x86_64 -kernel ${self.config.system.build.kernel}/bzImage \
      -initrd ${self.config.system.build.netbootRamdisk}/initrd \
      -append "init=${builtins.unsafeDiscardStringContext self.config.system.build.toplevel}/init ${toString self.config.boot.kernelParams}" \
      -m 2048 \
      -net nic,netdev=user.0,model=virtio \
      -netdev user,id=user.0,hostfwd=tcp:127.0.0.1:2200-:22
  '';
})
