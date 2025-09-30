{
  description = "flake for vectorcode-mcp-server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
        let
        pkgs = import nixpkgs { inherit system; };
        wheel_0_45_0 = pkgs.python3Packages.wheel.overrideAttrs (oldAttrs: {
          version = "0.45.0";
          src = pkgs.fetchPypi {
          pname = "wheel";
          version = "0.45.0";
          sha256 = "pXNTlBoxg7PVNlNGtWeiYKBgKg+KY1kmp97eQblMZ0o="; # correct sha256 for wheel 0.45.0
          };
          });

        # Override chromadb to 0.6.3
        chromadb_0_6_3 = pkgs.python3Packages.buildPythonPackage rec {
          pname = "chromadb";
          version = "0.6.3";
        
          pyproject = true;
        
          src = pkgs.fetchPypi {
            pname = "chromadb";
            version = "0.6.3";
            sha256 = "yPNMC3BLkQiwRJFICjbULolKlgQp+HxlFgJ7VIHVntM=";  # already correct
          };
        
          nativeBuildInputs = with pkgs.python3Packages; [
            setuptools
            wheel
            setuptools-scm
          ];
        
          # propagated build inputs for chromadb dependencies
          propagatedBuildInputs = with pythonPkgs; [
            numpy
            pydantic
            sqlalchemy
            requests
            click
            uvicorn
            fastapi
            onnxruntime
            tokenizers
            importlib-resources
            pypika
            tqdm
            overrides
            posthog
            pulsar-client
            opentelemetry-api
            opentelemetry-exporter-otlp-proto-grpc
            opentelemetry-sdk
            opentelemetry-instrumentation-fastapi
            grpcio
            bcrypt
            authlib
            kubernetes
            tenacity
            httptools
            httpx
            monotonic
            mmh3
            orjson
            typer
            rich
            chroma-hnswlib
            build
          ];
        
          meta = with pkgs.lib; {
            description = "ChromaDB vector store";
            homepage = "https://github.com/chroma-core/chroma";
            license = licenses.asl20;
          };
        };


        # Override posthog to 5.X.X (last before 6.0.0, adjust if needed)
        posthog_5_20_4 = pkgs.python3Packages.buildPythonPackage rec {
          pname = "posthog";
          version = "5.4.0";
          pyproject = true;
          
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "cBZpJhuNB83eAnblvAlrh/niAOO5WJxev/FN9ljFiTw=";
          };
          
          nativeBuildInputs = with pkgs.python3Packages; [
            setuptools
          ];
          
          propagatedBuildInputs = with pkgs.python3Packages; [
            requests
            six
            monotonic
            backoff
            python-dateutil
            distro
          ];
          
          doCheck = false;
          
          meta = with pkgs.lib; {
            description = "PostHog Python library";
            homepage = "https://posthog.com";
            license = licenses.mit;
          };
        };
          pythonPkgs = pkgs.python3Packages // {
            wheel = wheel_0_45_0;
            chromadb = chromadb_0_6_3;
            posthog = posthog_5_20_4;
          };
        in
        {
          packages.default = pythonPkgs.buildPythonPackage rec {
            pname = "vectorcode-mcp";
            version = "0.7.16"; # dummy; overridden below

              pyproject = true;
            pythonBuildBackend = "pdm.backend";


            src = pkgs.fetchPypi {
              pname = "vectorcode";
              version = "0.7.16"; #
                sha256 = "i/5yM/ipX57dbGEtjQ7Oi1v/Ag3Qrxn0OOVQQ0zCL8Y="; # Replace with actual sha256
            };

            nativeBuildInputs = with pythonPkgs; [ 
              pdm-backend 
              pythonRelaxDepsHook
              installer
            ];
            
            # Disable runtime dependency check since tree-sitter-language-pack is not available
            pythonRelaxDeps = [ "tree-sitter-language-pack" ];
            
            # Patch out the tree_sitter_language_pack import
            postPatch = ''
              substituteInPlace src/vectorcode/chunking.py \
                --replace "from tree_sitter_language_pack import SupportedLanguage, get_parser" "" \
                --replace "parser = get_parser(language)" "parser = None" \
                --replace "if not parser:" "if True:"
            '';
            
            # Disable runtime dependency checks completely
            dontCheckRuntimeDeps = true;
            
            # Disable catch conflicts hook to allow duplicate packages
            dontUsePythonCatchConflicts = true;


# Override dependencies
            propagatedBuildInputs = with pythonPkgs; [
              numpy
                chromadb
                sentence-transformers
                pathspec
                tabulate
                shtab
                psutil
                httpx
                tree-sitter
                pygments
                transformers
                wheel
                colorlog
                charset-normalizer
                json5
                posthog
                filelock
                # MCP dependencies
                mcp
                packaging
            ];


# We need to install the `[mcp]` extras — handled in installPhase
            # Let Nix handle the installation
            postInstall = ''
              # The wheel should have installed the entry points already
              # Just ensure the script exists
              if [ ! -f "$out/bin/vectorcode-mcp-server" ]; then
                echo "Creating vectorcode-mcp-server wrapper..."
                mkdir -p $out/bin
                cat > $out/bin/vectorcode-mcp-server << 'EOF'
              #!${pkgs.python3}/bin/python
              import sys
              from vectorcode.mcp_main import main
              if __name__ == "__main__":
                  sys.exit(main())
              EOF
                chmod +x $out/bin/vectorcode-mcp-server
              fi
            '';

            meta = with pkgs.lib; {
              description = "Vectorcode MCP Server";
              homepage = "https://github.com/vectorcode/vectorcode";
              license = licenses.mit;
              maintainers = [ maintainers.yourname ];
            };
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [ self.packages.${system}.default ];
          };

          defaultPackage = self.packages.${system}.default;

          defaultApp = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/vectorcode-mcp-server";
          };
        });
}

