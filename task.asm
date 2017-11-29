;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Implements the write system call
%macro putStr 1
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, %1
    mov     rdx, %1Len
    syscall
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    msg      db  "hello, world!", 0xA, 0xD
    msgLen   equ $ - msg
    filename db  "input.txt"

;; Errors
    exist_err db "File doesn't exist"
    exist_len equ $-exist_err

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
    global _start

_start:
    putStr msg
    mov    rax, 60
    mov    rdi, 0
    syscall
