{ config, ... }:

{
  age.secrets = {
    "mqtt.zigbee2mqtt.yaml" = {
      file = ./secrets/mqtt.zigbee2mqtt.yaml.age;
      owner = "zigbee2mqtt";
    };
  };
  networking.firewall.allowedTCPPorts = [
    config.services.zigbee2mqtt.settings.frontend.port
  ];

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      advanced.channel = 25;
      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "mqtt://127.0.0.1:1883";
        user = "zigbee2mqtt";
        password = "!${config.age.secrets."mqtt.zigbee2mqtt.yaml".path} password";
      };

      serial = {
        adapter = "ezsp";
        baudrate = 115200;
        port = "/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20240124195805-if00";
      };

      frontend.port = 8099;
    };
  };
}
