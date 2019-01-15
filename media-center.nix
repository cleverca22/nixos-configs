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
        plexmediaplayer --fullscreen --tv
      '';
    };
  };
  environment.systemPackages = [ pkgs.plex-media-player ];
  users.extraUsers.media = {
    isNormalUser = true;
    uid = 1100;
  };
}
