;;; mjolmacs.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Sean Farley
;;
;; Author: Sean Farley <https://github.com/seanfarley>
;; Maintainer: Sean Farley <sean@farley.io>
;; Created: April 01, 2021
;; Modified: April 01, 2021
;; Version: 0.0.1
;; Keywords: c macos ojbective-c
;; Homepage: https://github.com/seanfarley/mjolmacs
;; Package-Requires: ((emacs "27.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(require 'subr-x)

(defvar mjolmacs-frame-name "mjolmacs--frame")
(defvar mjolmacs-frame nil)
(defvar mjolmacs-prev-pid nil)

(defvar mjolmacs-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-g") #'mjolmacs-keypress-close)
    (define-key map (kbd "ESC") #'mjolmacs-keypress-close)
    map))

(unless (require 'mjolmacs-module nil t)
  (error "The mjolmacs package needs `mjolmacs-module' to be compiled!"))

(declare-function mjolmacs--start "mjolmacs")
(declare-function mjolmacs--focus-pid "mjolmacs")

(defun mjolmacs--filter (proc string)
  "Filter that enables mjolmacs to send code to Emacs.

PROC is the process buffer from `make-pipe-process'
STRING is from mjolmacs writing via fd which comes from `open_channel'."
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (goto-char (point-max))
      (insert string)
      (goto-char 1)
      (while (re-search-forward "\\([^\x00]*\\)\x00" nil t)
        (let ((msg (match-string 1)))
          (delete-region 1 (match-end 0))
          ;; https://emacs.stackexchange.com/questions/19877/how-to-evaluate-elisp-code-contained-in-a-string#19878
          (eval (read (format "(progn %s)" msg))))))))

(defun mjolmacs-leeroy (&rest extra)
  "A callback test function.

Optionally print EXTRA."
  (let ((estr (string-join extra " ")))
    (message (concat "LEEEEEEEROYYYYY" (if extra " ") estr))))

(defun mjolmacs--frame-keypress (pid)
  "Toggle visibility of our own frame.

PID is the process id of the app when the key was pressed. Used
to switch back to said app when the popup is dismissed."
  (if mjolmacs-frame
      ;; frame is already opened and user toggled the global shortcut
      (mjolmacs-keypress-close)
    ;; else, it's the first time to popup
    (setq mjolmacs-frame (make-frame `((name . ,mjolmacs-frame-name))))
    (setq mjolmacs-prev-pid pid)
    (with-selected-frame mjolmacs-frame
      (switch-to-buffer (get-buffer-create "*mjolmacs*"))
      (mjolmacs-mode)
      (select-frame-set-input-focus mjolmacs-frame))))

(defun mjolmacs-close ()
  "Close mjolmac's frame."
  (interactive)
  (when (or mjolmacs-frame (frame-live-p mjolmacs-frame))
    (delete-frame mjolmacs-frame)
    (setq mjolmacs-frame nil)
    (setq mjolmacs-prev-pid nil)))

(defun mjolmacs-keypress-close ()
  "Close mjolmac's frame via keypress."
  (interactive)
  (when (or mjolmacs-frame (frame-live-p mjolmacs-frame))
    (when mjolmacs-prev-pid
      (mjolmacs--focus-pid mjolmacs-prev-pid))
    (mjolmacs-close)))

(defun mjolmacs-close-hook ()
  "Hook to close mjolmac's frame upon defocus."
  ;; this function is also called when activating emacs; e.g. Firefox -> Emacs
  (unless (frame-focus-state mjolmacs-frame)
    (mjolmacs-close)))

(defun mjolmacs-start (&optional buffer-name)
  "Start a process buffer to listen for mjolmacs events.

If called with an argument BUFFER-NAME, the name of the new buffer will
be set to BUFFER-NAME, otherwise it will be `*mjolmacs*'.
Returns the newly created mjolmacs buffer."
  (add-function :after after-focus-change-function #'mjolmacs-close-hook)

  (let ((buffer (generate-new-buffer (or buffer-name "*mjolmacs-process*"))))
    (with-current-buffer buffer
      (mjolmacs-process-mode)
      (mjolmacs--start
       (make-pipe-process :name "mjolmacs"
                          :buffer buffer
                          :filter 'mjolmacs--filter
                          :noquery t)
       #'mjolmacs--frame-keypress)
      ;; (run-hooks 'mjolmacs-start-hook)
      (switch-to-buffer buffer))))

;;;###autoload
(define-derived-mode mjolmacs-process-mode special-mode
  '("" nil "mjolmacs process buffer")
  "Major mode for mjolmacs process."
  (setq buffer-read-only nil))

;;;###autoload
(define-derived-mode mjolmacs-mode text-mode "mjolmacs"
  "Major mode for mjolmacs popup frame.")

(provide 'mjolmacs)
;;; mjolmacs.el ends here
