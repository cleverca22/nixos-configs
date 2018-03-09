{ pkgs, lib, ... }:

let
  slack_plugin_src = pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "slack-irc-gateway";
    rev = "4f3497d011c7686d38413c096a7cdb076f2060ee";
    sha256 = "0msxf7wqf4a8hnwhxc87awc5kzx8m2gz9cx6z27jnmhv3i3j61bj";
  };
  wee-slack = import "${slack_plugin_src}/wee-slack.nix";
  mkService = name: {
    "weechat-${name}" = {
      description = "weechat - ${name}";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.weechat pkgs.tmux ];
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
  configs = [ "example" ];
in {
  systemd.services = lib.foldl' (state: name: state // (mkService name)) {} configs;
  users.extraUsers = lib.foldl' (state: name: state // (mkUser name)) {} configs;
  environment.systemPackages = [ pkgs.tmux pkgs.weechat ];
}
