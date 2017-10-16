{ foo }:
{
  network = {
    enableRollback = true;
  };
  eeepc1 = {
    deployment = {
      targetHost = "192.168.123.21";
    };
    imports = [ ./eeepc.nix ];
    _module.args.foo = foo;
    services.toxvpn.localip = "192.168.123.21";
    fileSystems."/" = { device = "/dev/sda1"; fsType = "xfs"; };
  };
  eeepc2 = {
    deployment.targetHost = "192.168.2.159";
    deployment.hasFastConnection = true;
    imports = [ ./eeepc.nix ];
    _module.args.foo = foo;
    services.toxvpn.localip = "192.168.123.64";
    fileSystems = {
      "/boot" = { device = "/dev/sda1"; fsType = "ext2"; };
      "/" = { device = "/dev/sda3"; fsType = "ext2"; };
      "/home" = { device = "/dev/sda4"; fsType = "ext2"; };
    };
  };
  defaults = {
    imports = [ ./core.nix ];
  };
}
