{ runCommand, fetchurl, glibc }:

let
  src = fetchurl {
    url = "https://ircd.bircd.org/bewareircd-linux.tar.gz";
    sha256 = "sha256-yTZSiCpZvQMHMvdd4yFn5tMU/lF8csfRbjZ+dFQ83Gg=";
  };
in runCommand "bircd-1.6.3" {} ''
  tar -xvf ${src}
  cd bircd
  ls -ltrh
  mkdir -p $out/bin
  cp -v rehash restart stop mkpasswd bircd $out/bin/

  patchShebangs $out/bin
  patchelf --set-interpreter ${glibc.out}/lib/ld-linux.so.2 $out/bin/bircd
''
