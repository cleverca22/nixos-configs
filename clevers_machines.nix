{
  imports = [ ./core.nix ];
  users.extraUsers.clever.extraGroups = [ "wheel" "wireshark" ];
  time.timeZone = "America/Moncton";
}
