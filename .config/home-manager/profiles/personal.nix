{ config, pkgs, lib, ... }:

{
  imports = [ ./base.nix ];

  home.username = "brian";
  home.homeDirectory = "/home/brian";

  programs.git.userEmail = "your.personal@email.com";
  programs.git.signing.key = "YOUR_PERSONAL_GPG_KEY";
}
