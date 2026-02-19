{
  description = "Interactive Plan Review for Claude Code - annotate plans visually and share with team";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        version = "0.8.2";

        # Platform-specific binary selection
        platformInfo = {
          x86_64-linux = {
            name = "plannotator-linux-x64";
            sha256 = "8dcc5dcef98cbc3e66f38d801263b12a1735c335615c4cd6bddf76d7cf29fb3a";
          };
          aarch64-linux = {
            name = "plannotator-linux-arm64";
            sha256 = "5b1c0f959a40dce1e60fb1db2fb4db7d3c72238a46cfa31e1b1addce269a0b37";
          };
          x86_64-darwin = {
            name = "plannotator-darwin-x64";
            sha256 = "66e13f28e5331bf3ffc4a082de148df04fa42d32ca500a1fb4f4c2b201936651";
          };
          aarch64-darwin = {
            name = "plannotator-darwin-arm64";
            sha256 = "0f1441471842a0f70619aa6f8f333d0d51ae607c96bd7beda7c0e61cc76942d6";
          };
        };

        info = platformInfo.${system} or (throw "Unsupported system: ${system}");

      in
      {
        packages = {
          default = pkgs.stdenv.mkDerivation {
            pname = "plannotator";
            inherit version;

            src = pkgs.fetchurl {
              url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/${info.name}";
              sha256 = info.sha256;
            };

            dontUnpack = true;
            dontBuild = true;

            # Don't patch the Bun-compiled executable - it breaks it
            dontPatchELF = true;
            dontStrip = true;
            dontPatchShebangs = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              cp $src $out/bin/plannotator
              chmod +x $out/bin/plannotator

              # Install Claude Code skill
              mkdir -p $out/share/claude/commands
              cp ${./plannotator-review.md} $out/share/claude/commands/plannotator-review.md

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Interactive Plan Review for Claude Code - annotate plans visually, share with team, automatically send feedback";
              homepage = "https://github.com/backnotprop/plannotator";
              license = with licenses; [ asl20 mit ];
              maintainers = [ ];
              platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
              mainProgram = "plannotator";
            };
          };

          # Expose just the skill file for easy access
          claude-skill = pkgs.runCommand "plannotator-claude-skill" {} ''
            mkdir -p $out
            cp ${./plannotator-review.md} $out/plannotator-review.md
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/plannotator";
        };
      });
}
