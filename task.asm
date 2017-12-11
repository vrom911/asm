;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Implements the write system call
%macro putStr 1
    mov rax, 1      ; system call number (sys_write)
    mov rdi, 1      ; file descriptor (stdout)
    mov rsi, %1     ; message to write
    mov rdx, %1Len  ; message length
    syscall             ; call write syscall
%endmacro

; Implements the write system call with given length
%macro putStrLen 2
    mov rax, 1      ; system call number (sys_write)
    mov rdi, 1      ; file descriptor (stdout)
    mov rsi, %1     ; message to write
    mov rdx, %2     ; message length
    syscall         ; call write syscall
%endmacro

; Opens the file with proper error handling
%macro openFile 2
    ; open input.txt file
    mov rax, 2      ; system call number (open file)
    mov rdi, %1     ; file name
    mov rsi, 0
    mov rdx, 0      ; file access read-only
    syscall
    mov [fd_in], rax
    ; if managed to open file
    cmp rax, 0
    jge if_exist_%2
    ; if doesn't exist print the error
    cmp rax, -2
    jz  if_not_exist_%2
    ; some other error while opening
    putStr fileError
    ret

  if_not_exist_%2:
    putStr existErr
    putStr %1
    putStr newline
    call   exit
  if_exist_%2:
%endmacro

%macro mmap 2
    mov rdx, [%2]
    mov rax, 9    ; syscall mmap
    mov rdi, 0    ; addr
    mov rsi, rdx  ; len
    mov rdx, 3    ; prot PROT_READ | PROT_WRITE
    mov r10, 0x22 ; flags MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1    ; fd (anonymous memory)
    mov r9, 0     ; off
    syscall

    mov [%1], rax
%endmacro

%macro printValue 1
    mov r8, 0
    mov rdx, [valsSort]
    add rdx, %1
 nextWordVal:
    mov rsi, rdx
    add rsi, r8
    mov bl, [rsi]
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

; Prints the array
%macro putArr 2
    mov r9, [%1]
    mov rax, 1      ; system call number (sys_write)
    mov rdi, 1      ; file descriptor (stdout)
    mov rsi, r9     ; message to write
    mov r10, [%2]
    mov rdx, r10    ; message length
    syscall             ; call write syscall
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
    mov rdx, rax
    shr rdx, 32
    mov ecx, 10
    div ecx
    add dl, '0'
    mov [lineDec + r15], dl
    dec r15
    jmp divTen%2

  end%2:
    putStrLen lineDec, 20
%endmacro

; Add the word to the array of keys or values
%macro putInto 1
    mov r12, [%1]
    add r12, r10
    mov r11, 0
  loop%1:
    mov bl, byte [nextWord + r11]
    mov r13, r11
    add r13, r12
    mov [r13], bl
    add r11, 1
    cmp r11, 256
    jl loop%1
%endmacro

; Rewrite one cell to another array at index `n`.
; `writeTo keys 1 2` will put keys[1] into keysSort[2]
%macro writeTo 4
    mov r8, 0
    mov rdx, [%1]
    mov rax, [%1Sort]
  loopwrite%1%2%3%4:
    mov rsi, rdx
    add rsi, %2
    add rsi, r8
    mov bl, byte [rsi]

    mov rsi, rax
    add rsi, %3
    add rsi, r8
    mov [rsi], bl

    add r8, 1
    cmp r8, 256
    jl loopwrite%1%2%3%4
%endmacro

; Rewrite original with the xSort array
%macro rewriteArr 1
    mov rdx, [%1]
    mov rax, [%1Sort]
    mov r8, 0
  looprewrite%1:
    mov rsi, rax
    add rsi, r8
    mov rbx, [rsi]
    mov rsi, rdx
    add rsi, r8
    mov [rsi], rbx
    add r8, 8
    cmp r8, [size256]
    jl looprewrite%1
%endmacro

; Fill the sort array with the normal one
%macro fillSortArr 1
    mov r9, [%1]
    mov r11, [%1Sort]
    mov r8, 0
  loopfill%1:
    mov r10, r9
    add r10, r8
    mov rbx, [r10]
    mov r10, r11
    add r10, r8
    mov [r10], rbx
    add r8, 8
    cmp r8, [size256]
    jl loopfill%1
%endmacro

; Compare two elements of array at index i and j return the result at r8
%macro cmpKeys 2
    mov r8, 0
    mov rdx, [keys]
  loopCmp%1%2:
    mov rsi, rdx
    add rsi, r8
    add rsi, %1
    mov bl, byte [rsi]
    mov rsi, rdx
    add rsi, r8
    add rsi, %2
    mov dl, byte [rsi]
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
    mov r11, [keysSort]
    add r11, r10
  loopCmpOn%1:
    mov r10, r11
    add r10, r8
    mov bl, byte [r10]
    mov dl, byte [keyRead + r8]
    cmp bl, dl
    jne endLoopCmpOn%1
    inc r8
    cmp r8, 256
    jl loopCmpOn%1
  endLoopCmpOn%1:
%endmacro

%macro divide 2
    mov rdx, rax
    shr rdx, 32
    mov ecx, %2
    div ecx
    mov [%1], rax
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
    var emptyErr, "The file is empty"
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
  keys     resb 8
  vals     resb 8
  nums     resb 8
  keysSort resb 8
  valsSort resb 8
  numsSort resb 8
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
    call getLineNums
    call playWithFile
    call sorting
    call search_section
    call exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Get non-empty lines number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getLineNums:
    ; open input.txt file
    openFile filename, first


    mov rbx, nextWord
    mov r9,  'e'         ; flag for empty line
    mov r10, 0           ; inc by 256
  readSymbFirst:
    ;read from file
    mov rax, 0
    mov rdi, [fd_in]
    mov rsi, rbx
    mov rdx, 1
    syscall

    cmp rax, 0
    jz closeFileFirst
    jl exit

    mov rcx, [rbx]
    ; if current symb is new line
    cmp rcx, 0xa
    jz newLineFirst

    ; if any other char
    mov r9, 'n'
    add rbx, rax
    jmp readSymbFirst

  newLineFirst:
    cmp r9, 'e'
    je emptyLineFirst

    ; next line
    add r10, 256

    mov r9, 'e'
    jmp readSymbFirst

  emptyLineFirst:
    jmp readSymbFirst

  closeFileFirst:

    ; put size of array into size variable
    mov [size256], r10
    mov rax, r10
    divide size, 256

    ; close the file
    mov rax, 3        ; system call number (close file)
    mov rdi, [fd_in]  ; file descriptor

    ; if empty file then print error
    cmp r10, 0
    jne fileOk
    putStr emptyErr
    putStr newline
    call exit
  fileOk:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Fill keys values lines arrays
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

playWithFile:
    ; open input.txt file
    openFile filename, second

    ; allocate memory for arrays
    mmap keys, size256
    mmap vals, size256
    mmap nums, size256


    mov r8, 1
    mov [line], r8
    ; remove the nextWord for the next one
    mov r8, 256
  loopRefresh:
    mov [nextWord + r8], byte 0
    dec r8
    jnz loopRefresh
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
    putInto vals

    ; put line number into array
    mov r8, [line]
    mov rsi, [nums]
    add rsi, r10
    mov [rsi], r8

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
    putInto keys
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

    ; check if non empty line
    mov r14, [size]
    mov r15, [line]
    sub r15, r14
    cmp r15, 3
    jg exit

    ; close the file
    mov rax, 3        ; system call number (close file)
    mov rdi, [fd_in]  ; file descriptor
    ret


exit:
    mov rax, 60  ; system call number (sys_write)
    mov rdi, 0   ; exit code
    syscall

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Merge Sort
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sorting:
    ; allocate memory for sorted arrays
    mmap keysSort, size256
    mmap valsSort, size256
    mmap numsSort, size256

; DIRTY HACK
; for (int i = 0; i < n; i++) c[i] = a[i];
    fillSortArr keys
    fillSortArr vals
    fillSortArr nums


    ; int h = 1;
    ; rax == h
    mov rax, 256
    mov [h], rax

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

            ; this one is to deal with duplicate keys
            numI_l_J:
                ; nums[i] < nums[j]
                mov rdx, [nums]
                mov rsi, rdx
                add rsi, r13
                mov r8, [rsi]
                mov rsi, rdx
                add rsi, r14
                mov r9, [rsi]
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
    ; refreash keyWord
    mov r8, 0
  refreshLoop:
    mov [keyRead + r8], byte 0
    add r8, 1
    cmp r8, 256
    jl refreshLoop

    ; print enter message
    putStr enterMsg

    ; read the key from the console
    ; and put it in keyRead
    mov r9, 0
 readKeySymb:
    mov rax, 0  ; system call number (read)
    mov rdi, 0  ; from stdin
    mov rsi, h  ; buffer
    mov rdx, 1  ; length
    syscall

    cmp rax, 0
    jne keepGoing
    call exit
  keepGoing:
    ; if the symb is newline then stop reading
    mov bl, [h]
    cmp bl, 0xa
    je endKeyReading

    mov [keyRead + r9], bl
    add r9, 1
    cmp r9, 256
    jge endKeyReading
    jmp readKeySymb

  endKeyReading:
    ; left  == seqs
    ; right == halfseqs
    mov r8, -256
    mov [seqs], r8       ; left
    mov rax, [size256]
    mov [halfseqs], rax  ; right

 ; search algorithm itself
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
    cmpKeyOn seqs
    jne keyNotFound
    mov r14, [seqs]
    printValue r14
    putStr newline
    ; new query
    jmp search_section

  keyNotFound:
    putStr keyNotFoundErr
    putStrLen keyRead, 256
    putStr newline
    jmp search_section
