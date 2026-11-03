#!/usr/bin/env bash
# build-source.sh <emacs-version> — compile a GNU Emacs release
# tarball in MSYS2 CLANGARM64 and stage it under dist/ in the same
# layout package-msys2.sh produces.
#
# Runs inside the MSYS2 CLANGARM64 shell on a windows-11-arm runner,
# after msys2/setup-msys2 has installed the toolchain and the
# mingw-w64-clang-aarch64-* dependency set (see the workflow file).
set -euo pipefail

VER="${1:?usage: build-source.sh <emacs-version>}"
STAGE="$GITHUB_WORKSPACE/dist/emacs-$VER-windows-arm64"
rm -rf "$STAGE"

TARBALL="emacs-$VER.tar.xz"
if [ ! -f "$TARBALL" ]; then
  curl -fLO "https://ftpmirror.gnu.org/emacs/$TARBALL" \
    || curl -fLO "https://ftp.gnu.org/gnu/emacs/$TARBALL"
  curl -fLO "https://ftpmirror.gnu.org/emacs/$TARBALL.sig" \
    || curl -fLO "https://ftp.gnu.org/gnu/emacs/$TARBALL.sig"
fi
# Verify the tarball against the GNU keyring before building it.
if [ -f "$TARBALL.sig" ]; then
  curl -fsLO "https://ftp.gnu.org/gnu/gnu-keyring.gpg"
  gpg --import gnu-keyring.gpg >/dev/null 2>&1
  gpg --verify "$TARBALL.sig" "$TARBALL"
fi
tar -xf "$TARBALL"
cd "emacs-$VER"

# The Windows build is configured from nt/ and built from the top.
# --with-native-compilation=no matches what CLANGARM64 packaging
# can do today (libgccjit is a GCC component; under the Clang
# ARM64 toolchain it is not available). Flip it if that changes.
PREFIX_WIN="$(cygpath -wm "$STAGE")"
( cd nt && ./configure \
    --prefix="$PREFIX_WIN" \
    --with-tree-sitter \
    --with-sqlite3 \
    --with-gnutls \
    --with-xml2 \
    --with-modules \
    --with-native-compilation=no \
    --without-pop )

MAKE=make
command -v mingw32-make >/dev/null 2>&1 && MAKE=mingw32-make
"$MAKE" -j"$(nproc)"
"$MAKE" install

"$STAGE/bin/emacs.exe" --version | head -1
CFG="$("$STAGE/bin/emacs.exe" --batch --eval '(message "%s" system-configuration)' 2>&1)"
echo "system-configuration: $CFG"
case "$CFG" in
  *aarch64*) ;;
  *) echo "unexpected system-configuration: $CFG" >&2; exit 1 ;;
esac

echo "$VER" > "$GITHUB_WORKSPACE/dist/VERSION.txt"
echo "staged at $STAGE"
