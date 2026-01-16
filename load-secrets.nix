if builtins.pathExists ./secrets.nix then import ./secrets.nix else {
  token1 = "";
  token2 = "";
  token3 = "";
  snmp = "";
  hashedPw = "";
  weechats = [];
  publicIpv6Prefix = "";
  wifiPassword = "";
  grafanaCreds = {
    user = "admin";
    password = "admin";
  };
  oauth = {
    clientID = "";
    clientSecret = "";
    cookie.secret = "";
  };
  hass_token = "";
}
