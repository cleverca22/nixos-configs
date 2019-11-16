let
  secrets = import ./load-secrets.nix;
in {
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
  };
  networking = {
    interfaces = {
      wlp2s0 = {
        ipv4.addresses = [
          {
            address = "192.168.3.1";
            prefixLength = 24;
          }
        ];
      };
    };
  };
  services = {
    hostapd = {
      enable = true;
      interface = "wlp2s0";
      ssid = "Family-nas";
      wpaPassphrase = secrets.wifiPassword;
    };
    dhcpd4 = {
      enable = true;
      interfaces = [ "wlp2s0" ];
      extraConfig = ''
        authoritative;
        subnet 192.168.3.0 netmask 255.255.255.0 {
          option routers 192.168.3.1;
          option broadcast-address 192.168.3.255;
          option domain-name-servers 192.168.2.1;
          range 192.168.3.100 192.168.3.200;
        }
      '';
    };
  };
}
