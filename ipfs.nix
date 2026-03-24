{
  services = {
    kubo = {
      autoMount = true;
      dataDir = "/var/lib/ipfs";
      enable = true;
      enableGC = true;
      localDiscovery = true;
      settings = {
        Addresses.API = "/ip4/0.0.0.0/tcp/5001";
        Experimental = {
          FilestoreEnabled = true;
        };
      };
    };
  };
}
