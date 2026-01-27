{
  boot = {
    blacklistedKernelModules = [
      "radeon"
    ];
    kernelParams = [
      "amdgpu.cik_support=1"
      "amdgpu.noretry=0"
      "amdgpu.pcie_gen_cap=0x4"
      "radeon.cik_support=0"
    ];
  };
  services.xserver.videoDrivers = [ "amdgpu" ];
}
