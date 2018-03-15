self: super:

{
  qemu-user-arm = self.callPackage ./qemu { user_arch = "arm"; };
  qemu-user-x86 = self.callPackage ./qemu { user_arch = "x86_64"; };
  qemu-user-arm64 = self.callPackage ./qemu { user_arch = "aarch64"; };
  qemu-user-riscv32 = self.callPackage ./qemu { user_arch = "riscv32"; };
  qemu-user-riscv64 = self.callPackage ./qemu { user_arch = "riscv64"; };
  patchedNix = self.nixUnstable.overrideAttrs (drv: {
    patches = [ ./upgrade.patch ];
  });
}
