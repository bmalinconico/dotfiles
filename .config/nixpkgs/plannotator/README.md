# Plannotator Nix Flake

A Nix flake for [plannotator](https://github.com/backnotprop/plannotator), an interactive tool for reviewing and annotating AI coding agent plans.

## About Plannotator

Plannotator enables users to mark up and refine their plans using a visual UI, share for team collaboration with Claude Code and OpenCode. It supports:

- Plan approval and change requests with structured feedback
- Code review with inline annotations
- Image markup capabilities
- Team collaboration features

## Installation

### Using `nix run`

Run plannotator directly without installing:

```bash
nix run /home/brian/workspace/dotfiles/.config/nixpkgs/plannotator
```

Or from a git repository:

```bash
nix run github:backnotprop/plannotator  # If they add a flake
```

### Using `nix profile`

Install to your user profile:

```bash
nix profile install /home/brian/workspace/dotfiles/.config/nixpkgs/plannotator
```

### Using Home Manager (Recommended)

Create a profile file (e.g., `profiles/plannotator.nix`):

```nix
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
```

Then import it in your `base.nix` or `home.nix`:

```nix
{
  imports = [ ./plannotator.nix ];
  # ... rest of config
}
```

This will:
- Install the `plannotator` binary to your PATH
- Symlink the `/plannotator-review` skill to `~/.claude/commands/`

### Using `nix shell`

Enter a shell with plannotator available:

```bash
nix shell /home/brian/workspace/dotfiles/.config/nixpkgs/plannotator
plannotator --help
```

## Supported Platforms

- `x86_64-linux` (Linux x86_64)
- `aarch64-linux` (Linux ARM64)
- `x86_64-darwin` (macOS Intel)
- `aarch64-darwin` (macOS Apple Silicon)

## Version

Current version: **0.8.2**

## Usage

After installation, the `plannotator` binary will be available in your PATH.

For Claude Code integration, you'll need to separately install the plannotator plugin through the Claude Code plugin marketplace.

For OpenCode integration, add to your `opencode.json`:

```json
{
  "plugin": ["@plannotator/opencode@latest"]
}
```

## License

Plannotator is dual-licensed under Apache License 2.0 or MIT at your option.

## Links

- [GitHub Repository](https://github.com/backnotprop/plannotator)
- [Official Website](https://plannotator.ai)
