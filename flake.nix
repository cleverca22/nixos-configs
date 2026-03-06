{
  inputs = {
    agenix.url = "github:ryantm/agenix";
    cachecache.inputs.nixpkgs.follows = "nixpkgs";
    cachecache.url = "github:cleverca22/cachecache";
    colmena.url = "github:zhaofengli/colmena";
    firmware = {
      flake = false;
      url = "path:/home/clever/apps/rpi/firmware2";
      #url = "github:raspberrypi/firmware";
    };
    hydra.url = "github:cleverca22/hydra/1ef6b5e7";
    iohk-ops = {
      flake = false;
      url = "github:input-output-hk/iohk-ops/65cb4d0b11d4504497aa334fb648716de2338ff5";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rpi-nixos.url = "github:cleverca22/rpi-nixos?rev=7dea0d95cfb31060b360833d5f60e0f5ebb4b84a";
    temp-daemon.inputs.nixpkgs.follows = "nixpkgs";
    temp-daemon.url = "github:cleverca22/temp_daemon";
    toxvpn.url = "github:cleverca22/toxvpn";
    utils.url = "github:numtide/flake-utils";
    #rpi-nixos.url = "path:/home/clever/apps/rpi/rpi-nixos";
    #nix.url = "path:/home/clever/apps/nix-master";
    zfs-utils = {
      url = "github:cleverca22/zfs-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { agenix, colmena, rpi-nixos, temp-daemon, firmware, cachecache, self, toxvpn, utils, nixpkgs, zfs-utils, iohk-ops, hydra }@attrs:
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
      #nix.package = nix.packages.aarch64-linux.nix;
      networking.firewall.enable = false;
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
      networking.hostName = "netboot-1";
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
  (utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
  {
    packages = {
      cachecache = cachecache.outputs.packages.${system}.cachecache;
      caller-id-client = nixpkgs.legacyPackages.${system}.callPackage ./caller-id-client.nix {};
      ghidra = nixpkgs.legacyPackages.${system}.ghidra.overrideAttrs (old: {
        patches = old.patches ++ [ ./ghidra-1147.patch ];
      });
      bircd = nixpkgs.legacyPackages.i686-linux.callPackage ./bircd.nix {};
    };
    hydraJobs = {
      cachecache = cachecache.outputs.packages.${system}.cachecache;
    } // lib.optionalAttrs (system == "x86_64-linux") {
      colmena = self.colmenaHive.toplevel;
      nixos = lib.mapAttrs (k: v: v.config.system.build.toplevel) self.nixosConfigurations;
    };
  } // lib.optionalAttrs (system == "aarch64-linux") {
    packages = arm64_images;
    hydraJobs = arm64_images;
  }
  )) // {
    colmenaHive = colmena.lib.makeHive (import ./hive.nix attrs);
    nixosConfigurations = {
      thinkpad = nixpkgs.lib.nixosSystem {
        modules = [ ./thinkpad.nix ];
        specialArgs.inputs = attrs;
        system = "x86_64-linux";
      };
      amd-nixos = nixpkgs.lib.nixosSystem {
        modules = [ ./amd-nixos.nix ];
        specialArgs.inputs = attrs;
        system = "x86_64-linux";
      };
      system76 = nixpkgs.lib.nixosSystem {
        modules = [ ./system76.nix ];
        specialArgs.inputs = attrs;
        system = "x86_64-linux";
      };
    };
  };
}
