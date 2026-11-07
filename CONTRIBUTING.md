# Contributing

`nix develop` provides moon, node and typst.
It also builds the pele that the checks compare against.

```sh
nix develop
moon test --target wasm
```

[doc/testing.md](doc/testing.md) lists the other checks.

## Publishing

`moon publish` uploads every file in the module directory, so pele is published to mooncakes from the git-tracked files the flake sees rather than from the working tree, where builds and untracked files would be uploaded with them.

```sh
moon login
nix build .#mooncakes
nix run .#publish
```

`nix build .#mooncakes` packs pele in the nix sandbox and leaves the archive that would be uploaded, so its contents can be read first.
`nix run .#publish` publishes that same tree with the credentials `moon login` saved under `~/.moon`.
