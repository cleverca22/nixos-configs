{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager = {
      slim = {
        enable = true;
        autoLogin = true;
        defaultUser = "media";
      };
      sessionCommands = ''
        ratpoison &
        exec plexmediaplayer --fullscreen --tv
      '';
    };
  };
  hardware.pulseaudio = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [ plex-media-player ratpoison pavucontrol ];
  users.extraUsers.media = {
    isNormalUser = true;
    uid = 1100;
  };
}
