{
  networking.firewall.allowedTCPPorts = [ 5432 ];
  services = {
    postgresql = {
      authentication = ''
        host midnight-sync midnight-sync 172.18.0.0/16 scram-sha-256
      '';
      enable = true;
      enableTCPIP = true;
      ensureDatabases = [ "midnight-sync" ];
      ensureUsers = [
        {
          # ALTER ROLE "midnight-sync" LOGIN PASSWORD 'hunter2';
          name = "midnight-sync";
          ensureDBOwnership = true;
        }
      ];
    };
  };
}
