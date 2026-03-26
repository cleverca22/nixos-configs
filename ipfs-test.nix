{
  imports = [ ./ipfs.nix ];

  services.ipfs-cluster = {
    enable = true;
    consensus = "crdt";
    openSwarmPort = true;
    secretFile = "/root/cluster.secret";
  };
}
