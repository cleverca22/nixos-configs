{ stdenv, fetchurl, openjdk, libX11, libXext, libXcursor, libXrandr, libXxf86vm, mesa, openal, pulseaudioFull, lib }:

assert openjdk ? architecture;

let java = openjdk;
in
stdenv.mkDerivation {
  name = "technic-launcher-4.347";

  src = fetchurl {
    url = "https://launcher.technicpack.net/launcher4/1033/TechnicLauncher.jar";
    sha256 = "sha256-l5wJeA4DP9p2FN3lXecWY3KlQ/upGzXiP5tRQMGWV8c=";
  };

  phases = "installPhase";

  installPhase = ''
    set -x
    mkdir -pv $out/bin
    cp -v $src $out/TechnicLauncher.jar

    cat > $out/bin/technic-launcher << EOF
    #!${stdenv.shell}

    # wrapper for technic-launcher
    export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${java}/lib/${java.architecture}/:${libX11}/lib/:${libXext}/lib/:${libXcursor}/lib/:${libXrandr}/lib/:${libXxf86vm}/lib/:${mesa}/lib/:${openal}/lib/
    ${pulseaudioFull}/bin/padsp ${java}/bin/java -jar $out/TechnicLauncher.jar
    EOF

    chmod +x $out/bin/technic-launcher
  '';

  meta = {
      description = "A modpack loader for Minecraft";
      homepage = http://www.technicpack.net;
      maintainers = [ lib.maintainers.taktoa ];
      license = lib.licenses.unfreeRedistributable;
  };
}
