{
  imports = [ ./core.nix ];
  users.extraUsers.clever.extraGroups = [ "wheel" "wireshark" "docker" ];
  time.timeZone = "America/Moncton";
}
