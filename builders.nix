let
  key = "/etc/nixos/keys/distro";
in {
  notos = {
    hostName = "192.168.2.142";
    maxJobs = 1;
    sshUser = "root";
    system = "armv6l-linux,armv7l-linux";
    sshKey = key;
    speedFactor = 2;
    supportedFeatures = [ "big-parallel" ];
  };
  rpi2 = {
    hostName = "192.168.2.126";
    maxJobs = 1;
    sshUser = "builder";
    system = "armv6l-linux,armv7l-linux";
    sshKey = key;
    speedFactor = 2;
    supportedFeatures = [ "big-parallel" ];
  };
  rpi4 = {
    hostName = "pi4";
    maxJobs = 4;
    sshUser = "pi";
    sshKey = key;
    speedFactor = 1;
    supportedFeatures = [ "big-parallel" ];
    systems = [ "armv7l-linux" "aarch64-linux" ];
  };
  pi400 = {
    hostName = "pi400";
    maxJobs = 1;
    sshUser = "pi";
    sshKey = key;
    speedFactor = 1;
    supportedFeatures = [ "big-parallel" ];
    systems = [ "armv7l-linux" "aarch64-linux" ];
  };
  amd = {
    hostName = "192.168.2.15";
    maxJobs = 5;
    speedFactor = 4;
    sshUser = "builder";
    system = "i686-linux,x86_64-linux"; #,armv6l-linux,armv7l-linux";
    sshKey = key;
    supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ];
  };
  darwin = {
    hostName = "du075.macincloud.com";
    maxJobs = 1;
    sshUser = "clever";
    system = "x86_64-darwin";
    sshKey = key;
  };
  system76 = {
    hostName = "builder@system76.localnet";
    systems = [
      "x86_64-linux" "i686-linux"
      #"aarch64-linux"
    ];
    sshKey = key;
    maxJobs = 4;
    speedFactor = 1;
    supportedFeatures = [ "big-parallel" "nixos-test" "kvm" ];
  };
}
