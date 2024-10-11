{
  description = "vector-systemd-secrets, a program for retrieving systemd credentials for vector's secrets.exec mechanism";

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      fenix,
      crane,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [
        inputs.devshell.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.pre-commit-hooks-nix.flakeModule
      ];

      perSystem =
        {
          config,
          pkgs,
          final,
          system,
          ...
        }:
        let
          craneLib = crane.mkLib pkgs;
          inherit (pkgs) lib;
          rustPlatform = pkgs.makeRustPlatform {
            inherit (fenix.packages.${system}.stable) rustc cargo;
          };
        in
        {
          formatter = pkgs.nixfmt-rfc-style;
          packages = {
            default = config.packages.vector-systemd-secrets;
            vector-systemd-secrets = rustPlatform.buildRustPackage {
              pname = "vector-systemd-secrets";
              version = "0.1.0";
              cargoLock.lockFile = ./Cargo.lock;
              src = craneLib.cleanCargoSource ./.;

              meta = {
                mainProgram = "vector-systemd-secrets";
                platforms = lib.platforms.linux;
              };
            };
          };

          devshells.default = {
            imports = [
              "${inputs.devshell}/extra/language/rust.nix"
            ];
            commands = [
              {
                category = "development";
                help = "setup the pre-commit hook for this repo";
                name = "setup-pre-commit";
                command = config.pre-commit.installationScript;
              }
            ];
            language.rust = {
              enableDefaultToolchain = false;
              packageSet = fenix.packages.${system}.stable;
              tools = [
                "rust-analyzer"
                "cargo"
                "clippy"
                "rustfmt"
                "rustc"
              ];
            };
          };

          pre-commit.settings = {
            hooks = {
              nixfmt-rfc-style.enable = true;
              rustfmt.enable = true;
            };
          };
        };
    };

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };
}
