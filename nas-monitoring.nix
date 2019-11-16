let
  secrets = import ./load-secrets.nix;
  sources = import ./nix/sources.nix;
  iohk-ops = sources.iohk-ops;
in {
  imports = [ (iohk-ops +"/modules/monitoring-services.nix") ];
  services.prometheus2.scrapeConfigs = [
    {
      job_name = "node-test";
      scrape_interval = "10s";
      metrics_path = "/";
      static_configs = [
        {
          targets = [ "192.168.2.15:8000" ];
        }
      ];
    }
    {
      job_name = "jormungandr";
      scrape_interval = "10s";
      metrics_path = "/metrics";
      static_configs = [
        { targets = [ "192.168.2.1:8000" ]; }
      ];
    }
    {
      job_name = "jormungandr-sam";
      scrape_interval = "10s";
      metrics_path = "/sam-metrics";
      static_configs = [
        { targets = [ "192.168.2.15:80" ]; }
      ];
    }
    {
      job_name = "exporter";
      scrape_interval = "10s";
      metrics_path = "/";
      static_configs = [ { targets = [ "amd.localnet:8080" ]; } ];
    }
    {
      job_name = "cachecache";
      scrape_interval = "10s";
      metrics_path = "/";
      static_configs = [ { targets = [ "127.0.0.1:8080" ]; } ];
    }
  ];
  services.monitoring-services = {
    enable = true;
    enableACME = false;
    enableWireguard = false;
    metrics = true;
    logging = false;
    oauth = {
      enable = true;
      emailDomain = "iohk.io";
      inherit (secrets.oauth) clientID clientSecret cookie;
    };
    webhost = "monitoring.earthtools.ca";
    inherit (secrets) grafanaCreds;
    monitoredNodes = {
      "router.localnet" = {
        hasNginx = true;
      };
      "nas" = {
        hasNginx = true;
      };
      "amd.localnet" = {};
    };
    grafanaAutoLogin = true;
  };
}
