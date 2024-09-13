let
  secrets = import ./load-secrets.nix;
  WIFI = "wlan0";
in {
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
  };
  networking = {
    interfaces = {
      ${WIFI} = {
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
      interface = WIFI;
      ssid = "Family-nas";
      wpaPassphrase = secrets.wifiPassword;
    };
    dhcpd4 = {
      enable = true;
      interfaces = [ WIFI ];
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
