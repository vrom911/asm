;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Implements the write system call
%macro putStr 1
    mov     rax, 1      ; system call number (sys_write)
    mov     rdi, 1      ; file descriptor (stdout)
    mov     rsi, %1     ; message to write
    mov     rdx, %1Len  ; message length
    syscall             ; call write syscall
%endmacro

; Implements the write system call with given length
%macro putStrLen 2
    mov     rax, 1      ; system call number (sys_write)
    mov     rdi, 1      ; file descriptor (stdout)
    mov     rsi, %1     ; message to write
    mov     rdx, %2     ; message length
    syscall             ; call write syscall
%endmacro

%macro printValue 1
    mov r8, 0
 nextWordVal:
    mov bl, [valsSort + %1 + r8]
    mov [nextWord + r8], bl
    add r8, 1
    cmp r8, 256
    jl nextWordVal

    mov rax, 1
    mov rdi, 1
    mov rsi, nextWord
    mov rdx, 256
    syscall
%endmacro

; Implements variable initialization along with its length
%macro var 2+
    %1    db  %2    ; initialize the variable
    %1Len equ $-%1  ; initialize the length
%endmacro

%macro debugReg 1
    mov [regval], %1
    putStrLen regval, 8
    putStr newline
%endmacro

%macro printHumanLine 2
    mov r15, 19
    mov rax, [%1]
  divTen%2:
    cmp rax, 0
    je end%2
    mov    rdx, rax
    shr    rdx, 32
    mov    ecx, 10
    div    ecx
    add dl, '0'
    mov [lineDec + r15], dl
    dec r15
    jmp divTen%2 

  end%2:
    putStrLen lineDec, 20
%endmacro

; Add the word to the array of keys or values
%macro printTo 1
    mov r11, 0
  loop%1:
    mov bl, byte [nextWord + r11]
    mov [%1 + r10 + r11], bl
    add r11, 1
    cmp r11, 256
    jl loop%1
%endmacro

; Rewrite one cell to another array at index `n`.
; `writeTo keys 1 2` will put keys[1] into keysSort[2]
%macro writeTo 4
    mov r8, 0
  loopwrite%1%2%3%4:
    mov bl, byte [%1 + %2 + r8]
    mov [%1Sort + %3 + r8], bl
    add r8, 1
    cmp r8, 256
    jl loopwrite%1%2%3%4
%endmacro

; Rewrite original with the xSort array
%macro rewriteArr 1
    mov r8, 0
  looprewrite%1:
    mov rbx, [%1Sort + r8]
    mov [%1 + r8], rbx
    add r8, 8
    cmp r8, [size256]
    jl looprewrite%1
%endmacro

; Fill the sort array
%macro fillSortArr 1
    mov r8, 0
  loopfill%1:
    mov rbx, [%1 + r8]
    mov [%1Sort + r8], rbx
    add r8, 8
    cmp r8, [size256]
    jl loopfill%1
%endmacro

; Compare two elements of array at index i and j return the result at r8
%macro cmpKeys 2
    mov r8, 0
  loopCmp%1%2:
    mov bl, byte [keys + %1 + r8]
    mov dl, byte [keys + %2 + r8]
    cmp bl, dl
    jne endLoopCmp%1%2
    inc r8
    cmp r8, 256
    jl loopCmp%1%2
  endLoopCmp%1%2:
%endmacro

; Compare the input key with the one at index %1
%macro cmpKeyOn 1
    mov r8, 0
    mov r10, [%1]
  loopCmpOn%1:
    mov bl, byte [keysSort + r10 + r8]
    mov dl, byte [keyRead + r8]
    cmp bl, dl
    jne endLoopCmpOn%1
    inc r8
    cmp r8, 256
    jl loopCmpOn%1
  endLoopCmpOn%1:
%endmacro

%macro divide 2
    mov    rdx, rax
    shr    rdx, 32
    mov    ecx, %2
    div    ecx
    mov    [%1], rax
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    var filename, "input.txt", 0x0
    var newline, 0xa
    var enterMsg, "Enter the key: ", 0x0

;; Errors
    var existErr, "File doesn't exist: "
    var missingKey, "Missing key before the space symbol at line "
    var missingValue, "Missing value at line "
    var keyNotFoundErr, "Key wasn't found: "

    var fileError, "Something went wrong", 0x0

section .bss
  fd_in    resb 8
  line     resb 8
  size     resb 8
  size256  resb 8
  mid      resb 8
  h        resb 8
  seqs     resb 8
  halfseqs resb 8
  keys     resb 128000 ; 256 * 500
  vals     resb 128000
  nums     resb 128000
  keysSort resb 128000 ; 256 * 500
  valsSort resb 128000
  numsSort resb 128000
  keyRead  resb 256
  nextWord resb 257
  regval   resb 8
  lineDec  resb 20

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
    global _start

_start:
    call playWithFile
    call sorting
    putStrLen keysSort, 128000
    putStr newline
    putStrLen valsSort, 128000
    putStr newline
    putStrLen numsSort, 128000
    putStr newline

    call search_section
    call exit

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
    mov r8, 1
    mov [line], r8
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
    ; if current symb is ' ' 
    cmp rcx, ' '
    jz space
    ; if current symb is new line
    cmp rcx, 0xa
    jz newLine

    ; if current symb is any other char
    cmp r9, 'k'
    jne valSymb
    ; key is not empty anymore
    mov r9, 'l'
    jmp next
  valSymb:
    cmp r9, 'v'
    jne next
    ; value is not empty anymore
    mov r9, 'w'
    
  next:
    add rbx, rax
    jmp readSymb

  space:
    cmp r9, 'l'
    je putKey
    putStr missingKey
    printHumanLine line, keey
    putStr newline
    call exit
  
  newLine:
    cmp r9, 'w'
    je putValue
    cmp r9, 'k'
    je emptyLine
    putStr missingValue
    printHumanLine line, value
    putStr newline
    call exit


putValue:
    ; remove space or newline
    mov [rbx], byte 0
    ; print the word to values
    mov r9, 'k'
    printTo vals

    ; put line number into array
    mov r8, [line]
    mov [nums + r10], r8

    ; next line
    add r10, 256
    ; increase line number
    mov r8, 1
    add [line], r8
    jmp continuePrintWord

emptyLine:
    ; remove space or newline
    mov [rbx], byte 0
    ; increase line number
    mov r8, 1
    add [line], r8
    jmp readSymb

putKey:
    ; remove space or newline
    mov [rbx], byte 0

    mov r9, 'v'
    printTo keys
    jmp continuePrintWord

continuePrintWord:
    ; remove the nextWord for the next one
    mov r8, 256
loop:
    mov [nextWord + r8], byte 0
    dec r8
    jnz loop
    mov rbx, nextWord
    jmp readSymb

closeFile:
    ; put size of array into size variable
    mov [size256], r10
    mov rax, r10
    divide size, 256 

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
    mov    rax, 60  ; system call number (sys_write)
    mov    rdi, 0   ; exit code
    syscall

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Merge Sort
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sorting:
; DIRTY HACK
; for (int i = 0; i < n; i++) c[i] = a[i];
    fillSortArr keys
    fillSortArr vals
    fillSortArr nums

    ; int h = 1; 
    ; rax == h
    mov  rax, 256
    mov  [h], rax
    
; while (h < n)
whileH_l_N:
    cmp rax, [size256]
    jge afterWhileH_l_N
    ; int numberOfSequences = n / h;
    mov rax, [size256]
    divide seqs, [h]
    ; if (n % h != 0) numberOfSequences++;
    cmp edx, 0
    je half
    mov r9, [seqs]
    inc r9
    mov [seqs], r9
  half:
    ; int halfOfSequences = numberOfSequences / 2;
    mov rax, [seqs]
    divide halfseqs, 2 
    ; int mid = halfOfSequences * h
    mov rax, [halfseqs]
    mov r9, [h]
    imul rax, r9
    mov [mid], rax

    ; step = h;
    ; int i = 0;   // index of the first path
    ; int j = mid; // index of the second path
    ; int k = 0;   // index of the element of the result array
    ; r12 == step
    ; r13 == i
    ; r14 == j
    ; r15 == k
    mov r12, [h]
    mov r13, 0
    mov r14, [mid]
    mov r15, 0

    ; while (step <= mid)
    whileSTEP_le_MID:
        cmp r12, [mid]
        jg afterWhileSTEP_le_MID
        ; while not at the end of the path
        ; fill the next element with the lowest of the two we have
        whileComplicated:
            ; (i < step)
            cmp r13, r12
            jge afterWhileComplicated
            ; (i < mid)
            cmp r13, [mid]
            jge afterWhileComplicated
            ; (j < n)
            cmp r14, [size256]
            jge afterWhileComplicated
            ; (j < (mid + step))
            mov rbx, [mid]
            add rbx, r12
            cmp r14, rbx
            jge afterWhileComplicated
            ; if (a[i] < a[j])  
            ; { c[k] = a[i]; i++; k++; }
            ; else { c[k] = a[j]; j++; k++; } 
            cmpKeys r13, r14
            jl keyI_l_J
            je numI_l_J
            keyI_g_J:
                writeTo keys, r14, r15, keysI_g_J
                writeTo vals, r14, r15, valsI_g_J
                writeTo nums, r14, r15, numsI_g_J
                add r14, 256
            jmp incK
            keyI_l_J:
                writeTo keys, r13, r15, keysI_l_J
                writeTo vals, r13, r15, valsI_l_J
                writeTo nums, r13, r15, numsI_l_J
                add r13, 256
            jmp incK
            numI_l_J:
                mov r8, [nums + r13]
                mov r9, [nums + r14]
                cmp r8, r9
                jl keyI_l_J
                jmp keyI_g_J

            incK:
                add r15, 256
            jmp whileComplicated

        afterWhileComplicated:
            ; if the second path is finished earlier than the first
            ; rewrite all the remains from the first
            ; while (i < step && i < mid) { c[k] = a[i]; i++; k++; }
            whileI_l_STEPandMID:
                cmp r13, r12
                jge afterWhileI_l_STEPandMID
                cmp r13, [mid]
                jge afterWhileI_l_STEPandMID

                writeTo keys, r13, r15, keysI_l_STEP
                writeTo vals, r13, r15, valsI_l_STEP
                writeTo nums, r13, r15, numsI_l_STEP

                add r13, 256
                add r15, 256
                jmp whileI_l_STEPandMID
            afterWhileI_l_STEPandMID:

            ; if the first one is finished earlier that the second one
            ; rewrite all the remains from the second
            ; while ((j < (mid + step)) && (j<n)) { c[k] = a[j]; j++; k++; }
            whileSecond:
                mov rbx, [mid]
                add rbx, r12
                cmp r14, rbx
                jge afterWhileSecond
                cmp r14, [size256]
                jge afterWhileSecond

                writeTo keys, r14, r15, keysSecond
                writeTo vals, r14, r15, valsSecond
                writeTo nums, r14, r15, numsSecond

                add r14, 256
                add r15, 256
                jmp whileSecond
            afterWhileSecond:

            ; move to the next step
            ; step = step + h;
            mov rax, [h]
            add r12, rax
         
      jmp whileSTEP_le_MID

    afterWhileSTEP_le_MID:

    ; h = h * 2;
    mov rax, [h]
    imul rax, 2
    mov [h], rax
    ; move temp sorted version to the original one:
    ; for (i = 0; i<n; i++) a[i] = c[i];
    rewriteArr keys
    rewriteArr vals
    rewriteArr nums

    mov rax, [h]
    jmp whileH_l_N
afterWhileH_l_N :
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Binary Search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
search_section:
    putStr enterMsg
    ; read the key from the console
    ; and put it in keyRead
    mov    rax, 0        ; system call number (read)
    mov    rdi, 0        ; from stdin
    mov    rsi, keyRead  ; buffer
    mov    rdx, 256      ; length
    syscall
    

    ; left  == seqs
    ; right == halfseqs
    mov r8, -256
    mov [seqs], r8       ; left
    mov rax, [size256]
    mov [halfseqs], rax  ; right

 binarySearch:
    ; while (l < r - 1)
    mov rax, [halfseqs]
    sub rax, 256
    cmp [seqs], rax
    jge afterSearch

    ; m = (l + r) / 2
    mov r8, [seqs]
    mov rax, [halfseqs]
    add rax, r8
    divide mid, 500
    mov rax, [mid]
    imul rax, 256
    mov [mid], rax
    
    ; if keys[m] <= key
    cmpKeyOn mid
    jle less
    ; r = m
    mov r9, [mid]
    mov [halfseqs], r9
    jmp binarySearch
  less:
    ; l = m
    mov r10, [mid]
    mov [seqs], r10
    jmp binarySearch

afterSearch:
    putStr newline
    cmpKeyOn seqs
    jne keyNotFound
    mov r14, [seqs]
    printValue r14
    putStr newline
    ret

  keyNotFound:
    putStr keyNotFoundErr
    putStrLen keyRead, 256
    putStr newline
    ret
    


