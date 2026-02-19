{ config, pkgs, lib, ... }:

let
  plannotatorFlake = builtins.getFlake "path:/home/brian/workspace/dotfiles/.config/nixpkgs/plannotator";
  plannotator = plannotatorFlake.packages.${pkgs.system}.default;
in
{
  # Install the plannotator binary
  home.packages = [ plannotator ];

  # Symlink the Claude Code skill to ~/.claude/commands/
  home.file.".claude/commands/plannotator-review.md".source =
    "${plannotator}/share/claude/commands/plannotator-review.md";
}
