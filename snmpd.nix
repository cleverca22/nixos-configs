{ pkgs, ... }:

let
  passwords = import ./passwords.nix;
in
{
  systemd.services.snmpd = let
    snmpconfig = pkgs.writeTextFile {
      name = "snmpd.conf";
      text = ''
        rocommunity ${passwords.snmp}
        disk / 10000
        extend cputemp ${pkgs.stdenv.shell} -c "${pkgs.acpi}/bin/acpi -t|egrep -o '[0-9\.]{3,}'"
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