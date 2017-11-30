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

; Implements the write system call with given length
%macro putStrLen 2
    mov     rax, 1      ; system call number (sys_write)
    mov     rdi, 1      ; file descriptor (stdout
    mov     rsi, %1     ; message to write
    mov     rdx, %2     ; message length
    syscall             ; call write syscall
%endmacro

; Implements variable initialization along with its length
%macro var 2+
    %1    db  %2    ; initialize the variable
    %1Len equ $-%1  ; initialize the length
%endmacro

%macro debugReg 1
    mov [regval], %1
    putStrLen regval, 1
    putStr newline
%endmacro

; Add the word to the array of keys or values
%macro printTo 1
    mov r11, 0
loop%1:
    mov bl, byte [nextWord + r11]
    mov [%1 + r10 + r11], bl
    add r11, 1
    cmp r11, 257
    jnz loop%1
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    var filename, "input.txt", 0x0
    var newline, 0xa

;; Errors
    var existErr, "File doesn't exist: "

    var fileError, "Something went wrong", 0x0

section .bss
  fd_in    resb 8
  keys     resb 128000 ; 256 * 500
  vals     resb 128000
  nextWord resb 257
  regval   resb 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
    global _start

_start:
    call   playWithFile
    putStrLen keys, 128000
    putStr newline
    putStrLen vals, 128000
    call   exit

playWithFile:
    ; open input.txt file
    mov    rax, 2           ; system call number (open file)
    mov    rdi, filename    ; file name
    mov    rdx, 0           ; file access read-only
    syscall
    mov    [fd_in], rax
    ; if managed to open file
    cmp    rax, 0
    jge    print_exist
    ; if doesn't exist print the error
    cmp    rax, -2
    jz     print_not_exist
    ; some other error while opening
    putStr fileError
    ret

print_exist:
    mov rbx, nextWord
    mov r9,  'k'         ; flag for key or value
    mov r10, 0           ; inc by 256

readSymb:
    ;read from file
    mov rax, 0
    mov rdi, [fd_in]
    mov rsi, rbx
    mov rdx, 1
    syscall

    cmp rax, 0
    jz closeFile
    jl exit
    mov rcx, [rbx]
    cmp rcx, ' '
    jz printWord
    cmp rcx, 0xa
    jz printWord

    add rbx, rax
    jmp readSymb

printWord:
    ; remove space or newline
    mov [rbx], byte 0
    ; 'k -- write to keys, 'v' -- write to vals
    cmp r9, 'k'
    jz printToKeys

    ; print the word to values
    mov r9, 'k'
    printTo vals

    ; next line
    add r10, 256
    jmp continuePrintWord

    ; print the word to keys
printToKeys:
    mov r9, 'v'
    printTo keys

continuePrintWord:
    ; remove the nextWord for the next one
    mov r8, 257
loop:
    mov [nextWord + r8], byte 0
    dec r8
    jnz loop
    mov rbx, nextWord
    jmp readSymb

closeFile:
    ; close the file
    mov    rax, 3        ; system call number (close file)
    mov    rdi, [fd_in]  ; file descriptor
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
