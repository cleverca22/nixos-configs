{ pkgs, lib, ... }:

let
  rev = "cb5f8262e3eedec31866d958400cb5f962320a7e";
  cardanoSrc = pkgs.fetchFromGitHub {
    owner = "input-output-hk";
    repo = "cardano-sl";
    inherit rev;
    sha256 = "0z5ccs95q05nhnmp16g7nbc2pqqbmsqlrif1giyjdzn8jxh7wy7f";
  };
  cardano = import cardanoSrc { gitrev = rev; };
  topofile = pkgs.writeText "topology.yaml" ''
    wallet:
      relays: [[{ host: relays.cardano-mainnet.iohk.io }]]
      valency: 1
      fallbacks: 7
  '';
  topofile2 = pkgs.writeText "topology.yaml" ''
    nodes:
      relay1:
        region: ap-northeast-1
        zone: ap-northeast-1a
        type: relay
        org: IOHK
        host: nas.localnet
        dynamic-subscribe: [[{ host: relays.cardano-mainnet.iohk.io }]]
        kademlia: false
        public: true
  '';
  myip = "99.192.62.202";
in {
  config = lib.mkIf true {
    users.users.cardano = {
      home = "/var/lib/cardano";
      createHome = true;
      isSystemUser = true;
    };
    networking.firewall.allowedTCPPorts = [ 3002 ];
    systemd.services.cardano-relay = {
      wantedBy = [ "multi-user.target" ];
      path = [ cardano.cardano-sl-node-static ];
      serviceConfig = {
        User = "cardano";
        WorkingDirectory = "/var/lib/cardano";
      };
      script = ''
        cardano-node-simple --configuration-key mainnet_full --configuration-file ${cardano.cardano-sl-config}/lib/configuration.yaml --topology ${topofile2} --node-id relay1 --listen 0.0.0.0:3002 --address ${myip}:3000 --statsd-server 127.0.0.1:8125 --metrics +RTS -T -RTS
      '';
    };
  };
}
