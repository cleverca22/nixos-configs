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
    nat = {
      enable = true;
      externalInterface = "eth0";
      internalIPs = [
        "192.168.3.0/24"
      ];
      internalInterfaces = [ WIFI ];
    };
  };
  services = {
    hostapd = {
      enable = true;
      radios = {
        ${WIFI} = {
          countryCode = "US";
          channel = 11;
          networks = {
            ${WIFI} = {
              bssid = "a8:e2:91:97:5a:4b";
              ssid = "Family-nas";
              authentication.wpaPassword = secrets.wifiPassword;
              authentication.mode = "wpa2-sha1";
            };
          };
        };
      };
    };
    kea.dhcp4 = {
      enable = true;
      settings = {
        interfaces-config.interfaces = [ WIFI ];
        lease-database = {
          name = "/var/lib/kea/dhcp4.leases";
          persist = true;
          type = "memfile";
        };
        rebind-timer = 3600 * 10;
        renew-timer = 3600;
        valid-lifetime = 3600 * 24;
        subnet4 = [
          {
            id = 1;
            subnet = "192.168.3.0/24";
            pools = [
              {
                pool = "192.168.3.100 - 192.168.3.200";
              }
            ];
            option-data = [
              {
                name = "routers";
                data = "192.168.3.1";
              }
              {
                name = "domain-name-servers";
                data = "10.0.0.1";
              }
              {
                name = "domain-search";
                data = "localnet";
              }
            ];
          }
        ];
      };
    };
  };
}
