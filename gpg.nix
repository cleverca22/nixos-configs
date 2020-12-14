{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    keybase
    gnupg
  ];
  programs.gnupg.agent = {
    enable = false;
    enableSSHSupport = true;
  };
  # xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false
}
