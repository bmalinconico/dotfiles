{ config, pkgs, lib, ... }:

let
  cupcakeFlake = builtins.getFlake "path:${toString ../../nixpkgs/cupcake}";
  cupcake = cupcakeFlake.packages.${pkgs.system}.default;
in
{
  home.packages = with pkgs; [
    # Atlassian/Jira tools
    go-jira

    # Cupcake - AI coding agent policy enforcement (includes OPA)
    cupcake

    # Add other work-specific packages here as needed
  ];
}
