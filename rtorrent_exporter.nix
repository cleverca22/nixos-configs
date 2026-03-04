{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "rtorrent_exporter";
  version = "1.4.9";
  rev = "v${version}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "aauren";
    repo = "rtorrent-exporter";
    hash = "sha256-mn5AHEJEDz/bifTAllbcdfuonGFkGx72dT+4zD02uLw=";
  };

  vendorHash = "sha256-xud2r1dDyYv9ImmnhF6sPGtyfpPCPKRIz31Vb1dLq10=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/aauren/rtorrent-exporter/cmd.Version=${version}"
    "-X github.com/aauren/rtorrent-exporter/cmd.Revision=${rev}"
    "-X github.com/aauren/rtorrent-exporter/cmd.Branch=unknown"
    "-X github.com/aauren/rtorrent-exporter/cmd.BuildUser=nix@nixpkgs"
    "-X github.com/aauren/rtorrent-exporter/cmd.BuildDate=unknown"
  ];

  meta = {
    description = "Prometheus exporter for rtorrent's XML-RPC";
    mainProgram = "rtorrent-exporter";
    homepage = "https://github.com/aauren/rtorrent-exporter";
    license = lib.licenses.mit;
  };
}