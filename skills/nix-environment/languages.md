# Adding a language to the house template

Works for any stack nixpkgs can provide. Start from `templates/`, then fill the five slots below. Two worked examples close the file.

## The five slots

1. **Toolchain.**
   - Plain nixpkgs packages go straight into `nix/devshell.nix` `packages` as `pkgs.<name>`.
   - Wrapped or customised toolchains are built in the `flake.nix` `let` block, passed through `_module.args`, and taken as an argument in `nix/devshell.nix`. Examples: `python3.withPackages`, `flutter.override`, `androidenv.composeAndroidPackages`.
   - Native libraries that the language's packages link against also go here, for example `pkgs.pkg-config` and `pkgs.openssl`.
   - The devshell has no stdenv compiler. Add `pkgs.gcc` (or `pkgs.clang`) when anything links native code: Rust, C/C++, cgo, native extensions.
2. **Formatter and linter.** Add `programs.<name>.enable = true;` in `nix/treefmt.nix`. When the formatter must match the toolchain version, set its package in `flake.nix`:
   ```nix
   treefmt = treefmt-nix.lib.evalModule pkgs {
     imports = [ ./nix/treefmt.nix ];
     programs.dart-format.package = flutter.dart;
   };
   ```
   treefmt programs are not on PATH. When a CLI or editor calls the formatter directly, also add its package to `packages`. For example, `cargo fmt` and rust-analyzer need `pkgs.rustfmt`.
3. **Environment variables.** Add them to the `env` list in `nix/devshell.nix`, one `{ name = "..."; value = "..."; }` per variable. Point SDK homes at store paths, for example `"${pkgs.jdk21}"`. Use it to turn off telemetry and to bind servers to `127.0.0.1`.
4. **Commands.** Add these to the `commands` list in `nix/devshell.nix`:
   - `doctor`: print toolchain versions.
   - `run-tests`: never name it `test`, which is a shell builtin.
   - A dev server bound to `127.0.0.1`.
   - A build command, if the project has one.

   Use this shape:

   ```nix
   {
     name = "run-tests";
     category = "Quality"; # or "Development"
     help = "Run the test suite";
     command = ''
       set -euo pipefail
       cd "$PRJ_ROOT"
       exec cargo test "$@"
     '';
   }
   ```

5. **Excludes.**
   - Build output, caches and generated code go in both `settings.global.excludes` (treefmt) and `.gitignore`.
   - Language lockfiles go in treefmt excludes only. Commit them.

## Finding names

- Packages: `nix search nixpkgs <name>`. Confirm the version inside the shell afterwards with `nix develop -c <tool> --version`.
- treefmt programs: one file per program in <https://github.com/numtide/treefmt-nix/tree/main/programs>.

## Project dependencies: ask first

The toolchain always comes from Nix. For the project's own libraries, ask the user before writing anything, because the answer differs per project. Ask in the user's language, for example:

> Should the project's libraries be managed in `flake.nix` (all pinned by `flake.lock`), or by the language's package manager with a lockfile in the project (for example `npm ci`, `cargo`, `go mod`, `flutter pub get`)?

- **In `flake.nix`.** Everything is pinned by `flake.lock`, and the project works offline after the first build. Each library change means editing `flake.nix`, and libraries missing from nixpkgs must be packaged. Typical for Python with `python3.withPackages`.
- **Language package manager.** The project's lockfile pins the libraries. The package manager writes into the project (`node_modules/`, `target/`, `.dart_tool/`, `vendor/`). Typical for Node, Rust, Go and Dart, for example `flutter pub get` with `pubspec.lock`.

Record the answer in `env.md`, so later sessions follow it without asking again.

## Missing from nixpkgs

Build the package in the `flake.nix` `let` block with a fixed hash. Use the ecosystem builder: `python3Packages.buildPythonPackage`, `buildNpmPackage`, `rustPlatform.buildRustPackage` or `buildGoModule`. To get the hash, start with `hash = pkgs.lib.fakeHash;`, build, then copy the `got:` hash from the error. Add a one-line comment saying why the package is built here. Example, a Python package from a PyPI wheel:

```nix
# Not in nixpkgs, so it is built from the PyPI wheel that already contains the frontend.
streamlit-option-menu = pkgs.python3Packages.buildPythonPackage rec {
  pname = "streamlit_option_menu";
  version = "0.4.0";
  format = "wheel";
  src = pkgs.python3Packages.fetchPypi {
    inherit pname version format;
    dist = "py3";
    python = "py3";
    hash = "sha256-pV/HVUBHtts3FZWvIYLkNbiixxXuYSToVDaFvUZwsH4=";
  };
  dependencies = [ pkgs.python3Packages.streamlit ];
};
```

## Unfree or licensed SDKs

Replace `pkgs = nixpkgs.legacyPackages.${system};` with:

```nix
pkgs = import nixpkgs {
  inherit system;
  config = {
    allowUnfree = true;
    android_sdk.accept_license = true; # only for Android
  };
};
```

## Common stacks

Package names below are nixpkgs attributes (`pkgs.<name>`).

| Stack         | Toolchain                                                               | treefmt programs                                                   | Excludes                                                | Env                                                 |
| ------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------- | --------------------------------------------------- |
| Node / TS     | `nodejs` (+ `pnpm` if chosen)                                           | `biome`, or extend `prettier.includes` to `*.ts`, `*.tsx`, `*.css` | `node_modules/**`, `dist/**`, lockfile                  | —                                                   |
| Rust          | `cargo`, `rustc`, `clippy`, `rust-analyzer`, `rustfmt`, `gcc`           | `rustfmt` (set `edition` to match `Cargo.toml`), `taplo`           | `target/**`, `Cargo.lock`                               | `RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}"` |
| Go            | `go`, `gopls` (+ `gcc` for cgo)                                         | `gofumpt` or `gofmt`                                               | `bin/**`, `go.sum`                                      | —                                                   |
| Java / Kotlin | `jdk21`, `gradle` or `maven`, `kotlin`                                  | `google-java-format`, `ktfmt`                                      | `build/**`, `.gradle/**`, `target/**`                   | `JAVA_HOME = "${pkgs.jdk21}"`                       |
| C / C++       | `gcc` or `clang`, `cmake`, `gnumake`, `pkg-config`, `clang-tools`       | `clang-format`                                                     | `build/**`                                              | —                                                   |
| Python        | `python3.withPackages` (or `python3` + `uv`, per the dependency answer) | `ruff-check`, `ruff-format`                                        | `__pycache__/`, `.ruff_cache/`, `.pytest_cache/`        | —                                                   |
| Dart/Flutter  | `flutter` (override), `jdk17`, Android SDK                              | `dart-format` (package = `flutter.dart`)                           | `.dart_tool/**`, `build/**`, `*.g.dart`, `pubspec.lock` | `ANDROID_HOME`, `JAVA_HOME`                         |
| PHP           | `php`, `php.packages.composer`                                          | `php-cs-fixer`                                                     | `vendor/**`, `composer.lock`                            | —                                                   |
| Ruby          | `ruby`, `bundler`                                                       | `rubocop`                                                          | `vendor/**`, `Gemfile.lock`                             | —                                                   |
| Zig           | `zig`, `zls`                                                            | `zig`                                                              | `zig-out/**`, `.zig-cache/**`                           | —                                                   |

## Worked example: Python with libraries in `flake.nix`

`flake.nix` `let`:

```nix
python = pkgs.python3.withPackages (
  ps: with ps; [
    numpy
    pandas
    pytest
  ]
);
```

Pass it with `_module.args = { inherit python treefmt hooks; };`, take `python` as an argument in `nix/devshell.nix`, and add it to `packages`. In `nix/treefmt.nix`, enable `ruff-check` and `ruff-format`. Commands: `run-tests` (`exec python -m pytest tests "$@"`), and `doctor`, which prints versions via `importlib.metadata`.

## Worked example: Flutter + Android SDK

`flake.nix` uses the unfree `pkgs` import above, then:

```nix
androidSdk =
  (pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "36" ];
    buildToolsVersions = [ "36.0.0" ];
    ndkVersions = [ "28.2.13676358" ];
    includeNDK = true;
    includeEmulator = false;
  }).androidsdk;
flutter = pkgs.flutter.override {
  supportedTargetFlutterPlatforms = [
    "universal"
    "android"
    "web"
  ];
};
```

`env`:

- `ANDROID_HOME = "${androidSdk}/libexec/android-sdk"`
- `JAVA_HOME = "${pkgs.jdk17}"`

The SDK lives in the read-only Nix store. Change its versions in `flake.nix`. Never run `sdkmanager --install`, `flutter upgrade` or `flutter config --android-sdk`.
