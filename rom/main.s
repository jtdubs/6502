;;
;; main.s - defines the memory map and pulls in the code and data
;;


;;
;; define memory map
;;

;; zero page
.data zp
.org $0000

;; general ram
.data
.org $0200

;; code segment
.text
.org $8000


;;
;; Code
;;

.require "entry.s"


;;
;; Vector Table
;;

.text
.advance $fff4, $ff
.word $0000 ; cop
.word $0000 ; --
.word $0000 ; abort
.word $0000 ; nmi
.word on_reset
.word $0000 ; irq / brk


;;
;; verify no segments overruns
;;

.data zp
.checkpc $0100

.data
.checkpc $4000

.text
.checkpc $10000
