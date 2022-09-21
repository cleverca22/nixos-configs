{ ... }:

{
  nix = {
    settings = {
      trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
      substituters = [ "https://hydra.iohk.io" ];
    };
  };
}
