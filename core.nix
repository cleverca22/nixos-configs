{ pkgs, config, ... }:

let
  passwords = import ./passwords.nix;
in {
  environment.systemPackages = with pkgs; [
    sqlite-interactive screen nix-repl
    (if config.services.xserver.enable then gitAndTools.gitFull else git)
    ncdu
  ];
  nixpkgs = {
    config = {
      allowUnfree = true;
      vim.ruby = false;
    };
  };
  programs = {
    screen.screenrc = ''
      defscrollback 5000
      caption always
      termcapinfo xterm 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'
      term xterm-256color
      defbce "on"
    '';
  };
  users = {
    extraUsers = {
      clever = {
        isNormalUser = true;
        uid = 1000;
        initialHashedPassword = passwords.hashedPw;
      };
    };
    extraGroups = {
      wireshark.gid = 500;
    };
  };
  services = {
    openssh = {
      enable = true;
    };
  };
}
