{
  # export NIX_PATH=nixpkgs=https://github.com/nixos/nixpkgs/archive/8bce347f02f6bd606ec1822f0ba9b94d7f139071.tar.gz
  network = {
    enableRollback = true;
    description = "router deployment";
  };
  router = {
    imports = [
      ../router.nix
    ];
    deployment = {
      targetHost = "192.168.2.1";
    };
  };
}
