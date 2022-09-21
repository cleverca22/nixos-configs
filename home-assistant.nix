let
  nixpkgsfix = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/pull/152462/head.tar.gz";
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
in {
  systemd.services.home-assistant = {
    serviceConfig = {
      DeviceAllow = [
        "/dev/ttyUSB0"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [
    1883
  ];
  services.mosquitto = {
    enable = true;
    host = "0.0.0.0";
    users = {
      full_access = {
        password = "hunter2";
        acl = [
          "topic readwrite homeassistant/#"
          "topic readwrite home/#"
          "topic readwrite $SYS/#"
        ];
      };
    };
    extraConf = ''
      log_type all
    '';
  };
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    package = (fixed_pkgs.home-assistant.override {
      extraComponents = [ "cast" ];
    }).overrideAttrs (oldAttrs: { doInstallCheck = false; });
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
          {
            service = "scene.turn_on";
            target.entity_id = "scene.lights_off";
          }
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
          {
            service = "scene.turn_on";
            target.entity_id = "scene.lights_on";
          }
        ];
      };
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
          {
            service = "scene.turn_on";
            target.entity_id = "scene.lights_off";
          }
        ];
      };
      api = {};
      cast = {};
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
        broker = "127.0.0.1";
        username = "full_access";
        password = "hunter2";
      };
      onboarding = {
      };
      person = {
      };
      zha = {
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
      openweathermap = {};
      tuya = {
      };
      prometheus = {};
      scene = [
        {
          name = "lights off";
          entities = {
            "switch.floor_lamp_socket" = "off";
          };
        }
        {
          name = "lights on";
          entities = {
            "switch.floor_lamp_socket" = "on";
          };
        }
      ];
    };
  };
}
