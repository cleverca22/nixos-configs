{
  networking = {
    wireguard = {
      interfaces = {
        wg0 = {
          privateKeyFile = "/root/blockfrost.wg.sec";
          ips = [ "10.6.0.2/16" ];
          listenPort = 51822;
          peers = [
            {
              allowedIPs = [ "10.6.0.1/32" ];
              publicKey = "bsy4wbh7sleHwdp2C0Br52xqBPEoPbR2caN9bTDQglc=";
              endpoint = "45.63.41.160:51822";
            }
          ];
        };
      };
    };
  };
}
