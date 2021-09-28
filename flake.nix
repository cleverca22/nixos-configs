{
  inputs = {
    cachecache.url = "github:cleverca22/cachecache";
    utils.url = "github:numtide/flake-utils";
    rpi-nixos.url = "github:cleverca22/rpi-nixos";
    #rpi-nixos.url = "path:/home/clever/apps/rpi/rpi-nixos";
    firmware = {
      flake = false;
      url = "path:/home/clever/apps/rpi/firmware2";
      #url = "github:raspberrypi/firmware";
    };
  };
  outputs = { rpi-nixos, firmware, cachecache, self, utils, nixpkgs }:
  let
    lib = (import nixpkgs { system = "x86_64-linux"; }).lib;
    common-config = { pkgs, ... }:
    {
      imports = [
        ./auto-gc.nix
      ];
      boot = {
        loader = {
          raspberryPi = {
            firmwareConfig = ''
              enable_uart=1
              uart_2ndstage=1
            '';
          };
        };
      };
      nixpkgs.overlays = [
        (self: super: {
          raspberrypifw = super.raspberrypifw.overrideAttrs (old: {
            src = firmware;
          });
        })
      ];
      environment.systemPackages = with pkgs; [
        screen libraspberrypi
        ncdu
      ];
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC34wZQFEOGkA5b0Z6maE3aKy/ix1MiK1D0Qmg4E9skAA57yKtWYzjA23r5OCF4Nhlj1CuYd6P1sEI/fMnxf+KkqqgW3ZoZ0+pQu4Bd8Ymi3OkkQX9kiq2coD3AFI6JytC6uBi6FaZQT5fG59DbXhxO5YpZlym8ps1obyCBX0hyKntD18RgHNaNM+jkQOhQ5OoxKsBEobxQOEdjIowl2QeEHb99n45sFr53NFqk3UCz0Y7ZMf1hSFQPuuEC/wExzBBJ1Wl7E1LlNA4p9O3qJUSadGZS4e5nSLqMnbQWv2icQS/7J8IwY0M8r1MsL8mdnlXHUofPlG1r4mtovQ2myzOx clever@nixos"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDM3J+b+IoVRaM3Mr8M0iHPNTdLvBCKDJyt3zuiYVi1PoEKHuEd+BT7CDhdWS0BrvWoXNfa6vFNnniXQHY4euZPoyVHhVphJ508p+TfBReHgJ41+UHU6TOjam7+bIek5LN+qTi8s/CXsTsn2e6wAhgwmKPLEt2NBGgDvwVlivBfmgpcob+hOwOaFHpOEv+W1jmsJYdnRsX9K4jWEx6EEj+qxUa53ubwCwjtJ0o+s59wT2b+4M3qakpu1UZgmmchn8RWmf9OYPRaSyO1TEaGdLnDrhBezwVXKDgulZ8VKbAowpPCMjuqzR28XyNJDVQJHudy9Ir7k0HKQwTUYsqgcV/h root@nas"
      ];
      services = {
        prometheus.exporters.node = {
          enable = true;
          enabledCollectors = [
            #"systemd"
            "tcpstat"
            "conntrack"
            "diskstats"
            #"entropy"
            "filefd"
            "filesystem"
            "loadavg"
            "meminfo"
            "netdev"
            #"netstat"
            "stat"
            "time"
            "ntp"
            "timex"
            "vmstat"
            #"logind"
            "interrupts"
            "ksmd"
            #"processes"
          ];
          #disabledCollectors = [ "hwmon" ];
        };
      };
      nix = {
        min-free-collection = true;
      };
    };
    arm64-config = {
      imports = [ common-config ];
      nix = {
        extraOptions = ''
          extra-platforms = armv6l-linux armv7l-linux
        '';
      };
    };
    netboot-1 = { pkgs, ... }: {
      imports = [ arm64-config ];
      rpi-netboot.lun = "iqn.2021-08.com.example:pi400.img";
    };
    netboot-2 = { pkgs, ... }: {
      imports = [ arm64-config ];
      rpi-netboot.lun = "iqn.2021-08.com.example:netboot-2.img";
    };
    arm64_images = {
      netboot-1 = rpi-nixos.packages.aarch64-linux.net_image_pi4.override { configuration = netboot-1; };
      netboot-2 = rpi-nixos.packages.aarch64-linux.net_image_pi4.override { configuration = netboot-2; };
    };
  in
  utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
  {
    packages.cachecache = cachecache.outputs.packages.${system}.cachecache;
    hydraJobs.cachecache = cachecache.outputs.packages.${system}.cachecache;
  } // lib.optionalAttrs (system == "aarch64-linux") {
    packages = arm64_images;
    hydraJobs = arm64_images;
  }
  );
}
