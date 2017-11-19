# README #

Log-mode is a minor mode used for finding and navigating errors within a buffer or a log file. For example, M-n moves the cursor to the first
error within the log file. M-p moves the cursor to the previous error. Log-mode only highlights the errors that are visible on the screen
rather than highlighting all errors found within the buffer. This is especially useful when opening up large log files for analysis.

To use Log-mode add the following line in your .emacs file:

(require 'log-mode)
