{
  networking = {
    firewall.allowedUDPPorts = [ 51822 ];
    wireguard = {
      interfaces = {
        wg0 = {
          privateKeyFile = "/root/blockfrost.wg.sec";
          ips = [ "10.6.0.2/16" ];
          listenPort = 51822;
          peers = [
            { # dbsyncsnap1.core
              allowedIPs = [ "10.6.0.1/32" ];
              publicKey = "bsy4wbh7sleHwdp2C0Br52xqBPEoPbR2caN9bTDQglc=";
              endpoint = "45.63.41.160:51822";
            }
            { # thinkpad
              allowedIPs = [ "10.6.0.4/32" ];
              publicKey = "3uT1mDtRHl+HCvzsXo8y1TtJZwb62iEedghCDxXx2l4=";
              endpoint = "10.0.0.112:51822";
            }
          ];
        };
      };
    };
  };
}
