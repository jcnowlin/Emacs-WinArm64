# Emacs on jProX — the editing core of the jNix setup

This folder is `config/` in the jcnowlin/Emacs-WinArm64 repo. It
carries the editing core of James's jNix Emacs over to the Surface:
the completion stack (Vertico/Orderless/Marginalia/Consult/
Corfu/Embark), Magit, doom-modeline, the ef-melissa-light theme, the
pandoc markdown renderer (markdown opens rendered, with a raw editing
tab), the cheatsheet (`C-c h`) and guide (`C-c g`), the two-tab start
page, EPUB reading with nov, and (since 2026-11-02) the dev layout
from jNix: `C-c L` builds main pane + cheatsheet + terminal strip,
with a PowerShell 7 shell (`C-c t`) standing in for ghostel.

Not included, on purpose: mu4e mail, the Google Calendar diary and
dashboard agenda, forge, envrc, nix-ts-mode, and pdf-tools
(its server component does not build on Windows; PDFs open in the
built-in DocView). private.el is not copied: it holds mail secrets,
and it never goes in this repo.

Config updates ship as `emacscore-config.zip`: attached to every
binary release, and kept current on the rolling `config-latest`
release whenever `config/` changes on main. Download, unzip, run
install.ps1 — that is the whole update.

## Step 1 — Emacs itself (native ARM64)

Download the latest binary release from this repo (tag
`emacs-<version>-arm64`) and unzip it where you keep portables,
e.g. `C:\Nextcloud\AppsPortable\Emacs\`. The zip is the portable
bundle this repo's workflow builds from MSYS2's native ARM64 Emacs;
run its `bin\runemacs.exe`.

Manual alternative: MSYS2 ships the same build. Install MSYS2 from
https://www.msys2.org, open the **MSYS2 CLANGARM64** terminal,
`pacman -Syu`, then `pacman -S mingw-w64-clang-aarch64-emacs`.

## Step 2 — the supporting tools (Scoop, PowerShell)

- PowerShell 7 — the `C-c t` terminal and the dev layout's bottom
  pane run it. On jProX it is the GUI .msi install
  (`C:\Program Files\PowerShell\7\pwsh.exe`, also on PATH);
  `scoop install pwsh` works too. (Without it, the terminal falls
  back to cmd.)
- `scoop install pandoc` — the markdown renderer shells out to pandoc.
  There is no native Windows ARM64 pandoc; the x86_64 build runs under
  emulation and is only ever a background converter here, so the cost
  is invisible.
- Optional, for the same font as jNix:
  `scoop bucket add nerd-fonts` then `scoop install JetBrainsMono-NF`.
  Without it Emacs falls back to a default font; nothing breaks.
- Magit needs `git` on the Windows PATH (you already have it; if not,
  `scoop install git`).

## Step 3 — install the config

In PowerShell, from this folder:

```powershell
.\install.ps1
```

It copies `init.el`, `cheatsheet.org`, `guide.org`, and `bookmarks`
into `%APPDATA%\.emacs.d`. An existing init.el there gets backed up
once to `init.el.pre-jprox-port`. Re-running the script is how config
updates land.

## Step 4 — launch

Run the bundle's `bin\runemacs.exe` (or
`C:\msys64\clangarm64\bin\runemacs.exe` for the MSYS2 route; pin
it wherever you like). The first launch downloads the packages from ELPA/MELPA, so
keep it online and give it a few minutes; after that it starts as
fast as anywhere. A fresh window opens with the About page in tab 1
and the dashboard in tab 2, same as jNix.

## Notes and known gaps

- If Emacs opens with none of this config, check whether a `HOME`
  environment variable is set: with one, Emacs looks in
  `$HOME\.emacs.d` instead of `%APPDATA%\.emacs.d`. The install
  script warns about this when it sees one. Tell Bill; it is a
  five-minute adjustment.
- The seeded bookmarks (init.el, cheatsheet, guide) assume the
  Windows user is `boss`. Wrong paths would just be dead bookmarks;
  delete them with `C-x r l` if so.
- Bookmarks and recent files on the dashboard fill in as you work,
  same as on jNix.
- The guide (`C-c g`) is shared with jNix and a few of its sections
  describe the jNix-only parts (Gmail/mu4e, the calendar feed,
  ghostel, envrc, the Nix language server). Those features are not
  in this port; the sections are context, not instructions.
- The cheatsheet text mentions a `~/.config/emacs` path in passing;
  on this machine the files live in `%APPDATA%\.emacs.d`. `C-c h`
  finds them regardless.
