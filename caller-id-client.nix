{ runCommand, python3, gbject-introspection, libnotify }:

runCommand "caller-id-client" {
} ''
  mkdir -pv $out/bin/
  cp ${./caller-id.py} $out/caller-id.py
''
