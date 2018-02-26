let
  key = "/etc/nixos/keys/distro";
in {
  rpi2 = {
    hostName = "192.168.2.126";
    maxJobs = 1;
    sshUser = "builder";
    system = "armv6l-linux,armv7l-linux";
    sshKey = key;
    speedFactor = 2;
    supportedFeatures = [ "big-parallel" ];
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
}
