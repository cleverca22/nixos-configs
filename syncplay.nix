{
  # (import <nixpkgs> { config = {}; }).python3.withPackages (p: [p.pyside p.pysideTools p.twisted])
  # https://github.com/Syncplay/syncplay
  systemd.services.syncplay-server = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "clever";
      WorkingDirectory = "/home/clever/apps/syncplay";
      Restart = "always";
    };
    script = ''
      ./result/bin/python syncplayServer.py  --port 1337 --password hunter2 --stats-db-file stats.sqlite --salt GNCXTBCQDN
    '';
  };
}
