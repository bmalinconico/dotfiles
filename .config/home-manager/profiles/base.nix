{ config, pkgs, lib, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "brianmalinconico";
  home.homeDirectory = "/Users/brianmalinconico";

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.bin"
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    pkgs.silver-searcher
 #   pkgs.git
    pkgs.devbox
    pkgs.gnupg
    pkgs.zsh-powerlevel10k

    pkgs.jq
    pkgs.tree
    pkgs.wget
    pkgs.curl
    pkgs.git-lfs
    pkgs.nodejs
    #pkgs.ruby
    pkgs.ripgrep
    pkgs.fd

    pkgs.lua # Required for Neovim / Lazy
    pkgs.luarocks # Required for Neovim / Lazy


    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".gitattributes".source = ./dotfiles/gitattributes;
    ".p10k.zsh".source = ./dotfiles/p10k.zsh;
    ".bin/dev" = { source = ./bin/dev.sh; executable = true; };
    ".bin/git-clean-branches" = { source = ./bin/git-clean-branches.sh; executable = true; };
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/brianmalinconico/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      copper = "bundle exec rubocop -A && git commit -am 'Copper' && git push";
      rake = "noglob rake";
      clean-workspace = "find . -depth 3 -name .git -type d -exec bash -c \"cd {}/.. && git clean-branches && git gc\" \\;";
    };

    history = {
      share = true;
      append = true;
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell"; # or "robbyrussell", or whatever theme you prefer
      plugins = [ "git" "sudo" ]; # add any plugins you like
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
       source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
       source ~/.p10k.zsh
       '')

        (lib.mkOrder 999 ''
           if [[ "$TERM" == "xterm-kitty" ]]; then
             alias ssh="kitty +kitten ssh"
           fi

           # It seems TMUX is maintaining everything except the PATH from the env...
           export PATH="$HOME/.nix-profile/bin:$PATH"
         ''
        )
    ];
  };



  programs.tmux = {
    enable = true;

    # defaultCommand = "reattach-to-user-namespace -l zsh"; # Uncomment if using macOS and reattach is needed

    terminal = "screen-256color";
    extraConfig = ''
      set-option -sa terminal-features ',xterm-kitty:RGB'
      set-option -g focus-events on
      set -sg escape-time 0

      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      bind -r Left select-pane -L
      bind -r Right select-pane -R
      bind -r Up select-pane -U
      bind -r Down select-pane -D
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true; 
    tmux.enableShellIntegration = true;
    defaultCommand = "ag --hidden --ignore .git -g \"\"";
  };

  programs.git = {
    enable = true;
    userName  = "Brian Malinconico";
    userEmail = "brian.malinconico@terminus.com";

    signing = {
      signByDefault = true;
    };

    extraConfig = {
      alias = {
        co = "checkout";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };

      color = {
        branch = "auto";
        diff = "auto";
        interactive = "auto";
        status = "auto";
        ui = "always";
      };

      push.default = "current";

      core = {
        editor = "nvim";
        attributesFile = "${config.home.homeDirectory}/.gitattributes";
      };

      credential.helper = "osxkeychain";

      merge.tool = "vimdiff";

      mergetool = {
        prompt = true;
      };

      "mergetool \"vimdiff\"" = {
        cmd = "nvim -d $BASE $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
      };

      "filter \"lfs\"" = {
        process  = "git-lfs filter-process";
        required = true;
        clean    = "git-lfs clean -- %f";
        smudge   = "git-lfs smudge -- %f";
      };

      "url \"git@github.com:\"" = {
        insteadOf = "https://github.com/";
      };

      commit.gpgSign = true;

      gpg.program = "${pkgs.gnupg}/bin/gpg";
    };
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;
    withRuby = false;
  };

# services.ssh-agent.enable = true;
}
