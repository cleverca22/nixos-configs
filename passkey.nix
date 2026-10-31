{
  services = {
    nginx = {
      virtualHosts = {
        "amd.earthtools.ca" = {
          root = "/var/www/html/";
          locations = {
            "/grafana/" = {
              proxyPass = "http://10.0.0.11:3000/";
              extraConfig = ''
                proxy_set_header Host "monitoring.earthtools.ca";
                proxy_set_header X-Email "passkey@earthtools.ca";
              '';
            };
            "= /passkey/auth" = {
              proxyPass = "http://localhost:3001/passkey/auth";
              extraConfig = ''
                auth_request off;
                # nginx auth_request includes headers but not body
                proxy_set_header Content-Length   "";
                proxy_pass_request_body           off;
              '';
            };
            "/passkey/" = {
              proxyPass = "http://localhost:3001";
              extraConfig = ''
                auth_request off;
              '';
            };
            "@redirectToPasskey" = {
              return = "307 http://amd.localnet/passkey/?rd=$scheme://$host$request_uri";
              extraConfig = ''
                auth_request off;
              '';
            };
          };
          extraConfig = ''
            auth_request /passkey/auth;
            auth_request_set $new_cookie $sent_http_set_cookie;
            add_header Set-Cookie $new_cookie;
            error_page 401 = @redirectToPasskey;
          '';
        };
      };
    };
  };
}
