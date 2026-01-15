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
    dq filesize + 0x1000
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
    xor rdx, rdx
.user_len:
    cmp byte [rdi+rdx], 0
    je .print_user
    inc rdx
    jmp .user_len
.print_user:
    mov eax, 1
    mov edi, 1
    syscall
.no_user:
    mov eax, 1
    mov edi, 1
    lea rsi, [rel hdr]
    mov edx, hdr_len
    syscall
    
    mov eax, 2
    lea rdi, [rel p_os]
    xor esi, esi
    xor edx, edx
    syscall
    test eax, eax
    js .sk_os
    
    push rax
    xor eax, eax
    pop rdi
    lea rsi, [rel buf]
    mov edx, 512
    syscall
    
    push rax
    mov eax, 3
    pop rdx
    syscall
    
    lea rdi, [rel buf]
    mov ecx, edx
.lp_os:
    cmp byte [rdi], 'P'
    jne .nx_os
    cmp dword [rdi+1], 0x54544552
    je .fd_os
.nx_os:
    inc rdi
    loop .lp_os
    jmp .sk_os
.fd_os:
    add rdi, 13
    cmp byte [rdi], '"'
    jne .pr_os
    inc rdi
.pr_os:
    mov rsi, rdi
    xor edx, edx
.ct_os:
    mov al, [rdi]
    cmp al, '"'
    je .wr_os
    cmp al, 10
    je .wr_os
    inc rdi
    inc edx
    jmp .ct_os
.wr_os:
    mov eax, 1
    mov edi, 1
    syscall
    jmp .do_kr
.sk_os:
    mov eax, 1
    mov edi, 1
    lea rsi, [rel s_na]
    mov edx, 3
    syscall

.do_kr:
    mov eax, 1
    mov edi, 1
    lea rsi, [rel l_kr]
    mov edx, l_kr_len
    syscall
    
    mov eax, 63
    lea rdi, [rel buf]
    syscall
    
    lea rsi, [rel buf + 130]
    mov rdi, rsi
    xor rdx, rdx
.ln_kr:
    cmp byte [rdi + rdx], 0
    je .pr_kr
    inc rdx
    jmp .ln_kr
.pr_kr:
    mov eax, 1
    mov edi, 1
    syscall
    
    mov eax, 1
    mov edi, 1
    lea rsi, [rel l_up]
    mov edx, l_up_len
    syscall
    
    mov eax, 2
    lea rdi, [rel p_up]
    xor esi, esi
    xor edx, edx
    syscall
    test eax, eax
    js .sk_up
    
    push rax
    xor eax, eax
    pop rdi
    lea rsi, [rel buf]
    mov edx, 32
    syscall
    
    mov eax, 3
    syscall
    
    lea rdi, [rel buf]
    xor eax, eax
.ps_up:
    movzx ecx, byte [rdi]
    inc rdi
    cmp cl, '.'
    je .cv_up
    sub cl, '0'
    lea eax, [rax + rax*4]
    lea eax, [rax + rax + rcx]
    jmp .ps_up
.cv_up:
    xor edx, edx
    mov ecx, 3600
    div ecx
    push rax
    mov eax, edx
    xor edx, edx
    mov ecx, 60
    div ecx
    
    mov r8d, eax
    pop rax
    
    lea rdi, [rel buf]
    call itoa
    mov word [rdi], 0x2068
    add rdi, 2
    mov eax, r8d
    call itoa
    mov byte [rdi], 'm'
    inc rdi
    
    lea rsi, [rel buf]
    sub rdi, rsi
    mov rdx, rdi
    mov eax, 1
    mov edi, 1
    syscall
    jmp .do_sh
.sk_up:
    mov eax, 1
    mov edi, 1
    lea rsi, [rel s_na]
    mov edx, 3
    syscall

.do_sh:
    mov eax, 1
    mov edi, 1
    lea rsi, [rel ftr]
    mov edx, ftr_len
    syscall
    
    xor edi, edi
    mov eax, 60
    syscall

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

l_up:
    db 10, 'UP: '
l_up_len equ $ - l_up

ftr:
    db 10, 'SH: bash', 10
ftr_len equ $ - ftr

s_na:
    db 'N/A'

p_os:
    db '/etc/os-release', 0
p_up:
    db '/proc/uptime', 0

buf:

filesize equ $ - $$
