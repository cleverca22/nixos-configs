{
  services = {
    kubo = {
      autoMount = true;
      dataDir = "/var/lib/ipfs";
      enable = true;
      enableGC = true;
      localDiscovery = true;
      settings = {
        Experimental = {
          FilestoreEnabled = true;
        };
      };
    };
  };
}
