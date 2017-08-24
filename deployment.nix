{ foo }:
{
  eeepc1 = {
    deployment = {
      targetHost = "192.168.123.21";
    };
    imports = [ ./eeepc.nix ];
    _module.args.foo = foo;
  };
  eeepc2 = {
    deployment.targetHost = "192.168.123.22";
    imports = [ ./eeepc.nix ];
    _module.args.foo = foo;
  };
}
