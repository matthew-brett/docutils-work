;;; rst.el --- Mode for viewing and editing reStructuredText-documents.

;; Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010
;;   Free Software Foundation, Inc.

;; Authors: Martin Blais <blais@furius.ca>,
;;          Stefan Merten <smerten@oekonux.de> (maintainer),
;;          David Goodger <goodger@python.org>,
;;          Wei-Wei Guo <wwguocn@gmail.com>

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides major mode rst-mode, which supports documents marked up
;; using the reStructuredText format.  Support includes font locking as well as
;; some convenience functions for editing.  It does this by defining a Emacs
;; major mode: rst-mode (ReST).  This mode is derived from text-mode (and
;; inherits much of it).  This package also contains:
;;
;; - Functions to automatically adjust and cycle the section underline
;;   adornments;
;; - A mode that displays the table of contents and allows you to jump anywhere
;;   from it;
;; - Functions to insert and automatically update a TOC in your source
;;   document;
;; - Function to insert list, processing item bullets and enumerations
;;   automatically;
;; - Font-lock highlighting of notable reStructuredText structures;
;; - Some other convenience functions.
;;
;; See the accompanying document in the docutils documentation about
;; the contents of this package and how to use it.
;;
;; For more information about reStructuredText, see
;; http://docutils.sourceforge.net/rst.html
;;
;; For full details on how to use the contents of this file, see
;; http://docutils.sourceforge.net/docs/user/emacs.html
;;
;;
;; There are a number of convenient keybindings provided by rst-mode.
;; The main one is
;;
;;    C-c C-a (also C-=): rst-adjust
;;
;; Updates or rotates the section title around point or promotes/demotes the
;; adornments within the region (see full details below).  Note that C-= is a
;; good binding, since it allows you to specify a negative arg easily with C--
;; C-= (easy to type), as well as ordinary prefix arg with C-u C-=.
;;
;; For more on bindings, see rst-mode-map below.  There are also many variables
;; that can be customized, look for defcustom and defvar in this file.
;;
;; If you use the table-of-contents feature, you may want to add a hook to
;; update the TOC automatically everytime you adjust a section title::
;;
;;   (add-hook 'rst-adjust-hook 'rst-toc-update)
;;
;; Syntax highlighting: font-lock is enabled by default.  If you want to turn
;; off syntax highlighting to rst-mode, you can use the following::
;;
;;   (setq font-lock-global-modes '(not rst-mode ...))
;;


;; CUSTOMIZATION
;;
;; rst
;; ---
;; This group contains some general customizable features.
;;
;; The group is contained in the wp group.
;;
;; rst-faces
;; ---------
;; This group contains all necessary for customizing fonts.  The default
;; settings use standard font-lock-*-face's so if you set these to your
;; liking they are probably good in rst-mode also.
;;
;; The group is contained in the faces group as well as in the rst group.
;;
;; rst-faces-defaults
;; ------------------
;; This group contains all necessary for customizing the default fonts used for
;; section title faces.
;;
;; The general idea for section title faces is to have a non-default background
;; but do not change the background.  The section level is shown by the
;; lightness of the background color.  If you like this general idea of
;; generating faces for section titles but do not like the details this group
;; is the point where you can customize the details.  If you do not like the
;; general idea, however, you should customize the faces used in
;; rst-adornment-faces-alist.
;;
;; Note: If you are using a dark background please make sure the variable
;; frame-background-mode is set to the symbol dark.  This triggers
;; some default values which are probably right for you.
;;
;; The group is contained in the rst-faces group.
;;
;; All customizable features have a comment explaining their meaning.
;; Refer to the customization of your Emacs (try ``M-x customize``).


;;; DOWNLOAD

;; The latest version of this file lies in the docutils source code repository:
;;   http://svn.berlios.de/svnroot/repos/docutils/trunk/docutils/tools/editors/emacs/rst.el


;;; INSTALLATION

;; Add the following lines to your `.emacs' file:
;;
;;   (require 'rst)
;;
;; If you are using `.txt' as a standard extension for reST files as
;; http://docutils.sourceforge.net/FAQ.html#what-s-the-standard-filename-extension-for-a-restructuredtext-file
;; suggests you may use one of the `Local Variables in Files' mechanism Emacs
;; provides to set the major mode automatically.  For instance you may use::
;;
;;    .. -*- mode: rst -*-
;;
;; in the very first line of your file.  The following code is useful if you
;; want automatically enter rst-mode from any file with compatible extensions:
;;
;; (setq auto-mode-alist
;;       (append '(("\\.txt$" . rst-mode)
;;                 ("\\.rst$" . rst-mode)
;;                 ("\\.rest$" . rst-mode)) auto-mode-alist))
;;

;;; BUGS

;; - rst-enumeration-region: Select a single paragraph, with the top at one
;;   blank line before the beginning, and it will fail.
;; - The active region goes away when we shift it left or right, and this
;;   prevents us from refilling it automatically when shifting many times.
;; - The suggested adornments when adjusting should not have to cycle
;;   below one below the last section adornment level preceding the
;;   cursor.  We need to fix that.

;;; TODO LIST

;; rst-toc-insert features
;; ------------------------
;; - rst-toc-insert: We should parse the contents:: options to figure out how
;;   deep to render the inserted TOC.
;; - On load, detect any existing TOCs and set the properties for links.
;; - TOC insertion should have an option to add empty lines.
;; - TOC insertion should deal with multiple lines.
;; - There is a bug on redo after undo of adjust when rst-adjust-hook uses the
;;   automatic toc update.  The cursor ends up in the TOC and this is
;;   annoying.  Gotta fix that.
;; - numbering: automatically detect if we have a section-numbering directive in
;;   the corresponding section, to render the toc.
;;
;; Other
;; -----
;; - It would be nice to differentiate between text files using
;;   reStructuredText_ and other general text files.  If we had a
;;   function to automatically guess whether a .txt file is following the
;;   reStructuredText_ conventions, we could trigger rst-mode without
;;   having to hard-code this in every text file, nor forcing the user to
;;   add a local mode variable at the top of the file.
;;   We could perform this guessing by searching for a valid adornment
;;   at the top of the document or searching for reStructuredText_
;;   directives further on.
;;
;; - We should support imenu in our major mode, with the menu filled with the
;;   section titles (this should be really easy).
;;
;; - Maybe some functions for adornment overlap.
;;
;; - We need to automatically recenter on rst-forward-section movement commands.


;;; HISTORY
;;

;;; Code:

(require 'cl)


(defgroup rst nil "Support for reStructuredText documents."
  :group 'wp
  :version "23.1"
  :link '(url-link "http://docutils.sourceforge.net/rst.html"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Facilities for regular expressions used everywhere

;; The trailing numbers in the names give the number of referenceable regex
;; groups contained in the regex

;; Used to be customizable but really is not customizable but fixed by the reST
;; syntax
(defconst rst-bullets
  ;; Sorted so they can form a character class when concatenated
  '(?- ?* ?+ ?\u2022 ?\u2023 ?\u2043)
  "List of all possible bullet characters for bulleted lists.")

(defconst rst-uri-schemes
  '("acap" "cid" "data" "dav" "fax" "file" "ftp" "gopher" "http" "https" "imap"
    "ldap" "mailto" "mid" "modem" "news" "nfs" "nntp" "pop" "prospero" "rtsp"
    "service" "sip" "tel" "telnet" "tip" "urn" "vemmi" "wais")
  "Supported URI schemes")

(defconst rst-adornment-chars
  ;; Sorted so they can form a character class when concatenated
  '(?\]
    ?! ?\" ?# ?$ ?% ?& ?' ?\( ?\) ?* ?+ ?, ?. ?/ ?: ?\; ?< ?= ?> ?? ?@ ?\[ ?\\
    ?^ ?_ ?` ?{ ?| ?} ?~
    ?-)
  "Characters which may be used in adornments for sections and transitions.")

(defconst rst-max-inline-length
  1000
  "Maximum length of inline markup to recognize.")

(defconst rst-re-alist-def
  ;; `*-beg' matches * at the beginning of a line
  ;; `*-end' matches * at the end of a line
  ;; `*-prt' matches a part of *
  ;; `*-tag' matches *
  ;; `*-sta' matches the start of * which may be followed by respective content
  ;; `*-pfx' matches the delimiter left of *
  ;; `*-sfx' matches the delimiter right of *
  ;; `*-hlp' helper for *
  ;;
  ;; A trailing number says how many referenceable groups are contained.
  `(

    ;; Horizontal white space (`hws')
    (hws-prt "[\t ]")
    (hws-tag hws-prt "*") ;; Optional sequence of horizontal white space
    (hws-sta hws-prt "+") ;; Mandatory sequence of horizontal white space

    ;; Lines (`lin')
    (lin-beg "^" hws-tag) ;; Beginning of a possibly indented line
    (lin-end hws-tag "$") ;; End of a line with optional trailing white space
    (linemp-tag "^" hws-tag "$") ;; Empty line with optional white space

    ;; Various tags and parts
    (ell-tag "\\.\\.\\.") ;; Ellipsis
    (bul-tag ,(concat "[" rst-bullets "]")) ;; A bullet
    (ltr-tag "[a-zA-Z]") ;; A letter enumerator tag
    (num-prt "[0-9]") ;; A number enumerator part
    (num-tag num-prt "+") ;; A number enumerator tag
    (rom-prt "[IVXLCDMivxlcdm]") ;; A roman enumerator part
    (rom-tag rom-prt "+") ;; A roman enumerator tag
    (aut-tag "#") ;; An automatic enumerator tag
    (dcl-tag "::") ;; Double colon

    ;; Block lead in (`bli')
    (bli-sfx (:alt hws-sta "$")) ;; Suffix of a block lead-in with *optional*
				 ;; immediate content

    ;; Various starts
    (bul-sta bul-tag bli-sfx) ;; Start of a bulleted item

    ;; Explicit markup tag (`exm')
    (exm-tag "\\.\\.")
    (exm-sta exm-tag hws-sta)
    (exm-beg lin-beg exm-sta)

    ;; Counters in enumerations (`cnt')
    (cntany-tag (:alt ltr-tag num-tag rom-tag aut-tag)) ;; An arbitrary counter
    (cntexp-tag (:alt ltr-tag num-tag rom-tag)) ;; An arbitrary explicit counter

    ;; Enumerator (`enm')
    (enmany-tag (:alt
		 (:seq cntany-tag "\\.")
		 (:seq "(?" cntany-tag ")"))) ;; An arbitrary enumerator
    (enmexp-tag (:alt
		 (:seq cntexp-tag "\\.")
		 (:seq "(?" cntexp-tag ")"))) ;; An arbitrary explicit
					      ;; enumerator
    (enmaut-tag (:alt
		 (:seq aut-tag "\\.")
		 (:seq "(?" aut-tag ")"))) ;; An automatic enumerator
    (enmany-sta enmany-tag bli-sfx) ;; An arbitrary enumerator start
    (enmexp-sta enmexp-tag bli-sfx) ;; An arbitrary explicit enumerator start
    (enmexp-beg lin-beg enmexp-sta) ;; An arbitrary explicit enumerator start
				    ;; at the beginning of a line

    ;; Items may be enumerated or bulleted (`itm')
    (itmany-tag (:alt enmany-tag bul-tag)) ;; An arbitrary item tag
    (itmany-sta-1 (:grp itmany-tag) bli-sfx) ;; An arbitrary item start, group
					     ;; is the item tag
    (itmany-beg-1 lin-beg itmany-sta-1) ;; An arbitrary item start at the
				        ;; beginning of a line, group is the
				        ;; item tag

    ;; Inline markup (`ilm')
    (ilm-pfx (:alt "^" hws-prt "[-'\"([{<\u2018\u201c\u00ab\u2019/:]"))
    (ilm-sfx (:alt "$" hws-prt "[]-'\")}>\u2019\u201d\u00bb/:.,;!?\\]"))

    ;; Inline markup content (`ilc')
    (ilcsgl-tag "\\S ") ;; A single non-white character
    (ilcast-prt (:alt "[^*\\]" "\\\\.")) ;; Part of non-asterisk content
    (ilcbkq-prt (:alt "[^`\\]" "\\\\.")) ;; Part of non-backquote content
    (ilcbkqdef-prt (:alt "[^`\\\n]" "\\\\.")) ;; Part of non-backquote
					      ;; definition
    (ilcbar-prt (:alt "[^|\\]" "\\\\.")) ;; Part of non-vertical-bar content
    (ilcbardef-prt (:alt "[^|\\\n]" "\\\\.")) ;; Part of non-vertical-bar
					      ;; definition
    (ilcast-sfx "[^\t *\\]") ;; Suffix of non-asterisk content
    (ilcbkq-sfx "[^\t `\\]") ;; Suffix of non-backquote content
    (ilcbar-sfx "[^\t |\\]") ;; Suffix of non-vertical-bar content
    (ilcrep-hlp ,(format "\\{0,%d\\}" rst-max-inline-length)) ;; Repeat count
    (ilcast-tag (:alt ilcsgl-tag
		      (:seq ilcsgl-tag
			    ilcast-prt ilcrep-hlp
			    ilcast-sfx))) ;; Non-asterisk content
    (ilcbkq-tag (:alt ilcsgl-tag
		      (:seq ilcsgl-tag
			    ilcbkq-prt ilcrep-hlp
			    ilcbkq-sfx))) ;; Non-backquote content
    (ilcbkqdef-tag (:alt ilcsgl-tag
			 (:seq ilcsgl-tag
			       ilcbkqdef-prt ilcrep-hlp
			       ilcbkq-sfx))) ;; Non-backquote definition
    (ilcbar-tag (:alt ilcsgl-tag
		      (:seq ilcsgl-tag
			    ilcbar-prt ilcrep-hlp
			    ilcbar-sfx))) ;; Non-vertical-bar content
    (ilcbardef-tag (:alt ilcsgl-tag
			 (:seq ilcsgl-tag
			       ilcbardef-prt ilcrep-hlp
			       ilcbar-sfx))) ;; Non-vertical-bar definition

    ;; Fields (`fld')
    (fldnam-prt (:alt "[^:\n]" "\\\\:")) ;; Part of a field name
    (fldnam-tag fldnam-prt "+") ;; A field name
    (fld-tag ":" fldnam-tag ":") ;; A field marker

    ;; Options (`opt')
    (optsta-tag (:alt "[-+/]" "--")) ;; Start of an option
    (optnam-tag "\\sw" (:alt "-" "\\sw") "*") ;; Name of an option
    (optarg-tag (:shy "[ =]\\S +")) ;; Option argument
    (optsep-tag (:shy "," hws-prt)) ;; Separator between options
    (opt-tag (:shy optsta-tag optnam-tag optarg-tag "?")) ;; A complete option

    ;; Footnotes and citations (`fnc')
    (fncnam-prt "[^\]\n]") ;; Part of a footnote or citation name
    (fncnam-tag fncnam-prt "+") ;; A footnote or citation name
    (fnc-tag "\\[" fncnam-tag "]") ;; A complete footnote or citation tag

    ;; Substitutions (`sub')
    (sub-tag "|" ilcbar-tag "|") ;; A complete substitution tag
    (subdef-tag "|" ilcbardef-tag "|") ;; A complete substitution definition
				       ;; tag

    ;; Symbol (`sym')
    (sym-prt (:alt "\\sw" "\\s_"))
    (sym-tag sym-prt "+")

    ;; URIs (`uri')
    (uri-tag (:alt ,@rst-uri-schemes))

    ;; Adornment (`ado')
    (ado-prt "[" ,(concat rst-adornment-chars) "]")
    (adorep-hlp "\\{2,\\}") ;; there must be at least 3 characters because
			    ;; otherwise explicit markup start would be
			    ;; recognized
    (ado-tag-1-1 (:grp ado-prt)
		 "\\1" adorep-hlp) ;; A complete adorment, group is the first
				   ;; adornment character and MUST be the FIRST
				   ;; group in the whole expression
    (ado-tag-1-2 (:grp ado-prt)
		 "\\2" adorep-hlp) ;; A complete adorment, group is the first
				   ;; adornment character and MUST be the
				   ;; SECOND group in the whole expression
    (ado-beg-2-1 "^" (:grp ado-tag-1-2)) ;; An adornment at the beginning of a
					 ;; line; first group is the whole
					 ;; adornment and MUST be the FIRST
					 ;; group in the whole expression

    ;; Titles (`ttl')
    (ttl-tag "\\S *\\w\\S *") ;; A title text
    (ttl-beg lin-beg ttl-tag) ;; A title text at the beginning of a line
    )
  "Definition alist of relevant regexes.
Each entry consists of the symbol naming the regex and an
argument list for `rst-re'.")

(defun rst-re (&rest args)
  "Interpret ARGS as regular expressions and return a regex string.
Each element of ARGS may be one of the following:

A string which is inserted unchanged.

A character which is resolved to a quoted regex.

A symbol which is resolved to a string using `rst-re-alist-def'.

A list with a keyword in the car. Each element of the cdr of such
a list is recursively interpreted as ARGS. The results of this
interpretation are concatenated according to the keyword.

For the keyword `:seq' the results are simply concatenated.

For the keyword `:shy' the results are concatenated and
surrounded by a shy-group (\"\\(?:...\\)\").

For the keyword `:alt' the results form an alternative (\"\\|\")
which is shy-grouped (\"\\(?:...\\)\").

For the keyword `:grp' the results are concatenated and form a
referencable grouped (\"\\(...\\)\").

After interpretation of ARGS the results are concatenated as for
`:seq'.
"
  (apply 'concat
	 (mapcar
	  (lambda (re)
	    (cond
	     ((stringp re)
	      re)
	     ((symbolp re)
	      (cadr (assoc re rst-re-alist)))
	     ((char-valid-p re)
	      (regexp-quote (char-to-string re)))
	     ((listp re)
	      (let ((nested
		     (mapcar (lambda (elt)
			       (rst-re elt))
			     (cdr re))))
		(cond
		 ((eq (car re) :seq)
		  (mapconcat 'identity nested ""))
		 ((eq (car re) :shy)
		  (concat "\\(?:" (mapconcat 'identity nested "") "\\)"))
		 ((eq (car re) :grp)
		  (concat "\\(" (mapconcat 'identity nested "") "\\)"))
		 ((eq (car re) :alt)
		  (concat "\\(?:" (mapconcat 'identity nested "\\|") "\\)"))
		 (t
		  (error "Unknown list car: %s" (car re))))))
	     (t
	      (error "Unknown object type for building regex: %s" re))))
	  args)))

(defconst rst-re-alist
  ;; Shadow global value we are just defining so we can construct it step by
  ;; step
  (let (rst-re-alist)
    (dolist (re rst-re-alist-def)
      (setq rst-re-alist
	    (nconc rst-re-alist
		   (list (list (car re) (apply 'rst-re (cdr re)))))))
    rst-re-alist)
  "Alist mapping symbols from `rst-re-alist-def' to regex strings")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mode definition.

(defvar rst-deprecated-keys nil
  "Alist of deprecated keys mapping to the right key to use and the
definition.")

(defun rst-call-deprecated ()
  (interactive)
  (let* ((dep-key (this-command-keys-vector))
	 (fnd (assoc dep-key rst-deprecated-keys)))
    (if (not fnd)
	(error "Unknown deprecated key sequence %s" dep-key)
      (message "[Deprecated use of key %S; use key %S instead]"
	       (mapconcat (lambda (c) (format (if (integerp c) "%c" "%s") c))
			  dep-key "")
	       (mapconcat (lambda (c) (format (if (integerp c) "%c" "%s") c))
			  (second fnd) ""))
      (call-interactively (third fnd)))))

(defun rst-define-key (keymap key def &rest deprecated)
  "Bind like `define-key'. DEPRECATED are further key definitions
which are deprecated. These should be in vector notation. These
are defined as well but give an additional message."
  (define-key keymap key def)
  (dolist (dep-key deprecated)
    (push (list dep-key key def) rst-deprecated-keys)
    (define-key keymap dep-key 'rst-call-deprecated)))

;; Key bindings.
(defvar rst-mode-map
  (let ((map (make-sparse-keymap)))

    ;; \C-c is the general keymap
    (rst-define-key map [?\C-c ?\C-h] 'describe-prefix-bindings)

    ;;
    ;; Section Adornments.
    ;;
    ;; The adjustment function that adorns or rotates a section title.
    (rst-define-key map [?\C-c ?\C-=] 'rst-adjust [?\C-c ?\C-a])
    (rst-define-key map [?\C-=] 'rst-adjust) ;; (Does not work on the Mac OSX.)

    ;; \C-c a is the keymap for adornments
    (rst-define-key map [?\C-c ?a ?\C-h] 'describe-prefix-bindings)
    ;; Display the hierarchy of adornments implied by the current document contents.
    (rst-define-key map [?\C-c ?a ?h] 'rst-display-adornments-hierarchy)
    ;; Homogeneize the adornments in the document.
    (rst-define-key map [?\C-c ?a ?s] 'rst-straighten-adornments
		    [?\C-c ?\C-s])

    ;;
    ;; Section Movement and Selection.
    ;;
    ;; Mark the subsection where the cursor is.
    (rst-define-key map [?\C-\M-h] 'rst-mark-section
		    ;; same as mark-defun sgml-mark-current-element
		    [?\C-c ?\C-m])
    ;; Move forward/backward between section titles.
    (rst-define-key map [?\C-\M-f] 'rst-forward-section
		    ;; same as forward-sexp sgml-forward-element
		    [?\C-c ?\C-n])
    (rst-define-key map [?\C-\M-b] 'rst-backward-section
		    ;; same as backward-sexp sgml-backward-element
		    [?\C-c ?\C-p])

    ;;
    ;; Operating on regions.
    ;;
    ;; \C-c r is the keymap for regions
    (rst-define-key map [?\C-c ?r ?\C-h] 'describe-prefix-bindings)
    ;; Makes region a line-block.
    (rst-define-key map [?\C-c ?r ?l] 'rst-line-block-region
		    [?\C-c ?\C-d])
    ;; Shift region left or right (taking into account of enumerations/bullets,
    ;; etc.).
    (rst-define-key map [?\C-c ?r backtab] 'rst-shift-region-left
		    [?\C-c ?\C-l])
    (rst-define-key map [?\C-c ?r tab] 'rst-shift-region-right
		    [?\C-c ?\C-r])

    ;;
    ;; Operating on lists.
    ;;
    ;; \C-c l is the keymap for regions
    (rst-define-key map [?\C-c ?l ?\C-h] 'describe-prefix-bindings)
    ;; Makes paragraphs in region as a bullet list.
    (rst-define-key map [?\C-c ?l ?b] 'rst-bullet-list-region
		    [?\C-c ?\C-b])
    ;; Makes paragraphs in region as a enumeration.
    (rst-define-key map [?\C-c ?l ?e] 'rst-enumerate-region
		    [?\C-c ?\C-e])
    ;; Converts bullets to an enumeration.
    (rst-define-key map [?\C-c ?l ?c] 'rst-convert-bullets-to-enumeration
		    [?\C-c ?\C-v])
    ;; Make sure that all the bullets in the region are consistent.
    (rst-define-key map [?\C-c ?l ?s] 'rst-straighten-bullets-region
		    [?\C-c ?\C-w])
    ;; Insert a list item
    (rst-define-key map [?\C-c ?l ?i] 'rst-insert-list)

    ;;
    ;; Table-of-Contents Features.
    ;;
    ;; \C-c t is the keymap for table of contents
    (rst-define-key map [?\C-c ?t ?\C-h] 'describe-prefix-bindings)
    ;; Enter a TOC buffer to view and move to a specific section.
    (rst-define-key map [?\C-c ?\C-t] 'rst-toc)
    (rst-define-key map [?\C-c ?t ?t] 'rst-toc)
    ;; Insert a TOC here.
    (rst-define-key map [?\C-c ?t ?i] 'rst-toc-insert
		    [?\C-c ?\C-i])
    ;; Update the document's TOC (without changing the cursor position).
    (rst-define-key map [?\C-c ?t ?u] 'rst-toc-update
		    [?\C-c ?\C-u])
    ;; Got to the section under the cursor (cursor must be in TOC).
    (rst-define-key map [?\C-c ?t ?j] 'rst-goto-section
		    [?\C-c ?\C-f])

    ;;
    ;; Converting Documents from Emacs.
    ;;
    ;; \C-c c is the keymap for compilation
    (rst-define-key map [?\C-c ?c ?\C-h] 'describe-prefix-bindings)
    ;; Run one of two pre-configured toolset commands on the document.
    (rst-define-key map [?\C-c ?c ?c] 'rst-compile
		    [?\C-c ?1])
    (rst-define-key map [?\C-c ?c ?a] 'rst-compile-alt-toolset
		    [?\C-c ?2])
    ;; Convert the active region to pseudo-xml using the docutils tools.
    (rst-define-key map [?\C-c ?c ?x] 'rst-compile-pseudo-region
		    [?\C-c ?3])
    ;; Convert the current document to PDF and launch a viewer on the results.
    (rst-define-key map [?\C-c ?c ?p] 'rst-compile-pdf-preview
		    [?\C-c ?4])
    ;; Convert the current document to S5 slides and view in a web browser.
    (rst-define-key map [?\C-c ?c ?s] 'rst-compile-slides-preview
		    [?\C-c ?5])

    map)
  "Keymap for reStructuredText mode commands.
This inherits from Text mode.")


;; Abbrevs.
(defvar rst-mode-abbrev-table nil
  "Abbrev table used while in Rst mode.")
(define-abbrev-table 'rst-mode-abbrev-table
  (mapcar (lambda (x) (append x '(nil 0 system)))
          '(("contents" ".. contents::\n..\n   ")
            ("con" ".. contents::\n..\n   ")
            ("cont" "[...]")
            ("skip" "\n\n[...]\n\n  ")
            ("seq" "\n\n[...]\n\n  ")
            ;; FIXME: Add footnotes, links, and more.
            )))


;; Syntax table.
(defvar rst-mode-syntax-table
  (let ((st (copy-syntax-table text-mode-syntax-table)))

    (modify-syntax-entry ?$ "." st)
    (modify-syntax-entry ?% "." st)
    (modify-syntax-entry ?& "." st)
    (modify-syntax-entry ?' "." st)
    (modify-syntax-entry ?* "." st)
    (modify-syntax-entry ?+ "." st)
    (modify-syntax-entry ?. "_" st)
    (modify-syntax-entry ?/ "." st)
    (modify-syntax-entry ?< "." st)
    (modify-syntax-entry ?= "." st)
    (modify-syntax-entry ?> "." st)
    (modify-syntax-entry ?\\ "\\" st)
    (modify-syntax-entry ?| "." st)
    (modify-syntax-entry ?_ "." st)
    (modify-syntax-entry (aref "\u00ab" 0) "." st)
    (modify-syntax-entry (aref "\u00bb" 0) "." st)
    (modify-syntax-entry (aref "\u2018" 0) "." st)
    (modify-syntax-entry (aref "\u2019" 0) "." st)
    (modify-syntax-entry (aref "\u201c" 0) "." st)
    (modify-syntax-entry (aref "\u201d" 0) "." st)

    st)
  "Syntax table used while in `rst-mode'.")


(defcustom rst-mode-hook nil
  "Hook run when Rst mode is turned on.
The hook for Text mode is run before this one."
  :group 'rst
  :type '(hook))


;; Use rst-mode for *.rst and *.rest files.  Many ReStructured-Text files
;; use *.txt, but this is too generic to be set as a default.
;;;###autoload (add-to-list 'auto-mode-alist (purecopy '("\\.re?st\\'" . rst-mode)))
;;;###autoload
(define-derived-mode rst-mode text-mode "ReST"
  "Major mode for editing reStructuredText documents.
\\<rst-mode-map>
There are a number of convenient keybindings provided by
Rst mode.  The main one is \\[rst-adjust], it updates or rotates
the section title around point or promotes/demotes the
adornments within the region (see full details below).
Use negative prefix arg to rotate in the other direction.

Turning on `rst-mode' calls the normal hooks `text-mode-hook'
and `rst-mode-hook'.  This mode also supports font-lock
highlighting.

\\{rst-mode-map}"
  :abbrev-table rst-mode-abbrev-table
  :syntax-table rst-mode-syntax-table
  :group 'rst

  (set (make-local-variable 'paragraph-separate)
       (rst-re '(:alt
		 "\f"
		 lin-end)))
  (set (make-local-variable 'indent-line-function)
       (if (<= emacs-major-version 21)
	   'indent-relative-maybe
	 'indent-relative))
  (set (make-local-variable 'paragraph-start)
       (rst-re '(:alt
		 "\f"
		 lin-end
		 (:seq hws-tag itmany-sta-1))))
  (set (make-local-variable 'adaptive-fill-mode) t)

  ;; The details of the following comment setup is important because it affects
  ;; auto-fill, and it is pretty common in running text to have an ellipsis
  ;; ("...") which trips because of the rest comment syntax (".. ").
  (set (make-local-variable 'comment-start) ".. ")
  (set (make-local-variable 'comment-start-skip) (rst-re "^" 'exm-sta))
  (set (make-local-variable 'comment-multi-line) nil)
  ;; Text after a changed line may need new fontification - though we don't use
  ;; jit-lock-mode at the moment...
  (set (make-local-variable 'jit-lock-contextually) t)

  ;; Special variables
  (make-local-variable 'rst-adornment-level-alist)

  ;; Font lock
  (setq font-lock-defaults
	'(rst-font-lock-keywords
	  t nil nil nil
	  (font-lock-multiline . t)
	  (font-lock-mark-block-function . mark-paragraph)
	  ;; rst-mode does not need font-lock-support-mode because it's fast
	  ;; enough. In fact using `jit-lock-mode` slows things down
	  ;; considerably even if `rst-font-lock-extend-region` is in place and
	  ;; compiled.
	  (font-lock-support-mode . nil)
	  ))
  (setq font-lock-extend-region-functions
	(append font-lock-extend-region-functions
		'(rst-font-lock-extend-region))))

;;;###autoload
(define-minor-mode rst-minor-mode
  "ReST Minor Mode.
Toggle ReST minor mode.
With no argument, this command toggles the mode.
Non-null prefix argument turns on the mode.
Null prefix argument turns off the mode.

When ReST minor mode is enabled, the ReST mode keybindings
are installed on top of the major mode bindings.  Use this
for modes derived from Text mode, like Mail mode."
 ;; The initial value.
 nil
 ;; The indicator for the mode line.
 " ReST"
 ;; The minor mode bindings.
 rst-mode-map
 :group 'rst)

;; FIXME: can I somehow install these too?
;;  :abbrev-table rst-mode-abbrev-table
;;  :syntax-table rst-mode-syntax-table


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Section Adornment Adjustment
;; ============================
;;
;; The following functions implement a smart automatic title sectioning feature.
;; The idea is that with the cursor sitting on a section title, we try to get as
;; much information from context and try to do the best thing automatically.
;; This function can be invoked many times and/or with prefix argument to rotate
;; between the various sectioning adornments.
;;
;; Definitions: the two forms of sectioning define semantically separate section
;; levels.  A sectioning ADORNMENT consists in:
;;
;;   - a CHARACTER
;;
;;   - a STYLE which can be either of 'simple' or 'over-and-under'.
;;
;;   - an INDENT (meaningful for the over-and-under style only) which determines
;;     how many characters and over-and-under style is hanging outside of the
;;     title at the beginning and ending.
;;
;; Important note: an existing adornment must be formed by at least two
;; characters to be recognized.
;;
;; Here are two examples of adornments (| represents the window border, column
;; 0):
;;
;;                                  |
;; 1. char: '-'   e                 |Some Title
;;    style: simple                 |----------
;;                                  |
;; 2. char: '='                     |==============
;;    style: over-and-under         |  Some Title
;;    indent: 2                     |==============
;;                                  |
;;
;; Some notes:
;;
;; - The underlining character that is used depends on context. The file is
;;   scanned to find other sections and an appropriate character is selected.
;;   If the function is invoked on a section that is complete, the character is
;;   rotated among the existing section adornments.
;;
;;   Note that when rotating the characters, if we come to the end of the
;;   hierarchy of adornments, the variable rst-preferred-adornments is
;;   consulted to propose a new underline adornment, and if continued, we cycle
;;   the adornments all over again.  Set this variable to nil if you want to
;;   limit the underlining character propositions to the existing adornments in
;;   the file.
;;
;; - A prefix argument can be used to alternate the style.
;;
;; - An underline/overline that is not extended to the column at which it should
;;   be hanging is dubbed INCOMPLETE.  For example::
;;
;;      |Some Title
;;      |-------
;;
;; Examples of default invocation:
;;
;;   |Some Title       --->    |Some Title
;;   |                         |----------
;;
;;   |Some Title       --->    |Some Title
;;   |-----                    |----------
;;
;;   |                         |------------
;;   | Some Title      --->    | Some Title
;;   |                         |------------
;;
;; In over-and-under style, when alternating the style, a variable is
;; available to select how much default indent to use (it can be zero).  Note
;; that if the current section adornment already has an indent, we don't
;; adjust it to the default, we rather use the current indent that is already
;; there for adjustment (unless we cycle, in which case we use the indent
;; that has been found previously).

(defgroup rst-adjust nil
  "Settings for adjustment and cycling of section title adornments."
  :group 'rst
  :version "21.1")

(defcustom rst-preferred-adornments '((?= over-and-under 1)
				      (?= simple 0)
				      (?- simple 0)
				      (?~ simple 0)
				      (?+ simple 0)
				      (?` simple 0)
				      (?# simple 0)
				      (?@ simple 0))
  "Preferred ordering of section title adornments.

This sequence is consulted to offer a new adornment suggestion
when we rotate the underlines at the end of the existing
hierarchy of characters, or when there is no existing section
title in the file."
  :group 'rst-adjust)


(defcustom rst-default-indent 1
  "Number of characters to indent the section title.

This is used for when toggling adornment styles, when switching
from a simple adornment style to a over-and-under adornment
style."
  :group 'rst-adjust)


(defun rst-line-homogeneous-p (&optional accept-special)
  "Return true if the line is homogeneous.

Predicate that returns the unique char if the current line is
composed only of a single repeated non-whitespace character.
This returns the char even if there is whitespace at the
beginning of the line.

If ACCEPT-SPECIAL is specified we do not ignore special sequences
which normally we would ignore when doing a search on many lines.
For example, normally we have cases to ignore commonly occurring
patterns, such as :: or ...; with the flag do not ignore them."
  (save-excursion
    (back-to-indentation)
    (unless (looking-at "\n")
      (let ((c (char-after)))
	(if (and (looking-at (rst-re c "+" 'lin-end))
		 (or accept-special
		     (and
		      ;; Common patterns.
		      (not (looking-at (rst-re 'dcl-tag 'lin-end)))
		      (not (looking-at (rst-re 'ell-tag 'lin-end)))
		      ;; Discard one char line
		      (not (looking-at (rst-re "." 'lin-end)))
		      )))
	    c)
	))
    ))

(defun rst-line-homogeneous-nodent-p (&optional accept-special)
  "Return true if the line is homogeneous with no indent.
See `rst-line-homogeneous-p' about ACCEPT-SPECIAL."
  (save-excursion
    (beginning-of-line)
    (if (looking-at (rst-re 'hws-sta))
        nil
      (rst-line-homogeneous-p accept-special)
      )))


(defun rst-compare-adornments (ado1 ado2)
  "Compare adornments.
Return true if both ADO1 and ADO2 adornments are equal,
according to restructured text semantics (only the character and
the style are compared, the indentation does not matter)."
  (and (eq (car ado1) (car ado2))
       (eq (cadr ado1) (cadr ado2))))


(defun rst-get-adornment-match (hier ado)
  "Return the index (level) in hierarchy HIER of adornment ADO.
This basically just searches for the item using the appropriate
comparison and returns the index.  Return nil if the item is
not found."
  (let ((cur hier))
    (while (and cur (not (rst-compare-adornments (car cur) ado)))
      (setq cur (cdr cur)))
    cur))


(defun rst-suggest-new-adornment (allados &optional prev)
  "Suggest a new, different adornment from all that have been seen.

ALLADOS is the set of all adornments, including the line numbers.
PREV is the optional previous adornment, in order to suggest a
better match."

  ;; For all the preferred adornments...
  (let* (
         ;; If 'prev' is given, reorder the list to start searching after the
         ;; match.
         (fplist
          (cdr (rst-get-adornment-match rst-preferred-adornments prev)))

         ;; List of candidates to search.
         (curpotential (append fplist rst-preferred-adornments)))
    (while
        ;; For all the adornments...
        (let ((cur allados)
              found)
          (while (and cur (not found))
            (if (rst-compare-adornments (car cur) (car curpotential))
                ;; Found it!
                (setq found (car curpotential))
              (setq cur (cdr cur))))
          found)

      (setq curpotential (cdr curpotential)))

    (copy-sequence (car curpotential))))

(defun rst-delete-entire-line ()
  "Delete the entire current line without using the `kill-ring'."
  (delete-region (line-beginning-position)
                 (line-beginning-position 2)))

(defun rst-update-section (char style &optional indent)
  "Unconditionally update the style of a section adornment.

Do this using the given character CHAR, with STYLE 'simple
or 'over-and-under, and with indent INDENT.  If the STYLE
is 'simple, whitespace before the title is removed (indent
is always assumed to be 0).

If there are existing overline and/or underline from the
existing adornment, they are removed before adding the
requested adornment."

  (interactive)
  (let (marker
        len)

      (end-of-line)
      (setq marker (point-marker))

      ;; Fixup whitespace at the beginning and end of the line
      (if (or (null indent) (eq style 'simple))
          (setq indent 0))
      (beginning-of-line)
      (delete-horizontal-space)
      (insert (make-string indent ? ))

      (end-of-line)
      (delete-horizontal-space)

      ;; Set the current column, we're at the end of the title line
      (setq len (+ (current-column) indent))

      ;; Remove previous line if it consists only of a single repeated character
      (save-excursion
        (forward-line -1)
        (and (rst-line-homogeneous-p 1)
             ;; Avoid removing the underline of a title right above us.
             (save-excursion (forward-line -1)
                             (not (looking-at (rst-re 'ttl-beg))))
             (rst-delete-entire-line)))

      ;; Remove following line if it consists only of a single repeated
      ;; character
      (save-excursion
        (forward-line +1)
        (and (rst-line-homogeneous-p 1)
             (rst-delete-entire-line))
        ;; Add a newline if we're at the end of the buffer, for the subsequence
        ;; inserting of the underline
        (if (= (point) (buffer-end 1))
            (newline 1)))

      ;; Insert overline
      (if (eq style 'over-and-under)
          (save-excursion
            (beginning-of-line)
            (open-line 1)
            (insert (make-string len char))))

      ;; Insert underline
      (forward-line +1)
      (open-line 1)
      (insert (make-string len char))

      (forward-line +1)
      (goto-char marker)
      ))


(defun rst-normalize-cursor-position ()
  "Normalize the cursor position.
If the cursor is on an adornment line or an empty line , place it
on the section title line (at the end).  Returns the line offset
by which the cursor was moved.  This works both over or under a
line."
  (if (save-excursion (beginning-of-line)
                      (or (rst-line-homogeneous-p 1)
                          (looking-at (rst-re 'lin-end))))
      (progn
        (beginning-of-line)
        (cond
         ((save-excursion (forward-line -1)
                          (beginning-of-line)
                          (and (looking-at (rst-re 'ttl-beg))
                               (not (rst-line-homogeneous-p 1))))
          (progn (forward-line -1) -1))
         ((save-excursion (forward-line +1)
                          (beginning-of-line)
                          (and (looking-at (rst-re 'ttl-beg))
                               (not (rst-line-homogeneous-p 1))))
          (progn (forward-line +1) +1))
         (t 0)))
    0 ))


(defun rst-find-all-adornments ()
  "Find all the adornments in the file.
Return a list of (line, adornment) pairs.  Each adornment
consists in a (char, style, indent) triple.

This function does not detect the hierarchy of adornments, it
just finds all of them in a file.  You can then invoke another
function to remove redundancies and inconsistencies."

  (let (positions
        (curline 1))
    ;; Iterate over all the section titles/adornments in the file.
    (save-excursion
      (goto-char (point-min))
      (while (< (point) (buffer-end 1))
        (if (rst-line-homogeneous-nodent-p)
            (progn
              (setq curline (+ curline (rst-normalize-cursor-position)))

              ;; Here we have found a potential site for a adornment,
              ;; characterize it.
              (let ((ado (rst-get-adornment)))
                (if (cadr ado) ;; Style is existing.
                    ;; Found a real adornment site.
                    (progn
                      (push (cons curline ado) positions)
                      ;; Push beyond the underline.
                      (forward-line 1)
                      (setq curline (+ curline 1))
                      )))
              ))
        (forward-line 1)
        (setq curline (+ curline 1))
        ))
    (reverse positions)))


(defun rst-infer-hierarchy (adornments)
  "Build a hierarchy of adornments using the list of given ADORNMENTS.

This function expects a list of (char, style, indent) adornment
specifications, in order that they appear in a file, and will
infer a hierarchy of section levels by removing adornments that
have already been seen in a forward traversal of the adornments,
comparing just the character and style.

Similarly returns a list of (char, style, indent), where each
list element should be unique."

  (let ((hierarchy-alist (list)))
    (dolist (x adornments)
      (let ((char (car x))
            (style (cadr x)))
        (unless (assoc (cons char style) hierarchy-alist)
	  (push (cons (cons char style) x) hierarchy-alist))
        ))

    (mapcar 'cdr (nreverse hierarchy-alist))
    ))


(defun rst-get-hierarchy (&optional allados ignore)
  "Return the hierarchy of section titles in the file.

Return a list of adornments that represents the hierarchy of
section titles in the file.  Reuse the list of adornments
already computed in ALLADOS if present.  If the line number in
IGNORE is specified, the adornment found on that line (if there
is one) is not taken into account when building the hierarchy."
  (let ((all (or allados (rst-find-all-adornments))))
    (setq all (assq-delete-all ignore all))
    (rst-infer-hierarchy (mapcar 'cdr all))))


(defun rst-get-adornment (&optional point)
  "Get the adornment at POINT.

Looks around point and finds the characteristics of the
adornment that is found there.  Assumes that the cursor is
already placed on the title line (and not on the overline or
underline).

This function returns a (char, style, indent) triple.  If the
characters of overline and underline are different, return
the underline character.  The indent is always calculated.
A adornment can be said to exist if the style is not nil.

A point can be specified to go to the given location before
extracting the adornment."

  (let (char style indent)
    (save-excursion
      (if point (goto-char point))
      (beginning-of-line)
      (if (looking-at (rst-re 'ttl-beg))
          (let* ((over (save-excursion
                         (forward-line -1)
                         (rst-line-homogeneous-nodent-p)))

                (under (save-excursion
                         (forward-line +1)
                         (rst-line-homogeneous-nodent-p)))
                )

            ;; Check that the line above the overline is not part of a title
            ;; above it.
            (if (and over
                     (save-excursion
                       (and (equal (forward-line -2) 0)
                            (looking-at (rst-re 'ttl-beg)))))
                (setq over nil))

            (cond
             ;; No adornment found, leave all return values nil.
             ((and (eq over nil) (eq under nil)))

             ;; Overline only, leave all return values nil.
             ;;
             ;; Note: we don't return the overline character, but it could
             ;; perhaps in some cases be used to do something.
             ((and over (eq under nil)))

             ;; Underline only.
             ((and under (eq over nil))
              (setq char under
                    style 'simple))

             ;; Both overline and underline.
             (t
              (setq char under
                    style 'over-and-under))
             )
            )
        )
      ;; Find indentation.
      (setq indent (save-excursion (back-to-indentation) (current-column)))
      )
    ;; Return values.
    (list char style indent)))


(defun rst-get-adornments-around (&optional allados)
  "Return the adornments around point.

Given the list of all adornments ALLADOS (with positions),
find the adornments before and after the given point.
A list of the previous and next adornments is returned."
  (let* ((all (or allados (rst-find-all-adornments)))
         (curline (line-number-at-pos))
         prev next
         (cur all))

    ;; Search for the adornments around the current line.
    (while (and cur (< (caar cur) curline))
      (setq prev cur
            cur (cdr cur)))
    ;; 'cur' is the following adornment.

    (if (and cur (caar cur))
        (setq next (if (= curline (caar cur)) (cdr cur) cur)))

    (mapcar 'cdar (list prev next))
    ))


(defun rst-adornment-complete-p (ado)
  "Return true if the adornment ADO around point is complete."
  ;; Note: we assume that the detection of the overline as being the underline
  ;; of a preceding title has already been detected, and has been eliminated
  ;; from the adornment that is given to us.

  ;; There is some sectioning already present, so check if the current
  ;; sectioning is complete and correct.
  (let* ((char (car ado))
         (style (cadr ado))
         (indent (caddr ado))
         (endcol (save-excursion (end-of-line) (current-column)))
         )
    (if char
        (let ((exps (rst-re "^" char (format "\\{%d\\}" (+ endcol indent)) "$")))
          (and
           (save-excursion (forward-line +1)
                           (beginning-of-line)
                           (looking-at exps))
           (or (not (eq style 'over-and-under))
               (save-excursion (forward-line -1)
                               (beginning-of-line)
                               (looking-at exps))))
          ))
    ))


(defun rst-get-next-adornment
  (curado hier &optional suggestion reverse-direction)
  "Get the next adornment for CURADO, in given hierarchy HIER.
If suggesting, suggest for new adornment SUGGESTION.
REVERSE-DIRECTION is used to reverse the cycling order."

  (let* (
         (char (car curado))
         (style (cadr curado))

         ;; Build a new list of adornments for the rotation.
         (rotados
          (append hier
                  ;; Suggest a new adornment.
                  (list suggestion
                        ;; If nothing to suggest, use first adornment.
                        (car hier)))) )
    (or
     ;; Search for next adornment.
     (cadr
      (let ((cur (if reverse-direction rotados
                   (reverse rotados))))
        (while (and cur
                    (not (and (eq char (caar cur))
                              (eq style (cadar cur)))))
          (setq cur (cdr cur)))
        cur))

     ;; If not found, take the first of all adornments.
     suggestion
     )))


(defun rst-adjust (pfxarg)
  "Auto-adjust the adornment around point.

Adjust/rotate the section adornment for the section title
around point or promote/demote the adornments inside the region,
depending on if the region is active.  This function is meant to
be invoked possibly multiple times, and can vary its behavior
with a positive prefix argument (toggle style), or with a
negative prefix argument (alternate behavior).

This function is the main focus of this module and is a bit of a
swiss knife.  It is meant as the single most essential function
to be bound to invoke to adjust the adornments of a section
title in restructuredtext.  It tries to deal with all the
possible cases gracefully and to do `the right thing' in all
cases.

See the documentations of `rst-adjust-adornment-work' and
`rst-promote-region' for full details.

Prefix Arguments
================

The method can take either (but not both) of

a. a (non-negative) prefix argument, which means to toggle the
   adornment style.  Invoke with a prefix arg for example;

b. a negative numerical argument, which generally inverts the
   direction of search in the file or hierarchy.  Invoke with C--
   prefix for example."
  (interactive "P")

  (let* (;; Save our original position on the current line.
	 (origpt (set-marker (make-marker) (point)))

         (reverse-direction (and pfxarg (< (prefix-numeric-value pfxarg) 0)))
         (toggle-style (and pfxarg (not reverse-direction))))

    (if (rst-portable-mark-active-p)
        ;; Adjust adornments within region.
        (rst-promote-region (and pfxarg t))
      ;; Adjust adornment around point.
      (rst-adjust-adornment-work toggle-style reverse-direction))

    ;; Run the hooks to run after adjusting.
    (run-hooks 'rst-adjust-hook)

    ;; Make sure to reset the cursor position properly after we're done.
    (goto-char origpt)

    ))

(defvar rst-adjust-hook nil
  "Hooks to be run after running `rst-adjust'.")

(defvar rst-new-adornment-down nil
  "Non-nil if new adornment is added deeper.
If non-nil, a new adornment being added will be initialized to
be one level down from the previous adornment.  If nil, a new
adornment will be equal to the level of the previous
adornment.")

(defun rst-adjust-adornment (pfxarg)
  "Call `rst-adjust-adornment-work' interactively.

Keep this for compatibility for older bindings (are there any?)."
  (interactive "P")

  (let* ((reverse-direction (and pfxarg (< (prefix-numeric-value pfxarg) 0)))
         (toggle-style (and pfxarg (not reverse-direction))))
    (rst-adjust-adornment-work toggle-style reverse-direction)))

(defun rst-adjust-adornment-work (toggle-style reverse-direction)
"Adjust/rotate the section adornment for the section title around point.

This function is meant to be invoked possibly multiple times, and
can vary its behavior with a true TOGGLE-STYLE argument, or with
a REVERSE-DIRECTION argument.

General Behavior
================

The next action it takes depends on context around the point, and
it is meant to be invoked possibly more than once to rotate among
the various possibilities.  Basically, this function deals with:

- adding a adornment if the title does not have one;

- adjusting the length of the underline characters to fit a
  modified title;

- rotating the adornment in the set of already existing
  sectioning adornments used in the file;

- switching between simple and over-and-under styles.

You should normally not have to read all the following, just
invoke the method and it will do the most obvious thing that you
would expect.


Adornment Definitions
=====================

The adornments consist in

1. a CHARACTER

2. a STYLE which can be either of 'simple' or 'over-and-under'.

3. an INDENT (meaningful for the over-and-under style only)
   which determines how many characters and over-and-under
   style is hanging outside of the title at the beginning and
   ending.

See source code for mode details.


Detailed Behavior Description
=============================

Here are the gory details of the algorithm (it seems quite
complicated, but really, it does the most obvious thing in all
the particular cases):

Before applying the adornment change, the cursor is placed on
the closest line that could contain a section title.

Case 1: No Adornment
--------------------

If the current line has no adornment around it,

- search backwards for the last previous adornment, and apply
  the adornment one level lower to the current line.  If there
  is no defined level below this previous adornment, we suggest
  the most appropriate of the `rst-preferred-adornments'.

  If REVERSE-DIRECTION is true, we simply use the previous
  adornment found directly.

- if there is no adornment found in the given direction, we use
  the first of `rst-preferred-adornments'.

The prefix argument forces a toggle of the prescribed adornment
style.

Case 2: Incomplete Adornment
----------------------------

If the current line does have an existing adornment, but the
adornment is incomplete, that is, the underline/overline does
not extend to exactly the end of the title line (it is either too
short or too long), we simply extend the length of the
underlines/overlines to fit exactly the section title.

If the prefix argument is given, we toggle the style of the
adornment as well.

REVERSE-DIRECTION has no effect in this case.

Case 3: Complete Existing Adornment
-----------------------------------

If the adornment is complete (i.e. the underline (overline)
length is already adjusted to the end of the title line), we
search/parse the file to establish the hierarchy of all the
adornments (making sure not to include the adornment around
point), and we rotate the current title's adornment from within
that list (by default, going *down* the hierarchy that is present
in the file, i.e. to a lower section level).  This is meant to be
used potentially multiple times, until the desired adornment is
found around the title.

If we hit the boundary of the hierarchy, exactly one choice from
the list of preferred adornments is suggested/chosen, the first
of those adornment that has not been seen in the file yet (and
not including the adornment around point), and the next
invocation rolls over to the other end of the hierarchy (i.e. it
cycles).  This allows you to avoid having to set which character
to use.

If REVERSE-DIRECTION is true, the effect is to change the
direction of rotation in the hierarchy of adornments, thus
instead going *up* the hierarchy.

However, if there is a non-negative prefix argument, we do not
rotate the adornment, but instead simply toggle the style of the
current adornment (this should be the most common way to toggle
the style of an existing complete adornment).


Point Location
==============

The invocation of this function can be carried out anywhere
within the section title line, on an existing underline or
overline, as well as on an empty line following a section title.
This is meant to be as convenient as possible.


Indented Sections
=================

Indented section titles such as ::

   My Title
   --------

are invalid in restructuredtext and thus not recognized by the
parser.  This code will thus not work in a way that would support
indented sections (it would be ambiguous anyway).


Joint Sections
==============

Section titles that are right next to each other may not be
treated well.  More work might be needed to support those, and
special conditions on the completeness of existing adornments
might be required to make it non-ambiguous.

For now we assume that the adornments are disjoint, that is,
there is at least a single line between the titles/adornment
lines."
  (let* (;; Check if we're on an underline around a section title, and move the
         ;; cursor to the title if this is the case.
         (moved (rst-normalize-cursor-position))

         ;; Find the adornment and completeness around point.
         (curado (rst-get-adornment))
         (char (car curado))
         (style (cadr curado))
         (indent (caddr curado))

         ;; New values to be computed.
         char-new style-new indent-new
         )

    ;; We've moved the cursor... if we're not looking at some text, we have
    ;; nothing to do.
    (if (save-excursion (beginning-of-line)
                        (looking-at (rst-re 'ttl-beg)))
        (progn
          (cond
           ;;-------------------------------------------------------------------
           ;; Case 1: No Adornment
           ((and (eq char nil) (eq style nil))

            (let* ((allados (rst-find-all-adornments))

                   (around (rst-get-adornments-around allados))
                   (prev (car around))
                   cur

                   (hier (rst-get-hierarchy allados))
                   )

              ;; Advance one level down.
              (setq cur
                    (if prev
                        (if (or (and rst-new-adornment-down reverse-direction)
				(and (not rst-new-adornment-down) (not reverse-direction)))
			    prev
                            (or (cadr (rst-get-adornment-match hier prev))
                                (rst-suggest-new-adornment hier prev)))
                      (copy-sequence (car rst-preferred-adornments))))

              ;; Invert the style if requested.
              (if toggle-style
                  (setcar (cdr cur) (if (eq (cadr cur) 'simple)
                                        'over-and-under 'simple)) )

              (setq char-new (car cur)
                    style-new (cadr cur)
                    indent-new (caddr cur))
              ))

           ;;-------------------------------------------------------------------
           ;; Case 2: Incomplete Adornment
           ((not (rst-adornment-complete-p curado))

            ;; Invert the style if requested.
            (if toggle-style
                (setq style (if (eq style 'simple) 'over-and-under 'simple)))

            (setq char-new char
                  style-new style
                  indent-new indent))

           ;;-------------------------------------------------------------------
           ;; Case 3: Complete Existing Adornment
           (t
            (if toggle-style

                ;; Simply switch the style of the current adornment.
                (setq char-new char
                      style-new (if (eq style 'simple) 'over-and-under 'simple)
                      indent-new rst-default-indent)

              ;; Else, we rotate, ignoring the adornment around the current
              ;; line...
              (let* ((allados (rst-find-all-adornments))

                     (hier (rst-get-hierarchy allados (line-number-at-pos)))

                     ;; Suggestion, in case we need to come up with something
                     ;; new
                     (suggestion (rst-suggest-new-adornment
                                  hier
                                  (car (rst-get-adornments-around allados))))

                     (nextado (rst-get-next-adornment
                                curado hier suggestion reverse-direction))

                     )

                ;; Indent, if present, always overrides the prescribed indent.
                (setq char-new (car nextado)
                      style-new (cadr nextado)
                      indent-new (caddr nextado))

                )))
           )

          ;; Override indent with present indent!
          (setq indent-new (if (> indent 0) indent indent-new))

          (if (and char-new style-new)
              (rst-update-section char-new style-new indent-new))
          ))


    ;; Correct the position of the cursor to more accurately reflect where it
    ;; was located when the function was invoked.
    (unless (= moved 0)
      (forward-line (- moved))
      (end-of-line))

    ))

;; Maintain an alias for compatibility.
(defalias 'rst-adjust-section-title 'rst-adjust)


(defun rst-promote-region (demote)
  "Promote the section titles within the region.

With argument DEMOTE or a prefix argument, demote the section
titles instead.  The algorithm used at the boundaries of the
hierarchy is similar to that used by `rst-adjust-adornment-work'."
  (interactive "P")

  (let* ((allados (rst-find-all-adornments))
         (cur allados)

         (hier (rst-get-hierarchy allados))
         (suggestion (rst-suggest-new-adornment hier))

         (region-begin-line (line-number-at-pos (region-beginning)))
         (region-end-line (line-number-at-pos (region-end)))

         marker-list
         )

    ;; Skip the markers that come before the region beginning
    (while (and cur (< (caar cur) region-begin-line))
      (setq cur (cdr cur)))

    ;; Create a list of markers for all the adornments which are found within
    ;; the region.
    (save-excursion
      (let (m line)
        (while (and cur (< (setq line (caar cur)) region-end-line))
          (setq m (make-marker))
          (goto-char (point-min))
          (forward-line (1- line))
          (push (list (set-marker m (point)) (cdar cur)) marker-list)
          (setq cur (cdr cur)) ))

      ;; Apply modifications.
      (let (nextado)
        (dolist (p marker-list)
          ;; Go to the adornment to promote.
          (goto-char (car p))

          ;; Rotate the next adornment.
          (setq nextado (rst-get-next-adornment
                          (cadr p) hier suggestion demote))

          ;; Update the adornment.
          (apply 'rst-update-section nextado)

          ;; Clear marker to avoid slowing down the editing after we're done.
          (set-marker (car p) nil)
          ))
      (setq deactivate-mark nil)
    )))



(defun rst-display-adornments-hierarchy (&optional adornments)
  "Display the current file's section title adornments hierarchy.
This function expects a list of (char, style, indent) triples in
ADORNMENTS."
  (interactive)

  (if (not adornments)
      (setq adornments (rst-get-hierarchy)))
  (with-output-to-temp-buffer "*rest section hierarchy*"
    (let ((level 1))
      (with-current-buffer standard-output
        (dolist (x adornments)
          (insert (format "\nSection Level %d" level))
          (apply 'rst-update-section x)
          (goto-char (point-max))
          (insert "\n")
          (incf level)
          ))
    )))

(defun rst-position (elem list)
  "Return position of ELEM in LIST or nil."
  (let ((tail (member elem list)))
    (if tail (- (length list) (length tail)))))

(defun rst-straighten-adornments ()
  "Redo all the adornments in the current buffer.
This is done using our preferred set of adornments.  This can be
used, for example, when using somebody else's copy of a document,
in order to adapt it to our preferred style."
  (interactive)
  (save-excursion
    (let* ((allados (rst-find-all-adornments))
	   (hier (rst-get-hierarchy allados))

	   ;; Get a list of pairs of (level . marker)
	   (levels-and-markers (mapcar
				(lambda (ado)
				  (cons (rst-position (cdr ado) hier)
					(let ((m (make-marker)))
					  (goto-char (point-min))
					  (forward-line (1- (car ado)))
					  (set-marker m (point))
					  m)))
				allados))
	   )
      (dolist (lm levels-and-markers)
	;; Go to the appropriate position
	(goto-char (cdr lm))

	;; Apply the new styule
	(apply 'rst-update-section (nth (car lm) rst-preferred-adornments))

	;; Reset the market to avoid slowing down editing until it gets GC'ed
	(set-marker (cdr lm) nil)
	)
    )))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Insert list items
;; =================


;=================================================
; Borrowed from a2r.el (version 1.3), by Lawrence Mitchell <wence@gmx.li>
; I needed to make some tiny changes to the functions, so I put it here.
; -- Wei-Wei Guo

(defconst rst-arabic-to-roman
  '((1000 .   "M") (900  .  "CM") (500  .   "D") (400  .  "CD")
    (100  .   "C") (90   .  "XC") (50   .   "L") (40   .  "XL")
    (10   .   "X") (9    .  "IX") (5    .   "V") (4    .  "IV")
    (1    .   "I"))
  "List of maps between Arabic numbers and their Roman numeral equivalents.")

(defun rst-arabic-to-roman (num &optional arg)
  "Convert Arabic number NUM to its Roman numeral representation.

Obviously, NUM must be greater than zero.  Don't blame me, blame the
Romans, I mean \"what have the Romans ever _done_ for /us/?\" (with
apologies to Monty Python).
If optional prefix ARG is non-nil, insert in current buffer."
  (let ((map rst-arabic-to-roman)
        res)
    (while (and map (> num 0))
      (if (or (= num (caar map))
              (> num (caar map)))
          (setq res (concat res (cdar map))
                num (- num (caar map)))
        (setq map (cdr map))))
    res))

(defun rst-roman-to-arabic (string &optional arg)
  "Convert STRING of Roman numerals to an Arabic number.

If STRING contains a letter which isn't a valid Roman numeral, the rest
of the string from that point onwards is ignored.

Hence:
MMD == 2500
and
MMDFLXXVI == 2500.
If optional ARG is non-nil, insert in current buffer."
  (let ((res 0)
        (map rst-arabic-to-roman))
    (while map
      (if (string-match (concat "^" (cdar map)) string)
          (setq res (+ res (caar map))
                string (replace-match "" nil t string))
        (setq map (cdr map))))
    res))
;=================================================

(defun rst-find-pfx-in-region (beg end pfx-re)
  "Find all the positions of prefixes in region between BEG and END.
This is used to find bullets and enumerated list items. PFX-RE is
a regular expression for matching the lines after indentation
with items. Returns a list of cons cells consisting of the point
and the column of the point."
  (let (pfx)
    (save-excursion
      (goto-char beg)
      (while (< (point) end)
	(back-to-indentation)
	(when (and
	       (looking-at pfx-re) ;; pfx found and...
	       (let ((pfx-col (current-column)))
		 (save-excursion
		   (forward-line -1) ;; ...previous line is...
		   (back-to-indentation)
		   (or (looking-at (rst-re 'lin-end)) ;; ...empty,
		       (> (current-column) pfx-col) ;; ...deeper level, or
		       (and (= (current-column) pfx-col)
			    (looking-at pfx-re)))))) ;; ...pfx at same level
	  (push (cons (point) (current-column))
                pfx))
	(forward-line 1)) )
    (nreverse pfx)))

(defun rst-insert-list-pos (newitem)
  "Arrange relative position of a newly inserted list item.

Adding a new list might consider three situations:

 (a) Current line is a blank line.
 (b) Previous line is a blank line.
 (c) Following line is a blank line.

When (a) and (b), just add the new list at current line.

when (a) and not (b), a blank line is added before adding the new list.

When not (a), first forward point to the end of the line, and add two
blank lines, then add the new list.

Other situations are just ignored and left to users themselves."
  (if (save-excursion
        (beginning-of-line)
        (looking-at (rst-re 'lin-end)))
      (if (save-excursion
            (forward-line -1)
            (looking-at (rst-re 'lin-end)))
          (insert newitem " ")
        (insert "\n" newitem " "))
    (end-of-line)
    (insert "\n\n" newitem " ")))

(defvar rst-initial-enums
  (let (vals)
    (dolist (fmt '("%s." "(%s)" "%s)"))
      (dolist (c '("1" "a" "A" "I" "i"))
        (push (format fmt c) vals)))
    (cons "#." (nreverse vals)))
  "List of initial enumerations.")

(defvar rst-initial-items
  (append (mapcar 'char-to-string rst-bullets) rst-initial-enums)
  "List of initial items.  It's collection of bullets and enumerations.")

(defun rst-insert-list-new-item ()
  "Insert a new list item.

User is asked to select the item style first, for example (a), i), +.  Use TAB
for completition and choices.

If user selects bullets or #, it's just added with position arranged by
`rst-insert-list-pos'.

If user selects enumerations, a further prompt is given. User need to input a
starting item, for example 'e' for 'A)' style.  The position is also arranged by
`rst-insert-list-pos'."
  (interactive)
  ;; FIXME: Make this comply to `interactive' standards
  (let* ((itemstyle (completing-read
		     "Select preferred item style [#.]: "
		     rst-initial-items nil t nil nil "#."))
	 (cnt (if (string-match (rst-re 'cntexp-tag) itemstyle)
		  (match-string 0 itemstyle)))
	 (no
	  (save-match-data
	    ;; FIXME: Make this comply to `interactive' standards
	    (cond
	     ((equal cnt "a")
	      (let ((itemno (read-string "Give starting value [a]: "
					 nil nil "a")))
		(downcase (substring itemno 0 1))))
	     ((equal cnt "A")
	      (let ((itemno (read-string "Give starting value [A]: "
					 nil nil "A")))
		(upcase (substring itemno 0 1))))
	     ((equal cnt "I")
	      (let ((itemno (read-number "Give starting value [1]: " 1)))
		(rst-arabic-to-roman itemno)))
	     ((equal cnt "i")
	      (let ((itemno (read-number "Give starting value [1]: " 1)))
		(downcase (rst-arabic-to-roman itemno))))
	     ((equal cnt "1")
	      (let ((itemno (read-number "Give starting value [1]: " 1)))
		(number-to-string itemno)))))))
    (if no
	(setq itemstyle (replace-match no t t itemstyle)))
    (rst-insert-list-pos itemstyle)))

(defvar rst-preferred-bullets
  '(?- ?* ?+)
  "List of favourite bullets.")

(defun rst-insert-list-continue (curitem prefer-roman)
  "Insert a list item with list start CURITEM including its indentation level."
  (end-of-line)
  (insert
   "\n" ;; FIXME: Separating lines must be possible
   (cond
    ((string-match (rst-re '(:alt enmaut-tag
				  bul-tag)) curitem)
     curitem)
    ((string-match (rst-re 'num-tag) curitem)
     (replace-match (number-to-string
		     (1+ (string-to-number (match-string 0 curitem))))
		    nil nil curitem))
    ((and (string-match (rst-re 'rom-tag) curitem)
	  (save-match-data
	    (if (string-match (rst-re 'ltr-tag) curitem) ;; Also a letter tag
		(save-excursion
		  ;; FIXME: Assumes one line list items without separating
		  ;; empty lines
		  (if (and (= (forward-line -1) 0)
			   (looking-at (rst-re 'enmexp-beg)))
		      (string-match
		       (rst-re 'rom-tag)
		       (match-string 0)) ;; Previous was a roman tag
		    prefer-roman)) ;; Don't know - use flag
	      t))) ;; Not a letter tag
     (replace-match
      (let* ((old (match-string 0 curitem))
	     (new (save-match-data
		    (rst-arabic-to-roman
		     (1+ (rst-roman-to-arabic
			  (upcase old)))))))
	(if (equal old (upcase old))
	    (upcase new)
	  (downcase new)))
      t nil curitem))
    ((string-match (rst-re 'ltr-tag) curitem)
     (replace-match (char-to-string
		     (1+ (string-to-char (match-string 0 curitem))))
		    nil nil curitem)))))


(defun rst-insert-list (&optional prefer-roman)
  "Insert a list item at the current point.

The command can insert a new list or a continuing list. When it is called at a
non-list line, it will promote to insert new list. When it is called at a list
line, it will insert a list with the same list style.

1. When inserting a new list:

User is asked to select the item style first, for example (a), i), +. Use TAB
for completition and choices.

 (a) If user selects bullets or #, it's just added.
 (b) If user selects enumerations, a further prompt is given.  User needs to
     input a starting item, for example 'e' for 'A)' style.

The position of the new list is arranged according to whether or not the
current line and the previous line are blank lines.

2. When continuing a list, one thing need to be noticed:

List style alphabetical list, such as 'a.', and roman numerical list, such as
'i.', have some overlapping items, for example 'v.' The function can deal with
the problem elegantly in most situations.  But when those overlapped list are
preceded by a blank line, it is hard to determine which type to use
automatically.  The function uses alphabetical list by default.  If you want
roman numerical list, just use a prefix (\\[universal-argument])."
  (interactive "P")
  (beginning-of-line)
  (if (looking-at (rst-re 'itmany-beg-1))
      (rst-insert-list-continue (match-string 0) prefer-roman)
    (rst-insert-list-new-item)))

(defun rst-straighten-bullets-region (beg end)
  "Make all the bulleted list items in the region consistent.
The region is specified between BEG and END.  You can use this
after you have merged multiple bulleted lists to make them use
the same/correct/consistent bullet characters.

See variable `rst-preferred-bullets' for the list of bullets to
adjust.  If bullets are found on levels beyond the
`rst-preferred-bullets' list, they are not modified."
  (interactive "r")

  (let ((bullets (rst-find-pfx-in-region beg end (rst-re 'bul-sta)))
	(levtable (make-hash-table :size 4)))

    ;; Create a map of levels to list of positions.
    (dolist (x bullets)
      (let ((key (cdr x)))
	(puthash key
		  (append (gethash key levtable (list))
			  (list (car x)))
		  levtable)))

    ;; Sort this map and create a new map of prefix char and list of positions.
    (let ((poslist ()))                 ; List of (indent . positions).
      (maphash (lambda (x y) (push (cons x y) poslist)) levtable)

      (let ((bullets rst-preferred-bullets))
        (dolist (x (sort poslist 'car-less-than-car))
          (when bullets
            ;; Apply the characters.
            (dolist (pos (cdr x))
              (goto-char pos)
              (delete-char 1)
              (insert (string (car bullets))))
            (setq bullets (cdr bullets))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Table of contents
;; =================

(defun rst-get-stripped-line ()
  "Return the line at cursor, stripped from whitespace."
  (re-search-forward (rst-re "\\S .*\\S ") (line-end-position))
  (buffer-substring-no-properties (match-beginning 0)
                                  (match-end 0)) )

(defun rst-section-tree (allados)
  "Get the hierarchical tree of section titles.

Returns a hierarchical tree of the sections titles in the
document, for adornments ALLADOS.  This can be used to generate
a table of contents for the document.  The top node will always
be a nil node, with the top level titles as children (there may
potentially be more than one).

Each section title consists in a cons of the stripped title
string and a marker to the section in the original text document.

If there are missing section levels, the section titles are
inserted automatically, and the title string is set to nil, and
the marker set to the first non-nil child of itself.
Conceptually, the nil nodes--i.e. those which have no title--are
to be considered as being the same line as their first non-nil
child.  This has advantages later in processing the graph."

  (let* ((hier (rst-get-hierarchy allados))
         (levels (make-hash-table :test 'equal :size 10))
         lines)

    (let ((lev 0))
      (dolist (ado hier)
	;; Compare just the character and indent in the hash table.
        (puthash (cons (car ado) (cadr ado)) lev levels)
        (incf lev)))

    ;; Create a list of lines that contains (text, level, marker) for each
    ;; adornment.
    (save-excursion
      (setq lines
            (mapcar (lambda (ado)
                      (goto-char (point-min))
                      (forward-line (1- (car ado)))
                      (list (gethash (cons (cadr ado) (caddr ado)) levels)
                            (rst-get-stripped-line)
                            (let ((m (make-marker)))
                              (beginning-of-line 1)
                              (set-marker m (point)))
                            ))
                    allados)))

    (let ((lcontnr (cons nil lines)))
      (rst-section-tree-rec lcontnr -1))))


(defun rst-section-tree-rec (ados lev)
  "Recursive guts of the section tree construction.
ADOS is a cons cell whose cdr is the remaining list of
adornments, and we change it as we consume them.  LEV is
the current level of that node.  This function returns a
pair of the subtree that was built.  This treats the ADOS
list destructively."

  (let ((nado (cadr ados))
        node
        children)

    ;; If the next adornment matches our level
    (when (and nado (= (car nado) lev))
      ;; Pop the next adornment and create the current node with it
      (setcdr ados (cddr ados))
      (setq node (cdr nado)) )
    ;; Else we let the node title/marker be unset.

    ;; Build the child nodes
    (while (and (cdr ados) (> (caadr ados) lev))
      (setq children
            (cons (rst-section-tree-rec ados (1+ lev))
                  children)))
    (setq children (reverse children))

    ;; If node is still unset, we use the marker of the first child.
    (when (eq node nil)
      (setq node (cons nil (cdaar children))))

    ;; Return this node with its children.
    (cons node children)
    ))


(defun rst-section-tree-point (node &optional point)
  "Find tree node at point.
Given a computed and valid section tree in NODE and a point
POINT (default being the current point in the current buffer),
find and return the node within the sectree where the cursor
lives.

Return values: a pair of (parent path, container subtree).
The parent path is simply a list of the nodes above the
container subtree node that we're returning."

  (let (path outtree)

    (let* ((curpoint (or point (point))))

      ;; Check if we are before the current node.
      (if (and (cadar node) (>= curpoint (cadar node)))

	  ;; Iterate all the children, looking for one that might contain the
	  ;; current section.
	  (let ((curnode (cdr node))
		last)

	    (while (and curnode (>= curpoint (cadaar curnode)))
	      (setq last curnode
		    curnode (cdr curnode)))

	    (if last
		(let ((sub (rst-section-tree-point (car last) curpoint)))
		  (setq path (car sub)
			outtree (cdr sub)))
	      (setq outtree node))

	    )))
    (cons (cons (car node) path) outtree)
    ))


(defgroup rst-toc nil
  "Settings for reStructuredText table of contents."
  :group 'rst
  :version "21.1")

(defcustom rst-toc-indent 2
  "Indentation for table-of-contents display.
Also used for formatting insertion, when numbering is disabled."
  :group 'rst-toc)

(defcustom rst-toc-insert-style 'fixed
  "Insertion style for table-of-contents.
Set this to one of the following values to determine numbering and
indentation style:
- plain: no numbering (fixed indentation)
- fixed: numbering, but fixed indentation
- aligned: numbering, titles aligned under each other
- listed: numbering, with dashes like list items (EXPERIMENTAL)"
  :group 'rst-toc)

(defcustom rst-toc-insert-number-separator "  "
  "Separator that goes between the TOC number and the title."
  :group 'rst-toc)

;; This is used to avoid having to change the user's mode.
(defvar rst-toc-insert-click-keymap
  (let ((map (make-sparse-keymap)))
       (define-key map [mouse-1] 'rst-toc-mode-mouse-goto)
       map)
  "(Internal) What happens when you click on propertized text in the TOC.")

(defcustom rst-toc-insert-max-level nil
  "If non-nil, maximum depth of the inserted TOC."
  :group 'rst-toc)


(defun rst-toc-insert (&optional pfxarg)
  "Insert a simple text rendering of the table of contents.
By default the top level is ignored if there is only one, because
we assume that the document will have a single title.

If a numeric prefix argument PFXARG is given, insert the TOC up
to the specified level.

The TOC is inserted indented at the current column."

  (interactive "P")

  (let* (;; Check maximum level override
         (rst-toc-insert-max-level
          (if (and (integerp pfxarg) (> (prefix-numeric-value pfxarg) 0))
              (prefix-numeric-value pfxarg) rst-toc-insert-max-level))

         ;; Get the section tree for the current cursor point.
         (sectree-pair
	  (rst-section-tree-point
	   (rst-section-tree (rst-find-all-adornments))))

         ;; Figure out initial indent.
         (initial-indent (make-string (current-column) ? ))
         (init-point (point)))

    (when (cddr sectree-pair)
      (rst-toc-insert-node (cdr sectree-pair) 0 initial-indent "")

      ;; Fixup for the first line.
      (delete-region init-point (+ init-point (length initial-indent)))

      ;; Delete the last newline added.
      (delete-backward-char 1)
    )))

(defun rst-toc-insert-node (node level indent pfx)
  "Insert tree node NODE in table-of-contents.
Recursive function that does printing of the inserted toc.
LEVEL is the depth level of the sections in the tree.
INDENT is the indentation string.  PFX is the prefix numbering,
that includes the alignment necessary for all the children of
level to align."

  ;; Note: we do child numbering from the parent, so we start number the
  ;; children one level before we print them.
  (let ((do-print (> level 0))
        (count 1))
    (when do-print
      (insert indent)
      (let ((b (point)))
	(unless (equal rst-toc-insert-style 'plain)
	  (insert pfx rst-toc-insert-number-separator))
	(insert (or (caar node) "[missing node]"))
	;; Add properties to the text, even though in normal text mode it
	;; won't be doing anything for now.  Not sure that I want to change
	;; mode stuff.  At least the highlighting gives the idea that this
	;; is generated automatically.
	(put-text-property b (point) 'mouse-face 'highlight)
	(put-text-property b (point) 'rst-toc-target (cadar node))
	(put-text-property b (point) 'keymap rst-toc-insert-click-keymap)

	)
      (insert "\n")

      ;; Prepare indent for children.
      (setq indent
	    (cond
	     ((eq rst-toc-insert-style 'plain)
              (concat indent (make-string rst-toc-indent ? )))

	     ((eq rst-toc-insert-style 'fixed)
	      (concat indent (make-string rst-toc-indent ? )))

	     ((eq rst-toc-insert-style 'aligned)
	      (concat indent (make-string (+ (length pfx) 2) ? )))

	     ((eq rst-toc-insert-style 'listed)
	      (concat (substring indent 0 -3)
		      (concat (make-string (+ (length pfx) 2) ? ) " - ")))
	     ))
      )

    (if (or (eq rst-toc-insert-max-level nil)
            (< level rst-toc-insert-max-level))
        (let ((do-child-numbering (>= level 0))
              fmt)
          (if do-child-numbering
              (progn
                ;; Add a separating dot if there is already a prefix
                (when (> (length pfx) 0)
		  (string-match (rst-re "[ \t\n]*\\'") pfx)
		  (setq pfx (concat (replace-match "" t t pfx) ".")))

                ;; Calculate the amount of space that the prefix will require
                ;; for the numbers.
                (if (cdr node)
                    (setq fmt (format "%%-%dd"
                                      (1+ (floor (log10 (length
							 (cdr node))))))))
                ))

          (dolist (child (cdr node))
            (rst-toc-insert-node child
				 (1+ level)
				 indent
				 (if do-child-numbering
				     (concat pfx (format fmt count)) pfx))
            (incf count)))

      )))


(defun rst-toc-update ()
  "Automatically find the contents section of a document and update.
Updates the inserted TOC if present.  You can use this in your
file-write hook to always make it up-to-date automatically."
  (interactive)
  (save-excursion
    ;; Find and delete an existing comment after the first contents directive.
    ;; Delete that region.
    (goto-char (point-min))
    ;; We look for the following and the following only (in other words, if your
    ;; syntax differs, this won't work.).
    ;;
    ;;   .. contents:: [...anything here...]
    ;;      [:field: value]...
    ;;   ..
    ;;      XXXXXXXX
    ;;      XXXXXXXX
    ;;      [more lines]
    (let ((beg (re-search-forward
		(rst-re "^" 'exm-sta "contents" 'dcl-tag ".*\n"
			"\\(?:" 'hws-sta 'fld-tag ".*\n\\)*" 'exm-tag) nil t))
	  last-real)
      (when beg
	;; Look for the first line that starts at the first column.
	(forward-line 1)
	(while (and
		(< (point) (point-max))
		(or (if (looking-at
			 (rst-re 'hws-sta "\\S ")) ;; indented content
			(setq last-real (point)))
		    (looking-at (rst-re 'lin-end)))) ;; empty line
	  (forward-line 1))
	(if last-real
	    (progn
	      (goto-char last-real)
	      (end-of-line)
	      (delete-region beg (point)))
	  (goto-char beg))
	(insert "\n    ")
	(rst-toc-insert))))
  ;; Note: always return nil, because this may be used as a hook.
  nil)

;; Note: we cannot bind the TOC update on file write because it messes with
;; undo.  If we disable undo, since it adds and removes characters, the
;; positions in the undo list are not making sense anymore.  Dunno what to do
;; with this, it would be nice to update when saving.
;;
;; (add-hook 'write-contents-hooks 'rst-toc-update-fun)
;; (defun rst-toc-update-fun ()
;;   ;; Disable undo for the write file hook.
;;   (let ((buffer-undo-list t)) (rst-toc-update) ))

(defalias 'rst-toc-insert-update 'rst-toc-update) ;; backwards compat.

;;------------------------------------------------------------------------------

(defun rst-toc-node (node level)
  "Recursive function that does insert NODE at LEVEL in the table-of-contents."

  (if (> level 0)
      (let ((b (point)))
        ;; Insert line text.
        (insert (make-string (* rst-toc-indent (1- level)) ? ))
        (insert (or (caar node) "[missing node]"))

        ;; Highlight lines.
        (put-text-property b (point) 'mouse-face 'highlight)

        ;; Add link on lines.
        (put-text-property b (point) 'rst-toc-target (cadar node))

        (insert "\n")
	))

  (dolist (child (cdr node))
    (rst-toc-node child (1+ level))))

(defun rst-toc-count-lines (node target-node)
  "Count the number of lines from NODE to the TARGET-NODE node.
This recursive function returns a cons of the number of
additional lines that have been counted for its node and
children, and t if the node has been found."

  (let ((count 1)
	found)
    (if (eq node target-node)
	(setq found t)
      (let ((child (cdr node)))
	(while (and child (not found))
	  (let ((cl (rst-toc-count-lines (car child) target-node)))
	    (setq count (+ count (car cl))
		  found (cdr cl)
		  child (cdr child))))))
    (cons count found)))

(defvar rst-toc-buffer-name "*Table of Contents*"
  "Name of the Table of Contents buffer.")

(defvar rst-toc-return-buffer nil
  "Window configuration to which to return when leaving the TOC.")


(defun rst-toc ()
  "Display a table-of-contents.
Finds all the section titles and their adornments in the
file, and displays a hierarchically-organized list of the
titles, which is essentially a table-of-contents of the
document.

The Emacs buffer can be navigated, and selecting a section
brings the cursor in that section."
  (interactive)
  (let* ((curbuf (list (current-window-configuration) (point-marker)))

         ;; Get the section tree
         (allados (rst-find-all-adornments))
         (sectree (rst-section-tree allados))

 	 (our-node (cdr (rst-section-tree-point sectree)))
	 line

         ;; Create a temporary buffer.
         (buf (get-buffer-create rst-toc-buffer-name))
         )

    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (rst-toc-mode)
        (delete-region (point-min) (point-max))
        (insert (format "Table of Contents: %s\n" (or (caar sectree) "")))
        (put-text-property (point-min) (point)
                           'face (list '(background-color . "gray")))
        (rst-toc-node sectree 0)

	;; Count the lines to our found node.
	(let ((linefound (rst-toc-count-lines sectree our-node)))
	  (setq line (if (cdr linefound) (car linefound) 0)))
        ))
    (display-buffer buf)
    (pop-to-buffer buf)

    ;; Save the buffer to return to.
    (set (make-local-variable 'rst-toc-return-buffer) curbuf)

    ;; Move the cursor near the right section in the TOC.
    (goto-char (point-min))
    (forward-line (1- line))
    ))


(defun rst-toc-mode-find-section ()
  "Get the section from text property at point."
  (let ((pos (get-text-property (point) 'rst-toc-target)))
    (unless pos
      (error "No section on this line"))
    (unless (buffer-live-p (marker-buffer pos))
      (error "Buffer for this section was killed"))
    pos))

;; FIXME: Cursor before of behind the list must be handled properly, before the
;;        list should jump to the top and behind the list to the last normal
;;        paragraph
(defun rst-goto-section (&optional kill)
  "Go to the section the current line describes."
  (interactive)
  (let ((pos (rst-toc-mode-find-section)))
    (when kill
      (set-window-configuration (car rst-toc-return-buffer))
      (kill-buffer (get-buffer rst-toc-buffer-name)))
    (pop-to-buffer (marker-buffer pos))
    (goto-char pos)
    ;; FIXME: make the recentering conditional on scroll.
    (recenter 5)))

(defun rst-toc-mode-goto-section ()
  "Go to the section the current line describes and kill the TOC buffer."
  (interactive)
  (rst-goto-section t))

(defun rst-toc-mode-mouse-goto (event)
  "In `rst-toc' mode, go to the occurrence whose line you click on.
EVENT is the input event."
  (interactive "e")
  (let (pos)
    (with-current-buffer (window-buffer (posn-window (event-end event)))
      (save-excursion
        (goto-char (posn-point (event-end event)))
        (setq pos (rst-toc-mode-find-section))))
    (pop-to-buffer (marker-buffer pos))
    (goto-char pos)
    (recenter 5)))

(defun rst-toc-mode-mouse-goto-kill (event)
  "Same as `rst-toc-mode-mouse-goto', but kill TOC buffer as well."
  (interactive "e")
  (call-interactively 'rst-toc-mode-mouse-goto event)
  (kill-buffer (get-buffer rst-toc-buffer-name)))

(defun rst-toc-quit-window ()
  "Leave the current TOC buffer."
  (interactive)
  (let ((retbuf rst-toc-return-buffer))
    (set-window-configuration (car retbuf))
    (goto-char (cadr retbuf))))

(defvar rst-toc-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] 'rst-toc-mode-mouse-goto-kill)
    (define-key map [mouse-2] 'rst-toc-mode-mouse-goto)
    (define-key map "\C-m" 'rst-toc-mode-goto-section)
    (define-key map "f" 'rst-toc-mode-goto-section)
    (define-key map "q" 'rst-toc-quit-window)
    (define-key map "z" 'kill-this-buffer)
    map)
  "Keymap for `rst-toc-mode'.")

(put 'rst-toc-mode 'mode-class 'special)

;; Could inherit from the new `special-mode'.
(define-derived-mode rst-toc-mode nil "ReST-TOC"
  "Major mode for output from \\[rst-toc], the table-of-contents for the document."
  (setq buffer-read-only t))

;; Note: use occur-mode (replace.el) as a good example to complete missing
;; features.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Section movement commands
;; =========================

(defun rst-forward-section (&optional offset)
  "Skip to the next restructured text section title.
OFFSET specifies how many titles to skip.  Use a negative OFFSET to move
backwards in the file (default is to use 1)."
  (interactive)
  (let* (;; Default value for offset.
         (offset (or offset 1))

         ;; Get all the adornments in the file, with their line numbers.
         (allados (rst-find-all-adornments))

         ;; Get the current line.
         (curline (line-number-at-pos))

         (cur allados)
         (idx 0)
         )

    ;; Find the index of the "next" adornment w.r.t. to the current line.
    (while (and cur (< (caar cur) curline))
      (setq cur (cdr cur))
      (incf idx))
    ;; 'cur' is the adornment on or following the current line.

    (if (and (> offset 0) cur (= (caar cur) curline))
        (incf idx))

    ;; Find the final index.
    (setq idx (+ idx (if (> offset 0) (- offset 1) offset)))
    (setq cur (nth idx allados))

    ;; If the index is positive, goto the line, otherwise go to the buffer
    ;; boundaries.
    (if (and cur (>= idx 0))
        (progn
          (goto-char (point-min))
          (forward-line (1- (car cur))))
      (if (> offset 0) (goto-char (point-max)) (goto-char (point-min))))
    ))

(defun rst-backward-section ()
  "Like `rst-forward-section', except move back one title."
  (interactive)
  (rst-forward-section -1))

(defun rst-mark-section (&optional arg allow-extend)
  "Select the section that point is currently in."
  ;; Cloned from mark-paragraph.
  (interactive "p\np")
  (unless arg (setq arg 1))
  (when (zerop arg)
    (error "Cannot mark zero sections"))
  (cond ((and allow-extend
	      (or (and (eq last-command this-command) (mark t))
		  (rst-portable-mark-active-p)))
	 (set-mark
	  (save-excursion
	    (goto-char (mark))
	    (rst-forward-section arg)
	    (point))))
	(t
	 (rst-forward-section arg)
	 (push-mark nil t t)
	 (rst-forward-section (- arg)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Functions to work on item lists (e.g. indent/dedent, enumerate), which are
;; always 2 or 3 characters apart horizontally with rest.

;; (FIXME: there is currently a bug that makes the region go away when we do that.)
(defvar rst-shift-fill-region nil
  "If non-nil, automatically re-fill the region that is being shifted.")

(defun rst-find-leftmost-column (beg end)
  "Find the leftmost column in the region."
  (let ((mincol 1000))
    (save-excursion
      (goto-char beg)
      (while (< (point) end)
        (back-to-indentation)
        (unless (looking-at (rst-re 'lin-end))
	  (setq mincol (min mincol (current-column))))
        (forward-line 1)
        ))
    mincol))


;; What we really need to do is compute all the possible alignment possibilities
;; and then select one.
;;
;; .. line-block::
;;
;;    a) sdjsds
;;
;;       - sdjsd jsjds
;;
;;           sdsdsjdsj
;;
;;               11. sjdss jddjs
;;
;; *  *  * * *   *   *
;;
;; Move backwards, accumulate the beginning positions, and also the second
;; positions, in case the line matches the bullet pattern, and then sort.

(defun rst-compute-bullet-tabs (&optional pt)
  "Build the list of possible horizontal alignment points.
Search backwards from point (or point PT if specified) to
build the list of possible horizontal alignment points that
includes the beginning and contents of a restructuredtext
bulleted or enumerated list item.  Return a sorted list
of (COLUMN-NUMBER . LINE) pairs."
  (save-excursion
    (when pt (goto-char pt))

    ;; We work our way backwards and towards the left.
    (let ((leftcol 100000) ;; Current column.
	  (tablist nil) ;; List of tab positions.
	  )

      ;; Start by skipping the current line.
      (forward-line -1)

      ;; Search backwards for each line.
      (while (and (> (point) (point-min))
		  (> leftcol 0))

	;; Skip empty lines.
	(unless (looking-at (rst-re 'lin-end))
	  ;; Inspect the current non-empty line
	  (back-to-indentation)

	  ;; Skip lines that are beyond the current column (we want to move
	  ;; towards the left).
	  (let ((col (current-column)))
	    (when (< col leftcol)

	      ;; Add the beginning of the line as a tabbing point.
	      (unless (memq col (mapcar 'car tablist))
		(push (cons col (point)) tablist))

	      ;; Look at the line to figure out if it is a bulleted or enumerate
	      ;; list item.
	      (when (looking-at (rst-re
				 `(:grp
				   (:alt
				    itmany-tag
				    ;; FIXME: What does this mean?
				    (:seq ,(char-after) "\\{2,\\}"))
				   hws-sta)
				 "\\S "))
		;; Add the column of the contained item.
		(let* ((matchlen (length (match-string 1)))
		       (newcol (+ col matchlen)))
		  (unless (or (>= newcol leftcol)
			      (memq (+ col matchlen) (mapcar 'car tablist)))
		    (push (cons (+ col matchlen) (+ (point) matchlen))
                          tablist)))
		)

	      (setq leftcol col)
	      )))

	(forward-line -1))

      (sort tablist (lambda (x y) (<= (car x) (car y))))
      )))

(defun rst-debug-print-tabs (tablist)
  "Insert a line and place special characters at the tab points in TABLIST."
  (beginning-of-line)
  (insert (concat "\n" (make-string 1000 ? ) "\n"))
  (beginning-of-line 0)
  (dolist (col tablist)
    (beginning-of-line)
    (forward-char (car col))
    (delete-char 1)
    (insert "@")
    ))

(defun rst-debug-mark-found (tablist)
  "Insert a line and place special characters at the tab points in TABLIST."
  (dolist (col tablist)
    (when (cdr col)
      (goto-char (cdr col))
      (insert "@"))))


(defvar rst-shift-basic-offset 2
  "Basic horizontal shift distance when there is no preceding alignment tabs.")

(defun rst-shift-region-guts (find-next-fun offset-fun)
  "(See `rst-shift-region-right' for a description)."
  (let* ((mbeg (set-marker (make-marker) (region-beginning)))
	 (mend (set-marker (make-marker) (region-end)))
	 (tabs (rst-compute-bullet-tabs mbeg))
	 (leftmostcol (rst-find-leftmost-column (region-beginning) (region-end)))
	 )
    ;; Add basic offset tabs at the end of the list.  This is a better
    ;; implementation technique than hysteresis and a basic offset because it
    ;; insures that movement in both directions is consistently using the same
    ;; column positions.  This makes it more predictable.
    (setq tabs
	  (append tabs
		  (mapcar (lambda (x) (cons x nil))
			  (let ((maxcol 120)
				(max-lisp-eval-depth 2000))
			    (flet ((addnum (x)
					   (if (> x maxcol)
					       nil
					     (cons x (addnum
						      (+ x rst-shift-basic-offset))))))
			      (addnum (or (caar (last tabs)) 0))))
			  )))

    ;; (For debugging.)
    ;;; (save-excursion (goto-char mbeg) (forward-char -1) (rst-debug-print-tabs tabs))))
    ;;; (print tabs)
    ;;; (save-excursion (rst-debug-mark-found tabs))

    ;; Apply the indent.
    (indent-rigidly
     mbeg mend

     ;; Find the next tab after the leftmost columnt.
     (let ((tab (funcall find-next-fun tabs leftmostcol)))

       (if tab
	   (progn
	     (when (cdar tab)
	       (message "Aligned on '%s'"
			(save-excursion
			  (goto-char (cdar tab))
			  (buffer-substring-no-properties
			   (line-beginning-position)
			   (line-end-position))))
	       )
	     (- (caar tab) leftmostcol)) ;; Num chars.

	 ;; Otherwise use the basic offset
	 (funcall offset-fun rst-shift-basic-offset)
	 )))

    ;; Optionally reindent.
    (when rst-shift-fill-region
      (fill-region mbeg mend))
    ))

;; FIXME Doesn't keep the region
;; FIXME Should work more like `indent-rigidly'
(defun rst-shift-region-right (pfxarg)
  "Indent region ridigly, by a few characters to the right.
This function first computes all possible alignment columns by
inspecting the lines preceding the region for bulleted or
enumerated list items.  If the leftmost column is beyond the
preceding lines, the region is moved to the right by
`rst-shift-basic-offset'.  With a prefix argument, do not
automatically fill the region."
  (interactive "P")
  (let ((rst-shift-fill-region
	 (if (not pfxarg) rst-shift-fill-region)))
    (rst-shift-region-guts (lambda (tabs leftmostcol)
			     (let ((cur tabs))
			       (while (and cur (<= (caar cur) leftmostcol))
				 (setq cur (cdr cur)))
			       cur))
			   'identity
			   )))

(defun rst-shift-region-left (pfxarg)
  "Like `rst-shift-region-right', except we move to the left.
Also, if invoked with a negative prefix arg, the entire
indentation is removed, up to the leftmost character in the
region, and automatic filling is disabled."
  (interactive "P")
  (let ((mbeg (set-marker (make-marker) (region-beginning)))
	(mend (set-marker (make-marker) (region-end)))
	(leftmostcol (rst-find-leftmost-column
		      (region-beginning) (region-end)))
	(rst-shift-fill-region
	 (if (not pfxarg) rst-shift-fill-region)))

    (when (> leftmostcol 0)
      (if (and pfxarg (< (prefix-numeric-value pfxarg) 0))
	  (progn
	    (indent-rigidly (region-beginning) (region-end) (- leftmostcol))
	    (when rst-shift-fill-region
	      (fill-region mbeg mend))
	    )
	(rst-shift-region-guts (lambda (tabs leftmostcol)
				 (let ((cur (reverse tabs)))
				   (while (and cur (>= (caar cur) leftmostcol))
				     (setq cur (cdr cur)))
				   cur))
			       '-
			       ))
      )))

(defmacro rst-iterate-leftmost-paragraphs
  (beg end first-only body-consequent body-alternative)
  "FIXME This definition is old and deprecated / we need to move
to the newer version below:

Call FUN at the beginning of each line, with an argument that
specifies whether we are at the first line of a paragraph that
starts at the leftmost column of the given region BEG and END.
Set FIRST-ONLY to true if you want to callback on the first line
of each paragraph only."
  `(save-excursion
    (let ((leftcol (rst-find-leftmost-column ,beg ,end))
	  (endm (set-marker (make-marker) ,end))
	  )

      (do* (;; Iterate lines
	    (l (progn (goto-char ,beg) (back-to-indentation))
	       (progn (forward-line 1) (back-to-indentation)))

	    (previous nil valid)

 	    (curcol (current-column)
		    (current-column))

	    (valid (and (= curcol leftcol)
			(not (looking-at (rst-re 'lin-end))))
		   (and (= curcol leftcol)
			(not (looking-at (rst-re 'lin-end)))))
	    )
	  ((>= (point) endm))

	(if (if ,first-only
		(and valid (not previous))
	      valid)
	    ,body-consequent
	  ,body-alternative)

	))))


(defmacro rst-iterate-leftmost-paragraphs-2 (spec &rest body)
  "Evaluate BODY for each line in region defined by BEG END.
LEFTMOST is set to true if the line is one of the leftmost of the
entire paragraph.  PARABEGIN is set to true if the line is the
first of a paragraph."
  (declare (indent 1) (debug (sexp body)))
  (destructuring-bind
      (beg end parabegin leftmost isleftmost isempty) spec

  `(save-excursion
     (let ((,leftmost (rst-find-leftmost-column ,beg ,end))
	   (endm (set-marker (make-marker) ,end))
	   )

      (do* (;; Iterate lines
	    (l (progn (goto-char ,beg) (back-to-indentation))
	       (progn (forward-line 1) (back-to-indentation)))

 	    (empty-line-previous nil ,isempty)

	    (,isempty (looking-at (rst-re 'lin-end))
			(looking-at (rst-re 'lin-end)))

	    (,parabegin (not ,isempty)
			(and empty-line-previous
			     (not ,isempty)))

	    (,isleftmost (and (not ,isempty)
			      (= (current-column) ,leftmost))
			 (and (not ,isempty)
			      (= (current-column) ,leftmost)))
	    )
	  ((>= (point) endm))

	(progn ,@body)

	)))))


;;------------------------------------------------------------------------------

;; FIXME: these next functions should become part of a larger effort to redo the
;; bullets in bulletted lists.  The enumerate would just be one of the possible
;; outputs.
;;
;; FIXME: TODO we need to do the enumeration removal as well.

(defun rst-enumerate-region (beg end all)
  "Add enumeration to all the leftmost paragraphs in the given region.
The region is specified between BEG and END.  With ALL,
do all lines instead of just paragraphs."
  (interactive "r\nP")
  (let ((count 0)
	(last-insert-len nil))
    (rst-iterate-leftmost-paragraphs
     beg end (not all)
     (let ((ins-string (format "%d. " (incf count))))
       (setq last-insert-len (length ins-string))
       (insert ins-string))
     (insert (make-string last-insert-len ?\ ))
     )))

(defun rst-bullet-list-region (beg end all)
  "Add bullets to all the leftmost paragraphs in the given region.
The region is specified between BEG and END.  With ALL,
do all lines instead of just paragraphs."
  (interactive "r\nP")
  (rst-iterate-leftmost-paragraphs
   beg end (not all)
   (insert (car rst-preferred-bullets) " ")
   (insert "  ")
   ))


;; FIXME: there are some problems left with the following function
;; implementation:
;;
;; * It does not deal with a varying number of digits appropriately
;; * It does not deal with multiple levels independently, and it should.
;;
;; I suppose it does 90% of the job for now.

(defun rst-convert-bullets-to-enumeration (beg end)
  "Convert all the bulleted items and enumerated items in the
region to enumerated lists, renumbering as necessary."
  (interactive "r")
  (let* (;; Find items and convert the positions to markers.
	 (items (mapcar
		 (lambda (x)
		   (cons (let ((m (make-marker)))
			   (set-marker m (car x))
			   m)
			 (cdr x)))
		 (rst-find-pfx-in-region beg end (rst-re 'itmany-sta-1))))
	 (count 1)
	 )
    (save-excursion
      (dolist (x items)
	(goto-char (car x))
	(looking-at (rst-re 'itmany-beg-1))
	(replace-match (format "%d." count) nil nil nil 1)
	(incf count)
	))
    ))



;;------------------------------------------------------------------------------

(defun rst-line-block-region (rbeg rend &optional pfxarg)
  "Toggle line block prefixes for a region.
With prefix argument set the empty lines too."
  (interactive "r\nP")
  (let ((comment-start "| ")
	(comment-end "")
	(comment-start-skip "| ")
	(comment-style 'indent)
	(force (not (not pfxarg))))
    (rst-iterate-leftmost-paragraphs-2
        (rbeg rend parbegin leftmost isleft isempty)
      (when (or force (not isempty))
        (move-to-column leftmost force)
        (delete-region (point) (+ (point) (- (current-indentation) leftmost)))
        (insert "| ")))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Font lock
;; =========

(require 'font-lock)

(defgroup rst-faces nil "Faces used in Rst Mode."
  :group 'rst
  :group 'faces
  :version "21.1")

(defcustom rst-block-face 'font-lock-keyword-face
  "All syntax marking up a special block."
  :group 'rst-faces
  :type '(face))

(defcustom rst-external-face 'font-lock-type-face
  "Field names and interpreted text."
  :group 'rst-faces
  :type '(face))

(defcustom rst-definition-face 'font-lock-function-name-face
  "All other defining constructs."
  :group 'rst-faces
  :type '(face))

(defcustom rst-directive-face
  ;; XEmacs compatibility
  (if (boundp 'font-lock-builtin-face)
      'font-lock-builtin-face
    'font-lock-preprocessor-face)
  "Directives and roles."
  :group 'rst-faces
  :type '(face))

(defcustom rst-comment-face 'font-lock-comment-face
  "Comments."
  :group 'rst-faces
  :type '(face))

(defcustom rst-emphasis1-face
  ;; XEmacs compatibility
  (if (facep 'italic)
      ''italic
    'italic)
  "Simple emphasis."
  :group 'rst-faces
  :type '(face))

(defcustom rst-emphasis2-face
  ;; XEmacs compatibility
  (if (facep 'bold)
      ''bold
    'bold)
  "Double emphasis."
  :group 'rst-faces
  :type '(face))

(defcustom rst-literal-face 'font-lock-string-face
  "Literal text."
  :group 'rst-faces
  :type '(face))

(defcustom rst-reference-face 'font-lock-variable-name-face
  "References to a definition."
  :group 'rst-faces
  :type '(face))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup rst-faces-defaults nil
  "Values used to generate default faces for section titles on all levels.
Tweak these if you are content with how section title faces are built in
general but you do not like the details."
  :group 'rst-faces
  :version "21.1")

(defun rst-set-level-default (sym val)
  "Set custom var SYM affecting section title text face and recompute the faces."
  (custom-set-default sym val)
  ;; Also defines the faces initially when all values are available
  (and (boundp 'rst-level-face-max)
       (boundp 'rst-level-face-format-light)
       (boundp 'rst-level-face-base-color)
       (boundp 'rst-level-face-step-light)
       (boundp 'rst-level-face-base-light)
       (fboundp 'rst-define-level-faces)
       (rst-define-level-faces)))

;; Faces for displaying items on several levels; these definitions define
;; different shades of grey where the lightest one (i.e. least contrasting) is
;; used for level 1
(defcustom rst-level-face-max 6
  "Maximum depth of levels for which section title faces are defined."
  :group 'rst-faces-defaults
  :type '(integer)
  :set 'rst-set-level-default)
(defcustom rst-level-face-base-color "grey"
  "The base name of the color to be used for creating background colors in
section title faces for all levels."
  :group 'rst-faces-defaults
  :type '(string)
  :set 'rst-set-level-default)
(defcustom rst-level-face-base-light
  (if (eq frame-background-mode 'dark)
      15
    85)
  "The lightness factor for the base color.  This value is used for level 1.
The default depends on whether the value of `frame-background-mode' is
`dark' or not."
  :group 'rst-faces-defaults
  :type '(integer)
  :set 'rst-set-level-default)
(defcustom rst-level-face-format-light "%2d"
  "The format for the lightness factor appended to the base name of the color.
This value is expanded by `format' with an integer."
  :group 'rst-faces-defaults
  :type '(string)
  :set 'rst-set-level-default)
(defcustom rst-level-face-step-light
  (if (eq frame-background-mode 'dark)
      7
    -7)
  "The step width to use for the next color.
The formula

    `rst-level-face-base-light'
    + (`rst-level-face-max' - 1) * `rst-level-face-step-light'

must result in a color level which appended to `rst-level-face-base-color'
using `rst-level-face-format-light' results in a valid color such as `grey50'.
This color is used as background for section title text on level
`rst-level-face-max'."
  :group 'rst-faces-defaults
  :type '(integer)
  :set 'rst-set-level-default)

(defcustom rst-adornment-faces-alist
  (let ((alist '((t . font-lock-keyword-face)
		 (nil . font-lock-keyword-face)))
	(i 1))
    (while (<= i rst-level-face-max)
      (nconc alist (list (cons i (intern (format "rst-level-%d-face" i)))))
      (setq i (1+ i)))
    alist)
  "Faces for the various adornment types.
Key is a number (for the section title text of that level),
t (for transitions) or nil (for section title adornment).
If you generally do not like how section title text faces are
set up tweak here.  If the general idea is ok for you but you do not like the
details check the Rst Faces Defaults group."
  :group 'rst-faces
  :type '(alist
	  :key-type
	  (choice
	   (integer
	    :tag
	    "Section level (may not be bigger than `rst-level-face-max')")
	   (boolean :tag "transitions (on) / section title adornment (off)"))
	  :value-type (face))
  :set-after '(rst-level-face-max))

(defun rst-define-level-faces ()
  "Define the faces for the section title text faces from the values."
  ;; All variables used here must be checked in `rst-set-level-default'
  (let ((i 1))
    (while (<= i rst-level-face-max)
      (let ((sym (intern (format "rst-level-%d-face" i)))
	    (doc (format "Face for showing section title text at level %d" i))
	    (col (format (concat "%s" rst-level-face-format-light)
			 rst-level-face-base-color
			 (+ (* (1- i) rst-level-face-step-light)
			    rst-level-face-base-light))))
	(make-empty-face sym)
	(set-face-doc-string sym doc)
	(set-face-background sym col)
	(set sym sym)
	(setq i (1+ i))))))

(rst-define-level-faces)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar rst-font-lock-keywords
  ;; The reST-links in the comments below all relate to sections in
  ;; http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html
  `(;; FIXME: Block markup is not recognized in blocks after explicit markup
    ;; start

    ;; Simple `Body Elements`_
    ;; `Bullet Lists`_
    (,(rst-re 'lin-beg '(:grp bul-sta))
     1 ,rst-block-face)
    ;; `Enumerated Lists`_
    (,(rst-re 'lin-beg '(:grp enmany-sta))
     1 ,rst-block-face)
    ;; `Definition Lists`_ FIXME: missing
    ;; `Field Lists`_
    (,(rst-re 'lin-beg '(:grp fld-tag) 'bli-sfx)
     1 ,rst-external-face)
    ;; `Option Lists`_
    (,(rst-re 'lin-beg '(:grp opt-tag (:shy optsep-tag opt-tag) "*")
	      '(:alt "$" (:seq hws-prt "\\{2\\}")))
     1 ,rst-block-face)
    ;; `Line Blocks`_
    ;; Only for lines containing no more bar - to distinguish from tables
    (,(rst-re 'lin-beg '(:grp "|" bli-sfx) "[^|\n]*$")
     1 ,rst-block-face)

    ;; `Tables`_ FIXME: missing

    ;; All the `Explicit Markup Blocks`_
    ;; `Footnotes`_ / `Citations`_
    (,(rst-re 'lin-beg '(:grp exm-sta fnc-tag) 'bli-sfx)
     1 ,rst-definition-face)
    ;; `Directives`_ / `Substitution Definitions`_
    (,(rst-re 'lin-beg '(:grp exm-sta)
	      '(:grp (:shy subdef-tag hws-sta) "?")
	      '(:grp sym-tag dcl-tag) 'bli-sfx)
     (1 ,rst-directive-face)
     (2 ,rst-definition-face)
     (3 ,rst-directive-face))
    ;; `Hyperlink Targets`_
    (,(rst-re 'lin-beg
	      '(:grp exm-sta "_" (:alt
				  (:seq "`" ilcbkqdef-tag "`")
				  (:seq (:alt "[^:\\\n]" "\\\\.") "+")) ":")
	      'bli-sfx)
     1 ,rst-definition-face)
    (,(rst-re 'lin-beg '(:grp "__") 'bli-sfx)
     1 ,rst-definition-face)

    ;; All `Inline Markup`_ - most of them may be multiline though this is
    ;; uninteresting

    ;; FIXME: Condition 5 preventing fontification of e.g. "*" not implemented
    ;; `Strong Emphasis`_
    (,(rst-re 'ilm-pfx '(:grp "\\*\\*" ilcast-tag "\\*\\*") 'ilm-sfx)
     1 ,rst-emphasis2-face)
    ;; `Emphasis`_
    (,(rst-re 'ilm-pfx '(:grp "\\*" ilcast-tag "\\*") 'ilm-sfx)
     1 ,rst-emphasis1-face)
    ;; `Inline Literals`_
    (,(rst-re 'ilm-pfx '(:grp "``" ilcbkq-tag "``") 'ilm-sfx)
     1 ,rst-literal-face)
    ;; `Inline Internal Targets`_
    (,(rst-re 'ilm-pfx '(:grp "_`" ilcbkq-tag "`") 'ilm-sfx)
     1 ,rst-definition-face)
    ;; `Hyperlink References`_
    ;; FIXME: `Embedded URIs`_ not considered
    (,(rst-re 'ilm-pfx '(:grp (:alt (:seq "`" ilcbkq-tag "`")
				    (:seq "\\sw" (:alt "\\sw" "-") "+\\sw"))
			      "__?") 'ilm-sfx)
     1 ,rst-reference-face)
    ;; `Interpreted Text`_
    (,(rst-re 'ilm-pfx '(:grp (:shy ":" sym-tag ":") "?")
	      '(:grp "`" ilcbkq-tag "`")
	      '(:grp (:shy ":" sym-tag ":") "?") 'ilm-sfx)
     (1 ,rst-directive-face)
     (2 ,rst-external-face)
     (3 ,rst-directive-face))
    ;; `Footnote References`_ / `Citation References`_
    (,(rst-re 'ilm-pfx '(:grp fnc-tag "_") 'ilm-sfx)
     1 ,rst-reference-face)
    ;; `Substitution References`_
    ;; FIXME: References substitutions like |this|_ or |this|__ are not
    ;;        fontified correctly
    (,(rst-re 'ilm-pfx '(:grp sub-tag) 'ilm-sfx)
     1 ,rst-reference-face)
    ;; `Standalone Hyperlinks`_
    ;; FIXME: This takes it easy by using a whitespace as delimiter
    (,(rst-re 'ilm-pfx '(:grp uri-tag ":\\S +") 'ilm-sfx)
     1 ,rst-definition-face)
    (,(rst-re 'ilm-pfx '(:grp sym-tag "@" sym-tag ) 'ilm-sfx)
     1 ,rst-definition-face)

    ;; Do all block fontification as late as possible so 'append works

    ;; Sections_ / Transitions_ - for sections this is multiline
    (,(rst-re 'ado-beg-2-1 'lin-end)
     (rst-font-lock-handle-adornment-match
      (rst-font-lock-handle-adornment-limit
       (match-string-no-properties 1) (match-end 1))
      nil
      (1 (cdr (assoc nil rst-adornment-faces-alist)) append t)
      (2 (cdr (assoc rst-font-lock-adornment-level
		     rst-adornment-faces-alist)) append t)
      (3 (cdr (assoc nil rst-adornment-faces-alist)) append t)))

    ;; FIXME: FACESPEC could be used instead of ordinary faces to set
    ;;        properties on comments and literal blocks so they are *not*
    ;;        inline fontified; see (elisp)Search-based Fontification

    ;; `Comments`_ - this is multiline
    (,(rst-re 'lin-beg '(:grp exm-sta) "[^\[|_\n]"
	      '(:alt "[^:\n]" (:seq ":" (:alt "[^:\n]" "$"))) "*$")
     (1 ,rst-comment-face)
     (rst-font-lock-find-unindented-line-match
      (rst-font-lock-find-unindented-line-limit (match-end 1))
      nil
      (0 ,rst-comment-face append)))
    (,(rst-re 'lin-beg '(:grp exm-tag) '(:grp hws-tag) "$")
     (1 ,rst-comment-face)
     (2 ,rst-comment-face)
     (rst-font-lock-find-unindented-line-match
      (rst-font-lock-find-unindented-line-limit 'next)
      nil
      (0 ,rst-comment-face append)))

    ;; FIXME: This is not rendered as comment::
    ;; .. .. list-table::
    ;;       :stub-columns: 1
    ;;       :header-rows: 1

    ;; `Literal Blocks`_ - this is multiline
    (,(rst-re 'lin-beg '(:shy (:alt "[^.\n]" "\\.[^.\n]") ".*") "?"
	      '(:grp dcl-tag) "$")
     (1 ,rst-block-face)
     (rst-font-lock-find-unindented-line-match
      (rst-font-lock-find-unindented-line-limit t)
      nil
      (0 ,rst-literal-face append)))

    ;; `Doctest Blocks`_
    (,(rst-re 'lin-beg '(:grp (:alt ">>>" ell-tag)) '(:grp ".+"))
     (1,rst-block-face)
     (2 ,rst-literal-face))
    )
  "Keywords to highlight in rst mode.")

(defun rst-font-lock-extend-region ()
  "Extend the region `font-lock-beg' / `font-lock-end' iff it may
be in the middle of a multiline construct and return non-nil if so."
  ;; There are many potential multiline constructs but really relevant ones are
  ;; comment lines without leading explicit markup tag and literal blocks
  ;; following "::" which are both indented. Thus indendation is what is
  ;; recognized here. The second criteria is an explicit markup tag which may
  ;; be a comment or a double colon at the end of a line.
  (if (not (get-text-property font-lock-beg 'font-lock-multiline))
      ;; Don't move if we start with a multiline construct already
      (save-excursion
	(let ((cont t))
	  (move-to-window-line 0) ;; Start at the top window line
	  (if (>= (point) font-lock-beg)
	      (goto-char font-lock-beg))
	  (forward-line 0)
	  (while cont
	    (if (looking-at (rst-re '(:alt
				      "[^ \t]"
				      (:seq hws-tag exm-tag "[^ \t]")
				      ;; FIXME: Shouldn't this allow whitespace
				      ;; after the explicit markup tag?
				      (:seq ".*" dcl-tag lin-end))))
		;; non-empty indented line, explicit markup tag or literal
		;; block tag
		(setq cont nil)
	      (if (not (= (forward-line -1) 0)) ;; try previous line
		  ;; no more previous line
		  (setq cont nil))))
	  (when (not (= (point) font-lock-beg))
	    (setq font-lock-beg (point))
	    t)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Indented blocks

(defun rst-forward-indented-block (&optional column limit)
  "Move forward across one indented block.
Find the next non-empty line which is not indented at least to COLUMN (defaults
to the column of the point).  Moves point to first character of this line or the
first empty line immediately before it and returns that position.  If there is
no such line before LIMIT (defaults to the end of the buffer) returns nil and
point is not moved."
  (interactive)
  (let ((clm (or column (current-column)))
	(start (point))
	fnd beg cand)
    (if (not limit)
	(setq limit (point-max)))
    (save-match-data
      (while (and (not fnd) (< (point) limit))
	(forward-line 1)
	(when (< (point) limit)
	  (setq beg (point))
	  (if (looking-at (rst-re 'lin-end))
	      (setq cand (or cand beg)) ; An empty line is a candidate
	    (move-to-column clm)
	    ;; FIXME: No indentation [(zerop clm)] must be handled in some
	    ;; useful way - though it is not clear what this should mean at all
	    (if (string-match
		 (rst-re 'linemp-tag)
		 (buffer-substring-no-properties beg (point)))
		(setq cand nil) ; An indented line resets a candidate
	      (setq fnd (or cand beg)))))))
    (goto-char (or fnd start))
    fnd))

;; Beginning of the match if `rst-font-lock-find-unindented-line-end'.
(defvar rst-font-lock-find-unindented-line-begin nil)

;; End of the match as determined by
;; `rst-font-lock-find-unindented-line-limit'. Also used as a trigger for
;; `rst-font-lock-find-unindented-line-match'.
(defvar rst-font-lock-find-unindented-line-end nil)

;; Finds the next unindented line relative to indenation at IND-PNT and returns
;; this point, the end of the buffer or nil if nothing found. If IND-PNT is
;; `next' takes the indentation from the next line if this is not empty and
;; indented more than the current one. If IND-PNT is non-nil but not a number
;; takes the indentation from the next non-empty line if this is indented more
;; than the current one.
(defun rst-font-lock-find-unindented-line-limit (ind-pnt)
  (setq rst-font-lock-find-unindented-line-begin ind-pnt)
  (setq rst-font-lock-find-unindented-line-end
	(save-excursion
	  (when (not (numberp ind-pnt))
	    ;; Find indentation point in next line if any
	    (setq ind-pnt
		  ;; FIXME: Should be refactored to two different functions
		  ;;        giving their result to this function, may be
		  ;;        integrated in caller
		  (save-match-data
		    (let ((cur-ind (current-indentation)))
		      (if (eq ind-pnt 'next)
			  (when (and (zerop (forward-line 1))
				     (< (point) (point-max)))
			    ;; Not at EOF
			    (setq rst-font-lock-find-unindented-line-begin
				  (point))
			    (when (and (not (looking-at (rst-re 'lin-end)))
				       (> (current-indentation) cur-ind))
			        ;; Use end of indentation if non-empty line
				(looking-at (rst-re 'hws-tag))
				(match-end 0)))
			;; Skip until non-empty line or EOF
			(while (and (zerop (forward-line 1))
				    (< (point) (point-max))
				    (looking-at (rst-re 'lin-end))))
			(when (< (point) (point-max))
			  ;; Not at EOF
			  (setq rst-font-lock-find-unindented-line-begin
				(point))
			  (when (> (current-indentation) cur-ind)
			    ;; Indentation bigger than line of departure
			    (looking-at (rst-re 'hws-tag))
			    (match-end 0))))))))
	  (when ind-pnt
	    (goto-char ind-pnt)
	    (or (rst-forward-indented-block nil (point-max))
		(point-max))))))

;; Sets the match found by `rst-font-lock-find-unindented-line-limit' the first
;; time called or nil.
(defun rst-font-lock-find-unindented-line-match (limit)
  (when rst-font-lock-find-unindented-line-end
    (set-match-data
     (list rst-font-lock-find-unindented-line-begin
	   rst-font-lock-find-unindented-line-end))
    (put-text-property rst-font-lock-find-unindented-line-begin
		       rst-font-lock-find-unindented-line-end
		       'font-lock-multiline t)
    ;; Make sure this is called only once
    (setq rst-font-lock-find-unindented-line-end nil)
    t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Adornments

;; Here `rst-font-lock-handle-adornment-match' stores the section level of the
;; current adornment or t for a transition.
(defvar rst-font-lock-adornment-level nil)

;; FIXME: It would be good if this could be used to markup section titles of
;; given level with a special key; it would be even better to be able to
;; customize this so it can be used for a generally available personal style
;;
;; FIXME: There should be some way to reset and reload this variable - probably
;; a special key
;;
;; FIXME: Some support for `outline-mode' would be nice which should be based
;; on this information
(defvar rst-adornment-level-alist nil
  "Associates adornments with section levels.
The key is a two character string.  The first character is the adornment
character.  The second character distinguishes underline section titles (`u')
from overline/underline section titles (`o').  The value is the section level.

This is made buffer local on start and adornments found during font lock are
entered.")

;; Returns section level for adornment key KEY. Adds new section level if KEY
;; is not found and ADD. If KEY is not a string it is simply returned.
(defun rst-adornment-level (key &optional add)
  (let ((fnd (assoc key rst-adornment-level-alist))
	(new 1))
    (cond
     ((not (stringp key))
      key)
     (fnd
      (cdr fnd))
     (add
      (while (rassoc new rst-adornment-level-alist)
	(setq new (1+ new)))
      (setq rst-adornment-level-alist
	    (append rst-adornment-level-alist (list (cons key new))))
      new))))

;; Classifies adornment for section titles and transitions. ADORNMENT is the
;; complete adornment string as found in the buffer. END is the point after the
;; last character of ADORNMENT. For overline section adornment LIMIT limits the
;; search for the matching underline. Returns a list. The first entry is t for
;; a transition, or a key string for `rst-adornment-level' for a section title.
;; The following eight values forming four match groups as can be used for
;; `set-match-data'. First match group contains the maximum points of the whole
;; construct. Second and last match group matched pure section title adornment
;; while third match group matched the section title text or the transition.
;; Each group but the first may or may not exist.
(defun rst-classify-adornment (adornment end limit)
  (save-excursion
    (save-match-data
      (goto-char end)
      (let ((ado-ch (aref adornment 0))
	    (ado-re (rst-re (regexp-quote adornment)))
	    (end-pnt (point))
	    (beg-pnt (progn
		       (forward-line 0)
		       (point)))
	    (nxt-emp
	     (save-excursion
	       (or (not (zerop (forward-line 1)))
		   (looking-at (rst-re 'lin-end)))))
	    (prv-emp
	     (save-excursion
	       (or (not (zerop (forward-line -1)))
		   (looking-at (rst-re 'lin-end)))))
	    key beg-ovr end-ovr beg-txt end-txt beg-und end-und)
	(cond
	 ((and nxt-emp prv-emp)
	  ;; A transition
	  (setq key t)
	  (setq beg-txt beg-pnt)
	  (setq end-txt end-pnt))
	 (prv-emp
	  ;; An overline
	  (setq key (concat (list ado-ch) "o"))
	  (setq beg-ovr beg-pnt)
	  (setq end-ovr end-pnt)
	  (forward-line 1)
	  (setq beg-txt (point))
	  (while (and (<= (point) limit) (not end-txt))
	    (if (or (= (point) limit) (looking-at (rst-re 'lin-end)))
		;; No underline found
		(setq end-txt (1- (point)))
	      (when (looking-at (rst-re (list :grp
					      ado-re)
					'lin-end))
		(setq end-und (match-end 1))
		(setq beg-und (point))
		(setq end-txt (1- beg-und))))
	    (forward-line 1)))
	 (t
	  ;; An underline
	  (setq key (concat (list ado-ch) "u"))
	  (setq beg-und beg-pnt)
	  (setq end-und end-pnt)
	  (setq end-txt (1- beg-und))
	  (setq beg-txt (progn
			  (goto-char end-txt)
			  (forward-line 0)
			  (point)))
	  (when (and (zerop (forward-line -1))
		     (looking-at (rst-re (list :grp
					       ado-re)
					 'lin-end)))
	    ;; There is a matching overline
	    (setq key (concat (list ado-ch) "o"))
	    (setq beg-ovr (point))
	    (setq end-ovr (match-end 1)))))
	(list key
	      (or beg-ovr beg-txt beg-und)
	      (or end-und end-txt end-und)
	      beg-ovr end-ovr beg-txt end-txt beg-und end-und)))))

;; Stores the result of `rst-classify-adornment'. Also used as a trigger
;; for `rst-font-lock-handle-adornment-match'.
(defvar rst-font-lock-adornment-data nil)

;; Determines limit for adornments for font-locking section titles and
;; transitions. In fact it determines all things necessary and puts the result
;; to `rst-font-lock-adornment-data'. ADO is the complete adornment matched.
;; ADO-END is the point where ADO ends. Returns the point where the whole
;; adorned construct ends.
(defun rst-font-lock-handle-adornment-limit (ado ado-end)
  (let ((ado-data (rst-classify-adornment ado ado-end (point-max))))
    (setq rst-font-lock-adornment-level (rst-adornment-level (car ado-data) t))
    (setq rst-font-lock-adornment-data (cdr ado-data))
    (goto-char (nth 1 ado-data))
    (nth 2 ado-data)))

;; Sets the match found by `rst-font-lock-handle-adornment-limit' the first
;; time called or nil.
(defun rst-font-lock-handle-adornment-match (limit)
  (let ((ado-data rst-font-lock-adornment-data))
    ;; May run only once - enforce this
    (setq rst-font-lock-adornment-data nil)
    (when ado-data
      (goto-char (nth 1 ado-data))
      (put-text-property (nth 0 ado-data) (nth 1 ado-data)
			 'font-lock-multiline t)
      (set-match-data ado-data)
      t)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Support for conversion from within Emacs

(defgroup rst-compile nil
  "Settings for support of conversion of reStructuredText
document with \\[rst-compile]."
  :group 'rst
  :version "21.1")

(defvar rst-compile-toolsets
  '((html . ("rst2html.py" ".html" nil))
    (latex . ("rst2latex.py" ".tex" nil))
    (newlatex . ("rst2newlatex.py" ".tex" nil))
    (pseudoxml . ("rst2pseudoxml.py" ".xml" nil))
    (xml . ("rst2xml.py" ".xml" nil))
    (pdf . ("rst2pdf.py" ".pdf" nil))
    (s5 . ("rst2s5.py" ".xml" nil)))
  "Table describing the command to use for each toolset.
An association list of the toolset to a list of the (command to use,
extension of produced filename, options to the tool (nil or a
string)) to be used for converting the document.")

;; Note for Python programmers not familiar with association lists: you can set
;; values in an alists like this, e.g. :
;; (setcdr (assq 'html rst-compile-toolsets)
;;      '("rst2html.py" ".htm" "--stylesheet=/docutils.css"))


(defvar rst-compile-primary-toolset 'html
  "The default toolset for `rst-compile'.")

(defvar rst-compile-secondary-toolset 'latex
  "The default toolset for `rst-compile' with a prefix argument.")

(defun rst-compile-find-conf ()
  "Look for the configuration file in the parents of the current path."
  (interactive)
  (let ((file-name "docutils.conf")
        (buffer-file (buffer-file-name)))
    ;; Move up in the dir hierarchy till we find a change log file.
    (let* ((dir (file-name-directory buffer-file))
	   (prevdir nil))
      (while (and (or (not (string= dir prevdir))
		      (setq dir nil)
		      nil)
                  (not (file-exists-p (concat dir file-name))))
        ;; Move up to the parent dir and try again.
	(setq prevdir dir)
        (setq dir (expand-file-name (file-name-directory
                                     (directory-file-name
				      (file-name-directory dir)))))
	)
      (or (and dir (concat dir file-name)) nil)
    )))


(require 'compile)

(defun rst-compile (&optional use-alt)
  "Compile command to convert reST document into some output file.
Attempts to find configuration file, if it can, overrides the
options.  There are two commands to choose from, with USE-ALT,
select the alternative toolset."
  (interactive "P")
  ;; Note: maybe we want to check if there is a Makefile too and not do anything
  ;; if that is the case.  I dunno.
  (let* ((toolset (cdr (assq (if use-alt
				 rst-compile-secondary-toolset
			       rst-compile-primary-toolset)
			rst-compile-toolsets)))
         (command (car toolset))
         (extension (cadr toolset))
         (options (caddr toolset))
         (conffile (rst-compile-find-conf))
         (bufname (file-name-nondirectory buffer-file-name))
         (outname (file-name-sans-extension bufname)))

    ;; Set compile-command before invocation of compile.
    (set (make-local-variable 'compile-command)
         (mapconcat 'identity
                    (list command
                          (or options "")
                          (if conffile
                              (concat "--config=" (shell-quote-argument conffile))
                            "")
                          (shell-quote-argument bufname)
                          (shell-quote-argument (concat outname extension)))
                    " "))

    ;; Invoke the compile command.
    (if (or compilation-read-command use-alt)
        (call-interactively 'compile)
      (compile compile-command))
    ))

(defun rst-compile-alt-toolset ()
  "Compile command with the alternative toolset."
  (interactive)
  (rst-compile t))

(defun rst-compile-pseudo-region ()
  "Show the pseudo-XML rendering of the current active region,
or of the entire buffer, if the region is not selected."
  (interactive)
  (with-output-to-temp-buffer "*pseudoxml*"
    (shell-command-on-region
     (if mark-active (region-beginning) (point-min))
     (if mark-active (region-end) (point-max))
     (cadr (assq 'pseudoxml rst-compile-toolsets))
     standard-output)))

(defvar rst-pdf-program "xpdf"
  "Program used to preview PDF files.")

(defun rst-compile-pdf-preview ()
  "Convert the document to a PDF file and launch a preview program."
  (interactive)
  (let* ((tmp-filename "/tmp/out.pdf")
	 (command (format "%s %s %s && %s %s"
			  (cadr (assq 'pdf rst-compile-toolsets))
			  buffer-file-name tmp-filename
			  rst-pdf-program tmp-filename)))
    (start-process-shell-command "rst-pdf-preview" nil command)
    ;; Note: you could also use (compile command) to view the compilation
    ;; output.
    ))

(defvar rst-slides-program "firefox"
  "Program used to preview S5 slides.")

(defun rst-compile-slides-preview ()
  "Convert the document to an S5 slide presentation and launch a preview program."
  (interactive)
  (let* ((tmp-filename "/tmp/slides.html")
	 (command (format "%s %s %s && %s %s"
			  (cadr (assq 's5 rst-compile-toolsets))
			  buffer-file-name tmp-filename
			  rst-slides-program tmp-filename)))
    (start-process-shell-command "rst-slides-preview" nil command)
    ;; Note: you could also use (compile command) to view the compilation
    ;; output.
    ))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generic text functions that are more convenient than the defaults.

(defun rst-replace-lines (fromchar tochar)
  "Replace flush-left lines, consisting of multiple FROMCHAR characters,
with equal-length lines of TOCHAR."
  (interactive "\
cSearch for flush-left lines of char:
cand replace with char: ")
  (save-excursion
    (let ((searchre (rst-re "^" fromchar "+\\( *\\)$"))
          (found 0))
      (while (search-forward-regexp searchre nil t)
        (setq found (1+ found))
        (goto-char (match-beginning 1))
        (let ((width (current-column)))
          (rst-delete-entire-line)
          (insert-char tochar width)))
      (message (format "%d lines replaced." found)))))

(defun rst-join-paragraph ()
  "Join lines in current paragraph into one line, removing end-of-lines."
  (interactive)
  (let ((fill-column 65000)) ; some big number
    (call-interactively 'fill-paragraph)))

(defun rst-force-fill-paragraph ()
  "Fill paragraph at point, first joining the paragraph's lines into one.
This is useful for filling list item paragraphs."
  (interactive)
  (rst-join-paragraph)
  (fill-paragraph nil))


;; Generic character repeater function.
;; For sections, better to use the specialized function above, but this can
;; be useful for creating separators.
(defun rst-repeat-last-character (use-next)
  "Fill the current line up to the length of the preceding line (if not
empty), using the last character on the current line.  If the preceding line is
empty, we use the `fill-column'.

If USE-NEXT, use the next line rather than the preceding line.

If the current line is longer than the desired length, shave the characters off
the current line to fit the desired length.

As an added convenience, if the command is repeated immediately, the alternative
column is used (fill-column vs. end of previous/next line)."
  (interactive "P")
  (let* ((curcol (current-column))
         (curline (+ (count-lines (point-min) (point))
                     (if (eq curcol 0) 1 0)))
         (lbp (line-beginning-position 0))
         (prevcol (if (and (= curline 1) (not use-next))
                      fill-column
                    (save-excursion
                      (forward-line (if use-next 1 -1))
                      (end-of-line)
                      (skip-chars-backward " \t" lbp)
                      (let ((cc (current-column)))
                        (if (= cc 0) fill-column cc)))))
         (rightmost-column
          (cond ((equal last-command 'rst-repeat-last-character)
                 (if (= curcol fill-column) prevcol fill-column))
                (t (save-excursion
                     (if (= prevcol 0) fill-column prevcol)))
                )) )
    (end-of-line)
    (if (> (current-column) rightmost-column)
        ;; shave characters off the end
        (delete-region (- (point)
                          (- (current-column) rightmost-column))
                       (point))
      ;; fill with last characters
      (insert-char (preceding-char)
                   (- rightmost-column (current-column))))
    ))


(defun rst-portable-mark-active-p ()
  "A portable function that returns non-nil if the mark is active."
  (cond
   ((fboundp 'region-active-p) (region-active-p))
   ((boundp 'transient-mark-mode) transient-mark-mode mark-active)))



(provide 'rst)
;;; rst.el ends here
