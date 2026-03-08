{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.blueman ];
  hardware.bluetooth.enable = true;
  #services.blueman.enable = true;
  services.pulseaudio.package = pkgs.pulseaudioFull;
}
