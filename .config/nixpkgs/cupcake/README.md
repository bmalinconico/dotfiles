# Cupcake Nix Flake

A Nix flake for [Cupcake](https://cupcake.eqtylab.io/), a native policy enforcement layer for AI coding agents built on OPA/Rego.

## Usage

### Direct Run

```bash
nix run github:yourusername/dotfiles#cupcake -- --version
```

Or from this directory:

```bash
nix run . -- --version
```

### Development Shell

Enter a development shell with Cupcake and OPA (required dependency):

```bash
nix develop
```

### Build and Install

```bash
# Build the package
nix build

# Install to your profile
nix profile install .
```

### Add to Home Manager

Add to your `home.nix`:

```nix
{
  home.packages = [
    (pkgs.callPackage ./cupcake/flake.nix {}).packages.${pkgs.system}.default
  ];
}
```

Or add the flake as an input to your configuration.

## Requirements

Cupcake requires [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) to function. The development shell includes OPA automatically.

## Supported Platforms

- x86_64-linux
- aarch64-linux
- x86_64-darwin (macOS Intel)
- aarch64-darwin (macOS Apple Silicon)

## Version

Current version: **v0.5.1**

## Resources

- [Official Documentation](https://cupcake.eqtylab.io/)
- [GitHub Repository](https://github.com/eqtylab/cupcake)
- [Getting Started Guide](https://cupcake.eqtylab.io/getting-started/installation/)

## License

Apache License 2.0
