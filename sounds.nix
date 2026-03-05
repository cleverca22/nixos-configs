{
  systemd.services = {
    startup-sound = {
      path = [ pkgs.alsa-utils ];
      script = ''
        aplay '/root/startup.wav'
      '';
      wantedBy = [ "multi-user.target" ];
    };
    startup-sound = {
      path = [ pkgs.alsa-utils ];
      script = ''
        aplay '/root/shutdown.wav'
      '';
      wantedBy = [ "shutdown.target" ];
    };
  };
}
