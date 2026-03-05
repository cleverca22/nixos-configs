{ runCommand, syncplay, mpv }:

runCommand "syncplays" {} ''
  mkdir -pv $out/bin
  cat <<EOF > $out/bin/sync-nix
  #!/bin/sh
  ${syncplay}/bin/syncplay -a ext.earthtools.ca:1337 -n clever -r vem -p hunter2 --player-path ${mpv}/bin/mpv
  EOF
  cat <<EOF > $out/bin/sync-ranime
  #!/bin/sh
  ${syncplay}/bin/syncplay -a syncplay.pl:8995 -n clever -r 'ranime groupwatch' --player-path ${mpv}/bin/mpv
  EOF

  chmod +x $out/bin/sync-nix $out/bin/sync-ranime
''
