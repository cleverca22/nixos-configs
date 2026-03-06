{ config, lib, pkgs, ... }:

{
  hardware.alsa.enable = true;
  systemd.services = {
    startup-sound = {
      path = [ pkgs.alsa-utils ];
      script = ''
        sleep 3
        cat /proc/asound/cards
        aplay '/root/startup.wav' -D hw:0,0
      '';
      wantedBy = [ "multi-user.target" ];
      after = [ "sound.target" ];
      requires = [ "sound.target" ];
    };
    shutdown-sound = {
      path = [ pkgs.alsa-utils ];
      script = ''
        aplay '/root/shutdown.wav' -D hw:0,0
      '';
      wantedBy = [ "shutdown.target" "reboot.target" ];
    };
  };
}
