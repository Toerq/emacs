;;; dash.el --- A modern list library for Emacs

;; Copyright (C) 2012 Magnar Sveen

;; Author: Magnar Sveen <magnars@gmail.com>
;; Version: 20131030.2119
;; X-Original-Version: 2.3.0
;; Keywords: lists

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A modern list api for Emacs.
;;
;; See documentation on https://github.com/magnars/dash.el#functions

;;; Code:

(defmacro !cons (car cdr)
  "Destructive: Sets CDR to the cons of CAR and CDR."
  `(setq ,cdr (cons ,car ,cdr)))

(defmacro !cdr (list)
  "Destructive: Sets LIST to the cdr of LIST."
  `(setq ,list (cdr ,list)))

(defmacro --each (list &rest body)
  "Anaphoric form of `-each'."
  (declare (debug t))
  (let ((l (make-symbol "list")))
    `(let ((,l ,list)
           (it-index 0))
       (while ,l
         (let ((it (car ,l)))
           ,@body)
         (setq it-index (1+ it-index))
         (!cdr ,l)))))

(put '--each 'lisp-indent-function 1)

(defun -each (list fn)
  "Calls FN with every item in LIST. Returns nil, used for side-effects only."
  (--each list (funcall fn it)))

(defmacro --each-while (list pred &rest body)
  "Anaphoric form of `-each-while'."
  (let ((l (make-symbol "list"))
        (c (make-symbol "continue")))
    `(let ((,l ,list)
           (,c t))
       (while (and ,l ,c)
         (let ((it (car ,l)))
           (if (not ,pred) (setq ,c nil) ,@body))
         (!cdr ,l)))))

(put '--each-while 'lisp-indent-function 2)

(defun -each-while (list pred fn)
  "Calls FN with every item in LIST while (PRED item) is non-nil.
Returns nil, used for side-effects only."
  (--each-while list (funcall pred it) (funcall fn it)))

(defmacro --dotimes (num &rest body)
  "Repeatedly executes BODY (presumably for side-effects) with `it` bound to integers from 0 through n-1."
  `(let ((it 0))
     (while (< it ,num)
       ,@body
       (setq it (1+ it)))))

(put '--dotimes 'lisp-indent-function 1)

(defun -dotimes (num fn)
  "Repeatedly calls FN (presumably for side-effects) passing in integers from 0 through n-1."
  (--dotimes num (funcall fn it)))

(defun -map (fn list)
  "Returns a new list consisting of the result of applying FN to the items in LIST."
  (mapcar fn list))

(defmacro --map (form list)
  "Anaphoric form of `-map'."
  (declare (debug t))
  `(mapcar (lambda (it) ,form) ,list))

(defmacro --reduce-from (form initial-value list)
  "Anaphoric form of `-reduce-from'."
  `(let ((acc ,initial-value))
     (--each ,list (setq acc ,form))
     acc))

(defun -reduce-from (fn initial-value list)
  "Returns the result of applying FN to INITIAL-VALUE and the
first item in LIST, then applying FN to that result and the 2nd
item, etc. If LIST contains no items, returns INITIAL-VALUE and
FN is not called.

In the anaphoric form `--reduce-from', the accumulated value is
exposed as `acc`."
  (--reduce-from (funcall fn acc it) initial-value list))

(defmacro --reduce (form list)
  "Anaphoric form of `-reduce'."
  (let ((lv (make-symbol "list-value")))
    `(let ((,lv ,list))
       (if ,lv
           (--reduce-from ,form (car ,lv) (cdr ,lv))
         (let (acc it) ,form)))))

(defun -reduce (fn list)
  "Returns the result of applying FN to the first 2 items in LIST,
then applying FN to that result and the 3rd item, etc. If LIST
contains no items, FN must accept no arguments as well, and
reduce returns the result of calling FN with no arguments. If
LIST has only 1 item, it is returned and FN is not called.

In the anaphoric form `--reduce', the accumulated value is
exposed as `acc`."
  (if list
      (-reduce-from fn (car list) (cdr list))
    (funcall fn)))

(defun -reduce-r-from (fn initial-value list)
  "Replace conses with FN, nil with INITIAL-VALUE and evaluate
the resulting expression. If LIST is empty, INITIAL-VALUE is
returned and FN is not called.

Note: this function works the same as `-reduce-from' but the
operation associates from right instead of from left."
  (if (not list) initial-value
    (funcall fn (car list) (-reduce-r-from fn initial-value (cdr list)))))

(defmacro --reduce-r-from (form initial-value list)
  "Anaphoric version of `-reduce-r-from'."
  `(-reduce-r-from (lambda (&optional it acc) ,form) ,initial-value ,list))

(defun -reduce-r (fn list)
  "Replace conses with FN and evaluate the resulting expression.
The final nil is ignored. If LIST contains no items, FN must
accept no arguments as well, and reduce returns the result of
calling FN with no arguments. If LIST has only 1 item, it is
returned and FN is not called.

The first argument of FN is the new item, the second is the
accumulated value.

Note: this function works the same as `-reduce' but the operation
associates from right instead of from left."
  (cond
   ((not list) (funcall fn))
   ((not (cdr list)) (car list))
   (t (funcall fn (car list) (-reduce-r fn (cdr list))))))

(defmacro --reduce-r (form list)
  "Anaphoric version of `-reduce-r'."
  `(-reduce-r (lambda (&optional it acc) ,form) ,list))

(defmacro --filter (form list)
  "Anaphoric form of `-filter'."
  (let ((r (make-symbol "result")))
    `(let (,r)
       (--each ,list (when ,form (!cons it ,r)))
       (nreverse ,r))))

(defun -filter (pred list)
  "Returns a new list of the items in LIST for which PRED returns a non-nil value.

Alias: `-select'"
  (--filter (funcall pred it) list))

(defalias '-select '-filter)
(defalias '--select '--filter)

(defmacro --remove (form list)
  "Anaphoric form of `-remove'."
  (declare (debug t))
  `(--filter (not ,form) ,list))

(defun -remove (pred list)
  "Returns a new list of the items in LIST for which PRED returns nil.

Alias: `-reject'"
  (--remove (funcall pred it) list))

(defalias '-reject '-remove)
(defalias '--reject '--remove)

(defmacro --keep (form list)
  "Anaphoric form of `-keep'."
  (let ((r (make-symbol "result"))
        (m (make-symbol "mapped")))
    `(let (,r)
       (--each ,list (let ((,m ,form)) (when ,m (!cons ,m ,r))))
       (nreverse ,r))))

(defun -keep (fn list)
  "Returns a new list of the non-nil results of applying FN to the items in LIST."
  (--keep (funcall fn it) list))

(defmacro --map-when (pred rep list)
  "Anaphoric form of `-map-when'."
  (let ((r (make-symbol "result")))
    `(let (,r)
       (--each ,list (!cons (if ,pred ,rep it) ,r))
       (nreverse ,r))))

(defmacro --map-indexed (form list)
  "Anaphoric form of `-map-indexed'."
  (let ((r (make-symbol "result")))
    `(let (,r)
       (--each ,list
         (!cons ,form ,r))
       (nreverse ,r))))

(defun -map-indexed (fn list)
  "Returns a new list consisting of the result of (FN index item) for each item in LIST.

In the anaphoric form `--map-indexed', the index is exposed as `it-index`."
  (--map-indexed (funcall fn it-index it) list))

(defun -map-when (pred rep list)
  "Returns a new list where the elements in LIST that does not match the PRED function
are unchanged, and where the elements in LIST that do match the PRED function are mapped
through the REP function."
  (--map-when (funcall pred it) (funcall rep it) list))

(defalias '--replace-where '--map-when)
(defalias '-replace-where '-map-when)

(defun -flatten (l)
  "Takes a nested list L and returns its contents as a single, flat list."
  (if (and (listp l) (listp (cdr l)))
      (-mapcat '-flatten l)
    (list l)))

(defun -concat (&rest lists)
  "Returns a new list with the concatenation of the elements in the supplied LISTS."
  (apply 'append lists))

(defmacro --mapcat (form list)
  "Anaphoric form of `-mapcat'."
  (declare (debug t))
  `(apply 'append (--map ,form ,list)))

(defun -mapcat (fn list)
  "Returns the concatenation of the result of mapping FN over LIST.
Thus function FN should return a list."
  (--mapcat (funcall fn it) list))

(defun -cons* (&rest args)
  "Makes a new list from the elements of ARGS.

The last 2 members of ARGS are used as the final cons of the
result so if the final member of ARGS is not a list the result is
a dotted list."
  (let (res)
    (--each
        args
      (cond
       ((not res)
        (setq res it))
       ((consp res)
        (setcdr res (cons (cdr res) it)))
       (t
        (setq res (cons res it)))))
    res))

(defmacro --first (form list)
  "Anaphoric form of `-first'."
  (let ((n (make-symbol "needle")))
    `(let (,n)
       (--each-while ,list (not ,n)
         (when ,form (setq ,n it)))
       ,n)))

(defun -first (pred list)
  "Returns the first x in LIST where (PRED x) is non-nil, else nil.

To get the first item in the list no questions asked, use `car'."
  (--first (funcall pred it) list))

(defmacro --last (form list)
  "Anaphoric form of `-last'."
  (let ((n (make-symbol "needle")))
    `(let (,n)
       (--each ,list
         (when ,form (setq ,n it)))
       ,n)))

(defun -last (pred list)
  "Return the last x in LIST where (PRED x) is non-nil, else nil."
  (--last (funcall pred it) list))

(defalias '-first-item 'car
  "Returns the first item of LIST, or nil on an empty list.")

(defun -last-item (list)
  "Returns the first item of LIST, or nil on an empty list."
  (car (last list)))

(defmacro --count (pred list)
  "Anaphoric form of `-count'."
  (let ((r (make-symbol "result")))
    `(let ((,r 0))
       (--each ,list (when ,pred (setq ,r (1+ ,r))))
       ,r)))

(defun -count (pred list)
  "Counts the number of items in LIST where (PRED item) is non-nil."
  (--count (funcall pred it) list))

(defun ---truthy? (val)
  (not (null val)))

(defmacro --any? (form list)
  "Anaphoric form of `-any?'."
  `(---truthy? (--first ,form ,list)))

(defun -any? (pred list)
  "Returns t if (PRED x) is non-nil for any x in LIST, else nil.

Alias: `-some?'"
  (--any? (funcall pred it) list))

(defalias '-some? '-any?)
(defalias '--some? '--any?)

(defalias '-any-p '-any?)
(defalias '--any-p '--any?)
(defalias '-some-p '-any?)
(defalias '--some-p '--any?)

(defmacro --all? (form list)
  "Anaphoric form of `-all?'."
  (let ((a (make-symbol "all")))
    `(let ((,a t))
       (--each-while ,list ,a (setq ,a ,form))
       (---truthy? ,a))))

(defun -all? (pred list)
  "Returns t if (PRED x) is non-nil for all x in LIST, else nil.

Alias: `-every?'"
  (--all? (funcall pred it) list))

(defalias '-every? '-all?)
(defalias '--every? '--all?)

(defalias '-all-p '-all?)
(defalias '--all-p '--all?)
(defalias '-every-p '-all?)
(defalias '--every-p '--all?)

(defmacro --none? (form list)
  "Anaphoric form of `-none?'."
  `(--all? (not ,form) ,list))

(defun -none? (pred list)
  "Returns t if (PRED x) is nil for all x in LIST, else nil."
  (--none? (funcall pred it) list))

(defalias '-none-p '-none?)
(defalias '--none-p '--none?)

(defmacro --only-some? (form list)
  "Anaphoric form of `-only-some?'."
  (let ((y (make-symbol "yes"))
        (n (make-symbol "no")))
    `(let (,y ,n)
       (--each-while ,list (not (and ,y ,n))
         (if ,form (setq ,y t) (setq ,n t)))
       (---truthy? (and ,y ,n)))))

(defun -only-some? (pred list)
  "Returns `t` if there is a mix of items in LIST that matches and does not match PRED.
Returns `nil` both if all items match the predicate, and if none of the items match the predicate."
  (--only-some? (funcall pred it) list))

(defalias '-only-some-p '-only-some?)
(defalias '--only-some-p '--only-some?)

(defun -slice (list from &optional to)
  "Return copy of LIST, starting from index FROM to index TO.
FROM or TO may be negative."
  (let ((length (length list))
        (new-list nil)
        (index 0))
    ;; to defaults to the end of the list
    (setq to (or to length))
    ;; handle negative indices
    (when (< from 0)
      (setq from (mod from length)))
    (when (< to 0)
      (setq to (mod to length)))

    ;; iterate through the list, keeping the elements we want
    (while (< index to)
      (when (>= index from)
        (!cons (car list) new-list))
      (!cdr list)
      (setq index (1+ index)))
    (nreverse new-list)))

(defun -take (n list)
  "Returns a new list of the first N items in LIST, or all items if there are fewer than N."
  (let (result)
    (--dotimes n
      (when list
        (!cons (car list) result)
        (!cdr list)))
    (nreverse result)))

(defun -drop (n list)
  "Returns the tail of LIST without the first N items."
  (--dotimes n (!cdr list))
  list)

(defmacro --take-while (form list)
  "Anaphoric form of `-take-while'."
  (let ((r (make-symbol "result")))
    `(let (,r)
       (--each-while ,list ,form (!cons it ,r))
       (nreverse ,r))))

(defun -take-while (pred list)
  "Returns a new list of successive items from LIST while (PRED item) returns a non-nil value."
  (--take-while (funcall pred it) list))

(defmacro --drop-while (form list)
  "Anaphoric form of `-drop-while'."
  (let ((l (make-symbol "list")))
    `(let ((,l ,list))
       (while (and ,l (let ((it (car ,l))) ,form))
         (!cdr ,l))
       ,l)))

(defun -drop-while (pred list)
  "Returns the tail of LIST starting from the first item for which (PRED item) returns nil."
  (--drop-while (funcall pred it) list))

(defun -split-at (n list)
  "Returns a list of ((-take N LIST) (-drop N LIST)), in no more than one pass through the list."
  (let (result)
    (--dotimes n
      (when list
        (!cons (car list) result)
        (!cdr list)))
    (list (nreverse result) list)))

(defun -rotate (n list)
  "Rotate LIST N places to the right.  With N negative, rotate to the left.
The time complexity is O(n)."
  (if (> n 0)
      (append (last list n) (butlast list n))
    (append (-drop (- n) list) (-take (- n) list))))

(defun -insert-at (n x list)
  "Returns a list with X inserted into LIST at position N."
  (let ((split-list (-split-at n list)))
    (nconc (car split-list) (cons x (cadr split-list)))))

(defmacro --split-with (pred list)
  "Anaphoric form of `-split-with'."
  (let ((l (make-symbol "list"))
        (r (make-symbol "result"))
        (c (make-symbol "continue")))
    `(let ((,l ,list)
           (,r nil)
           (,c t))
       (while (and ,l ,c)
         (let ((it (car ,l)))
           (if (not ,pred)
               (setq ,c nil)
             (!cons it ,r)
             (!cdr ,l))))
       (list (nreverse ,r) ,l))))

(defun -split-with (pred list)
  "Returns a list of ((-take-while PRED LIST) (-drop-while PRED LIST)), in no more than one pass through the list."
  (--split-with (funcall pred it) list))

(defmacro --separate (form list)
  "Anaphoric form of `-separate'."
  (let ((y (make-symbol "yes"))
        (n (make-symbol "no")))
    `(let (,y ,n)
       (--each ,list (if ,form (!cons it ,y) (!cons it ,n)))
       (list (nreverse ,y) (nreverse ,n)))))

(defun -separate (pred list)
  "Returns a list of ((-filter PRED LIST) (-remove PRED LIST)), in one pass through the list."
  (--separate (funcall pred it) list))

(defun ---partition-all-in-steps-reversed (n step list)
  "Private: Used by -partition-all-in-steps and -partition-in-steps."
  (when (< step 1)
    (error "Step must be a positive number, or you're looking at some juicy infinite loops."))
  (let ((result nil)
        (len 0))
    (while list
      (!cons (-take n list) result)
      (setq list (-drop step list)))
    result))

(defun -partition-all-in-steps (n step list)
  "Returns a new list with the items in LIST grouped into N-sized sublists at offsets STEP apart.
The last groups may contain less than N items."
  (nreverse (---partition-all-in-steps-reversed n step list)))

(defun -partition-in-steps (n step list)
  "Returns a new list with the items in LIST grouped into N-sized sublists at offsets STEP apart.
If there are not enough items to make the last group N-sized,
those items are discarded."
  (let ((result (---partition-all-in-steps-reversed n step list)))
    (while (and result (< (length (car result)) n))
      (!cdr result))
    (nreverse result)))

(defun -partition-all (n list)
  "Returns a new list with the items in LIST grouped into N-sized sublists.
The last group may contain less than N items."
  (-partition-all-in-steps n n list))

(defun -partition (n list)
  "Returns a new list with the items in LIST grouped into N-sized sublists.
If there are not enough items to make the last group N-sized,
those items are discarded."
  (-partition-in-steps n n list))

(defmacro --partition-by (form list)
  "Anaphoric form of `-partition-by'."
  (let ((r (make-symbol "result"))
        (s (make-symbol "sublist"))
        (v (make-symbol "value"))
        (n (make-symbol "new-value"))
        (l (make-symbol "list")))
    `(let ((,l ,list))
       (when ,l
         (let* ((,r nil)
                (it (car ,l))
                (,s (list it))
                (,v ,form)
                (,l (cdr ,l)))
           (while ,l
             (let* ((it (car ,l))
                    (,n ,form))
               (unless (equal ,v ,n)
                 (!cons (nreverse ,s) ,r)
                 (setq ,s nil)
                 (setq ,v ,n))
               (!cons it ,s)
               (!cdr ,l)))
           (!cons (nreverse ,s) ,r)
           (nreverse ,r))))))

(defun -partition-by (fn list)
  "Applies FN to each item in LIST, splitting it each time FN returns a new value."
  (--partition-by (funcall fn it) list))

(defmacro --partition-by-header (form list)
  "Anaphoric form of `-partition-by-header'."
  (let ((r (make-symbol "result"))
        (s (make-symbol "sublist"))
        (h (make-symbol "header-value"))
        (b (make-symbol "seen-body?"))
        (n (make-symbol "new-value"))
        (l (make-symbol "list")))
    `(let ((,l ,list))
       (when ,l
         (let* ((,r nil)
                (it (car ,l))
                (,s (list it))
                (,h ,form)
                (,b nil)
                (,l (cdr ,l)))
           (while ,l
             (let* ((it (car ,l))
                    (,n ,form))
               (if (equal ,h ,n)
                   (when ,b
                     (!cons (nreverse ,s) ,r)
                     (setq ,s nil)
                     (setq ,b nil))
                 (setq ,b t))
               (!cons it ,s)
               (!cdr ,l)))
           (!cons (nreverse ,s) ,r)
           (nreverse ,r))))))

(defun -partition-by-header (fn list)
  "Applies FN to the first item in LIST. That is the header
  value. Applies FN to each item in LIST, splitting it each time
  FN returns the header value, but only after seeing at least one
  other value (the body)."
  (--partition-by-header (funcall fn it) list))

(defmacro --group-by (form list)
  "Anaphoric form of `-group-by'."
  (let ((l (make-symbol "list"))
        (v (make-symbol "value"))
        (k (make-symbol "key"))
        (r (make-symbol "result")))
    `(let ((,l ,list)
           ,r)
       ;; Convert `list' to an alist and store it in `r'.
       (while ,l
         (let* ((,v (car ,l))
                (it ,v)
                (,k ,form)
                (kv (assoc ,k ,r)))
           (if kv
               (setcdr kv (cons ,v (cdr kv)))
             (push (list ,k ,v) ,r))
           (setq ,l (cdr ,l))))
       ;; Reverse lists in each group.
       (let ((rest ,r))
         (while rest
           (let ((kv (car rest)))
             (setcdr kv (nreverse (cdr kv))))
           (setq rest (cdr rest))))
       ;; Reverse order of keys.
       (nreverse ,r))))

(defun -group-by (fn list)
  "Separate LIST into an alist whose keys are FN applied to the
elements of LIST.  Keys are compared by `equal'."
  (--group-by (funcall fn it) list))

(defun -interpose (sep list)
  "Returns a new list of all elements in LIST separated by SEP."
  (let (result)
    (when list
      (!cons (car list) result)
      (!cdr list))
    (while list
      (setq result (cons (car list) (cons sep result)))
      (!cdr list))
    (nreverse result)))

(defun -interleave (&rest lists)
  "Returns a new list of the first item in each list, then the second etc."
  (let (result)
    (while (-none? 'null lists)
      (--each lists (!cons (car it) result))
      (setq lists (-map 'cdr lists)))
    (nreverse result)))

(defmacro --zip-with (form list1 list2)
  "Anaphoric form of `-zip-with'.

The elements in list1 is bound as `it`, the elements in list2 as `other`."
  (let ((r (make-symbol "result"))
        (l1 (make-symbol "list1"))
        (l2 (make-symbol "list2")))
    `(let ((,r nil)
           (,l1 ,list1)
           (,l2 ,list2))
       (while (and ,l1 ,l2)
         (let ((it (car ,l1))
               (other (car ,l2)))
           (!cons ,form ,r)
           (!cdr ,l1)
           (!cdr ,l2)))
       (nreverse ,r))))

(defun -zip-with (fn list1 list2)
  "Zip the two lists LIST1 and LIST2 using a function FN.  This
function is applied pairwise taking as first argument element of
LIST1 and as second argument element of LIST2 at corresponding
position.

The anaphoric form `--zip-with' binds the elements from LIST1 as `it`,
and the elements from LIST2 as `other`."
  (--zip-with (funcall fn it other) list1 list2))

(defun -zip (list1 list2)
  "Zip the two lists together.  Return the list where elements
are cons pairs with car being element from LIST1 and cdr being
element from LIST2.  The length of the returned list is the
length of the shorter one."
  (-zip-with 'cons list1 list2))

(defun -partial (fn &rest args)
  "Takes a function FN and fewer than the normal arguments to FN,
and returns a fn that takes a variable number of additional ARGS.
When called, the returned function calls FN with ARGS first and
then additional args."
  (apply 'apply-partially fn args))

(defun -elem-index (elem list)
  "Return the index of the first element in the given LIST which
is equal to the query element ELEM, or nil if there is no
such element."
  (car (-elem-indices elem list)))

(defun -elem-indices (elem list)
  "Return the indices of all elements in LIST equal to the query
element ELEM, in ascending order."
  (-find-indices (-partial 'equal elem) list))

(defun -find-indices (pred list)
  "Return the indices of all elements in LIST satisfying the
predicate PRED, in ascending order."
  (let ((i 0))
    (apply 'append (--map-indexed (when (funcall pred it) (list it-index)) list))))

(defmacro --find-indices (form list)
  "Anaphoric version of `-find-indices'."
  `(-find-indices (lambda (it) ,form) ,list))

(defun -find-index (pred list)
  "Take a predicate PRED and a LIST and return the index of the
first element in the list satisfying the predicate, or nil if
there is no such element."
  (car (-find-indices pred list)))

(defmacro --find-index (form list)
  "Anaphoric version of `-find-index'."
  `(-find-index (lambda (it) ,form) ,list))

(defun -select-by-indices (indices list)
  "Return a list whose elements are elements from LIST selected
as `(nth i list)` for all i from INDICES."
  (let (r)
    (--each indices
      (!cons (nth it list) r))
    (nreverse r)))

(defun -grade-up (comparator list)
  "Grades elements of LIST using COMPARATOR relation, yielding a
permutation vector such that applying this permutation to LIST
sorts it in ascending order."
  ;; ugly hack to "fix" lack of lexical scope
  (let ((comp `(lambda (it other) (funcall ',comparator (car it) (car other)))))
    (->> (--map-indexed (cons it it-index) list)
      (-sort comp)
      (-map 'cdr))))

(defun -grade-down (comparator list)
  "Grades elements of LIST using COMPARATOR relation, yielding a
permutation vector such that applying this permutation to LIST
sorts it in descending order."
  ;; ugly hack to "fix" lack of lexical scope
  (let ((comp `(lambda (it other) (funcall ',comparator (car other) (car it)))))
    (->> (--map-indexed (cons it it-index) list)
      (-sort comp)
      (-map 'cdr))))

(defmacro -> (x &optional form &rest more)
  "Threads the expr through the forms. Inserts X as the second
item in the first form, making a list of it if it is not a list
already. If there are more forms, inserts the first form as the
second item in second form, etc."
  (cond
   ((null form) x)
   ((null more) (if (listp form)
                    `(,(car form) ,x ,@(cdr form))
                  (list form x)))
   (:else `(-> (-> ,x ,form) ,@more))))

(defmacro ->> (x form &rest more)
  "Threads the expr through the forms. Inserts X as the last item
in the first form, making a list of it if it is not a list
already. If there are more forms, inserts the first form as the
last item in second form, etc."
  (if (null more)
      (if (listp form)
          `(,(car form) ,@(cdr form) ,x)
        (list form x))
    `(->> (->> ,x ,form) ,@more)))

(defmacro --> (x form &rest more)
  "Threads the expr through the forms. Inserts X at the position
signified by the token `it' in the first form. If there are more
forms, inserts the first form at the position signified by `it'
in in second form, etc."
  (if (null more)
      (if (listp form)
          (--map-when (eq it 'it) x form)
        (list form x))
    `(--> (--> ,x ,form) ,@more)))

(put '-> 'lisp-indent-function 1)
(put '->> 'lisp-indent-function 1)
(put '--> 'lisp-indent-function 1)

(defmacro -when-let (var-val &rest body)
  "If VAL evaluates to non-nil, bind it to VAR and execute body.
VAR-VAL should be a (VAR VAL) pair."
  (declare (debug ((symbolp form) body)))
  (let ((var (car var-val))
        (val (cadr var-val)))
    `(let ((,var ,val))
       (when ,var
         ,@body))))

(defmacro -when-let* (vars-vals &rest body)
  "If all VALS evaluate to true, bind them to their corresponding
  VARS and execute body. VARS-VALS should be a list of (VAR VAL)
  pairs (corresponding to bindings of `let*')."
  (declare (debug ((&rest (symbolp form)) body)))
  (if (= (length vars-vals) 1)
      `(-when-let ,(car vars-vals)
         ,@body)
    `(-when-let ,(car vars-vals)
       (-when-let* ,(cdr vars-vals)
         ,@body))))

(defmacro --when-let (val &rest body)
  "If VAL evaluates to non-nil, bind it to `it' and execute
body."
  (declare (debug (form body)))
  `(let ((it ,val))
     (when it
       ,@body)))

(defmacro -if-let (var-val then &rest else)
  "If VAL evaluates to non-nil, bind it to VAR and do THEN,
otherwise do ELSE. VAR-VAL should be a (VAR VAL) pair."
  (declare (debug ((symbolp form) form body)))
  (let ((var (car var-val))
        (val (cadr var-val)))
    `(let ((,var ,val))
       (if ,var ,then ,@else))))

(defmacro -if-let* (vars-vals then &rest else)
  "If all VALS evaluate to true, bind them to their corresponding
  VARS and do THEN, otherwise do ELSE. VARS-VALS should be a list
  of (VAR VAL) pairs (corresponding to the bindings of `let*')."
  (declare (debug ((&rest (symbolp form)) form body)))
  (let ((first-pair (car vars-vals))
        (rest (cdr vars-vals)))
    (if (= (length vars-vals) 1)
        `(-if-let ,first-pair ,then ,@else)
      `(-if-let ,first-pair
         (-if-let* ,rest ,then ,@else)
         ,@else))))

(defmacro --if-let (val then &rest else)
  "If VAL evaluates to non-nil, bind it to `it' and do THEN,
otherwise do ELSE."
  (declare (debug (form form body)))
  `(let ((it ,val))
     (if it ,then ,@else)))

(put '-when-let 'lisp-indent-function 1)
(put '-when-let* 'lisp-indent-function 1)
(put '--when-let 'lisp-indent-function 1)
(put '-if-let 'lisp-indent-function 2)
(put '-if-let* 'lisp-indent-function 2)
(put '--if-let 'lisp-indent-function 2)

(defun -distinct (list)
  "Return a new list with all duplicates removed.
The test for equality is done with `equal',
or with `-compare-fn' if that's non-nil.

Alias: `-uniq'"
  (let (result)
    (--each list (unless (-contains? result it) (!cons it result)))
    (nreverse result)))

(defun -union (list list2)
  "Return a new list containing the elements of LIST1 and elements of LIST2 that are not in LIST1.
The test for equality is done with `equal',
or with `-compare-fn' if that's non-nil."
  (let (result)
    (--each list (!cons it result))
    (--each list2 (unless (-contains? result it) (!cons it result)))
    (nreverse result)))

(defalias '-uniq '-distinct)

(defun -intersection (list list2)
  "Return a new list containing only the elements that are members of both LIST and LIST2.
The test for equality is done with `equal',
or with `-compare-fn' if that's non-nil."
  (--filter (-contains? list2 it) list))

(defun -difference (list list2)
  "Return a new list with only the members of LIST that are not in LIST2.
The test for equality is done with `equal',
or with `-compare-fn' if that's non-nil."
  (--filter (not (-contains? list2 it)) list))

(defvar -compare-fn nil
  "Tests for equality use this function or `equal' if this is nil.
It should only be set using dynamic scope with a let, like:
(let ((-compare-fn =)) (-union numbers1 numbers2 numbers3)")

(defun -contains? (list element)
  "Return whether LIST contains ELEMENT.
The test for equality is done with `equal',
or with `-compare-fn' if that's non-nil."
  (not
   (null
    (cond
     ((null -compare-fn)    (member element list))
     ((eq -compare-fn 'eq)  (memq element list))
     ((eq -compare-fn 'eql) (memql element list))
     (t
      (let ((lst list))
        (while (and lst
                    (not (funcall -compare-fn element (car lst))))
          (setq lst (cdr lst)))
        lst))))))

(defalias '-contains-p '-contains?)

(defun -sort (comparator list)
  "Sort LIST, stably, comparing elements using COMPARATOR.
Returns the sorted list.  LIST is NOT modified by side effects.
COMPARATOR is called with two elements of LIST, and should return non-nil
if the first element should sort before the second."
  (sort (copy-sequence list) comparator))

(defmacro --sort (form list)
  "Anaphoric form of `-sort'."
  (declare (debug t))
  `(-sort (lambda (it other) ,form) ,list))

(defun -repeat (n x)
  "Return a list with X repeated N times.
Returns nil if N is less than 1."
  (let (ret)
    (--dotimes n (!cons x ret))
    ret))

(defun -sum (list)
  "Return the sum of LIST."
  (apply '+ list))

(defun -product (list)
  "Return the product of LIST."
  (apply '* list))

(defun -max (list)
  "Return the largest value from LIST of numbers or markers."
  (apply 'max list))

(defun -min (list)
  "Return the smallest value from LIST of numbers or markers."
  (apply 'min list))

(defun -max-by (comparator list)
  "Take a comparison function COMPARATOR and a LIST and return
the greatest element of the list by the comparison function.

See also combinator `-on' which can transform the values before
comparing them."
  (--reduce (if (funcall comparator it acc) it acc) list))

(defun -min-by (comparator list)
  "Take a comparison function COMPARATOR and a LIST and return
the least element of the list by the comparison function.

See also combinator `-on' which can transform the values before
comparing them."
  (--reduce (if (funcall comparator it acc) acc it) list))

(defmacro --max-by (form list)
  "Anaphoric version of `-max-by'.

The items for the comparator form are exposed as \"it\" and \"other\"."
  `(-max-by (lambda (it other) ,form) ,list))

(defmacro --min-by (form list)
  "Anaphoric version of `-min-by'.

The items for the comparator form are exposed as \"it\" and \"other\"."
  `(-min-by (lambda (it other) ,form) ,list))

(defun -cons-pair? (con)
  "Return non-nil if CON is true cons pair.
That is (A . B) where B is not a list."
  (and (listp con)
       (not (listp (cdr con)))))

(defun -cons-to-list (con)
  "Convert a cons pair to a list with `car' and `cdr' of the pair respectively."
  (list (car con) (cdr con)))

(defun -value-to-list (val)
  "Convert a value to a list.

If the value is a cons pair, make a list with two elements, `car'
and `cdr' of the pair respectively.

If the value is anything else, wrap it in a list."
  (cond
   ((-cons-pair? val) (-cons-to-list val))
   (t (list val))))

(defun -tree-mapreduce-from (fn folder init-value tree)
  "Apply FN to each element of TREE, and make a list of the results.
If elements of TREE are lists themselves, apply FN recursively to
elements of these nested lists.

Then reduce the resulting lists using FOLDER and initial value
INIT-VALUE. See `-reduce-r-from'.

This is the same as calling `-tree-reduce-from' after `-tree-map'
but is twice as fast as it only traverse the structure once."
  (cond
   ((not tree) nil)
   ((-cons-pair? tree) (funcall fn tree))
   ((listp tree)
    (-reduce-r-from folder init-value (mapcar (lambda (x) (-tree-mapreduce-from fn folder init-value x)) tree)))
   (t (funcall fn tree))))

(defmacro --tree-mapreduce-from (form folder init-value tree)
  "Anaphoric form of `-tree-mapreduce-from'."
  `(-tree-mapreduce-from (lambda (it) ,form) (lambda (it acc) ,folder) ,init-value ,tree))

(defun -tree-mapreduce (fn folder tree)
  "Apply FN to each element of TREE, and make a list of the results.
If elements of TREE are lists themselves, apply FN recursively to
elements of these nested lists.

Then reduce the resulting lists using FOLDER and initial value
INIT-VALUE. See `-reduce-r-from'.

This is the same as calling `-tree-reduce' after `-tree-map'
but is twice as fast as it only traverse the structure once."
  (cond
   ((not tree) nil)
   ((-cons-pair? tree) (funcall fn tree))
   ((listp tree)
    (-reduce-r folder (mapcar (lambda (x) (-tree-mapreduce fn folder x)) tree)))
   (t (funcall fn tree))))

(defmacro --tree-mapreduce (form folder tree)
  "Anaphoric form of `-tree-mapreduce'."
  `(-tree-mapreduce (lambda (it) ,form) (lambda (it acc) ,folder) ,tree))

(defun -tree-map (fn tree)
  "Apply FN to each element of TREE while preserving the tree structure."
  (cond
   ((not tree) nil)
   ((-cons-pair? tree) (funcall fn tree))
   ((listp tree)
    (mapcar (lambda (x) (-tree-map fn x)) tree))
   (t (funcall fn tree))))

(defmacro --tree-map (form tree)
  "Anaphoric form of `-tree-map'."
  `(-tree-map (lambda (it) ,form) ,tree))

(defun -tree-reduce-from (fn init-value tree)
  "Use FN to reduce elements of list TREE.
If elements of TREE are lists themselves, apply the reduction recursively.

FN is first applied to INIT-VALUE and first element of the list,
then on this result and second element from the list etc.

The initial value is ignored on cons pairs as they always contain
two elements."
  (cond
   ((not tree) nil)
   ((-cons-pair? tree) tree)
   ((listp tree)
    (-reduce-r-from fn init-value (mapcar (lambda (x) (-tree-reduce-from fn init-value x)) tree)))
   (t tree)))

(defmacro --tree-reduce-from (form init-value tree)
  "Anaphoric form of `-tree-reduce-from'."
  `(-tree-reduce-from (lambda (it acc) ,form) ,init-value ,tree))

(defun -tree-reduce (fn tree)
  "Use FN to reduce elements of list TREE.
If elements of TREE are lists themselves, apply the reduction recursively.

FN is first applied to first element of the list and second
element, then on this result and third element from the list etc.

See `-reduce-r' for how exactly are lists of zero or one element handled."
  (cond
   ((not tree) nil)
   ((-cons-pair? tree) tree)
   ((listp tree)
    (-reduce-r fn (mapcar (lambda (x) (-tree-reduce fn x)) tree)))
   (t tree)))

(defmacro --tree-reduce (form tree)
  "Anaphoric form of `-tree-reduce'."
  `(-tree-reduce (lambda (it acc) ,form) ,tree))

(defun -clone (list)
  "Create a deep copy of LIST.
The new list has the same elements and structure but all cons are
replaced with new ones.  This is useful when you need to clone a
structure such as plist or alist."
  (-tree-map 'identity list))

(defun dash-enable-font-lock ()
  "Add syntax highlighting to dash functions, macros and magic values."
  (eval-after-load "lisp-mode"
    '(progn
       (let ((new-keywords '(
                             "--each"
                             "-each"
                             "--each-while"
                             "-each-while"
                             "--dotimes"
                             "-dotimes"
                             "-map"
                             "--map"
                             "--reduce-from"
                             "-reduce-from"
                             "--reduce"
                             "-reduce"
                             "--reduce-r-from"
                             "-reduce-r-from"
                             "--reduce-r"
                             "-reduce-r"
                             "--filter"
                             "-filter"
                             "-select"
                             "--select"
                             "--remove"
                             "-remove"
                             "-reject"
                             "--reject"
                             "--keep"
                             "-keep"
                             "-flatten"
                             "-concat"
                             "--mapcat"
                             "-mapcat"
                             "--first"
                             "-first"
                             "--any?"
                             "-any?"
                             "-some?"
                             "--some?"
                             "-any-p"
                             "--any-p"
                             "-some-p"
                             "--some-p"
                             "--all?"
                             "-all?"
                             "-every?"
                             "--every?"
                             "-all-p"
                             "--all-p"
                             "-every-p"
                             "--every-p"
                             "--none?"
                             "-none?"
                             "-none-p"
                             "--none-p"
                             "-only-some?"
                             "--only-some?"
                             "-only-some-p"
                             "--only-some-p"
                             "-take"
                             "-drop"
                             "--take-while"
                             "-take-while"
                             "--drop-while"
                             "-drop-while"
                             "-split-at"
                             "-rotate"
                             "-insert-at"
                             "--split-with"
                             "-split-with"
                             "-partition"
                             "-partition-in-steps"
                             "-partition-all"
                             "-partition-all-in-steps"
                             "-interpose"
                             "-interleave"
                             "--zip-with"
                             "-zip-with"
                             "-zip"
                             "--map-indexed"
                             "-map-indexed"
                             "--map-when"
                             "-map-when"
                             "--replace-where"
                             "-replace-where"
                             "-partial"
                             "-rpartial"
                             "-juxt"
                             "-applify"
                             "-on"
                             "-flip"
                             "-const"
                             "-cut"
                             "-orfn"
                             "-andfn"
                             "-elem-index"
                             "-elem-indices"
                             "-find-indices"
                             "--find-indices"
                             "-find-index"
                             "--find-index"
                             "-select-by-indices"
                             "-grade-up"
                             "-grade-down"
                             "->"
                             "->>"
                             "-->"
                             "-when-let"
                             "-when-let*"
                             "--when-let"
                             "-if-let"
                             "-if-let*"
                             "--if-let"
                             "-union"
                             "-distinct"
                             "-intersection"
                             "-difference"
                             "-contains?"
                             "-contains-p"
                             "-repeat"
                             "-cons*"
                             "-sum"
                             "-product"
                             "-min"
                             "-min-by"
                             "--min-by"
                             "-max"
                             "-max-by"
                             "--max-by"
                             "-cons-to-list"
                             "-value-to-list"
                             "-tree-mapreduce-from"
                             "--tree-mapreduce-from"
                             "-tree-mapreduce"
                             "--tree-mapreduce"
                             "-tree-map"
                             "--tree-map"
                             "-tree-reduce-from"
                             "--tree-reduce-from"
                             "-tree-reduce"
                             "--tree-reduce"
                             "-clone"
                             ))
             (special-variables '(
                                  "it"
                                  "it-index"
                                  "acc"
                                  "other"
                                  )))
         (font-lock-add-keywords 'emacs-lisp-mode `((,(concat "\\<" (regexp-opt special-variables 'paren) "\\>")
                                                     1 font-lock-variable-name-face)) 'append)
         (font-lock-add-keywords 'emacs-lisp-mode `((,(concat "(\\s-*" (regexp-opt new-keywords 'paren) "\\>")
                                                     1 font-lock-keyword-face)) 'append))
       (--each (buffer-list)
         (with-current-buffer it
           (when (and (eq major-mode 'emacs-lisp-mode)
                      (boundp 'font-lock-mode)
                      font-lock-mode)
             (font-lock-refresh-defaults)))))))

(provide 'dash)
;;; dash.el ends here
