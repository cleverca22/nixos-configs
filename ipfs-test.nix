{
  imports = [ ./ipfs.nix ];

  nixpkgs.overlays = [
    (self: super: {
      ipfs-cluster = super.ipfs-cluster.override { buildGoModule = super.buildGo126Module; };
    })
  ];
  services.ipfs-cluster = {
    enable = true;
    consensus = "crdt";
    openSwarmPort = true;
    secretFile = "/root/cluster.secret";
  };
}
