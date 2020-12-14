{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.blueman ];
  #services.blueman.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.bluetooth.enable = true;
}
