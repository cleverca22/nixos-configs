{ pkgs, lib, ... }:

let
  pkgs2_src = pkgs.fetchFromGitHub {
    owner = "nixos";
    repo = "nixpkgs";
    rev = "831ef4756e3";
    sha256 = "1rbfgfp9y2wqn1k0q00363hrb6dc0jbqm7nmnnmi9az3sw55q0rv";
  };
  pkgs2 = import pkgs2_src { config = {}; overlays = []; };
  weechat = pkgs2.weechat;
  slack_plugin_src = pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "slack-irc-gateway";
    rev = "eb4b3ca";
    sha256 = "1xvwrd59a0xj0jhk0y61fwvzfzf51s95haqykk14gb3d49w3hx88";
  };
  wee-slack = import "${slack_plugin_src}/wee-slack.nix";
  mkService = name: {
    "weechat-${name}" = {
      description = "weechat - ${name}";
      wantedBy = [ "multi-user.target" ];
      path = [ weechat pkgs.tmux ];
      preStart = ''
        mkdir -pv /var/lib/weechat-${name}/.weechat/python/autoload/
        cp -vf ${wee-slack}/wee_slack.py /var/lib/weechat-${name}/.weechat/python/autoload/wee_slack.py
        chown -R ${name} /var/lib/weechat-${name}
      '';
      script = ''
        tmux new-session -d -s ${name} weechat
      '';
      preStop = ''
        tmux kill-session -t ${name}
      '';
      serviceConfig = {
        User = name;
        KillMode = "process";
        Restart = "always";
        WorkingDirectory = "/var/lib/weechat-${name}";
        RemainAfterExit = "yes";
      };
    };
  };
  mkUser = name: {
    "${name}" = {
      createHome = true;
      home = "/var/lib/weechat-${name}";
      isNormalUser = true;
    };
  };
  secrets = import ./secrets.nix;
  configs = secrets.weechats;
in {
  systemd.services = lib.foldl' (state: name: state // (mkService name)) {} configs;
  users.extraUsers = lib.foldl' (state: name: state // (mkUser name)) {} configs;
  environment.systemPackages = [ pkgs.tmux weechat ];
}
