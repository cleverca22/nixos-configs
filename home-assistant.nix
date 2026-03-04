{ config, pkgs, ... }:

let
  #nixpkgsfix = builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/pull/152462/head.tar.gz";
  nixpkgsfix = builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/cad22e7d996aea55ecab064e84834289143e44a0.tar.gz";
    sha256 = "1k49sblli685i65vv4sw66c7k5fb16l13ww2ivkj86vmd7vv1wp6";
  };
  fixed_pkgs = import nixpkgsfix { config = {}; overlays = []; system = "x86_64-linux"; };
  mkYoutubeAction = video: {
    service = "media_player.play_media";
    target.entity_id = "media_player.living_room_tv";
    data = {
      media_content_type = "cast";
      media_content_id = builtins.toJSON {
        app_name = "youtube";
        media_id = video;
      };
    };
  };
  automation3 = {
    trigger = [
      {
        platform = "state";
        entity_id = [
          "sensor.bedroom"
          "sensor.outdoors"
        ];
      }
    ];
    condition = [
      {
        condition = "numeric_state";
        entity_id = "sensor.bedroom";
        above = "sensor.outdoors";
      }
      {
        condition = "numeric_state";
        entity_id = "sensor.bedroom";
        above = "21";
      }
    ];
    action = [
      {
        service = "switch.turn_on";
        target.entity_id = "switch.fan_switch";
      }
    ];
  };
  automation4 = {
    trigger = [
      {
        platform = "state";
        entity_id = [
          "sensor.bedroom"
          "sensor.outdoors"
        ];
      }
    ];
    condition = [
      {
        condition = "or";
        conditions = [
          {
            condition = "numeric_state";
            entity_id = "sensor.bedroom";
            below = "sensor.outdoors";
          }
          {
            condition = "numeric_state";
            entity_id = "sensor.bedroom";
            below = "20";
          }
        ];
      }
    ];
    action = [
      {
        service = "switch.turn_off";
        target.entity_id = "switch.fan_switch";
      }
    ];
  };
in {
  imports = [
    ./zigbee2mqtt.nix
  ];

  age.secrets = {
    "mqtt.callerid".file = ./secrets/mqtt.callerid.age;
    "mqtt.full_access".file = ./secrets/mqtt.full_access.age;
    "mqtt.hass".file = ./secrets/mqtt.hass.age;
    "mqtt.oc".file = ./secrets/mqtt.oc.age;
    "mqtt.zigbee2mqtt".file = ./secrets/mqtt.zigbee2mqtt.age;
  };

  environment.systemPackages = [ pkgs.blueman ];
  systemd.services.home-assistant = {
    serviceConfig = {
      DeviceAllow = [
        #"/dev/ttyUSB0"
        #"/dev/ttyACM*"
        #"/dev/ttyzigbee"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [
    1883
  ];
  hardware.bluetooth.enable = true;
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users = {
          full_access = {
            passwordFile = config.age.secrets."mqtt.full_access".path;
            acl = [
              "readwrite $SYS/#"
              "readwrite caller-id/#"
              "readwrite elite_dangerous/#"
              "readwrite home/#"
              "readwrite homeassistant/#"
              "readwrite oc-computer/#"
              "readwrite temp_daemon/#"
              "readwrite zigbee2mqtt/#"
            ];
          };
          hass = {
            passwordFile = config.age.secrets."mqtt.hass".path;
            acl = [
              "readwrite homeassistant/#"
              "readwrite zigbee2mqtt/#"
              "readwrite temp_daemon/#"
              "readwrite oc-computer/#"
            ];
          };
          zigbee2mqtt = {
            passwordFile = config.age.secrets."mqtt.zigbee2mqtt".path;
            acl = [
              "readwrite homeassistant/#"
              "readwrite zigbee2mqtt/#"
            ];
          };
          callerid = {
            passwordFile = config.age.secrets."mqtt.callerid".path;
            acl = [
              "readwrite caller-id/#"
            ];
          };
          oc = {
            passwordFile = config.age.secrets."mqtt.oc".path;
            acl = [
              "readwrite oc-computer/#"
              "readwrite homeassistant/#"
            ];
          };
        };
        settings.allow_anonymous = true;
      }
    ];
    # logType = [ "all" ];
  };
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    package = (fixed_pkgs.home-assistant.override {
      extraComponents = [
        "cast" "http" "openweathermap" "roku"
        "google"
        "jellyfin"
      ];
      extraPackages = pypkgs: [ pypkgs.aiohttp-cors ];
    }).overrideAttrs (oldAttrs: { doInstallCheck = false; });
    extraComponents = [ "http" ];
    config = {
      automation = {
        alias = "lights out when playing";
        #trigger = [
        #  {
        #    platform = "webhook";
        #    webhook_id = "plex";
        #  }
        #];
        trigger = [
          {
            platform = "state";
            entity_id = "media_player.plex_plex_media_player_amd_nixos";
            to = "playing";
            for = "00:00:10";
          }
        ];
        action = [
          #{
          #  service = "scene.turn_on";
          #  target.entity_id = "scene.lights_off";
          #}
        ];
      };
      "automation 2" = {
        alias = "lights on when not playing";
        trigger = [
          {
            platform = "state";
            entity_id = "media_player.plex_plex_media_player_amd_nixos";
            to = "paused";
            for = "00:00:10";
          }
          {
            platform = "state";
            entity_id = "media_player.plex_plex_media_player_amd_nixos";
            to = "idle";
          }
        ];
        action = [
          #{
          #  service = "scene.turn_on";
          #  target.entity_id = "scene.lights_on";
          #}
        ];
      };
      "automation leaky washing" = {
        alias = "no leaky washing";
        trigger = [
          {
            platform = "device";
            entity_id = "522f1a1953b291d9abab9fd5c6455df6";
            type = "moist";
            device_id = "30266e82fc382d5fd6050559fc204d3d";
            domain = "binary_sensor";
          }
        ];
        mode = "single";
        action = [
          #{
          #  service = "switch.turn_off";
          #  target.device_id = "e87bba0947b6f4b5d0fd12e9028f50df";
          #}
          (mkYoutubeAction "ufZoZzDjjzE")
        ];
      };
      "automation furnaceroom leak" = {
        alias = "furnace room leak";
        trigger = [
          {
            platform = "state";
            entity_id = "binary_sensor.furnace_leak_moisture";
          }
        ];
        mode = "single";
        action = [
          (mkYoutubeAction "ufZoZzDjjzE")
        ];
      };
      #"proxymity test1" = {
      #  alias = "dad approaching";
      #  trigger = [
      #    
      #  ];
      #};
      "automation fubuki" = {
        alias = "fubuki test";
        trigger = [
        ];
        action = [
          (mkYoutubeAction "dmkRV8SPBng")
        ];
      };
      "automation rick" = {
        alias = "rick test";
        trigger = [
        ];
        action = [
          (mkYoutubeAction "dQw4w9WgXcQ")
        ];
      };
      "automation upstairs detected" = {
        alias = "activity detected upstairs";
        trigger = [
          {
            platform = "state";
            entity_id = "media_player.living_room_tv";
            to = "playing";
            for = "00:00:10";
          }
        ];
        action = [
          #{
          #  service = "scene.turn_on";
          #  target.entity_id = "scene.lights_off";
          #}
        ];
      };
      #inherit automation3 automation4;
      api = {};
      #cast = {};
      sense = {};
      config = {};
      default_config = {};
      frontend = {};
      #google_assistant = {
        #project_id = "";
      #};
      http = { };
      history = {};
      homeassistant = {
        external_url = "https://hass.earthtools.ca";
        media_dirs = {
          nas_anime = "/nas/anime";
        };
      };
      lovelace = {
      };
      mqtt = {
        #broker = "127.0.0.1";
        #username = "full_access";
      };
      google_assistant_sdk = {
      };
      onboarding = {
      };
      person = {
      };
      zha = {
      };
      ibeacon = {
      };
      logger = {
        default = "warning";
        logs = {
          # https://github.com/zigpy/zigpy-xbee/blob/dev/zigpy_xbee/api.py#L16
          "zigpy_xbee.api" = "debug";
          "mqtt" = "debug";
        };
      };
      #met = {};
      #openweathermap = {};
      #tuya = {
      #};
      prometheus = {};
      scene = [
        {
          name = "lights off";
          entities = {
            #"switch.floor_lamp_socket" = "off";
          };
        }
        {
          name = "lights on";
          entities = {
            #"switch.floor_lamp_socket" = "on";
          };
        }
      ];
      template = [
        {
          sensor = {
            name = "desktop active plex";
            state = ''
              {{ state_attr("media_player.plex_plex_media_player_amd_nixos","media_series_title") }}: {{ state_attr("media_player.plex_plex_media_player_amd_nixos","media_title") }}
            '';
          };
        }
      ];
    };
  };
}
