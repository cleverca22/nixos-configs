let
  #nixpkgsfix = builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/pull/152462/head.tar.gz";
  nixpkgsfix = builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/b211b392b8486ee79df6cdfb1157ad2133427a29.tar.gz";
  fixed_pkgs = import nixpkgsfix { config = {}; overlays = []; };
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
  systemd.services.home-assistant = {
    serviceConfig = {
      DeviceAllow = [
        "/dev/ttyUSB0"
        "/dev/ttyACM*"
        "/dev/ttyzigbee"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [
    1883
  ];
  #hardware.bluetooth.enable = true;
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users = {
          full_access = {
            password = "hunter2";
            acl = [
              "readwrite homeassistant/#"
              "readwrite home/#"
              "readwrite elite_dangerous/#"
              "readwrite $SYS/#"
              "readwrite caller-id/#"
            ];
          };
          callerid = {
            password = "hunter2";
            acl = [
              "readwrite caller-id/#"
            ];
          };
        };
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
        #password = "hunter2";
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
