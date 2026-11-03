;;; init.el --- James's Emacs, jProX edition -*- lexical-binding: t; -*-
;;; The editing core of the jNix setup, ported to Windows (MSYS2
;;; CLANGARM64 Emacs 31.1 on the Surface Pro X). Same completion
;;; stack, same theme, same markdown renderer, same cheatsheet and
;;; guide. Packages come from ELPA/MELPA here (Nix provides them on
;;; jNix), so the first launch downloads them; give it a minute.
;;;
;;; Deliberately not ported (jNix-only, or not editing core):
;;; mu4e mail and its image allowlist, the Google Calendar diary
;;; pipeline and the dashboard agenda section, forge, org-gcal,
;;; ghostel, envrc, nix-ts-mode, pdf-tools (Windows cannot build
;;; its server; PDFs open in the built-in DocView instead), and
;;; the Noctalia theme block. private.el is not copied either: it
;;; holds mail OAuth values. The guarded load below stays, so a
;;; private.el dropped in this directory later will be picked up.
;;;
;;; Ported later (2026-11-02): the dev layout (C-c L) from jNix,
;;; with a PowerShell 7 comint shell standing in for ghostel --
;;; ghostel, vterm and eat all need a PTY, which Windows Emacs
;;; does not have. See my/pwsh and my/layout-dev at the end.

;; Packages from ELPA + MELPA on this machine.
(require 'package)
;; Signature checking is disabled on this port, deliberately. The
;; MSYS2 CLANGARM64 build calls a POSIX gpg that mangles the
;; Windows-style homedir package.el hands it (first-launch log,
;; 2026-11-01: the keyring path came out doubled, prefixed with
;; the launch directory -- /c/Nextcloud/AppsPortable/EmacsCore/c:/
;; Users/boss/...), so verification of the signed GNU/NonGNU
;; archive contents can never succeed and package.el rejects
;; those archives wholesale (ef-themes was the first casualty).
;; Downloads still come only from the official archives over
;; HTTPS; what is given up is the archive signature layer.
(setq package-check-signature nil)
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(setq use-package-always-ensure t)

;; Vendored packages (2026-11-01): ef-themes, embark-consult, and
;; modus-themes ship inside this package under vendor/ instead of
;; being fetched from GNU ELPA -- that is the archive the broken
;; signature check above locks out, and rather than lean on the
;; workaround for the packages James actually noticed missing, they
;; ride along.  modus-themes is here because ef-themes 2.x is built
;; on it (Package-Requires: modus-themes "5.0.0"); ELPA would have
;; pulled it in automatically, the hand vendoring has to name it.
;; install.ps1 copies the vendor tree next to this file.
(add-to-list 'load-path
             (expand-file-name "vendor/modus-themes" user-emacs-directory))
(add-to-list 'load-path
             (expand-file-name "vendor/ef-themes" user-emacs-directory))
(add-to-list 'load-path
             (expand-file-name "vendor/embark-consult" user-emacs-directory))
(add-to-list 'custom-theme-load-path
             (expand-file-name "vendor/ef-themes" user-emacs-directory))

;; Clean UI
(setq inhibit-startup-screen t
      ring-bell-function 'ignore
      use-short-answers t)
(menu-bar-mode 1)
(tool-bar-mode 1)
(scroll-bar-mode 1)
(tab-bar-mode 1)
(pixel-scroll-precision-mode 1)              ; smooth scrolling
(add-to-list 'default-frame-alist '(alpha-background . 100))
(add-to-list 'default-frame-alist '(width . (text-pixels . 1440)))
(add-to-list 'default-frame-alist '(height . (text-pixels . 1380)))

;; Private values live in private.el, which is never shared or
;; committed. Not part of this port; the load stays as a hook.
(let ((private (expand-file-name "private.el" user-emacs-directory)))
  (when (file-exists-p private) (load private)))
;; The same font registers under different family names per source:
;; Scoop's nerd-fonts package calls it "JetBrainsMono NF", while
;; nixpkgs (jNix) uses "JetBrainsMono Nerd Font".  Ask for whichever
;; is actually installed.
(add-to-list 'default-frame-alist
             (cons 'font
                   (concat (if (member "JetBrainsMono NF" (font-family-list))
                               "JetBrainsMono NF"
                             "JetBrainsMono Nerd Font")
                           "-12")))
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(savehist-mode 1)
(recentf-mode 1)
(save-place-mode 1)
(which-key-mode 1)                           ; built in since Emacs 30

;; Completion stack. NOTE: global modes are switched on in :config,
;; not :init -- the nixpkgs builds do not autoload every mode
;; command, so calling them pre-load from :init fails with
;; void-function errors (verified the hard way, 2026-10-28).
(use-package vertico :config (vertico-mode))
(use-package orderless :custom (completion-styles '(orderless basic)))
(use-package marginalia :config (marginalia-mode))
(use-package consult :bind (("C-s" . consult-line)
                            ("C-x b" . consult-buffer)))
(use-package embark :bind (("C-." . embark-act)))
(use-package embark-consult :ensure nil :after (embark consult))
(use-package corfu :custom (corfu-auto t) :config (global-corfu-mode))

;; Tools
(use-package magit :bind ("C-x g" . magit-status))
(use-package doom-modeline :config (doom-modeline-mode 1))
(use-package nov
  :mode ("\\.epub\\'" . nov-mode))

;; Start pages (James's arrangement, 2026-10-28): a fresh frame
;; opens with the OG start page in tab 1 and the dashboard in tab 2.
;; The jNix dashboard's agenda section reads the Google Calendar
;; diary, which is not part of this port; recents and bookmarks
;; carry over.
(use-package dashboard
  :config
  (setq dashboard-startup-banner 'logo
        dashboard-items '((recents . 5) (bookmarks . 5))))
(defun my/frame-start-tabs ()
  "Give a new graphic client frame start tabs: OG page, then dashboard.
Runs on server-after-make-frame-hook, after emacsclient has done its
own initial buffer display (which otherwise stomps the OG page with
*scratch* in tab 1)."
  (let ((frame (selected-frame)))
    (when (and (frame-parameter frame 'client)
               (display-graphic-p frame))
      (with-selected-frame frame
        (display-about-screen)
        (when (require 'dashboard nil t)
          (tab-bar-new-tab)
          (dashboard-open)
          (tab-bar-select-tab 1))))))
(add-hook 'server-after-make-frame-hook #'my/frame-start-tabs)
;; A plain runemacs launch has no client frame, so arrange the same
;; two tabs once at startup.
(add-hook 'window-setup-hook
          (lambda ()
            (when (and (display-graphic-p) (not (daemonp)))
              (display-about-screen)
              (when (require 'dashboard nil t)
                (tab-bar-new-tab)
                (dashboard-open)
                (tab-bar-select-tab 1)))))

;; Markdown (James's pick, 2026-10-28; formatted-first, 2026-10-30;
;; true render, 2026-10-31). A markdown file opens with two tabs: a
;; RENDERED view (pandoc -> HTML -> shr, so tables come out as actual
;; tables; markdown-mode's view mode cannot render tables) and a RAW
;; twin for editing. Saving the raw buffer re-renders the view. If
;; pandoc is ever missing, the opener falls back to markdown-mode's
;; view modes (headers render; tables stay raw). On jProX pandoc is
;; the Scoop build (x86_64 under emulation; invisible in practice).
(defvar-local my/markdown-twin-done nil
  "Non-nil in a buffer that already has (or is) a markdown raw twin.")
(defvar-local my/markdown-view-buffer nil
  "In a raw markdown buffer: its rendered view buffer.")
(defvar-local my/markdown-source-buffer nil
  "In a rendered view buffer: the raw buffer it renders.")

(defun my/markdown--pandoc ()
  "Path to pandoc, or nil."
  (require 'cl-lib)
  (or (executable-find "pandoc")
      (cl-find-if #'file-executable-p
                  '("/etc/profiles/per-user/boss/bin/pandoc"
                    "/home/boss/.nix-profile/bin/pandoc"
                    "/run/current-system/sw/bin/pandoc"
                    "/usr/bin/pandoc"))))

(defun my/markdown--style-table (table)
  "Return TABLE (one pandoc <table>...</table> string) with a
separator row inserted before each body row: a single cell spanning
all columns and holding an <hr>, which shr renders as a full-width
rule. shr ignores CSS table borders, hence this workaround."
  (let* ((cols (if (string-match "<thead>\\(\\(?:.\\|\n\\)*?\\)</thead>" table)
                   (let ((head (match-string 1 table)) (n 0) (idx 0))
                     (while (string-match "<th>" head idx)
                       (setq n (1+ n) idx (match-end 0)))
                     n)
                 1))
         (sep (format "<tr><td colspan=\"%d\"><hr></td></tr>\n" cols)))
    (if (string-match "<tbody>" table)
        (let ((before (substring table 0 (match-end 0)))
              (after (substring table (match-end 0))))
          (concat before
                  (replace-regexp-in-string "<tr>" (concat sep "<tr>")
                                            after nil t)))
      table)))

(defun my/markdown--styled (html)
  "Add row separators to every pandoc table in HTML."
  (let ((case-fold-search nil) (pos 0) (chunks '()))
    (while (string-match "<table>\\(\\(?:.\\|\n\\)*?\\)</table>" html pos)
      (let ((beg (match-beginning 0))
            (end (match-end 0))
            (tbl (match-string 0 html)))
        (push (substring html pos beg) chunks)
        (push (my/markdown--style-table tbl) chunks)
        (setq pos end)))
    (push (substring html pos) chunks)
    (apply #'concat (nreverse chunks))))

(defun my/markdown--render (source view)
  "Render SOURCE buffer's markdown into VIEW buffer via pandoc + shr."
  (require 'shr)
  (let ((html (with-current-buffer source
                (let ((tmp (generate-new-buffer " *md-html*")))
                  (unwind-protect
                      (progn
                        (call-process-region
                         (point-min) (point-max)
                         (my/markdown--pandoc) nil tmp nil
                         "-f" "commonmark_x+wikilinks_title_after_pipe" "-t" "html5")
                        (with-current-buffer tmp (buffer-string)))
                    (kill-buffer tmp))))))
    (with-current-buffer view
      (let ((inhibit-read-only t)
            (pos (point)))
        (erase-buffer)
        (insert (my/markdown--styled html))
        (shr-render-region (point-min) (point-max))
        (goto-char (min pos (point-max))))
      (setq buffer-read-only t)
      (set-buffer-modified-p nil))))

(defun my/markdown--refresh-view ()
  "after-save-hook: re-render the view of the just-saved raw buffer."
  (when (and my/markdown-view-buffer
             (buffer-live-p my/markdown-view-buffer))
    (my/markdown--render (current-buffer) my/markdown-view-buffer)))

(defun my/markdown-rerender ()
  "Re-render this view buffer from its source buffer (bound to g)."
  (interactive)
  (if (and my/markdown-source-buffer
           (buffer-live-p my/markdown-source-buffer))
      (my/markdown--render my/markdown-source-buffer (current-buffer))
    (message "Source buffer is gone; nothing to re-render from")))

(define-derived-mode my/markdown-rendered-mode special-mode "Markdown-Render"
  "Major mode for the rendered view of a markdown file."
  (setq buffer-read-only t))
(define-key my/markdown-rendered-mode-map (kbd "g") #'my/markdown-rerender)

(defun my/markdown--view-with-raw-twin (view-mode raw-mode)
  "Run VIEW-MODE here, then open a raw twin in RAW-MODE in the next tab."
  (require 'markdown-mode)
  (setq markdown-header-scaling t)
  (funcall view-mode)
  (when (and (buffer-file-name)
             (not my/markdown-twin-done)
             (bound-and-true-p tab-bar-mode))
    (setq my/markdown-twin-done t)
    ;; tab-bar-new-tab changes the current buffer, so pin the source
    ;; buffer first and clone inside with-current-buffer.
    (let ((source (current-buffer))
          (view-tab (1+ (tab-bar--current-tab-index))))
      (tab-bar-new-tab)
      (let ((raw (with-current-buffer source
                   (clone-indirect-buffer
                    (generate-new-buffer-name
                     (concat (buffer-name) " (raw)"))
                    nil))))
        (switch-to-buffer raw)
        (with-current-buffer raw
          (funcall raw-mode)
          (setq my/markdown-twin-done t)))
      (tab-bar-select-tab view-tab))))

(defun my/markdown-open (gfm)
  "Open this markdown file: rendered view tab + raw tab for editing.
With GFM non-nil the raw side uses gfm-mode. Falls back to
markdown-mode's view modes when pandoc is unavailable."
  (require 'markdown-mode)
  (if (not (my/markdown--pandoc))
      (my/markdown--view-with-raw-twin
       (if gfm #'gfm-view-mode #'markdown-view-mode)
       (if gfm #'gfm-mode #'markdown-mode))
    (funcall (if gfm #'gfm-mode #'markdown-mode))
    (when (and (buffer-file-name) (not my/markdown-view-buffer))
      (let* ((raw (current-buffer))
             (plain (buffer-name))
             (dir default-directory))
        (rename-buffer (concat plain " (raw)"))
        (let ((view (generate-new-buffer plain)))
          (with-current-buffer view
            (setq default-directory dir)
            (my/markdown-rendered-mode)
            (setq my/markdown-source-buffer raw))
          (with-current-buffer raw
            (setq my/markdown-view-buffer view)
            (add-hook 'after-save-hook #'my/markdown--refresh-view nil t))
          (my/markdown--render raw view)
          (when (bound-and-true-p tab-bar-mode)
            (let ((view-tab (1+ (tab-bar--current-tab-index))))
              (switch-to-buffer view)
              (tab-bar-new-tab)
              (switch-to-buffer raw)
              (tab-bar-select-tab view-tab))))))))

(defun my/markdown-view ()
  "Open this file rendered, with a raw tab for editing."
  (interactive)
  (my/markdown-open nil))

(defun my/gfm-view ()
  "Open this file rendered (GFM raw side), with a raw tab for editing."
  (interactive)
  (my/markdown-open t))

(use-package markdown-mode
  :custom
  (markdown-header-scaling t))

;; Take ownership of the three filename patterns: delete any stock
;; auto-mode entry with the same regexp (the package registers its
;; own), then add mine. Which entry wins among duplicates is an
;; Emacs-version detail; with only one entry per pattern there is
;; nothing to argue about.
;; add-to-list prepends, so the narrow patterns are added last:
;; the README entry must end up at the head of auto-mode-alist,
;; ahead of the plain .md entry, which also matches README.md.
(dolist (entry '(("\\.markdown\\'" . my/markdown-view)
                 ("\\.md\\'" . my/markdown-view)
                 ("README\\.md\\'" . my/gfm-view)))
  (setq auto-mode-alist
        (seq-remove (lambda (e) (equal (car e) (car entry)))
                    auto-mode-alist))
  (add-to-list 'auto-mode-alist entry))

;; James's theme pick (2026-10-29): ef-melissa-light (ef-themes).
;; On jNix it sits after a Noctalia theme block; there is no
;; Noctalia here, so the pick simply wins.
(use-package ef-themes :ensure nil)
;; Guarded: a missing theme package must never fail init. On the
;; first jProX launch (2026-11-01) ef-themes failed to install and
;; the bare load-theme escalated into an initialization error.
(if (locate-library "ef-themes")
    (load-theme 'ef-melissa-light t)
  (message "ef-themes not installed; ef-melissa-light theme skipped"))

;; Personal cheatsheet (Emacs terms, translated to plain English).
(defun my/open-cheatsheet ()
  "Open the Emacs cheatsheet page."
  (interactive)
  (find-file-read-only (expand-file-name "cheatsheet.org" user-emacs-directory)))
(global-set-key (kbd "C-c h") #'my/open-cheatsheet)

;; Getting-around guide (navigation + the features as configured here).
(defun my/open-guide ()
  "Open the Emacs getting-around guide."
  (interactive)
  (find-file-read-only (expand-file-name "guide.org" user-emacs-directory)))
(global-set-key (kbd "C-c g") #'my/open-guide)

;; Terminal: PowerShell 7 in a comint shell (the ghostel stand-in;
;; see the header note). C-c t mirrors the jNix ghostel binding.
(defun my/pwsh--exe ()
  "Path to pwsh.exe (PowerShell 7), or nil when not installed.
Checks PATH first (Scoop puts it there), then the standard MSI
location and the per-user Scoop location."
  (or (executable-find "pwsh")
      (cl-find-if #'file-executable-p
                  '("C:/Program Files/PowerShell/7/pwsh.exe"
                    "~/scoop/apps/pwsh/current/pwsh.exe"))))

(defun my/pwsh ()
  "Open a PowerShell 7 shell in the *PowerShell* buffer.
Falls back to the default shell (cmd) with a warning when
PowerShell 7 is not installed."
  (interactive)
  (require 'cl-lib)
  (require 'shell)  ; defines shell-file-name and explicit-shell-file-name
  (let ((exe (my/pwsh--exe)))
    (unless exe
      (message "PowerShell 7 (pwsh) not found; using the default shell"))
    (let ((shell-file-name (or exe shell-file-name))
          (explicit-shell-file-name (or exe explicit-shell-file-name)))
      (shell "*PowerShell*"))))
(global-set-key (kbd "C-c t") #'my/pwsh)

;; Dev layout: main pane + cheatsheet right + terminal strip below.
;; Ported from jNix (2026-11-02), where the strip is ghostel; here
;; it is the PowerShell 7 shell. The default main-pane target is
;; this init.el, the Surface counterpart of /etc/nixos/home.nix.
(defun my/layout-dev (&optional target)
  "Build the dev layout in the current frame.
Main pane (top left): TARGET, a file or directory (default
this init.el in `user-emacs-directory'; a directory opens in
Dired).  Right half: the cheatsheet.  Bottom quarter, full
width: a PowerShell 7 terminal.  With a prefix argument,
prompt for TARGET."
  (interactive
   (list (when current-prefix-arg
           (read-file-name "Main pane: " user-emacs-directory
                           (expand-file-name "init.el" user-emacs-directory)
                           t))))
  (delete-other-windows)
  (find-file (or target (expand-file-name "init.el" user-emacs-directory)))
  (let ((bottom (split-window-below (floor (* (window-height) 0.75))))
        (right (split-window-right)))
    (select-window right)
    (my/open-cheatsheet)
    (select-window bottom)
    (my/pwsh)
    (unless (eq (window-buffer bottom) (get-buffer "*PowerShell*"))
      (when (get-buffer "*PowerShell*")
        (set-window-buffer bottom (get-buffer "*PowerShell*"))))
    (select-window (frame-first-window))))
(global-set-key (kbd "C-c L") #'my/layout-dev)

;;; init.el ends here
