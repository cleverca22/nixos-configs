{ config, pkgs, lib, ...}:

with lib;

let
  notPython = pkgs.writeScript "notPython" ''
    #!${pkgs.stdenv.shell}
    shift
    shift
    shift
    wakatime "$@"
  '';
  myVim = pkgs.vim_configurable.customize {
    name = "vim";
    vimrcConfig = {
      customRC = ''
        syntax on
        set nu
        set foldmethod=syntax
        set listchars=tab:->
        set list
        set backspace=indent,eol,start
        nmap <F3> :!nix-build -A default <enter>
        map <F7> :tabp<enter>
        map <F8> :tabn<enter>
        set expandtab
        set softtabstop=2
        set shiftwidth=2
        set autoindent
        set statusline+=col:\ %c,
        set background=dark

        " remove trailing whitespace upon save
        au BufWritePre * %s/\s\+$//e

        " highlight all trailing whitespace
        highlight ExtraWhitespace ctermbg=red guibg=red
        au ColorScheme * highlight ExtraWhitespace guibg=red
        au BufEnter * match ExtraWhitespace /\s\+$/
        au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
        au InsertLeave * match ExtraWhiteSpace /\s\+$/


        let g:wakatime_PythonBinary = '${notPython}'
        autocmd Filetype haskell set foldmethod=indent foldcolumn=2 softtabstop=2 shiftwidth=2
      '';
      vam.pluginDictionaries = [
        {
          names = [
            "vim-nix"
            "Syntastic"
            "vim-wakatime"
          ] ++ optional config.programs.vim.fat "youcompleteme";
        }
      ];
    };
  };
in
{
  options = {
    programs.vim.fat = mkOption {
      type = types.bool;
      default = true;
      description = "include vim modules that consume a lot of disk space";
    };
  };
  config = {
    environment.systemPackages = [ myVim pkgs.wakatime ];
    environment.shellAliases.vi = "vim";
    environment.variables.EDITOR = "vim";
    programs.bash.shellAliases = {
      vi = "vim";
    };
  };
}
