{
  networking = {
    interfaces = {
      wlp0s20f3.useDHCP = true;
    };
    wireless = {
      enable = true;
      interfaces = [ "wlp0s20f3" ];
      extraConfigFiles = [ "/etc/wpa_supplicant.conf" ];
    };
    #supplicant.wwan0 = {
    #  configFile.path = "/etc/wpa_supplicant.conf";
    #};
  };
}
