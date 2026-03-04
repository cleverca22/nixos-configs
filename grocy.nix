{
  services = {
    grocy = {
      enable = true;
      hostName = "grocy.earthtools.ca";
      nginx.enableSSL = false;
      settings.currency = "CAD";
    };
  };
}
