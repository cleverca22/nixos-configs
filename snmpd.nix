{ pkgs, ... }:

let
  secrets = import ./secrets.nix;
in
{
  systemd.services.snmpd = let
    snmpconfig = pkgs.writeTextFile {
      name = "snmpd.conf";
      text = ''
        rocommunity ${secrets.snmp}
        disk / 10000
        extend cputemp ${pkgs.stdenv.shell} -c "${pkgs.acpi}/bin/acpi -t|egrep -o '[0-9\.]{3,}'"
        extend conntrack ${pkgs.stdenv.shell} -c "cat /proc/net/nf_conntrack | wc -l"
      '';
    };
  in {
    description = "net-snmp daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.net_snmp}/bin/snmpd -f -c ${snmpconfig}";
      KillMode = "process";
      Restart = "always";
    };
  };
}
