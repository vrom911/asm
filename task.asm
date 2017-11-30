;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Implements the write system call
%macro putStr 1
    mov     rax, 1      ; system call number (sys_write)
    mov     rdi, 1      ; file descriptor (stdout
    mov     rsi, %1     ; message to write
    mov     rdx, %1Len  ; message length
    syscall             ; call write syscall
%endmacro

; Implements variable initialization along with its length
%macro var 2+
    %1    db  %2    ; initialize the variable
    %1Len equ $-%1  ; initialize the length
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    var filename, "input.txt", 0
    var newline, 0xa

;; Errors
    var existErr, "File doesn't exist: "

    var lol, "WTF?!"

section .bss
  fd_out resb 1
  fd_in  resb 1
  info resb  26

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
    global _start

_start:
    call   playWithFile
    call   exit


playWithFile:
    mov    eax, 5           ; system call number (open file)
    mov    ebx, filename    ; file name
    mov    ecx, 0           ;file access read-only
    int    0x80
    mov    [fd_in], eax
    ; if managed to open file
    cmp    eax, 0
    jge    print_exist
    ; if doesn't exist print the error
    cmp    eax, -2
    jz     print_not_exist
    ; some other error while opening
    putStr lol
    ret

print_exist:
    putStr filename
    putStr newline

    ;read from file
    mov eax, 3
    mov ebx, [fd_in]
    mov ecx, info
    mov edx, 26
    int 0x80

    ; print the info
    mov eax, 4
    mov ebx, 1
    mov ecx, info
    mov edx, 26
    int 0x80

    ; close the file
    mov    eax, 6        ; system call number (close file)
    mov    ebx, [fd_in]  ; file descriptor
    ret

print_not_exist:
    putStr existErr
    putStr filename
    putStr newline
    call   exit

exit:
    mov    rax, 60	; system call number (sys_write)
    mov    rdi, 0   ; exit code
    syscall
