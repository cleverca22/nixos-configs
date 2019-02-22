{ pkgs, ... }:

let
  overlay = self: super: {
    plex-media-player = super.plex-media-player.overrideAttrs (old: {
      # the default mode is dbus, which supports shutdown/reboot/suspend via logind, but no dpms control
      # x11 mode supports dpms control via xdg-screensaver
      cmakeFlags = old.cmakeFlags ++ [ "-DLINUX_X11POWER=ON" ];
    });
  };
in {
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
  environment.systemPackages = with pkgs; [ plex-media-player ratpoison pavucontrol syncplay mpv teamspeak_client ];
  nixpkgs.overlays = [ overlay ];
  users.extraUsers.media = {
    isNormalUser = true;
    uid = 1100;
  };
}
