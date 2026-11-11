{ config, inputs, ... }:

{
  imports = [
    inputs.agenix.nixosModules.default
  ];
  age.secrets = {
    "hydra-token" = {
      file = ./secrets/hydra-token.age;
      owner = "hydra-builder";
    };
  };
  services = {
    hydra-builder = {
      enable = true;
      authorizationFile = config.age.secrets."hydra-token".path;
      queueRunnerAddr = "http://nas.localnet:50051";
    };
  };
}
