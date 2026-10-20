{ runCommand, python3, gobject-introspection, libnotify, lib, makeWrapper }:

runCommand "caller-id-client" {
  preferLocalBuild = true;
  buildInputs = [
    (python3.withPackages (ps: [ ps.paho-mqtt ps.pygobject3 ]))
    gobject-introspection
    libnotify
    makeWrapper
  ];
} ''
  mkdir -pv $out/bin/
  cp ${./caller-id.py} $out/bin/caller-id.py

  patchShebangs $out/bin/

  wrapProgram $out/bin/caller-id.py --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH"
''
