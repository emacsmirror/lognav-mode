;;; log-mode.el --- Navigate Log Error Messages -*- lexical-binding:t -*-

;; Copyright (C) 2016 - 2017

;; Author: Shawn Ellis <shawn.ellis17@gmail.com>
;; Version: 0.0.4
;; Package-Requires: ((emacs "24.3"))
;; URL: https://bitbucket.org/ellisvelo/log-mode
;; Keywords: log error log-mode convenience
;;

;; log-mode.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; log-mode.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Log-mode is a minor mode used for finding and navigating errors within a
;; buffer or a log file. The keybinding M-n moves the cursor to the first error
;; within the log file.  M-p moves the cursor to the previous error.  Log-mode
;; only highlights the errors that are visible on the screen rather than
;; highlighting all errors found within the buffer. This is especially useful
;; when opening up large log files for analysis.

;; Add the following line in your .emacs file to use Log-mode:
;;
;; (require 'log-mode)
;;
;;
;; The following bindings are created for Log-mode:
;; M-n   - Next log error            Moves the cursor to the next error
;; M-p   - Previous log error        Moves the cursor to the previous error
;;

(require 'easymenu)

;;; Code:

(defvar log-exception-regexp "\\(ERROR\\)\\|\\(WARNING\\)\\|\\(SEVERE\\)\\|\\(Caused by:\\)\\|\\(nested exception is:\\)"
  "Regular expression used for navigating errors.")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.log\\.?[0-9]*\\'" . log-mode))

(defvar log-mode-map nil)

(defface log-highlight-face
  '((t (:inherit error :underline nil)))
    "Face for highlighting the line that has an error message."
  :group 'log-mode)

(unless log-mode-map
  (setq log-mode-map (make-sparse-keymap "Log mode"))
  (define-key log-mode-map "\M-p" 'log-previous-error)
  (define-key log-mode-map "\M-n" 'log-next-error))

(easy-menu-define log-menu log-mode-map
  "'log-mode' menu"
  '("Log"
    ["Next Error" log-next-error t]
    ["Previous Error" log-previous-error t]
    ["Error Occur" log-error-occur t]
    ))

(defvar-local log-mode-idle-registered nil
  "Returns t if an idle timer has already been registered.")

;;;###autoload
(defun log-previous-error()
  "Moves the point to the previous error."
  (interactive)
  (move-beginning-of-line 1)
  (when (search-backward-regexp log-exception-regexp nil t)
      (move-beginning-of-line nil)
      (log-highlight-visible)))

;;;###autoload
(defun log-next-error()
  "Moves the point forward to the next error."
  (interactive)
  (let ((current (point)))
    (move-end-of-line 1)
    (if (search-forward-regexp log-exception-regexp nil t)
	(progn
	  (move-beginning-of-line 1)
	  (log-highlight-visible))
      (goto-char current))))


(defun log-highlight-region (begin end)
  "Highlight the region specified by BEGIN and END."
  (let  ((log-overlay (make-overlay begin end)))
    (overlay-put log-overlay 'log-overlay t)
    (overlay-put log-overlay 'face 'log-highlight-face)
    log-overlay))

(defun log-highlight-error (begin end)
  "Highlight any error within the region specified by BEGIN and END."
  (let ((current (point)))
    (goto-char begin)
    (while (search-forward-regexp log-exception-regexp end t)
      (if (not (log-overlay? (line-beginning-position)))
	  (log-highlight-region (line-beginning-position) (line-end-position))))
    (goto-char current)))

(defun log-highlight-position (lines)
  "Return the position based upon the line number."
  (save-excursion
    (forward-line lines)
    (point)))

(defun log-overlay? (pos)
  "Return the log overlay if it exists or nil."
  (car (delq nil (mapcar (lambda (x) (overlay-get x 'log-overlay))
			 (overlays-at pos)))))

(defun log-highlight-visible ()
  "Highlights the errors that are visible on the screen."
  (interactive)
  (when (not buffer-read-only)
    (let* ((height (frame-height))
	   (start (log-highlight-position (* -1 height)))
	   (end (log-highlight-position height)))

      (log-highlight-error start end))))

;;;###autoload
(defun log-error-occur ()
  "Create an Occur buffer with the matching errors."
  (interactive)
  (occur log-exception-regexp))

(defun log-mode-after-change (_begin _end _ignored)
  "Highlight the visible errors when a buffer is idle for 3 seconds."

  (when (not log-mode-idle-registered)
    (let ((buf (current-buffer)))
      (run-with-idle-timer 3 nil (lambda ()
				   (if (buffer-live-p buf)
				       (with-current-buffer buf
					 (log-highlight-visible)
					 (setq log-mode-idle-registered nil))))))
    (setq log-mode-idle-registered t)))

(defun log-mode-init ()
  (log-highlight-visible)

  (when buffer-file-name
    (auto-revert-tail-mode)
    (add-hook 'after-change-functions 'log-mode-after-change t t)))

(defun log-mode-deinit ()
  (remove-overlays (point-min) (point-max) 'log-overlay t)
  (remove-hook 'after-change-functions 'log-mode-after-change t)

  (if buffer-file-name
      (auto-revert-tail-mode -1)))

;;;###autoload
(define-minor-mode log-mode
  "Log-mode is a minor mode for finding and navigating errors
  within log files."  nil
  " Log"
  log-mode-map
  (if log-mode
      (log-mode-init)
    (log-mode-deinit)))


(provide 'log-mode)

;;; log-mode.el ends here
