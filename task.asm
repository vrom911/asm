section .data
    msg db      "hello, world!"
    filename equ "input.txt"

    exist_err db "File doesn't exist"
    exist_err_len equ $ - exist_err

section .text
    global _start

_start:
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, msg
    mov     rdx, 13
    syscall
    mov    rax, 60
    mov    rdi, 0
    syscall
