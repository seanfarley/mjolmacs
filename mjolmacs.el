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
(require 'ivy)

(defvar mjolmacs-frame-name "mjolmacs--frame")
(defvar mjolmacs-frame nil)
(defvar mjolmacs-prev-pid nil)

(defvar mjolmacs-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-g") #'mjolmacs-keypress-close)
    (define-key map [escape] (kbd "C-g"))
    map))

(declare-function mjolmacs--start "mjolmacs")
(declare-function mjolmacs--stop "mjolmacs")
(declare-function mjolmacs--focus-pid "mjolmacs")
(declare-function mjolmacs-register "mjolmacs")
(declare-function mjolmacs-alert "mjolmacs")

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

(defun mjolmacs-leeroy ()
  "A callback test function."
  (message "LEEEEEEEROYYYYY"))

(defun mjolmacs-leeroy2 ()
  "A callback test function."
  (message "JENNNNKINGSSSSSS"))

(defun mjolmacs--frame-keypress (pid)
  "Toggle visibility of our own frame.

PID is the process id of the app when the key was pressed. Used
to switch back to said app when the popup is dismissed."
  (if mjolmacs-frame
      ;; frame is already opened and user toggled the global shortcut
      (mjolmacs-keypress-close)
    ;; else, it's the first time to popup
    (setq mjolmacs-frame (make-frame `((name . ,mjolmacs-frame-name)
                                       (autoraise . t)
                                       (top . 200)
                                       (left . 0.33)
                                       (width . 100)
                                       (height . 20)
                                       (internal-border-width . 20)
                                       (left-fringe . 0)
                                       (right-fringe . 0)
                                       (vertical-scroll-bars . nil)
                                       (horizontal-scroll-bars . nil)
                                       (menu-bar-lines . 0)
                                       (minibuffer . only)
                                       (unsplittable . t)
                                       (undecorated . t))))
    (setq mjolmacs-prev-pid pid)
    (with-selected-frame mjolmacs-frame
      (with-current-buffer (get-buffer-create "*mjolmacs*")
        (mjolmacs-mode)
        (select-frame-set-input-focus mjolmacs-frame)

        (let ((ivy-height 20)
              (ivy-count-format ""))

          (ivy-read "Emacs acronyms: "
                    '(" Emacs: Escape-Meta-Alt-Control-Shift "
                      " Emacs: Eight Megabytes And Constantly Swapping "
                      " Emacs: Even a Master of Arts Comes Simpler "
                      " Emacs: Each Manual's Audience is Completely Stupified "
                      " Emacs: Eventually Munches All Computer Storage "
                      " Emacs: Eradication of Memory Accomplished with Complete Simplicity "
                      " Emacs: Easily Maintained with the Assistance of Chemical Solutions "
                      " Emacs: Extended Macros Are Considered Superfluous "
                      " Emacs: Every Mode Accelerates Creation of Software "
                      " Emacs: Elsewhere Maybe All Commands are Simple "
                      " Emacs: Emacs Makes All Computing Simple "
                      " Emacs: Emacs Masquerades As Comfortable Shell "
                      " Emacs: Emacs My Alternative Computer Story "
                      " Emacs: Emacs Made Almost Completely Screwed "
                      " Emacs: Each Mail A Continued Surprise "
                      " Emacs: Eating Memory And Cycle-Sucking "
                      " Emacs: Elvis Masterminds All Computer Software "
                      " Emacs: Emacs Makes A Computer Slow" )
                    :action (lambda (funny-quote)
                              (mjolmacs-alert funny-quote))
                    :unwind (lambda ()
                              (mjolmacs-close))))))))

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

;;;###autoload
(defun mjolmacs-start ()
  "Start a process buffer to listen for mjolmacs events.

The name of the process buffer will be `*mjolmacs-process*'.
Returns the newly created mjolmacs buffer."
  (add-function :after after-focus-change-function #'mjolmacs-close-hook)

  ;; make sure we close file handles, unregister cocoa hooks, and free memory
  (add-hook 'kill-emacs-hook #'mjolmacs-stop)

  (let ((buffer (generate-new-buffer "*mjolmacs-process*")))
    (with-current-buffer buffer
      (mjolmacs-process-mode)
      (mjolmacs--start
       (make-pipe-process :name "mjolmacs"
                          :buffer buffer
                          :filter 'mjolmacs--filter
                          :noquery t))
      ;; (run-hooks 'mjolmacs-start-hook)
      (switch-to-buffer buffer))))

(defun mjolmacs-stop ()
  "Stop mjolmacs and free C memory.

This will shutdown the pipes, close the filehandles, and free any
C memory we allocated."
  (mjolmacs--stop)

  ;; kill the process buffer
  (kill-buffer "*mjolmacs-process*"))

(defun mjolmacs-bind-popup (key-binding)
  "Bind KEY-BINDING to popup frame."
  (mjolmacs-register key-binding
                     #'mjolmacs--frame-keypress))

(define-derived-mode mjolmacs-process-mode special-mode
  '("" nil "mjolmacs process buffer")
  "Major mode for mjolmacs process."
  (setq buffer-read-only nil))

(define-derived-mode mjolmacs-mode text-mode "mjolmacs"
  "Major mode for mjolmacs popup frame."
  (setq mode-line-format nil))

(unless (require 'mjolmacs-module nil t)
  (error "The mjolmacs package needs `mjolmacs-module' to be compiled!"))

(provide 'mjolmacs)
;;; mjolmacs.el ends here
