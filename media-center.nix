{ pkgs, ... }:

{
  services = {
    pipewire.enable = false;
    pulseaudio = {
      enable = true;
    };
    displayManager = {
      autoLogin = {
        enable = true;
        user = "media";
      };
      sddm.enable = true;
    };
    xserver = {
      enable = true;
      displayManager = {
        sessionCommands = ''
          ratpoison &
          exec plexmediaplayer --fullscreen --tv > ~/.plexlogs
        '';
      };
    };
  };
  environment.systemPackages = with pkgs; [
    ratpoison pavucontrol
    #syncplay
    mpv
    #teamspeak_client
  ];
  users.extraUsers.media = {
    isNormalUser = true;
    uid = 1100;
    extraGroups = [ "audio" ];
  };
  networking.firewall.allowedTCPPorts = [
    8060 # the plex frontend does upnp things
    32433 # plex-media-player
  ];
}
