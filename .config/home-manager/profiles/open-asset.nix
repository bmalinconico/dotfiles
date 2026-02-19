{ config, pkgs, lib, ... }:

{
  imports = [
    ./base.nix
    ./work-packages.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "brian";
  home.homeDirectory = "/home/brian";

  programs.git.userEmail = "brian.malinconico@openasset.com";

  programs.git.signing.key = "9F208624916D128B";
}
