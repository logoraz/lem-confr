;;;; csv-mode-ref.lisp --- a READING COPY, not meant to be loaded.
;;;;
;;;; What you need from Lem to write the highlighting for contrib/csv-mode,
;;;; copied verbatim from Lem (commit da26ca84, identical in your ef6c48e
;;;; build for the files that matter) with original file and line numbers.
;;;; Only the `;;;;' blocks are mine.
;;;;
;;;; SETTLED
;;;;   - highlighting only: no alignment, no TSV
;;;;   - quoted values SPAN lines (PART 2 shows why that works)
;;;;   - separator: SYNTAX-BUILTIN-ATTRIBUTE (cyan in base16; PART 5)
;;;;   - parent mode: LANGUAGE-MODE (what it brings: PART 6)
;;;;
;;;; THINGS I CHECKED IN THE SOURCE
;;;;   1. Regions carry across lines.  An unclosed TM-REGION is stored as the
;;;;      line's syntax context and TM-CONTINUE-PREV-LINE resumes it on the
;;;;      next line (PART 2).  A quoted field with a line break just works.
;;;;   2. MAKE-TM-STRING-REGION (PART 3) is a region from SEPALATOR to
;;;;      SEPALATOR, but its default inner pattern treats a backslash as an
;;;;      escape.  CSV has no backslash escapes, so pass your own :PATTERNS
;;;;      (for example an empty (make-tm-patterns)).
;;;;   3. CSV escapes a quote by doubling it: "" inside a quoted field.  A
;;;;      region sees that as "close, then open again".  Both halves get the
;;;;      string attribute, so the color is unbroken; no special pattern is
;;;;      needed for the highlighting itself.
;;;;   4. MAKE-TM-MATCH takes a regex string and goes through
;;;;      ppcre:create-scanner (PART 1).  A comma needs no escaping.
;;;;   5. toml-mode (PART 4) colors its punctuation, commas included, with
;;;;      SYNTAX-BUILTIN-ATTRIBUTE.  That precedent is why it was chosen
;;;;      for the separator.
;;;;   6. There is no TEXT-MODE in Lem, so LANGUAGE-MODE (as in toml-mode)
;;;;      was chosen as the parent.
;;;;   7. toml-mode also calls LEM-TREE-SITTER:ENABLE-TREE-SITTER-FOR-MODE.
;;;;      Plain tmlanguage (no tree-sitter) is the "fallback" it mentions,
;;;;      and is all CSV needs.
;;;;   8. ENABLE-SYNTAX-HIGHLIGHT defaults to NIL (PART 6), so the mode body
;;;;      has to set it, as toml-mode does (PART 4).
;;;;   9. Tab runs FOLD-OR-INDENT-OR-COMPLETE.  With no buffer-local
;;;;      CALC-INDENT-FUNCTION and no COMPLETION-SPEC it ends in a no-op, so
;;;;      it never re-indents a CSV row (PART 6).
;;;;  10. LINE-COMMENT is NIL by default, so M-; has nothing to insert.
;;;;  11. Entering a language-mode starts one shared 200 ms idle timer; Lisp
;;;;      buffers already start it, so it adds nothing here.


;;;; ========================================================================
;;;; PART 1: tmlanguage constructors
;;;; src/buffer/internal/tmlanguage.lisp, lines 67-97 and 108-109
;;;; ========================================================================

(defun make-tmlanguage (&key (patterns (make-tm-patterns)) (repository (make-tm-repository)))
  (make-instance 'tmlanguage
                 :patterns patterns
                 :repository repository))

(defun make-tm-repository ()
  (make-hash-table :test 'equal))

(defun make-tm-match (string &key name captures move-action)
  (make-instance 'tm-match
                 :matcher (ppcre:create-scanner string)
                 :name name
                 :captures captures
                 :move-action move-action))

(defun make-tm-region (begin end
                       &key begin-captures end-captures captures
                            name content-name (patterns (make-tm-patterns)))
  (make-instance 'tm-region
                 :begin (ppcre:create-scanner begin)
                 :end (let ((tree (if (stringp end)
                                      (ppcre:parse-string end)
                                      end)))
                        (if (find-tree :back-reference tree)
                            tree
                            (ppcre:create-scanner end)))
                 :begin-captures (or begin-captures captures)
                 :end-captures (or end-captures captures)
                 :name name
                 :content-name content-name
                 :patterns patterns))

;;; lines 108-109
(defun make-tm-patterns (&rest patterns)
  (make-instance 'tm-patterns :patterns patterns))


;;;; ========================================================================
;;;; PART 2: how an unclosed region continues on the next line
;;;; src/buffer/internal/tmlanguage.lisp, lines 394-419
;;;; ========================================================================

(defun tm-continue-prev-line (point)
  (let* ((line (point-line point))
         (prev (line:line-previous line))
         (context (and prev (get-syntax-context prev)))
         (rule (alexandria:ensure-car context)))
    (cond ((null rule)
           (set-syntax-context line nil))
          ((typep rule 'tm-region)
           (tm-apply-region rule point
                            (when (consp context) (cdr context))
                            nil nil))
          ((typep rule 'tm-rule)
           (cond ((eq (get-syntax-context line) 'end-move-action)
                  (with-point ((p point))
                    (previous-single-property-change p :attribute)
                    (let ((goal (tm-move-action rule p t)))
                      (when goal
                        (move-point point goal)))))
                 (t
                  (line:line-add-property (point-line point)
                                     0 (line:line-length line)
                                     :attribute (tm-rule-name rule)
                                     t)
                  (line-end point))))
          (t
           (set-syntax-context line nil)))))


;;;; ========================================================================
;;;; PART 3: the string-region helper
;;;; src/ext/language-mode-tools.lisp, lines 10-15
;;;; ========================================================================

(defun make-tm-string-region (sepalator &key (name 'syntax-string-attribute)
                                             (patterns (make-tm-patterns (make-tm-match "\\\\."))))
  (make-tm-region `(:sequence ,sepalator)
                  `(:sequence ,sepalator)
                  :name name 
                  :patterns patterns))


;;;; ========================================================================
;;;; PART 4: toml-mode, the model to copy the shape of
;;;; extensions/toml-mode/toml-mode.lisp, lines 1-83
;;;; (its mode body also enables tree-sitter; you don't need that)
;;;; ========================================================================

(defpackage :lem-toml-mode
  (:use :cl :lem :lem/language-mode :lem/language-mode-tools)
  (:export :*toml-mode-hook*
           :toml-mode))
(in-package :lem-toml-mode)

#| link: https://toml.io/en/v1.0.0 |#

(defun tokens (boundary strings)
  "Create a regex alternation pattern from STRINGS, optionally wrapped with BOUNDARY."
  (let ((alternation
         `(:alternation ,@(sort (copy-list strings) #'> :key #'length))))
    (if boundary
        `(:sequence ,boundary ,alternation ,boundary)
        alternation)))

(defun make-tm-line-comment (separator)
  "Create a TextMate pattern for line comments starting with SEPARATOR."
  (make-tm-region separator "$" :name 'syntax-comment-attribute))

(defun make-tmlanguage-toml ()
  "Create a TextMate language definition for TOML syntax highlighting.
This serves as a fallback when tree-sitter is not available."
  (let* ((patterns (make-tm-patterns
                    ;; Comments
                    (make-tm-line-comment "#")
                    ;; Strings (basic and literal)
                    (make-tm-string-region "\"")
                    (make-tm-string-region "'")
                    ;; Multi-line strings
                    (make-tm-region "\"\"\"" "\"\"\"" :name 'syntax-string-attribute)
                    (make-tm-region "'''" "'''" :name 'syntax-string-attribute)
                    ;; Booleans
                    (make-tm-match (tokens :word-boundary '("true" "false"))
                                   :name 'syntax-keyword-attribute)
                    ;; Table headers [table] and [[array]]
                    (make-tm-match "^\\s*\\[\\[?[^\\]]+\\]\\]?"
                                   :name 'syntax-type-attribute)
                    ;; Punctuation and operators
                    (make-tm-match (tokens nil '("=" "," "[" "]" "{" "}" "."))
                                   :name 'syntax-builtin-attribute)
                    ;; Numbers (integers and floats)
                    (make-tm-match "\\b[+-]?[0-9][0-9_]*\\b"
                                   :name 'syntax-constant-attribute)
                    (make-tm-match "\\b[+-]?[0-9][0-9_]*\\.[0-9_]*\\b"
                                   :name 'syntax-constant-attribute)
                    ;; Special float values
                    (make-tm-match (tokens :word-boundary '("inf" "nan" "+inf" "-inf" "+nan" "-nan"))
                                   :name 'syntax-constant-attribute)
                    ;; Keys (bare keys at start of line or after newline)
                    (make-tm-match "^\\s*[a-zA-Z0-9_-]+"
                                   :name 'syntax-variable-attribute))))
    (make-tmlanguage :patterns patterns)))

(defvar *toml-syntax-table*
  (let ((table (make-syntax-table
                :symbol-chars '(#\- #\_)
                :string-quote-chars '(#\" #\')
                :paren-pairs '((#\[ . #\])
                               (#\{ . #\}))))
        (tmlanguage (make-tmlanguage-toml)))
    (set-syntax-parser table tmlanguage)
    table)
  "Syntax table for TOML mode.")

(defun tree-sitter-query-path ()
  "Return the path to the tree-sitter highlight query for TOML."
  (asdf:system-relative-pathname :lem-toml-mode "tree-sitter/highlights.scm"))

(define-major-mode toml-mode language-mode
    (:name "Toml"
     :keymap *toml-mode-keymap*
     :syntax-table *toml-syntax-table*
     :mode-hook *toml-mode-hook*)
  "Major mode for editing TOML configuration files."
  (lem-tree-sitter:enable-tree-sitter-for-mode
   *toml-syntax-table* "toml" (tree-sitter-query-path))
  (setf (variable-value 'enable-syntax-highlight) t
        (variable-value 'indent-tabs-mode) nil
        (variable-value 'tab-width) 2
        (variable-value 'line-comment) "#"))

(define-file-type ("toml") toml-mode)


;;;; ========================================================================
;;;; PART 5: the standard syntax attributes and how base16 themes color them
;;;; (from src/attribute.lisp and extensions/lem-base16-themes/src/macros.lisp;
;;;; "decaf" is one of these base16 themes: themes.lisp line 1289)
;;;; ========================================================================
;;;;
;;;;   attribute                        base16 slot
;;;;   -------------------------------  ----------------------------
;;;;   syntax-warning-attribute         base08  (red)
;;;;   syntax-string-attribute          base0B  (green)   <- quoted values
;;;;   syntax-comment-attribute         base03  (grey)
;;;;   syntax-keyword-attribute         base0E  (purple)
;;;;   syntax-constant-attribute        base09  (orange)
;;;;   syntax-function-name-attribute   base0D  (blue)
;;;;   syntax-variable-attribute        base08  (red)
;;;;   syntax-type-attribute            base0A  (yellow)
;;;;   syntax-builtin-attribute         base0C  (cyan)    <- CHOSEN: separators
;;;;
;;;; The colors are the base16 convention; the actual hex values depend on
;;;; the theme.  Quoted values already use the string attribute, so the
;;;; separator should be a different one.



;;;; ========================================================================
;;;; PART 6: what LANGUAGE-MODE, the parent, gives csv-mode
;;;; ========================================================================
;;;;
;;;; The first excerpt is the parent itself: its editor variables, its
;;;; define-major-mode, and its key bindings.  Tab is bound to
;;;; FOLD-OR-INDENT-OR-COMPLETE, which falls through to
;;;; INDENT-LINE-AND-COMPLETE-SYMBOL.  Its first branch fires when
;;;; CALC-INDENT-FUNCTION has no BUFFER-LOCAL value (the :buffer scope
;;;; returns NIL when nothing was set locally), and then it only calls
;;;; COMPLETE-SYMBOL, which does nothing without a COMPLETION-SPEC.
;;;;
;;;; Also below: ENABLE-SYNTAX-HIGHLIGHT's default (NIL), and the global
;;;; default of CALC-INDENT-FUNCTION, which only matters for commands that
;;;; indent explicitly, such as C-j.

;;; src/ext/language-mode.lisp, lines 54-110
(define-editor-variable idle-function nil)
(define-editor-variable beginning-of-defun-function nil)
(define-editor-variable end-of-defun-function nil)
(define-editor-variable line-comment nil)
(define-editor-variable insertion-line-comment nil)
(define-editor-variable find-definitions-function nil)
(define-editor-variable find-references-function nil)
(define-editor-variable language-mode-tag nil)
(define-editor-variable completion-spec nil)
(define-editor-variable indent-size 2)
(define-editor-variable root-uri-patterns '())
(define-editor-variable detective-search nil)
(define-editor-variable enable-tab-fold
  t
  "When T, the Tab key attempts to fold/unfold defuns and falls back to
`indent-line-and-complete-symbol', otherwise it just invokes the latter.")
(define-editor-variable fold-region-function
  'fold-region-default
  "Function of one point returning (values start end) for the foldable region at point, or NIL.")

(defun prompt-for-symbol (prompt history-name)
  (prompt-for-string prompt :history-symbol history-name))

(defvar *idle-timer* nil)

(defun language-idle-function ()
  (alexandria:when-let ((fn (variable-value 'idle-function :buffer)))
    (funcall fn)))

(define-major-mode language-mode ()
    (:name "language"
     :keymap *language-mode-keymap*)
  (when (or (null *idle-timer*)
            (timer-expired-p *idle-timer*))
    (setf *idle-timer*
          (start-timer (make-idle-timer 'language-idle-function
                                        :handle-function (lambda (condition)
                                                           (stop-timer *idle-timer*)
                                                           (pop-up-backtrace condition)
                                                           (setf *idle-timer* nil))
                                        :name "language-idle-function")
                       200 :repeat t))))

(define-key *language-mode-keymap* "C-M-a" 'beginning-of-defun)
(define-key *language-mode-keymap* "C-M-e" 'end-of-defun)
(define-key *language-mode-keymap* "Tab" 'fold-or-indent-or-complete)
(define-key *global-keymap* "C-j" 'newline-and-indent)
(define-key *global-keymap* "M-j" 'newline-and-indent)
(define-key *language-mode-keymap* "C-M-\\" 'indent-region)
(define-key *language-mode-keymap* "M-;" 'comment-or-uncomment-region)
(define-key *language-mode-keymap* "M-." 'find-definitions)
(define-key *language-mode-keymap* "M-_" 'find-references)
(define-key *language-mode-keymap* "M-?" 'find-references)
(define-key *language-mode-keymap* "M-," 'pop-definition-stack)
(define-key *language-mode-keymap* "C-M-i" 'complete-symbol)
(define-key *global-keymap* "M-(" 'insert-\(\)-or-wrap)
(define-key *global-keymap* "M-)" 'move-over-\)-or-wrap)

;;; src/ext/language-mode.lisp, lines 169-173
(define-command fold-or-indent-or-complete () ()
  "Fold or unfold the defun at point. otherwise indent and complete the symbol."
  (unless (and (variable-value 'enable-tab-fold)
               (fold-toggle-at-point))
    (indent-line-and-complete-symbol)))

;;; src/ext/language-mode.lisp, lines 530-548
(define-command complete-symbol () ()
  (alexandria:when-let (completion (variable-value 'completion-spec :buffer))
    (lem/completion-mode:run-completion completion)))

(define-command indent-line-and-complete-symbol () ()
  (cond
    ;; If no indent function is defined then just complete-symbol
    ((null (variable-value 'calc-indent-function :buffer))
     (complete-symbol))

    ;; Else if there is a highlighted region indent the region
    ((buffer-mark-p (current-buffer))
     (call-command 'indent-region nil))

    ;; Else indent the line and complete-symbol if the cursor doesn't move
    (t (let* ((p (current-point))
              (old (point-charpos p))
              (charpos (point-charpos p)))
         (handler-case (indent-line p)

;;; src/buffer/internal/syntax-parser.lisp, line 5
(define-editor-variable enable-syntax-highlight nil)

;;; src/buffer/indent.lisp, line 4 and lines 52-56
(define-editor-variable calc-indent-function 'calc-indent-default)
(defun indent-line (point)
  (let ((column (funcall (or (variable-value 'calc-indent-function :buffer point)
                             'calc-indent-default)
                         (copy-point point :temporary))))
    (indent-line-1 point column)))
