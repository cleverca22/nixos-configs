self: super:

{
  qemu-user-arm = self.callPackage ./qemu { user_arch = "arm"; };
  qemu-user-x86 = self.callPackage ./qemu { user_arch = "x86_64"; };
  qemu-user-arm64 = self.callPackage ./qemu { user_arch = "aarch64"; };
  patchedNix = self.nixUnstable.overrideAttrs (drv: {
    patches = [ ./upgrade.patch ];
  });
}
