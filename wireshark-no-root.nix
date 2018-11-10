{ pkgs, ... }:

{
  users.users.clever.extraGroups = [ "wireshark" ];
  users.groups.wireshark.gid = 500;
  security.wrappers.dumpcap = {
    source = "${pkgs.wireshark}/bin/dumpcap";
    permissions = "u+xs,g+x";
    owner = "root";
    group = "wireshark";
  };
}
             
