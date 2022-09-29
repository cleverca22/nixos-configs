{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.steam ];
  hardware.pulseaudio.support32Bit = true;
  hardware.opengl.driSupport32Bit = true;
}
