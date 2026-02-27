let
  nas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHavqgrU0CMprEOyHQqdXfDnEvOlPudv2m/m9HHkCgB6";
  local = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzi6WhKzn+zxShsiqjlzqDndPsBqN4F2+n1E24CfSu3 clever@thinkpad";
  thin-router = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcx7QvkEoETl750N8qo+hH7n6ApOYAtnkkPTRmx4ngJ";
in {
  "oauth.age".publicKeys = [ nas local ];
  "hass_token.age".publicKeys = [ nas local ];
  "ircd-secret.age".publicKeys = [ local thin-router ];
  "temp-daemon.age".publicKeys = [ local thin-router ];
}
