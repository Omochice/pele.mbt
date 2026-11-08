{
  description = "sample description";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-packages = {
      url = "github:Omochice/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonbit-overlay = {
      url = "github:moonbit-community/moonbit-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pele = {
      url = "github:obsidianmd/pele/1.13.0";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      flake-utils,
      nur-packages,
      git-hooks,
      moonbit-overlay,
      pele,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nur-packages.overlays.default
            moonbit-overlay.overlays.default
          ];
        };
        # pele publishes only dist/, but the scripts also read its tests/ and package.json,
        # so the whole source tree is installed rather than what npm pack would keep.
        peleCheckout = pkgs.buildNpmPackage {
          pname = "pele";
          version = (pkgs.lib.importJSON "${pele}/package.json").version;
          src = pele;
          nodejs = pkgs.nodejs_24;
          npmDepsHash = "sha256-AXLKwNzyEKggUhcd6lILvTvComquC6ODTKvffIHjarc=";
          installPhase = ''
            runHook preInstall
            rm -rf node_modules
            cp -r . $out
            runHook postInstall
          '';
        };
        typstPackage = pkgs.stdenvNoCC.mkDerivation {
          pname = "pele-typst";
          version = (fromTOML (builtins.readFile ./typst/package/typst.toml)).package.version;
          src = pkgs.lib.fileset.toSource {
            root = ./.;
            fileset = pkgs.lib.fileset.unions [
              ./LICENSE
              ./LICENSE-PELE
              ./moon.work
              ./pele/moon.mod
              ./pele/src
              ./typst/moon.mod
              ./typst/src
              ./typst/package
              ./scripts/build-typst.mjs
              ./scripts/allocator.mjs
            ];
          };
          nativeBuildInputs = [
            pkgs.moonbit-bin.latest
            pkgs.nodejs_24
          ];
          buildPhase = ''
            runHook preBuild
            export HOME=$TMPDIR
            node scripts/build-typst.mjs
            runHook postBuild
          '';
          # typst.toml excludes the examples and the tests from the published package, so they are left out here too.
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp LICENSE LICENSE-PELE typst/package/{README.md,lib.typ,typst.toml,plugin.wasm} $out/
            runHook postInstall
          '';
        };
        typstExamples =
          pkgs.runCommand "pele-typst-examples"
            {
              nativeBuildInputs = [ pkgs.typst ];
              examples = ./typst/package/examples;
            }
            ''
              export HOME=$TMPDIR
              # The examples import ../lib.typ, so they are compiled from inside a copy of the package.
              cp -r ${typstPackage} package
              chmod -R u+w package
              cp -r $examples package/examples
              mkdir -p $out
              for file in package/examples/*.typ; do
                typst compile --root package "$file" "$out/$(basename "$file" .typ).pdf"
              done
            '';
        # moon publish packs whatever lies in the module directory, so the module is packed from git-tracked files alone, in the sandbox, rather than from a working tree that may hold builds or stray files.
        mooncakes = pkgs.stdenvNoCC.mkDerivation {
          name = "pele-mooncakes";
          src = pkgs.lib.fileset.toSource {
            root = ./.;
            fileset = pkgs.lib.fileset.unions [
              ./pele
              ./LICENSE
              ./LICENSE-PELE
            ];
          };
          nativeBuildInputs = [ pkgs.moonbit-bin.latest ];
          # The licenses stay at the repository root, where GitHub reads them, and are copied into the module only for the archive.
          buildPhase = ''
            runHook preBuild
            export HOME=$TMPDIR
            cp LICENSE LICENSE-PELE pele/
            (cd pele && moon package --target-dir $TMPDIR/build)
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r pele $out/source
            cp $TMPDIR/build/publish/*.zip $out/
            runHook postInstall
          '';
        };
        publish = pkgs.writeShellApplication {
          name = "publish";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.moonbit-bin.latest
          ];
          # A dirty flake still packs the uncommitted contents of tracked files, so the check reads the flake's own revision rather than the git status of whatever directory the app runs in.
          text = ''
            rev="${self.rev or ""}"
            if [ -z "$rev" ]; then
              echo "publish: the flake has uncommitted changes; commit or stash them first" >&2
              exit 1
            fi
            work=$(mktemp -d)
            trap 'rm -rf "$work"' EXIT
            cp -r ${mooncakes}/source/. "$work"
            chmod -R u+w "$work"
            cd "$work"
            moon publish --target-dir "$work/_build"
          '';
        };
        treefmt = treefmt-nix.lib.evalModule pkgs (
          { ... }:
          let
            rumdlConfig = (pkgs.formats.toml { }).generate "rumdl.toml" {
              # keep-sorted start
              MD004.style = "dash";
              MD007.indent = 4;
              MD007.style = "fixed";
              MD041.enabled = false;
              MD049.style = "underscore";
              MD050.style = "asterisk";
              MD055.style = "leading-and-trailing";
              MD060.enabled = true;
              MD060.style = "aligned";
              MD077.enabled = false;
              global.line_length = 0;
              # keep-sorted end
            };
          in
          {
            # .git is a file in a linked worktree, so the default .git/config would make treefmt format the main checkout instead.
            projectRootFile = "flake.nix";
            settings.global.excludes = [ "CHANGELOG.md" ];
            # moon fmt formats each package a file it is given belongs to, so its output matches moon fmt run by hand.
            settings.formatter.moon-fmt = {
              command = "${pkgs.moonbit-bin.latest}/bin/moon";
              options = [ "fmt" ];
              includes = [
                "*.mbt"
                "moon.mod"
                "moon.pkg"
              ];
            };
            settings.formatter.rumdl-format.options = [
              "--config"
              (toString rumdlConfig)
            ];
            programs = {
              # keep-sorted start block=yes
              keep-sorted.enable = true;
              nixfmt.enable = true;
              rumdl-format.enable = true;
              yamlfmt = {
                enable = true;
                settings = {
                  formatter = {
                    type = "basic";
                    retain_line_breaks_single = true;
                  };
                };
              };
              # keep-sorted end
            };
          }
        );
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          package = pkgs.prek;
          hooks = {
            # Claude Code sets CLAUDECODE; humans are covered by the pre-push hook
            gitleaks-commit = {
              enable = true;
              name = "gitleaks (claude commit)";
              entry = pkgs.lib.getExe (
                pkgs.writeShellApplication {
                  name = "gitleaks-when-claude";
                  runtimeInputs = [ pkgs.gitleaks ];
                  text = ''
                    if [ -z "''${CLAUDECODE:-}" ]; then
                      exit 0
                    fi
                    gitleaks git --pre-commit --staged --no-banner --redact
                  '';
                }
              );
              pass_filenames = false;
              stages = [ "pre-commit" ];
            };
            gitleaks-push = {
              enable = true;
              name = "gitleaks";
              entry = "${pkgs.lib.getExe pkgs.gitleaks} git --no-banner --redact";
              pass_filenames = false;
              stages = [ "pre-push" ];
            };
            treefmt = {
              enable = true;
              packageOverrides.treefmt = treefmt.config.build.wrapper;
              stages = [ "pre-push" ];
            };
          };
        };
        devPackages = rec {
          # keep-sorted start block=yes
          actions = with pkgs; [
            actionlint
            ghalint
            zizmor
          ];
          coverage = [ pkgs.octocov ];
          golden = with pkgs; [
            nodejs_24
          ];
          moonbit = with pkgs; [
            moonbit-bin.latest
          ];
          typst = [
            pkgs.typst
          ];
          # keep-sorted end
          default = [
            treefmt.config.build.wrapper
          ]
          ++ actions
          ++ coverage
          ++ golden
          ++ moonbit
          ++ typst;
        };
      in
      {
        # keep-sorted start block=yes
        apps.publish = {
          type = "app";
          program = pkgs.lib.getExe publish;
          meta.description = "Publish pele to mooncakes from git-tracked files";
        };
        checks = {
          # keep-sorted start
          actions =
            pkgs.runCommand "check-actions"
              {
                buildInputs = with pkgs; [
                  actionlint
                  ghalint
                  zizmor
                ];
                src = self;
              }
              ''
                cd $src
                actionlint -config-file .github/actionlint.yaml .github/**/*.{yaml,yml}
                ghalint run
                zizmor .github/workflows .github/actions
                touch $out
              '';
          formatting = treefmt.config.build.check self;
          pre-commit = pre-commit-check;
          renovate =
            pkgs.runCommand "validate-renovate-config"
              {
                buildInputs = with pkgs; [
                  renovate
                ];
                src = self;
              }
              ''
                cd $src
                renovate-config-validator --strict renovate.json5
                touch $out
              '';
          # keep-sorted end
        };
        devShells = pkgs.lib.pipe devPackages [
          (pkgs.lib.attrsets.mapAttrs (
            name: buildInputs:
            pkgs.mkShell (
              {
                buildInputs = buildInputs ++ pre-commit-check.enabledPackages;
                inherit (pre-commit-check) shellHook;
              }
              # Only the shells that run the scripts against pele build it on entry.
              // pkgs.lib.optionalAttrs (name == "golden" || name == "default") {
                PELE_ROOT = peleCheckout;
              }
            )
          ))
        ];
        formatter = treefmt.config.build.wrapper;
        packages = {
          # keep-sorted start
          default = typstPackage;
          mooncakes = mooncakes;
          typst-examples = typstExamples;
          typst-package = typstPackage;
          # keep-sorted end
        };
        # keep-sorted end
      }
    );
}
