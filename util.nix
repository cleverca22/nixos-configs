{ writeScriptBin, runCommand, xterm }:

let
  nixposition = writeScriptBin "nix-position" ''
nix-position () {
    usage () {
        echo "Usage: nix-position <attribute-path-under-pkgs>"
        echo "Shows the Nix source file for a given attribute path."
    }
    if [ $# -ne 1 ]; then usage; return -1; fi
    local EXPR="(import <nixpkgs> {}).pkgs.${1}.meta.position"
    nix-instantiate --eval -E "''${EXPR}" | sed 's:"$::g' | sed 's:^"::g'
    return 0
}
'';
in runCommand "util-1" {} ''
  mkdir -pv $out/bin

  cat << EOF > $out/bin/loginto
  #!$SHELL
  exec ${xterm}/bin/xterm -e ssh \$1 -t screen -xRRU
  EOF
  chmod +x $out/bin/loginto

  cat << EOF > $out/bin/showsize
  #!$SHELL
  nix-store --query --tree "\$1" | sed 's,[-+| ]*/,/,' | awk '{print \$1}' | sort | uniq | xargs nix-store --query --size | paste -sd+ | ( echo -n '( ';sed 's,+, + ,g';echo ' ) / 1024 / 1024' ) | xargs expr
  EOF
  chmod +x $out/bin/showsize

  cat << EOF > $out/bin/nix-lookup
  #!$SHELL
  local USAGE
  USAGE="$USAGE Usage: nix-lookup <expression-path-under-pkgs>"
  USAGE="$USAGE Shows the directory for the given attribute path."
  if [ $# -ne 1 ]; then echo "$USAGE"; return -1; fi
  nix-instantiate --eval -E "\"\''${(import <nixpkgs> {}).pkgs.$1}\"" | sed 's:"::g'
  EOF
  chmod +x $out/bin/nix-lookup
''
