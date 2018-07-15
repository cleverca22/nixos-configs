{ config, ... }:

{
  services.dd-agent = {
    enable = true;
    api_key = (import ./secrets.nix).datadogKey;
    hostname = config.networking.hostName;
  };
}
