#!/usr/bin/env bash

nix-shell -p nodePackages.node2nix --command "node2nix -i ./node-packages.json -o node-packages.nix"

# Replace default nodejs_14 with nodejs_22
sed -i 's/nodejs_14/nodejs_22/g' default.nix

