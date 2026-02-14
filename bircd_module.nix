{ config, lib, inputs, pkgs, ... }:

let
  cfg = config.services.bircd;
  bircd_ini = builtins.toFile "bircd.ini" ''
    AccountLen=17
    AutoUserMode=
    AwayLen=200
    ChanNameLen=200
    ChannelMode=nt
    Clearmode=1
    DelayedJoin=1
    DNSlookup=1
    DNSserver=127.0.0.1
    FloodBufSize=1024
    GlobalOperFailed=1
    HalfOp=0
    HeadInSand=0
    HeadInSandDesc=my IRC network
    HeadInSandGline=1
    HeadInSandKillWho=0
    HeadInSandMapStr=has been disabled
    HeadInSandName=*.mynet.org
    Hub=1
    Ident=1
    IrcuLusers=1
    ListSecretChannels=1
    LookupNotice=1
    LookupTimeout=6
    MaxBans=45
    MaxClients=512
    MaxJoins=20
    MaxNick=40
    MaxTopic=300
    MaxTotalSendq=30000000
    NetriderKick=1
    NetworkName=MikesNet
    NoDie=1
    NoRestart=0
    NoSpoof=1
    NoThrottle=0
    OperGline=2
    OperJoinOverride=1
    OperModek=1
    OperNoFlood=1
    OperNoTargetLimit=1
    OperNoWhoLimit=1
    OperOnlyCmds=
    OpMode=1
    Penalty=1
    QnetModes=1
    QuitPrefix=1
    RandSeed=12345678
    RelaxedChannelChars=0
    ReliableClock=1
    ResendModes=1
    RestrictCreate=0
    RestrictPrivate=0
    SecretNotices=1
    SecretStats=aAbBcCdDeEfFgGhHiIkKlLmMnNoOpPqQrRsStTUvVwWxXyYzZ
    SecretUserip=0
    SecretWallops=1
    Send005=1
    SetHost=1
    SetHostAuto=1
    SetHostFreeform=1
    SetHostUser=1
    ShortMotd=0
    ShortMotdStr=
    ShortNumerics=0
    SignalPort=46789
    SnoDefaultOper=1919
    StartTargets=10
    SvsJoin=1
    SvsNick=1
    TopicBurst=1
    u21011features=1
    UserModeHacking=1
    VhostAccountStr=.users.earthtools.ca
    VHostCryptStr=this is a secret
    VHostQuitReason=Host Change
    VHostStyle=1
  '';

  ircd_conf = builtins.toFile "ircd.conf" ''
    M:thin-router.earthtools.ca::clever's irc server::11

    # ports to listen on
    P::::6667
    P::::7000
    P:::S:4400

    # standard Y-lines
    # client class: ping freq 90, no autoconnect, no limit on connections, 80k sendQ
    # oper class (same as client class)
    # server class: ping freq 30, connect freq 300 secs, no limit on connections, 3M sendQ

    Y:1:90:0:0:80000
    Y:5:30:0:10:80000
    Y:6:30:0:2:80000
    Y:10:90:0:0:750000
    Y:20:60:60:0:3000000
    Y:21:120:5:0:3000000

    # standard I-line, accept everyone, max. 3 clones
    I:*@*:10:*@*::1

    # standard I-line for IPv6 connections: max 5 clones from a /48
    I:"*@::/0":5/48:nomatch::1

    # C-line for accepting services connection on same machine

    U:services.mikesnet.net:ChanServ,NickServ,MemoServ,OpServ,AuthServ:

    # every server can be hub
    H:*::*:
  '';
in {
  imports = [
    inputs.agenix.nixosModules.default
  ];
  options = {
    services.bircd = {
      enable = lib.mkEnableOption "enable BIRCD";
    };
  };
  config = lib.mkIf cfg.enable {
    age.secrets = {
      ircd-secret = {
        file = ./secrets/ircd-secret.age;
        owner = "bircd";
      };
    };
    networking.firewall.allowedTCPPorts = [
      6667
    ];
    systemd.services.bircd = {
      preStart = ''
        mkdir -pv /run/bircd/
        cd /run/bircd/
        cp -v ${inputs.self.packages.x86_64-linux.bircd}/bin/bircd bircd
        cp -v ${bircd_ini} bircd.ini
        cat ${ircd_conf} ${config.age.secrets.ircd-secret.path} > ircd.conf

        chown -Rv bircd:bircd /run/bircd
      '';
      serviceConfig = {
        ExecStart = "/run/bircd/bircd -foreground";
        PermissionsStartOnly = true;
        User = "bircd";
      };
      wantedBy = [ "multi-user.target" ];
    };

    users.users.bircd = {
      isSystemUser = true;
      group = "bircd";
    };
    users.groups.bircd = {};
  };
}
