{
  networking = {
    firewall.allowedUDPPorts = [ 51822 ];
    wireguard = {
      interfaces = {
        wg0 = {
          privateKeyFile = "/root/blockfrost.wg.sec";
          ips = [ "10.6.0.4/16" ];
          listenPort = 51822;
          peers = [
            { # dbsyncsnap1.core
              allowedIPs = [ "10.6.0.1/32" ];
              publicKey = "bsy4wbh7sleHwdp2C0Br52xqBPEoPbR2caN9bTDQglc=";
              endpoint = "45.63.41.160:51822";
            }
            { # amd
              allowedIPs = [ "10.6.0.2/32" ];
              publicKey = "ddUVGbhwh0eknKBi5ECFEls7ZhADs+x9t6aTQ90NGXc=";
              endpoint = "10.0.0.15:51822";
            }
          ];
        };
      };
    };
  };
}
