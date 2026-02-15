{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    #nix-direnv
    direnv
  ];
  nix.extraOptions = ''
    # direnv.nix
    #keep-outputs = true
    keep-derivations = true
  '';
  environment.pathsToLink = [
    #"/share/nix-direnv"
  ];
  programs = {
    bash.interactiveShellInit = ''
      if [ -z $IN_NIX_SHELL ]; then
        eval "$(direnv hook bash)"
      fi
    '';
    zsh.interactiveShellInit = ''
      if [ -z $IN_NIX_SHELL ]; then
        eval "$(direnv hook zsh)"
      fi
    '';
  };
}
