{ pkgs, config, ... }:

let
  cfg = config.programs.gnupg;
in {
  environment.systemPackages = with pkgs; [
    keybase
    gnupg
    #pinentry-gnome
  ];
  programs.gnupg.agent = {
    enable = true;
    #enableSSHSupport = true;
    #pinentryFlavor = "gtk2";
  };
  # xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false
  systemd.user.sockets.gpg-agent-ssh.wantedBy = [ "sockets.target" ];
    environment.extraInit = ''
      if [ -z "$SSH_AUTH_SOCK" ]; then
        export SSH_AUTH_SOCK=$(${cfg.package}/bin/gpgconf --list-dirs agent-ssh-socket)
      fi
    '';
}
