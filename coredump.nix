{
  systemd.coredump = {
    enable = true;
    #extraConfig = ''
    #  ExternalSizeMax=${toString (16 * 1024 * 1024 * 1024)}
    #  Compress=no
    #'';
  };
}
