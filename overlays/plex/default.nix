let
  sources = import ../../nix/sources.nix;
in
self: super: {
  plex-media-player = super.plex-media-player.overrideAttrs (old: {
    src = sources.plex-media-player;
  });
}
