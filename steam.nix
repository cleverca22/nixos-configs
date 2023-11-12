{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.steam pkgs.steamcmd pkgs.steam-run ];
  hardware.pulseaudio.support32Bit = true;
  hardware.opengl.driSupport32Bit = true;
}
