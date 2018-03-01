{ stdenv, fetchurl, python, pkgconfig, zlib, glib, user_arch, flex, bison,
makeStaticLibraries, glibc, qemu }:

let
  env2 = makeStaticLibraries stdenv;
  myglib = glib.override { stdenv = env2; };
  magic = {
    arm     = ''\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00'';
    aarch64 = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00'';
  };
  mask = ''\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\x00\xff\xfe\xff\xff\xff'';
in
stdenv.mkDerivation rec {
  name = "qemu-user-${user_arch}-${version}";
  version = "2.7.0";
  inherit (qemu) src;
  buildInputs = [ python pkgconfig zlib.static myglib flex bison glibc.static ];
  patches = [ ./qemu-stack.patch ];
  configureFlags = [
    "--enable-linux-user" "--target-list=${user_arch}-linux-user"
    "--disable-bsd-user" "--disable-system" "--disable-vnc"
    #"--without-pixman"
    "--disable-curses" "--disable-sdl" "--disable-vde"
    "--disable-bluez" "--disable-kvm"
    "--static"
    "--disable-tools"
  ];
  NIX_LDFLAGS = [ "-lglib-2.0" "-lssp" ];
  enableParallelBuilding = true;
  postInstall = ''
    cc -static ${./qemu-wrap.c} -D QEMU_ARM_BIN="\"qemu-${user_arch}"\" -o $out/bin/qemu-wrap
    cat <<EOF > $out/bin/register
    #!${stdenv.shell}
    set -e
    modprobe binfmt_misc
    grep binfmt_misc /proc/mounts >/dev/null || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
    [[ ! -e /proc/sys/fs/binfmt_misc/${user_arch} ]] || echo -1 > /proc/sys/fs/binfmt_misc/${user_arch}
    echo ':${user_arch}:M::${magic.${user_arch}}:${mask}:$out/bin/qemu-wrap:P' > /proc/sys/fs/binfmt_misc/register
    EOF
    chmod +x $out/bin/register
  '';
}
