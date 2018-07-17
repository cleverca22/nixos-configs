{ config, ... }:

{
  services.dd-agent = {
    enable = true;
    api_key = (import ./load-secrets.nix).datadogKey;
    hostname = config.networking.hostName;
  };
}
