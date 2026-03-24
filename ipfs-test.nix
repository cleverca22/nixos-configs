{
  imports = [ ./ipfs.nix ];

  services.ipfs-cluster = {
    enable = true;
    consensus = "raft";
    openSwarmPort = true;
    secretFile = "/root/cluster.secret";
  };
}
