{
  description = "Cupcake - A native policy enforcement layer for AI coding agents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Platform-specific information
        platformInfo = {
          x86_64-linux = {
            url = "https://github.com/eqtylab/cupcake/releases/download/v0.5.1/cupcake-v0.5.1-x86_64-unknown-linux-gnu.tar.gz";
            sha256 = "377aa6f0213cda732c8b3d7892fe8585c585c232be753bf199d4d36443a547ea";
          };
          aarch64-linux = {
            url = "https://github.com/eqtylab/cupcake/releases/download/v0.5.1/cupcake-v0.5.1-aarch64-unknown-linux-gnu.tar.gz";
            sha256 = "d7641cd77eb4f1cabc6f73b867e3918affc7ff7468c62f4b70bf6a75b2e88bc5";
          };
          x86_64-darwin = {
            url = "https://github.com/eqtylab/cupcake/releases/download/v0.5.1/cupcake-v0.5.1-x86_64-apple-darwin.tar.gz";
            sha256 = "39e0855d4b27989aa7efb07523a671baa6db2a03e49090e8630e25ed6adcd880";
          };
          aarch64-darwin = {
            url = "https://github.com/eqtylab/cupcake/releases/download/v0.5.1/cupcake-v0.5.1-aarch64-apple-darwin.tar.gz";
            sha256 = "de06f98f8916517a1f979123439abde431dbbefbfdeb9118321a651a6d9394db";
          };
        };

        platform = platformInfo.${system} or (throw "Unsupported system: ${system}");

      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "cupcake";
          version = "0.5.1";

          src = pkgs.fetchurl {
            url = platform.url;
            sha256 = platform.sha256;
          };

          nativeBuildInputs = [
            pkgs.autoPatchelfHook
            pkgs.makeWrapper
          ];

          buildInputs = [
            pkgs.stdenv.cc.cc.lib
          ];

          sourceRoot = ".";

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp cupcake-*/bin/cupcake $out/bin/.cupcake-unwrapped
            chmod +x $out/bin/.cupcake-unwrapped

            # Wrap cupcake with OPA in PATH
            makeWrapper $out/bin/.cupcake-unwrapped $out/bin/cupcake \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.open-policy-agent ]} \
              --argv0 cupcake

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "A native policy enforcement layer for AI coding agents built on OPA/Rego";
            homepage = "https://cupcake.eqtylab.io/";
            license = licenses.asl20;
            maintainers = [ ];
            platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
          };
        };

        packages.cupcake = self.packages.${system}.default;

        # Include OPA as a development dependency
        devShells.default = pkgs.mkShell {
          buildInputs = [
            self.packages.${system}.default
            pkgs.open-policy-agent  # Open Policy Agent - required dependency
          ];

          shellHook = ''
            echo "Cupcake development environment"
            echo "Cupcake version: $(cupcake --version 2>/dev/null || echo 'not found')"
            echo "OPA version: $(opa version 2>/dev/null || echo 'not found')"
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/cupcake";
        };
      }
    );
}
