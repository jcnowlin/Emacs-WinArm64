#!/usr/bin/env bash
# package-msys2.sh — bundle MSYS2's published ARM64 Emacs into a
# portable tree under dist/.
#
# Runs inside the MSYS2 CLANGARM64 shell on a windows-11-arm runner,
# after msys2/setup-msys2 has installed mingw-w64-clang-aarch64-emacs
# (setup-msys2 resolves and installs its runtime dependencies too,
# so the prefix's bin/ holds the full DLL closure).
set -euo pipefail

PREFIX="${MSYSTEM_PREFIX:-/clangarm64}"
if [ ! -x "$PREFIX/bin/emacs.exe" ]; then
  echo "emacs.exe not found under $PREFIX/bin — is the package installed?" >&2
  exit 1
fi

VER="$(pacman -Q mingw-w64-clang-aarch64-emacs | awk '{print $2}' | cut -d- -f1)"
echo "packaging MSYS2 Emacs $VER from $PREFIX"

STAGE="$GITHUB_WORKSPACE/dist/emacs-$VER-windows-arm64"
rm -rf "$STAGE"
mkdir -p "$STAGE"

# Copy the runtime tree. bin/ carries the executables, the pdmp
# dump, and every dependency DLL; lib/ carries Emacs's exec
# directory; share/ carries the Lisp tree; etc/ comes along when
# present (fonts and friends).
for d in bin lib share etc; do
  if [ -d "$PREFIX/$d" ]; then
    cp -a "$PREFIX/$d" "$STAGE/$d"
  fi
done

# Conservative prune: static/import libraries, headers, and
# pkg-config files are build-time material, useless at runtime.
find "$STAGE" -name '*.a' -delete
rm -rf "$STAGE/include" "$STAGE/lib/pkgconfig" "$STAGE/share/pkgconfig"

# Self-test inside the staging tree before the workflow zips it.
"$STAGE/bin/emacs.exe" --version | head -1
CFG="$("$STAGE/bin/emacs.exe" --batch --eval '(message "%s" system-configuration)' 2>&1)"
echo "system-configuration: $CFG"
case "$CFG" in
  *aarch64*) ;;
  *) echo "unexpected system-configuration: $CFG" >&2; exit 1 ;;
esac

echo "$VER" > "$GITHUB_WORKSPACE/dist/VERSION.txt"
echo "staged at $STAGE"
