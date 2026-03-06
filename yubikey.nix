{ pkgs, ... }:

let
  dependencies = with pkgs; [ coreutils gnupg gawk gnugrep ];
  clearYubikey = pkgs.writeScript "clear-yubikey" ''
    #!${pkgs.stdenv.shell}
    export PATH=${pkgs.lib.makeBinPath dependencies};
    keygrips=$(
      gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null \
      | grep -v OK \
      | awk '{if ($4 == "T") { print $3 ".key" }}')
    for f in $keygrips; do
      rm -v ~/.gnupg/private-keys-v1.d/$f
    done
    gpg --card-status 2>/dev/null 1>/dev/null || true
  '';
  clearYubikeyUser = pkgs.writeScript "clear-yubikey-user" ''
    #!${pkgs.stdenv.shell}
    ${pkgs.sudo}/bin/sudo -u <your username> ${clearYubikey}
  '';
in {
  #services.udev.extraRules = ''ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", RUN+="${clearYubikeyUser}"'';
  #environment.shellInit = ''
  #  export GPG_TTY="$(tty)"
  #  gpg-connect-agent /bye
  #  export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  #'';
  services = {
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization pkgs.libu2f-host ];
  };
  environment = {
    systemPackages = with pkgs; [
      gnupg
      paperkey
      #pinentry-gnome
      yubikey-manager
      yubikey-personalization
      #yubioath-desktop
    ];
    shellInit = ''
      export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
    '';
  };
  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      #pinentryFlavor = "gtk2";
    };
  };
}
