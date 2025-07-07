{ config, pkgs, lib, ... }:

{
imports = [./base.nix];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "brianmalinconico";
  home.homeDirectory = "/Users/brianmalinconico";

  programs.git.userEmail = "brian.malinconico@terminus.com";

  programs.git.signing.key = "94BA5A6DAD07B16C";
}
