# Emacs for Windows ARM64, built by GitHub Actions

A GitHub Actions workflow that produces a portable, self-contained
Emacs for the Surface Pro X (SQ1, Windows 11 ARM64), so updating
Emacs on the Surface stops being a manual MSYS2 chore.

## Why GitHub and not Forgejo

A Windows ARM64 Emacs must be built on Windows ARM64: the toolchain
is MSYS2's CLANGARM64 (Clang is the only compiler emitting GNU-ABI
Windows ARM64 binaries), and Emacs's Windows port does not
cross-compile from Linux. Forgejo Actions would need a Windows
ARM64 runner machine, and the only one in the house is the Surface
itself. GitHub hosts the machine: the `windows-11-arm` runner.

## Files

- `emacs-windows-arm64.yml` — the workflow. Put it at
  `.github/workflows/emacs-windows-arm64.yml` in the repo.
- `package-msys2.sh`, `build-source.sh` — the build scripts. Put
  them at `.github/workflows/scripts/` in the repo.
- `config/` — the EmacsCore config (init.el, cheatsheet, guide,
  bookmarks, vendored packages, install.ps1). See below.

Repo: `jcnowlin/Emacs-WinArm64`, public. Public because the ARM
runner minutes are free for public repos and the repo contains
nothing but these build scripts. Private works too; a monthly run
costs a few billed minutes.

## How it runs

- **Monthly**, on the 3rd at 06:17 UTC, using the repackage method.
- **On demand**: Actions tab → "Emacs Windows ARM64" → Run workflow,
  choosing `repackage` or `source` (source takes an Emacs version,
  default 31.1).
- Each run stages a bundle, smoke-tests it (the built `emacs.exe`
  must run and report an `aarch64` configuration), zips it, and
  uploads it as a workflow artifact.
- If that Emacs version has no release yet, the run also publishes
  a GitHub Release tagged `emacs-<version>-arm64` with the zip
  attached. Scheduled runs are quiet no-ops when MSYS2's Emacs
  version hasn't moved.

## The two methods

- **repackage** (default): installs MSYS2's own published
  `mingw-w64-clang-aarch64-emacs` — the same package the Surface's
  current Emacs 31.1 came from — into a clean runner, copies the
  runtime tree (bin, lib, share, etc) into a bundle, prunes
  build-time files (static libs, headers, pkg-config), and zips it.
  Minutes per run.
- **source**: downloads the GNU release tarball and compiles it in
  CLANGARM64 with tree-sitter, sqlite3, gnutls, libxml2, modules,
  and image libraries. For when MSYS2's configure choices aren't
  the ones wanted. Tens of minutes per run.

## Installing a bundle on the Surface

1. Download the zip from the repo's Releases page.
2. Unzip it where you keep portables, e.g.
   `C:\Nextcloud\AppsPortable\Emacs\` — the zip contains a single
   `emacs-<version>-windows-arm64` folder.
3. Point the Start Menu Emacs shortcut at the new
   `bin\runemacs.exe` inside that folder.
4. Done. The bundle is independent of the Surface's MSYS2 install,
   and it never touches `%APPDATA%\.emacs.d`, so the EmacsCore
   config (init.el, the vendored packages, the cheatsheet and
   guide) carries over untouched.

## The EmacsCore config

The `config/` folder is the Surface's Emacs configuration, the
editing core of the jNix setup ported to Windows (see
`config/README.md` for what is in it and what is deliberately not).
It ships as `emacscore-config.zip`, attached to every binary
release and kept current on the rolling `config-latest` release by
the config-release workflow whenever `config/` changes on main.
Updating the Surface's config: download that zip, unzip, run
`config/install.ps1`. private.el (mail secrets) is never part of
this repo.

## Known deltas and caveats

- **No native compilation**, in either method: libgccjit is a GCC
  component and isn't available under the CLANGARM64 toolchain, and
  MSYS2's packaged build is in the same boat. Your jNix Emacs keeps
  its native-comp; the Surface build stays byte-compiled, same as
  today.
- **First run is the real test.** These files are syntax-checked
  but have never executed on a runner; expect the possibility of a
  small fix-up round (a package name, a path) on the first dispatch.
- Bundle size is a few hundred MB zipped: the runtime tree carries
  every dependency DLL and the full Lisp tree, which is what makes
  it portable.
