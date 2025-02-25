{ config, pkgs, lib, ... }:

let
  passwords = import ./load-secrets.nix;
  hydraRev = "1ef6b5e7";
  hydraSrc = pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "hydra";
    rev = hydraRev;
    hash = "sha256-Fj0QgY+lkuEoRsPxL/y4VLHs1QWeq+kPbnt4hq7j+/o=";
  };
  hydraFlake = builtins.getFlake "github:cleverca22/hydra/${hydraRev}";
  hydra-fork = hydraFlake.packages.x86_64-linux.default;
  hydraSrc' = {
    outPath = hydraSrc;
    rev = hydraRev;
    revCount = 1234;
  };
  #hydra-fork = (import (hydraSrc + "/release.nix") { hydraSrc = hydraSrc'; nixpkgs = pkgs.path; }).build.x86_64-linux;
in {
  users.users.hydra-www.extraGroups = [ "hydra" ];
  systemd.services.hydra-queue-runner = {
    serviceConfig = {
      #ExecStart = lib.mkForce "@${config.services.hydra.package}/bin/hydra-queue-runner hydra-queue-runner -vvvvvv";
    };
    wantedBy = lib.mkForce [];
  };
  systemd.services.hydra-evaluator = {
    path = [ pkgs.jq pkgs.gawk ];
    environment.TMPDIR = "/dev/shm";
    wantedBy = lib.mkForce [];
  };
  nix.extraOptions = ''
    allowed-uris = https://github.com/input-output-hk/nixpkgs/archive/ https://github.com/nixos https://github.com/input-output-hk https://github.com/taktoa/nixpkgs github:
    experimental-features = nix-command flakes
  '';
  nix.min-free = 10;
  nix.max-free = 15;
  nix.settings.auto-optimise-store = true;
  services = {
    postgresql = {
      package = pkgs.postgresql_16;
      identMap = ''
        hydra-users clever clever
        hydra-users root root
      '';
    };
    hydra = {
      package = hydra-fork;
      enable = true;
      extraConfig = with passwords; ''
        binary_cache_secret_key_file = /etc/nix/keys/secret-key-file
        store-uri = file:///nix/store?secret-key=/etc/nix/keys/secret-key-file
        max_output_size = ${toString (1024*1024*1024*3)} # 3gig
        max_concurrent_evals = 1
        evaluator_initial_heap_size = ${toString (1024*1024*1024)} # 1gig
        <github_authorization>
          input-output-hk = ${token1}
          cleverca22 = ${token1}
          arcane-chat = ${token1}
          haskell-capnp = ${token1}
          zenhack = ${token1}
          language-ninja = ${token1}
          awakesecurity = ${token1}
          zenhack = ${token2}
          taktoa = ${token3}
        </github_authorization>
        <githubstatus>
          jobs = toxvpn:toxvpn.*
          inputs = toxvpn
          excludeBuildFromContext = 1
        </githubstatus>
        <githubstatus>
          jobs = not-os:notos.*
          inputs = notos
          excludeBuildFromContext = 1
        </githubstatus>
        <githubstatus>
          jobs = haskell-capnp:zenhack.*
          inputs = src
          excludeBuildFromContext = 1
        </githubstatus>
      '';
      hydraURL = "https://hydra.angeldsis.com";
      listenHost = "localhost";
      maxServers = 10;
      maxSpareServers = 2;
      minSpareServers = 1;
      minimumDiskFree = 2;
      minimumDiskFreeEvaluator = 1;
      notificationSender = "cleverca22@gmail.com";
      port = 3001;
      useSubstitutes = true;
    };
    nginx = {
      virtualHosts = {
        "hydra.angeldsis.com" = {
          enableACME = false;
          forceSSL = false;
          locations = {
            "/".extraConfig = ''
              proxy_pass http://localhost:3001;
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto "https";
              proxy_set_header  X-Real-IP         $remote_addr;
              proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
              proxy_read_timeout 120;
            '';
            "/hydra-charter/" = {
              alias = "/nas/private/hydra-charter/";
              index = "index.htm";
            };
          };
        };
      };
    };
  };
}
