{ config, pkgs, lib, ... }:

let
  hydraRev = "19912e15b14a153346ed21256434a47a0b1a0926";
  hydraSrc = pkgs.fetchFromGitHub {
    owner = "cleverca22";
    repo = "hydra";
    sha256 = "1b59dc2akclhryzrsb3pgwz1f80vhyr9hgglgy6xmzzwnln4dw5g";
    rev = hydraRev;
  };
  hydraSrc-local = /home/clever/iohk/hydra;
  hydraSrc' = {
    outPath = hydraSrc;
    rev = hydraRev;
    revCount = 1234;
  };
  hydra-fork = (import (hydraSrc + "/release.nix") { hydraSrc = hydraSrc'; nixpkgs = pkgs.path; }).build.x86_64-linux;
  patched-hydra = pkgs.hydra.overrideDerivation (drv: {
    patches = [
      ./extra-debug.patch
    ];
  });
  passwords = import ./load-secrets.nix;
in {
  users.users.hydra-www.extraGroups = [ "hydra" ];
  systemd.services.hydra-queue-runner = {
    serviceConfig = {
      #ExecStart = lib.mkForce "@${config.services.hydra.package}/bin/hydra-queue-runner hydra-queue-runner -vvvvvv";
    };
  };
  systemd.services.hydra-evaluator.path = [ pkgs.jq pkgs.gawk ];
  nix.extraOptions = ''
    allowed-uris = https://github.com/input-output-hk/nixpkgs/archive/
  '';
  services = {
    postgresql = {
      identMap = ''
        hydra-users clever clever
      '';
    };
    hydra = {
      useSubstitutes = true;
      # package = hydra-fork;
      enable = true;
      hydraURL = "https://hydra.angeldsis.com";
      notificationSender = "cleverca22@gmail.com";
      minimumDiskFree = 2;
      minimumDiskFreeEvaluator = 1;
      listenHost = "localhost";
      port = 3001;
      extraConfig = with passwords; ''
        binary_cache_secret_key_file = /etc/nix/keys/secret-key-file
        store-uri = file:///nix/store?secret-key=/etc/nix/keys/secret-key-file
        max_output_size = ${toString (1024*1024*1024*3)} # 3gig
        max_concurrent_evals = 1
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
    };
    nginx = {
      virtualHosts = {
        "hydra.angeldsis.com" = {
          enableACME = false;
          forceSSL = false;
          locations."/".extraConfig = ''
            proxy_pass http://localhost:3001;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto "https";
            proxy_set_header  X-Real-IP         $remote_addr;
            proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
          '';
        };
      };
    };
  };
}
