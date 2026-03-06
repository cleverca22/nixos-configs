{ runCommand, python3, gobject-introspection, libnotify }:

runCommand "caller-id-client" {
} ''
  mkdir -pv $out/bin/
  cp ${./caller-id.py} $out/caller-id.py
''
