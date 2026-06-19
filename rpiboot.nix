{ stdenv, fetchFromGitHub, libusb1, pkg-config }:

stdenv.mkDerivation {
  name = "rpiboot";
  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "usbboot";
    rev = "87d6e03272b0ae155d85a125bfdec03e3d4a1095";
    sha256 = "sha256-wWhHJMA8e8hnjib87Mf7TKCyt08dWU8qbK+Kinamv8I=";
  };
  buildInputs = [ libusb1 ];
  nativeBuildInputs = [ pkg-config ];
  installPhase = ''
    mkdir -pv $out/bin/
    cp rpiboot $out/bin/
  '';
}
