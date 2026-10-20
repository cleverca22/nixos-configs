{ config, ... }:

{
  networking = {
    firewall = {
      allowedTCPPorts = [
        config.services.teamspeak3.fileTransferPort
        config.services.teamspeak3.queryPort
      ];
      allowedUDPPorts = [
        config.services.teamspeak3.defaultVoicePort
      ];
    };
  };
  services = {
    teamspeak3 = {
      enable = true;
    };
  };
}
