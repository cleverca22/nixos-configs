{ pkgs, ... }:

{
  systemd = {
    services.zfs-fragmentation = {
      script = ''
        socat TCP-LISTEN:9103,reuseaddr,fork SYSTEM:"echo HTTP/1.0 200; echo Content-Type\: text/plain; echo; cat /proc/spl/kstat/zfs/{amdnew,naspool,tank}/fragmentation"
      '';
      path = [ pkgs.socat ];
      wantedBy = [ "multi-user.target" ];
    };
  };
  networking.firewall.allowedTCPPorts = [ 9103 ];
}
