BITS 64
ORG 0x400000
ehdr:
    db 0x7F, "ELF"
    db 2, 1, 1, 0
    times 8 db 0
    dw 2
    dw 0x3E
    dd 1
    dq _start
    dq phdr - $$
    dq 0
    dd 0
    dw ehdrsize
    dw phdrsize
    dw 1
    dw 0, 0, 0
ehdrsize equ $ - ehdr
phdr:
    dd 1
    dd 7
    dq 0
    dq $$
    dq $$
    dq filesize
    dq filesize + bufsz
    dq 0x1000
phdrsize equ $ - phdr
_start:
    mov rsi, [rsp]
    lea rsi, [rsp + rsi*8 + 16]
.next_env:
    mov rdi, [rsi]
    test rdi, rdi
    jz .no_user
    cmp dword [rdi], 'USER'
    je .found_user
    add rsi, 8
    jmp .next_env
.found_user:
    add rdi, 5
    mov rsi, rdi
    xor edx, edx
    xor ecx, ecx
    call putsz
.no_user:
    mov esi, hdr
    mov edx, hdr_len
    call puts
    mov edi, p_os
    call openread
    js .do_kr
    mov esi, buf + 13
    xor edx, edx
    mov cl, '"'
    call putsz
.do_kr:
    mov esi, l_kr
    mov edx, l_kr_len
    call puts
    mov eax, 63
    mov edi, buf
    syscall
    mov esi, buf + 130
    xor edx, edx
    xor ecx, ecx
    call putsz
    mov esi, l_ram
    mov edx, l_ram_len
    call puts
    mov edi, p_mem
    call openread
    jle .fin
    mov edi, buf + 9
    call skip_sp
    call atoi_kb
    mov ebx, eax
    mov edi, buf
    mov ecx, bufsz - 4
.fnd_av:
    cmp dword [rdi], 0x41 << 24 | 'm' << 16 | 'e' << 8 | 'M'
    je .got_av
    inc rdi
    loop .fnd_av
    jmp .fin
.got_av:
    add rdi, 13
    call skip_sp
    call atoi_kb
    sub ebx, eax
    mov eax, ebx
    sar eax, 10
    mov edi, buf
    call itoa
    mov word [rdi], 0x424d
    add rdi, 2
    mov esi, buf
    sub rdi, rsi
    mov edx, edi
    call puts
.fin:
    mov esi, hdr
    mov edx, 1
    call puts
    xor edi, edi
    mov eax, 60
    syscall
openread:
    push rdi
    mov eax, 2
    xor esi, esi
    xor edx, edx
    syscall
    test eax, eax
    js .err
    mov edi, eax
    xor eax, eax
    mov esi, buf
    mov edx, bufsz
    syscall
    test eax, eax
.err:
    pop rdi
    ret
putsz:
.f:
    cmp byte [rsi + rdx], cl
    je puts
    inc edx
    jmp .f
puts:
    mov eax, 1
    mov edi, 1
    syscall
    ret
skip_sp:
    cmp byte [rdi], ' '
    jne .done
    inc rdi
    jmp skip_sp
.done:
    ret
atoi_kb:
    xor eax, eax
    xor ecx, ecx
.lp:
    mov cl, [rdi]
    cmp cl, '0'
    jb .done
    cmp cl, '9'
    ja .done
    sub cl, '0'
    imul eax, eax, 10
    add eax, ecx
    inc rdi
    jmp .lp
.done:
    ret
itoa:
    mov ecx, 10
    xor r9d, r9d
.lp:
    xor edx, edx
    div ecx
    add dl, '0'
    push rdx
    inc r9d
    test eax, eax
    jnz .lp
.wr:
    pop rax
    mov [rdi], al
    inc rdi
    dec r9d
    jnz .wr
    ret
hdr:
    db 10, 10, 'OS: '
hdr_len equ $ - hdr
l_kr:
    db 10, 'KR: '
l_kr_len equ $ - l_kr
l_ram:
    db 10, 'RAM: '
l_ram_len equ $ - l_ram
p_os:
    db '/etc/os-release', 0
p_mem:
    db '/proc/meminfo', 0
bufsz equ 160
buf:
filesize equ $ - $$
