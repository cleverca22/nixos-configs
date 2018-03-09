{ config, ... }:

{
  services.dd-agent = {
    enable = true;
    api_key = builtins.readFile ./datadog-api.secret;
    hostname = config.networking.hostName;
  };
}
