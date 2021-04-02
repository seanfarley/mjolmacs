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
;; Package-Requires: ((emacs "25.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(unless (require 'mjolmacs-module nil t)
  (error "The mjolmacs package needs `mjolmacs-module' to be compiled!"))

(declare-function mjolmacs--start "mjolmacs")

(defun mjolmacs--filter (proc string)
  "Filter that enables mjolmacs to send code to Emacs.

PROC is the process buffer from `make-pipe-process'
STRING is from mjolmacs writing via fd which comes from `open_channel'."
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (goto-char (point-max))
      (insert string)
      (goto-char 1)
      (while (re-search-forward "\\([^\x00]*\\)\x00\\([^\x00]*\\)\x00" nil t)
        (let ((id (match-string 1))
              (msg (match-string 2)))
          (delete-region 1 (match-end 0))
          (message "id: %s message: %s" id msg)
          ;; https://emacs.stackexchange.com/questions/19877/how-to-evaluate-elisp-code-contained-in-a-string#19878
          ;; (funcall (intern id) msg)
          (funcall (car (read-from-string msg)))
          )))))

(defun mjolmacs-leeroy ()
  "A callback test function."
  (message "LEEEEEEEROYYYYY"))

(defun mjolmacs-start (&optional buffer-name)
  "Start a process buffer to listen for mjolmacs events.

If called with an argument BUFFER-NAME, the name of the new buffer will
be set to BUFFER-NAME, otherwise it will be `*mjolmacs*'.
Returns the newly created mjolmacs buffer."
  (let ((buffer (generate-new-buffer (or buffer-name "*mjolmacs-process*"))))
    (with-current-buffer buffer
      (mjolmacs-process-mode)
      (mjolmacs--start
       (make-pipe-process :name "mjolmacs"
                          :buffer buffer
                          :filter 'mjolmacs--filter
                          :noquery t)
       #'mjolmacs-leeroy)
      ;; (run-hooks 'mjolmacs-start-hook)
      (switch-to-buffer buffer))))

;;;###autoload
(define-derived-mode mjolmacs-process-mode special-mode
  '("" nil "mjolmacs process buffer")
  "Major mode for mjolmacs process."
  (setq buffer-read-only nil))


(provide 'mjolmacs)
;;; mjolmacs.el ends here
