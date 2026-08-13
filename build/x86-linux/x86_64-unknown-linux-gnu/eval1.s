# features: emit-with-object-headers=true, redefinable-functions-in-target=(), strict-semantics-for-compiled-set=true, profiler=(), track-expr-names=true, object-canary=(), debug-info=true
	.section .rodata
m_cstr12:
	.asciz "encountered a <symbol> in eval. this shouldn't happen!"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr13:
	.8byte	109
	.8byte	m_cstr12
	.text
m_eval__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	mov	$3, %rax
	cmp	-24(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1
	xor	%rax, %rax
m_L1:
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	$6, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L3
	mov	-8(%rbp), %rax
	jmp	m_L4
m_L3:
	mov	$7, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L5
	mov	-8(%rbp), %rax
	jmp	m_L6
m_L5:
	mov	$12, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L7
	mov	-8(%rbp), %rax
	jmp	m_L8
m_L7:
	mov	$15, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L9
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_eval_2Fvariable__code
	add	$0, %rsp
	jmp	m_L10
m_L9:
	mov	$9, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L11
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr13(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
	jmp	m_L14
m_L11:
	movq	-24(%rbp), %rdi
	movq	-8(%rbp), %rsi
	movq	-16(%rbp), %rdx
	call	m_eval_2Fwith_call_frame__code
	add	$0, %rsp
m_L14:
m_L10:
m_L8:
m_L6:
m_L4:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr15:
	.asciz "eval"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr16:
	.8byte	9
	.8byte	m_cstr15
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_eval:
	.8byte	m_eval__code
	.8byte	m_ostr16
	.globl m_eval__code
	.type m_eval__code, @function
	.text
m_cons__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	$18, %rdi
	movq	$2, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr17:
	.asciz "cons"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr18:
	.8byte	9
	.8byte	m_cstr17
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cons:
	.8byte	m_cons__code
	.8byte	m_ostr18
	.globl m_cons__code
	.type m_cons__code, @function
	.text
m_car__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	test	%rax, %rax
	je	m_L19
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
m_L19:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr21:
	.asciz "car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr22:
	.8byte	7
	.8byte	m_cstr21
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_car:
	.8byte	m_car__code
	.8byte	m_ostr22
	.globl m_car__code
	.type m_car__code, @function
	.text
m_cdr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	test	%rax, %rax
	je	m_L23
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
m_L23:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr25:
	.asciz "cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr26:
	.8byte	7
	.8byte	m_cstr25
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cdr:
	.8byte	m_cdr__code
	.8byte	m_ostr26
	.globl m_cdr__code
	.type m_cdr__code, @function
	.text
m_form__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	$14, %rdi
	movq	$2, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr27:
	.asciz "form"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr28:
	.8byte	9
	.8byte	m_cstr27
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_form:
	.8byte	m_form__code
	.8byte	m_ostr28
	.globl m_form__code
	.type m_form__code, @function
	.text
m__25bitwise_shift__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$64, %rax
	cmp	-24(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L29
	xor	%rax, %rax
	jmp	m_L30
m_L29:
	mov	$64, %rax
	neg	%rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	cmp	-24(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L31
	mov	-8(%rbp), %rax
	test	%rax, %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L32
	mov	$-1, %rax
	jmp	m_L33
m_L32:
	xor	%rax, %rax
m_L33:
	jmp	m_L34
m_L31:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	cmp	-24(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L35
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	-24(%rbp), %rcx
	shl	%cl, %rax
	jmp	m_L36
m_L35:
	mov	-16(%rbp), %rax
	test	%rax, %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L37
	mov	-16(%rbp), %rax
	neg	%rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	-24(%rbp), %rcx
	sar	%cl, %rax
	jmp	m_L38
m_L37:
	mov	-8(%rbp), %rax
m_L38:
m_L36:
m_L34:
m_L30:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr39:
	.asciz "%bitwise-shift"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr40:
	.8byte	29
	.8byte	m_cstr39
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25bitwise_shift:
	.8byte	m__25bitwise_shift__code
	.8byte	m_ostr40
	.globl m__25bitwise_shift__code
	.type m__25bitwise_shift__code, @function
	.text
m_C_string_length__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	xor	%rax, %rax
	mov	%rax, -16(%rbp)
	jmp	m_L42
m_L41:
	mov	-16(%rbp), %rax
	add	$1, %rax
	mov	%rax, -16(%rbp)
m_L42:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	-24(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
	test	%rax, %rax
	jne	m_L41
	mov	-16(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr43:
	.asciz "C-string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr44:
	.8byte	31
	.8byte	m_cstr43
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_C_string_length:
	.8byte	m_C_string_length__code
	.8byte	m_ostr44
	.globl m_C_string_length__code
	.type m_C_string_length__code, @function
	.section .rodata
m_cstr46:
	.asciz "feature/platform/linux"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr47:
	.8byte	45
	.8byte	m_cstr46
	.section .rodata
m_cstr48:
	.asciz "feature/platform/posix"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr49:
	.8byte	45
	.8byte	m_cstr48
	.text
m_code45:
	push	%rbp
	mov	%rsp, %rbp
	push	%rbx
	push	%r12
	push	%r13
	sub	$8, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_ostr47(%rip), %rax
	mov	%rax, %r12
	movq	%r12, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, %r12
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r13
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	%r13, %rdx
	call	m_environment_define__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_ostr49(%rip), %rax
	mov	%rax, %r12
	movq	%r12, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, %r12
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r13
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	%r13, %rdx
	call	m_environment_define__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%r13
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure50:
	.8byte	m_code45
	.8byte	0
	.text
m_main__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	lea	m_oclosure50(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	$0, %rdx
	movq	$1, %rcx
	movq	$2, %r8
	movq	%rbx, %r9
	call	m_main_2Fcommon__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr51:
	.asciz "main"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr52:
	.8byte	9
	.8byte	m_cstr51
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_main:
	.8byte	m_main__code
	.8byte	m_ostr52
	.set main, m_main__code
	.globl main
	.type m_main__code, @function
	.text
m_platform_2Fflush_streams__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr53:
	.asciz "platform/flush-streams"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr54:
	.8byte	45
	.8byte	m_cstr53
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_platform_2Fflush_streams:
	.8byte	m_platform_2Fflush_streams__code
	.8byte	m_ostr54
	.globl m_platform_2Fflush_streams__code
	.type m_platform_2Fflush_streams__code, @function
	.text
m_copy_oops__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	jmp	m_L56
m_L55:
	mov	-32(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	mov	-48(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	-56(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	add	$1, %rax
	mov	%rax, -32(%rbp)
m_L56:
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L55
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr57:
	.asciz "copy-oops"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr58:
	.8byte	19
	.8byte	m_cstr57
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_copy_oops:
	.8byte	m_copy_oops__code
	.8byte	m_ostr58
	.globl m_copy_oops__code
	.type m_copy_oops__code, @function
	.text
m_copy_bytes__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	jmp	m_L60
m_L59:
	mov	-32(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	mov	-48(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	-56(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	movb	-48(%rbp), %al
	movb	%al, (%rcx)
	mov	-32(%rbp), %rax
	add	$1, %rax
	mov	%rax, -32(%rbp)
m_L60:
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L59
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr61:
	.asciz "copy-bytes"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr62:
	.8byte	21
	.8byte	m_cstr61
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_copy_bytes:
	.8byte	m_copy_bytes__code
	.8byte	m_ostr62
	.globl m_copy_bytes__code
	.type m_copy_bytes__code, @function
	.text
m_platform_2Fmove_oops__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	cmp	-32(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L63
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	jmp	m_L65
m_L64:
	mov	-32(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	mov	-48(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	-56(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	add	$1, %rax
	mov	%rax, -32(%rbp)
m_L65:
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L64
	jmp	m_L66
m_L63:
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L67
	mov	-24(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -40(%rbp)
	mov	$-1, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L69
m_L68:
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	mov	-48(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	-56(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-40(%rbp), %rax
	add	$-1, %rax
	mov	%rax, -40(%rbp)
m_L69:
	mov	-32(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L68
	jmp	m_L70
m_L67:
	xor	%rax, %rax
m_L70:
m_L66:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr71:
	.asciz "platform/move-oops"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr72:
	.8byte	37
	.8byte	m_cstr71
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_platform_2Fmove_oops:
	.8byte	m_platform_2Fmove_oops__code
	.8byte	m_ostr72
	.globl m_platform_2Fmove_oops__code
	.type m_platform_2Fmove_oops__code, @function
	.text
m_platform_2Fmove_bytes__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	cmp	-32(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L73
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	jmp	m_L75
m_L74:
	mov	-32(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	mov	-48(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	-56(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	movb	-48(%rbp), %al
	movb	%al, (%rcx)
	mov	-32(%rbp), %rax
	add	$1, %rax
	mov	%rax, -32(%rbp)
m_L75:
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L74
	jmp	m_L76
m_L73:
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L77
	mov	-24(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -40(%rbp)
	mov	$-1, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L79
m_L78:
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	mov	-48(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	-56(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	movb	-48(%rbp), %al
	movb	%al, (%rcx)
	mov	-40(%rbp), %rax
	add	$-1, %rax
	mov	%rax, -40(%rbp)
m_L79:
	mov	-32(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L78
	jmp	m_L80
m_L77:
	xor	%rax, %rax
m_L80:
m_L76:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr81:
	.asciz "platform/move-bytes"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr82:
	.8byte	39
	.8byte	m_cstr81
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_platform_2Fmove_bytes:
	.8byte	m_platform_2Fmove_bytes__code
	.8byte	m_ostr82
	.globl m_platform_2Fmove_bytes__code
	.type m_platform_2Fmove_bytes__code, @function
	.text
m_platform_2Fclear_cells__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	jmp	m_L84
m_L83:
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	mov	-40(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	$0, %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	add	$1, %rax
	mov	%rax, -24(%rbp)
m_L84:
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L83
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr85:
	.asciz "platform/clear-cells"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr86:
	.8byte	41
	.8byte	m_cstr85
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_platform_2Fclear_cells:
	.8byte	m_platform_2Fclear_cells__code
	.8byte	m_ostr86
	.globl m_platform_2Fclear_cells__code
	.type m_platform_2Fclear_cells__code, @function
	.text
m_platform_2Fdiag_print_char__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	lea	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-16(%rbp), %rsi
	mov	$1, %rdx
	syscall
	mov	-8(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr87:
	.asciz "platform/diag-print-char"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr88:
	.8byte	49
	.8byte	m_cstr87
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_platform_2Fdiag_print_char:
	.8byte	m_platform_2Fdiag_print_char__code
	.8byte	m_ostr88
	.globl m_platform_2Fdiag_print_char__code
	.type m_platform_2Fdiag_print_char__code, @function
	.text
m_platform_2Fhalt__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$60, %rax
	mov	-16(%rbp), %rdi
	syscall
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr89:
	.asciz "platform/halt"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr90:
	.8byte	27
	.8byte	m_cstr89
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_platform_2Fhalt:
	.8byte	m_platform_2Fhalt__code
	.8byte	m_ostr90
	.globl m_platform_2Fhalt__code
	.type m_platform_2Fhalt__code, @function
	.section .data
m__2Ainitial_break_2A:
	.8byte	0
	.section .data
m__2Acurrent_break_2A:
	.8byte	0
	.section .rodata
m_cstr94:
	.asciz "SYS_brk failed, aborting"
	.text
m_platform_2Facquire_memory__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	lea	m__2Ainitial_break_2A(%rip), %rax
	mov	(%rax), %rax
	test	%rax, %rax
	je	m_L91
	xor	%rax, %rax
	jmp	m_L92
m_L91:
	mov	$12, %rax
	mov	$0, %rdi
	syscall
	lea	m__2Ainitial_break_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m__2Acurrent_break_2A(%rip), %rcx
	mov	%rax, (%rcx)
m_L92:
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	lea	m__2Acurrent_break_2A(%rip), %rax
	mov	(%rax), %rax
	add	-16(%rbp),%rax
	mov	%rax, -16(%rbp)
	mov	$12, %rax
	mov	-16(%rbp), %rdi
	syscall
	mov	%rax, -16(%rbp)
	lea	m__2Acurrent_break_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	lea	m__2Acurrent_break_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L93
	lea	m_cstr94(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$24, %rdx
	syscall
	movq	$39, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L93:
	mov	-16(%rbp), %rax
	lea	m__2Acurrent_break_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m__2Ainitial_break_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	lea	m__2Ainitial_break_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	lea	m__2Acurrent_break_2A(%rip), %rax
	mov	(%rax), %rax
	sub	-40(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	add	$2, %rax
	add	$4, %rax
	mov	%rax, -48(%rbp)
	mov	$10, %rax
	mov	-32(%rbp), %rdi
	mov	-40(%rbp), %rsi
	mov	-48(%rbp), %rdx
	syscall
	mov	-24(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr96:
	.asciz "platform/acquire-memory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr97:
	.8byte	47
	.8byte	m_cstr96
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_platform_2Facquire_memory:
	.8byte	m_platform_2Facquire_memory__code
	.8byte	m_ostr97
	.globl m_platform_2Facquire_memory__code
	.type m_platform_2Facquire_memory__code, @function
	.section .data
m__25envp:
	.8byte	0
	.text
m_posix_2Fenvp__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$0, %rsp
	lea	m__25envp(%rip), %rax
	mov	(%rax), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr98:
	.asciz "posix/envp"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr99:
	.8byte	21
	.8byte	m_cstr98
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_posix_2Fenvp:
	.8byte	m_posix_2Fenvp__code
	.8byte	m_ostr99
	.globl m_posix_2Fenvp__code
	.type m_posix_2Fenvp__code, @function
	.text
m__start__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	lea	8(%rbp), %rax
	mov	%rax, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	add	$8, %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	add	$1, %rax
	mov	$8, %rcx
	mul	%rcx
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	add	-32(%rbp),%rax
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	lea	m__25envp(%rip), %rcx
	mov	%rax, (%rcx)
	movq	-16(%rbp), %rdi
	movq	-24(%rbp), %rsi
	call	m_main__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$60, %rax
	mov	-40(%rbp), %rdi
	syscall
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr100:
	.asciz "_start"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr101:
	.8byte	13
	.8byte	m_cstr100
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__start:
	.8byte	m__start__code
	.8byte	m_ostr101
	.set _start, m__start__code
	.globl _start
	.type m__start__code, @function
	.section .data
m__2Aglobals_2A:
	.8byte	0
	.section .data
m__2Amaru_2A:
	.8byte	0
	.section .data
m__2Asymbols_2A:
	.8byte	0
	.section .data
m__2Aexpanders_var_2A:
	.8byte	0
	.section .data
m__2Aencoders_var_2A:
	.8byte	0
	.section .data
m__2Aevaluators_var_2A:
	.8byte	0
	.section .data
m__2Aapplicators_var_2A:
	.8byte	0
	.section .data
m_fixed_primitive_function_2Fquote:
	.8byte	0
	.section .data
m_fixed_primitive_function_2Flambda:
	.8byte	0
	.section .data
m_fixed_primitive_function_2Flet:
	.8byte	0
	.section .data
m_fixed_primitive_function_2Fdefine:
	.8byte	0
	.section .data
m_fixed_primitive_function_2Fset:
	.8byte	0
	.section .data
m__2Bend_2B:
	.8byte	0
	.section .rodata
m_cstr107:
	.asciz "\033[34m"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr108:
	.8byte	11
	.8byte	m_cstr107
	.section .rodata
m_cstr109:
	.asciz "\033[0m"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr110:
	.8byte	9
	.8byte	m_cstr109
	.section .rodata
m_cstr111:
	.asciz ": "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr112:
	.8byte	5
	.8byte	m_cstr111
	.section .rodata
m_cstr113:
	.asciz "\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr114:
	.8byte	3
	.8byte	m_cstr113
	.section .rodata
m_cstr117:
	.asciz "\011callee:\011"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr118:
	.8byte	19
	.8byte	m_cstr117
	.section .rodata
m_cstr119:
	.asciz "\033[32m"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr120:
	.8byte	11
	.8byte	m_cstr119
	.section .rodata
m_cstr121:
	.asciz "\033[0m"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr122:
	.8byte	9
	.8byte	m_cstr121
	.section .rodata
m_cstr123:
	.asciz "\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr124:
	.8byte	3
	.8byte	m_cstr123
	.section .rodata
m_cstr127:
	.asciz "\011expr: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr128:
	.8byte	15
	.8byte	m_cstr127
	.section .rodata
m_cstr129:
	.asciz "\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr130:
	.8byte	3
	.8byte	m_cstr129
	.section .rodata
m_cstr131:
	.asciz "\011env: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr132:
	.8byte	13
	.8byte	m_cstr131
	.section .rodata
m_cstr133:
	.asciz "\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr134:
	.8byte	3
	.8byte	m_cstr133
	.section .rodata
m_cstr138:
	.asciz "\011arg "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr139:
	.8byte	11
	.8byte	m_cstr138
	.section .rodata
m_cstr140:
	.asciz ":\011"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr141:
	.8byte	5
	.8byte	m_cstr140
	.section .rodata
m_cstr142:
	.asciz "\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr143:
	.8byte	3
	.8byte	m_cstr142
	.text
m_print_backtrace__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$96, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	xor	%rax, %rax
	mov	%rax, -16(%rbp)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L103
m_L102:
	call	m_platform_2Fflush_streams__code
	add	$0, %rsp
	lea	m__2Acall_stack_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-16(%rbp), %rdi
	call	m_long__3Estring__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	lea	m_symbol_2Fexpand(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	-48(%rbp), %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L104
	lea	m_symbol_2Fencode(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	-48(%rbp), %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L104:
	mov	%rax, -56(%rbp)
	movq	-40(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	$3, %rax
	sub	-64(%rbp), %rax
	mov	%rax, -64(%rbp)
	jmp	m_L106
m_L105:
	movq	-40(%rbp), %rdi
	movq	$0, %rsi
	movq	$32, %rdx
	call	m_string_insert__code
	add	$0, %rsp
m_L106:
	mov	-64(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -64(%rbp)
	mov	%rax, -72(%rbp)
	xor	%rax, %rax
	cmp	-72(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L105
	lea	m_ostr108(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr110(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr112(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr114(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	test	%rax, %rax
	je	m_L115
	xor	%rax, %rax
	jmp	m_L116
m_L115:
	lea	m_ostr118(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr120(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr122(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr124(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
m_L116:
	lea	m__2Aerror_level_2A(%rip), %rax
	mov	(%rax), %rax
	cmp	$1, %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L125
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -64(%rbp)
	mov	-56(%rbp), %rax
	test	%rax, %rax
	je	m_L126
	lea	m_ostr128(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-64(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr130(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr132(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr134(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	jmp	m_L135
m_L126:
	xor	%rax, %rax
	mov	%rax, -72(%rbp)
	mov	-64(%rbp), %rax
	mov	%rax, -80(%rbp)
	jmp	m_L137
m_L136:
	movq	-80(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -88(%rbp)
	lea	m_ostr139(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-72(%rbp), %rdi
	call	m_long__3Estring__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr141(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-88(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr143(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
	add	$1, %rax
	mov	%rax, -72(%rbp)
	movq	-80(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
m_L137:
	mov	-80(%rbp), %rax
	test	%rax, %rax
	jne	m_L136
m_L135:
m_L125:
	mov	-16(%rbp), %rax
	add	$1, %rax
	mov	%rax, -16(%rbp)
m_L103:
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L102
	call	m_platform_2Fflush_streams__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr145:
	.asciz "print-backtrace"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr146:
	.8byte	31
	.8byte	m_cstr145
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_print_backtrace:
	.8byte	m_print_backtrace__code
	.8byte	m_ostr146
	.globl m_print_backtrace__code
	.type m_print_backtrace__code, @function
	.text
m_capture_well_known_globals__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	xor	%rax, %rax
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -8(%rbp)
	lea	m_symbol_2F_2Aexpanders_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	lea	m__2Aexpanders_var_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_symbol_2F_2Aencoders_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	lea	m__2Aencoders_var_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_symbol_2F_2Aevaluators_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	lea	m__2Aevaluators_var_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_symbol_2F_2Aapplicators_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	lea	m__2Aapplicators_var_2A(%rip), %rcx
	mov	%rax, (%rcx)
	xor	%rax, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr147:
	.asciz "capture-well-known-globals"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr148:
	.8byte	53
	.8byte	m_cstr147
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_capture_well_known_globals:
	.8byte	m_capture_well_known_globals__code
	.8byte	m_ostr148
	.globl m_capture_well_known_globals__code
	.type m_capture_well_known_globals__code, @function
	.text
m_print__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr149:
	.asciz "print"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr150:
	.8byte	11
	.8byte	m_cstr149
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_print:
	.8byte	m_print__code
	.8byte	m_ostr150
	.globl m_print__code
	.type m_print__code, @function
	.text
m_println__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	$10, %rsi
	call	m__24put__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr151:
	.asciz "println"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr152:
	.8byte	15
	.8byte	m_cstr151
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_println:
	.8byte	m_println__code
	.8byte	m_ostr152
	.globl m_println__code
	.type m_println__code, @function
	.text
m_read__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_read_toplevel__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr153:
	.asciz "read"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr154:
	.8byte	9
	.8byte	m_cstr153
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read:
	.8byte	m_read__code
	.8byte	m_ostr154
	.globl m_read__code
	.type m_read__code, @function
	.section .rodata
m_cstr156:
	.asciz "infinite recursion guard triggered at call depth "
	.section .rodata
m_cstr157:
	.asciz "\012"
	.text
m_encode__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	lea	m_symbol_2Fencode(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	xor	%rax, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-8(%rbp), %rdx
	call	m__25new_call_frame__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m__2Acall_stack_index_2A(%rip), %rcx
	mov	%rax, (%rcx)
	cmp	$10000, %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L155
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr156(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$49, %rdx
	syscall
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	$10, %rsi
	movq	%r12, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr157(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L155:
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	24(%rax), %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L159
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_encode_2Fpair__code
	add	$0, %rsp
	jmp	m_L160
m_L159:
	movq	-8(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L161
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_encode_2Fsymbol__code
	add	$0, %rsp
	jmp	m_L162
m_L161:
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	lea	m__2Aencoders_var_2A(%rip), %rax
	mov	(%rax), %rax
	test	%rax, %rax
	je	m_L163
	lea	m__2Aencoders_var_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	mov	$10, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_maybe_object_in_variable__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	test	%rax, %rax
	je	m_L163
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-32(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_array_at__code
	add	$0, %rsp
m_L163:
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L164
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_list2__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_apply__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	jmp	m_L165
m_L164:
	mov	-8(%rbp), %rax
m_L165:
m_L162:
m_L160:
	mov	%rax, -24(%rbp)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	sub	$1, %rax
	lea	m__2Acall_stack_index_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L166
	lea	m__2Acall_stack_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
m_L166:
	mov	-24(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr168:
	.asciz "encode"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr169:
	.8byte	13
	.8byte	m_cstr168
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_encode:
	.8byte	m_encode__code
	.8byte	m_ostr169
	.globl m_encode__code
	.type m_encode__code, @function
	.section .rodata
m_cstr171:
	.asciz "infinite recursion guard triggered at call depth "
	.section .rodata
m_cstr172:
	.asciz "\012"
	.text
m_expand__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	lea	m_symbol_2Fexpand(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	xor	%rax, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-8(%rbp), %rdx
	call	m__25new_call_frame__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m__2Acall_stack_index_2A(%rip), %rcx
	mov	%rax, (%rcx)
	cmp	$10000, %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L170
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr171(%rip), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-40(%rbp), %rsi
	mov	$49, %rdx
	syscall
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	$10, %rsi
	movq	%r12, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr172(%rip), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-40(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L170:
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	24(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L174
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	movq	-32(%rbp), %rcx
	call	m_expand_2Fpair__code
	add	$0, %rsp
	jmp	m_L175
m_L174:
	movq	-8(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L176
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand_2Fsymbol__code
	add	$0, %rsp
	jmp	m_L177
m_L176:
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	lea	m__2Aexpanders_var_2A(%rip), %rax
	mov	(%rax), %rax
	test	%rax, %rax
	je	m_L178
	lea	m__2Aexpanders_var_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	mov	$10, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_maybe_object_in_variable__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	test	%rax, %rax
	je	m_L178
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-40(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_array_at__code
	add	$0, %rsp
m_L178:
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	test	%rax, %rax
	je	m_L179
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-40(%rbp), %rdi
	movq	-48(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_apply__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	jmp	m_L180
m_L179:
	mov	-8(%rbp), %rax
m_L180:
m_L177:
m_L175:
	mov	%rax, -32(%rbp)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	sub	$1, %rax
	lea	m__2Acall_stack_index_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	cmp	-40(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L181
	lea	m__2Acall_stack_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
m_L181:
	mov	-32(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr183:
	.asciz "expand"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr184:
	.8byte	13
	.8byte	m_cstr183
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_expand:
	.8byte	m_expand__code
	.8byte	m_ostr184
	.globl m_expand__code
	.type m_expand__code, @function
	.text
m_code185:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_string_compare__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure186:
	.8byte	m_code185
	.8byte	0
	.text
m_code187:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_symbol__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-32(%rbp), %rdx
	call	m_array_insert__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure188:
	.8byte	m_code187
	.8byte	0
	.text
m_string__3Esymbol__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	push	%r13
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	lea	m__2Asymbols_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_oclosure186(%rip), %rax
	mov	%rax, %r12
	lea	m_oclosure188(%rip), %rax
	mov	%rax, %r13
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	movq	%r12, %rdx
	movq	%r13, %rcx
	call	m_array_binary_search__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%r13
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr189:
	.asciz "string->symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr190:
	.8byte	29
	.8byte	m_cstr189
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string__3Esymbol:
	.8byte	m_string__3Esymbol__code
	.8byte	m_ostr190
	.globl m_string__3Esymbol__code
	.type m_string__3Esymbol__code, @function
	.section .rodata
m_cstr192:
	.asciz "kernel accessor type error: expected type id "
	.section .rodata
m_cstr193:
	.asciz ", got "
	.section .rodata
m_cstr194:
	.asciz "\012"
	.section .rodata
m_cstr195:
	.asciz "\012"
	.text
m__25accessor_typecheck__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-16(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L191
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr192(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$45, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	$10, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr193(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$6, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-24(%rbp), %rdi
	movq	$10, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr194(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$1, %rdx
	syscall
	lea	m_cstr195(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L191:
	mov	-16(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr196:
	.asciz "%accessor-typecheck"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr197:
	.8byte	39
	.8byte	m_cstr196
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25accessor_typecheck:
	.8byte	m__25accessor_typecheck__code
	.8byte	m_ostr197
	.globl m__25accessor_typecheck__code
	.type m__25accessor_typecheck__code, @function
	.section .rodata
m_cstr199:
	.asciz "ABORTING at error level "
	.section .rodata
m_cstr200:
	.asciz "\012"
	.text
m_abort__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	lea	m__2Aerror_level_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -8(%rbp)
	mov	$3, %rax
	cmp	-8(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L198
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr199(%rip), %rax
	mov	%rax, -8(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-8(%rbp), %rsi
	mov	$24, %rdx
	syscall
	lea	m__2Aerror_level_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	$10, %rsi
	movq	%r12, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr200(%rip), %rax
	mov	%rax, -8(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-8(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L198:
	call	m_print_backtrace__code
	add	$0, %rsp
	call	m_platform_2Fflush_streams__code
	add	$0, %rsp
	movq	$18, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr202:
	.asciz "abort"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr203:
	.8byte	11
	.8byte	m_cstr202
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_abort:
	.8byte	m_abort__code
	.8byte	m_ostr203
	.globl m_abort__code
	.type m_abort__code, @function
	.text
m__25string__3EC_string__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_string_ensure_zero_terminated__code
	add	$0, %rsp
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr204:
	.asciz "%string->C-string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr205:
	.8byte	35
	.8byte	m_cstr204
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25string__3EC_string:
	.8byte	m__25string__3EC_string__code
	.8byte	m_ostr205
	.globl m__25string__3EC_string__code
	.type m__25string__3EC_string__code, @function
	.section .rodata
m_cstr208:
	.asciz "kernel assertion failed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr209:
	.8byte	47
	.8byte	m_cstr208
	.text
m_long__3Estring_2Femit__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	cmp	-32(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L207
	mov	-16(%rbp), %rax
	cmp	$35, %rax
	setle	%al
	movzb	%al, %rax
m_L207:
	test	%rax, %rax
	jne	m_L206
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr209(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L206:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L210
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_positive_long__3Estring__code
	add	$0, %rsp
	jmp	m_L211
m_L210:
	movq	$45, %rdi
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	mov	-8(%rbp), %rax
	neg	%rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_positive_long__3Estring__code
	add	$0, %rsp
m_L211:
	mov	-8(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr212:
	.asciz "long->string/emit"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr213:
	.8byte	35
	.8byte	m_cstr212
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_long__3Estring_2Femit:
	.8byte	m_long__3Estring_2Femit__code
	.8byte	m_ostr213
	.globl m_long__3Estring_2Femit__code
	.type m_long__3Estring_2Femit__code, @function
	.section .data
m_symbol_2F_2Astandard_input_2A:
	.8byte	0
	.section .data
m_symbol_2F_2Astandard_output_2A:
	.8byte	0
	.section .data
m_symbol_2F_2Aerror_output_2A:
	.8byte	0
	.section .data
m_symbol_2F_2Adebug_output_2A:
	.8byte	0
	.text
m_environment_define__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_find_local_variable__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L214
	jmp	m_L215
m_L214:
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_new_variable__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
m_L215:
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr216:
	.asciz "environment-define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr217:
	.8byte	37
	.8byte	m_cstr216
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_environment_define:
	.8byte	m_environment_define__code
	.8byte	m_ostr217
	.globl m_environment_define__code
	.type m_environment_define__code, @function
	.text
m_defined_3F__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L219
m_L218:
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
m_L219:
	mov	-16(%rbp), %rax
	test	%rax, %rax
	je	m_L220
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_find_local_variable__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
m_L220:
	test	%rax, %rax
	jne	m_L218
	mov	-24(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr221:
	.asciz "defined?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr222:
	.8byte	17
	.8byte	m_cstr221
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_defined_3F:
	.8byte	m_defined_3F__code
	.8byte	m_ostr222
	.globl m_defined_3F__code
	.type m_defined_3F__code, @function
	.section .rodata
m_cstr225:
	.asciz "variable-value: '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr226:
	.8byte	35
	.8byte	m_cstr225
	.section .rodata
m_cstr227:
	.asciz "' is not defined in env "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr228:
	.8byte	49
	.8byte	m_cstr227
	.text
m_variable_value__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L223
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	jmp	m_L224
m_L223:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr226(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr228(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L224:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr229:
	.asciz "variable-value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr230:
	.8byte	29
	.8byte	m_cstr229
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_variable_value:
	.8byte	m_variable_value__code
	.8byte	m_ostr230
	.globl m_variable_value__code
	.type m_variable_value__code, @function
	.text
m_set_variable_value__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L231
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	jmp	m_L232
m_L231:
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_environment_define__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
m_L232:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr233:
	.asciz "set-variable-value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr234:
	.8byte	37
	.8byte	m_cstr233
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_variable_value:
	.8byte	m_set_variable_value__code
	.8byte	m_ostr234
	.globl m_set_variable_value__code
	.type m_set_variable_value__code, @function
	.text
m_main_2Fcommon__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	movq	%r8, -40(%rbp)
	movq	%r9, -48(%rbp)
	call	m_initialize_vm__code
	add	$0, %rsp
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	movq	-40(%rbp), %rdx
	call	m_initialize_streams__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	test	%rax, %rax
	je	m_L235
	mov	-48(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
m_L235:
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_process_command_line_arguments__code
	add	$0, %rsp
	xor	%rax, %rax
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L237
	call	m_gc_2Fcollect__code
	add	$0, %rsp
	call	m_gc_2Fprint_statistics__code
	add	$0, %rsp
m_L237:
	xor	%rax, %rax
	call	m_platform_2Fflush_streams__code
	add	$0, %rsp
	xor	%rax, %rax
	xor	%rax, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr239:
	.asciz "main/common"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr240:
	.8byte	23
	.8byte	m_cstr239
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_main_2Fcommon:
	.8byte	m_main_2Fcommon__code
	.8byte	m_ostr240
	.globl m_main_2Fcommon__code
	.type m_main_2Fcommon__code, @function
	.section .data
m__2Acall_stack_index_2A:
	.8byte	0
	.section .data
m__2Acall_stack_2A:
	.8byte	0
	.section .data
m__2Averbosity_2A:
	.8byte	0
	.section .data
m__2Aoptimised_2A:
	.8byte	0
	.text
m_max__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	cmp	-24(%rbp), %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L241
	mov	-8(%rbp), %rax
	jmp	m_L242
m_L241:
	mov	-16(%rbp), %rax
m_L242:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr243:
	.asciz "max"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr244:
	.8byte	7
	.8byte	m_cstr243
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_max:
	.8byte	m_max__code
	.8byte	m_ostr244
	.globl m_max__code
	.type m_max__code, @function
	.text
m_min__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	cmp	-24(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L245
	mov	-8(%rbp), %rax
	jmp	m_L246
m_L245:
	mov	-16(%rbp), %rax
m_L246:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr247:
	.asciz "min"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr248:
	.8byte	7
	.8byte	m_cstr247
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_min:
	.8byte	m_min__code
	.8byte	m_ostr248
	.globl m_min__code
	.type m_min__code, @function
	.text
m_zero_3F__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr249:
	.asciz "zero?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr250:
	.8byte	11
	.8byte	m_cstr249
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_zero_3F:
	.8byte	m_zero_3F__code
	.8byte	m_ostr250
	.globl m_zero_3F__code
	.type m_zero_3F__code, @function
	.section .rodata
m_cstr251:
	.asciz "\012FATAL: "
	.text
m_fatal_prologue__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	call	m_platform_2Fflush_streams__code
	add	$0, %rsp
	lea	m_cstr251(%rip), %rax
	mov	%rax, -8(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-8(%rbp), %rsi
	mov	$8, %rdx
	syscall
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr252:
	.asciz "fatal-prologue"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr253:
	.8byte	29
	.8byte	m_cstr252
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_fatal_prologue:
	.8byte	m_fatal_prologue__code
	.8byte	m_ostr253
	.globl m_fatal_prologue__code
	.type m_fatal_prologue__code, @function
	.section .data
m__2Aerror_level_2A:
	.8byte	0
	.section .rodata
m_cstr257:
	.asciz "WARNING: error-prologue was reached too early in init. We'll most probably crash before printing the actual error message.\012"
	.section .rodata
m_cstr259:
	.asciz "NESTED ERROR 1, attempting to print a limited backtrace\012"
	.section .rodata
m_cstr262:
	.asciz "NESTED ERROR 2, giving up...\012"
	.section .rodata
m_cstr264:
	.asciz "\012ERROR: "
	.text
m_error_prologue__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	lea	m__2Aerror_level_2A(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m__2Aerror_level_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m__2Asymbols_2A(%rip), %rax
	mov	(%rax), %rax
	test	%rax, %rax
	je	m_L255
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
m_L255:
	test	%rax, %rax
	je	m_L254
	xor	%rax, %rax
	jmp	m_L256
m_L254:
	lea	m_cstr257(%rip), %rax
	mov	%rax, -8(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-8(%rbp), %rsi
	mov	$123, %rdx
	syscall
m_L256:
	lea	m__2Aerror_level_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -8(%rbp)
	mov	$2, %rax
	cmp	-8(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L258
	lea	m_cstr259(%rip), %rax
	mov	%rax, -8(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-8(%rbp), %rsi
	mov	$56, %rdx
	syscall
	call	m_abort__code
	add	$0, %rsp
	jmp	m_L260
m_L258:
	lea	m__2Aerror_level_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -8(%rbp)
	mov	$2, %rax
	cmp	-8(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L261
	lea	m_cstr262(%rip), %rax
	mov	%rax, -8(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-8(%rbp), %rsi
	mov	$29, %rdx
	syscall
	movq	$19, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
	jmp	m_L263
m_L261:
	xor	%rax, %rax
m_L263:
m_L260:
	lea	m_cstr264(%rip), %rax
	mov	%rax, -8(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-8(%rbp), %rsi
	mov	$8, %rdx
	syscall
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr265:
	.asciz "error-prologue"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr266:
	.8byte	29
	.8byte	m_cstr265
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_error_prologue:
	.8byte	m_error_prologue__code
	.8byte	m_ostr266
	.globl m_error_prologue__code
	.type m_error_prologue__code, @function
	.section .rodata
m_cstr267:
	.asciz "\012"
	.text
m_error_epilogue__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	lea	m_cstr267(%rip), %rax
	mov	%rax, -8(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-8(%rbp), %rsi
	mov	$1, %rdx
	syscall
	call	m_abort__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr268:
	.asciz "error-epilogue"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr269:
	.8byte	29
	.8byte	m_cstr268
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_error_epilogue:
	.8byte	m_error_epilogue__code
	.8byte	m_ostr269
	.globl m_error_epilogue__code
	.type m_error_epilogue__code, @function
	.text
m__25error__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr270:
	.asciz "%error"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr271:
	.8byte	13
	.8byte	m_cstr270
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25error:
	.8byte	m__25error__code
	.8byte	m_ostr271
	.globl m__25error__code
	.type m__25error__code, @function
	.section .rodata
m_cstr272:
	.asciz ": not enough arguments: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr273:
	.8byte	49
	.8byte	m_cstr272
	.text
m__25not_enough_arguments__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	call	m_error_prologue__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr273(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr274:
	.asciz "%not-enough-arguments"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr275:
	.8byte	43
	.8byte	m_cstr274
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25not_enough_arguments:
	.8byte	m__25not_enough_arguments__code
	.8byte	m_ostr275
	.globl m__25not_enough_arguments__code
	.type m__25not_enough_arguments__code, @function
	.section .rodata
m_cstr276:
	.asciz ": too many arguments: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr277:
	.8byte	45
	.8byte	m_cstr276
	.text
m__25too_many_arguments__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	call	m_error_prologue__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr277(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr278:
	.asciz "%too-many-arguments"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr279:
	.8byte	39
	.8byte	m_cstr278
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25too_many_arguments:
	.8byte	m__25too_many_arguments__code
	.8byte	m_ostr279
	.globl m__25too_many_arguments__code
	.type m__25too_many_arguments__code, @function
	.text
m_abort_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	call	m_abort__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr280:
	.asciz "abort/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr281:
	.8byte	41
	.8byte	m_cstr280
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_abort_2Fevaluator_stub:
	.8byte	m_abort_2Fevaluator_stub__code
	.8byte	m_ostr281
	.globl m_abort_2Fevaluator_stub__code
	.type m_abort_2Fevaluator_stub__code, @function
	.section .data
m_gc_2Fminimum_growth_unit:
	.8byte	51200
	.section .data
m_gc_2Fallocations_until_gc:
	.8byte	131072
	.section .data
m_gc_2Fobjects_live:
	.8byte	0
	.section .data
m_gc_2Fbytes_used:
	.8byte	0
	.section .data
m_gc_2Fbytes_free:
	.8byte	0
	.section .data
m_gc_2Froots:
	.8byte	0
	.section .data
m_gc_2Froot_count:
	.8byte	0
	.section .data
m_gc_2Froot_max:
	.8byte	0
	.section .data
m_gc_2Fmemory_base:
	.8byte	0
	.section .data
m_gc_2Flowest_memory_address:
	.8byte	0
	.section .data
m_gc_2Fmemory_last:
	.8byte	0
	.section .data
m_gc_2Falloc_count:
	.8byte	0
	.section .data
m_gc_2Fcollection_count:
	.8byte	0
	.section .rodata
m_cstr283:
	.asciz "out of memory"
	.section .rodata
m_cstr284:
	.asciz "\012"
	.section .rodata
m_cstr288:
	.asciz "gc/acquire-new-heap-space: aligned-to-oop? has failed for ptr "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr289:
	.8byte	125
	.8byte	m_cstr288
	.text
m_gc_2Facquire_new_heap_space__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_platform_2Facquire_memory__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	-16(%rbp), %rax
	test	%rax, %rax
	jne	m_L282
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr283(%rip), %rax
	mov	%rax, -24(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-24(%rbp), %rsi
	mov	$13, %rdx
	syscall
	lea	m_cstr284(%rip), %rax
	mov	%rax, -24(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-24(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L282:
	lea	m_gc_2Flowest_memory_address(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	cmp	-24(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L285
	mov	-16(%rbp), %rax
	lea	m_gc_2Flowest_memory_address(%rip), %rcx
	mov	%rax, (%rcx)
m_L285:
	mov	-8(%rbp), %rax
	sub	$32, %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	$0, %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	-16(%rbp), %rax
	and	$7, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L287
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr289(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L287:
	mov	-16(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr290:
	.asciz "gc/acquire-new-heap-space"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr291:
	.8byte	51
	.8byte	m_cstr290
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Facquire_new_heap_space:
	.8byte	m_gc_2Facquire_new_heap_space__code
	.8byte	m_ostr291
	.globl m_gc_2Facquire_new_heap_space__code
	.type m_gc_2Facquire_new_heap_space__code, @function
	.text
m_gc_2Fgrow_heap__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_gc_2Facquire_new_heap_space__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	m_gc_2Fmemory_last(%rip), %rax
	mov	(%rax), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	m_gc_2Fmemory_last(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr292:
	.asciz "gc/grow-heap"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr293:
	.8byte	25
	.8byte	m_cstr292
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fgrow_heap:
	.8byte	m_gc_2Fgrow_heap__code
	.8byte	m_ostr293
	.globl m_gc_2Fgrow_heap__code
	.type m_gc_2Fgrow_heap__code, @function
	.text
m_gc_2Fobject_size__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	sub	$32, %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr294:
	.asciz "gc/object-size"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr295:
	.8byte	29
	.8byte	m_cstr294
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fobject_size:
	.8byte	m_gc_2Fobject_size__code
	.8byte	m_ostr295
	.globl m_gc_2Fobject_size__code
	.type m_gc_2Fobject_size__code, @function
	.text
m__25next_object_from_header__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	jmp	m_L297
m_L296:
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -8(%rbp)
	lea	m_gc_2Fmemory_base(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L298
	xor	%rax, %rax
	jmp	m_L299
m_L298:
m_L297:
	mov	-8(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -16(%rbp)
	mov	$1, %rax
	and	-16(%rbp), %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L296
	mov	-8(%rbp), %rax
	add	$32, %rax
m_L299:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr301:
	.asciz "%next-object-from-header"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr302:
	.8byte	49
	.8byte	m_cstr301
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25next_object_from_header:
	.8byte	m__25next_object_from_header__code
	.8byte	m_ostr302
	.globl m__25next_object_from_header__code
	.type m__25next_object_from_header__code, @function
	.text
m_gc_2Ffirst_object__code:
	push	%rbp
	mov	%rsp, %rbp
	push	%rbx
	sub	$8, %rsp
	lea	m_gc_2Fmemory_base(%rip), %rax
	mov	(%rax), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25next_object_from_header__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr303:
	.asciz "gc/first-object"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr304:
	.8byte	31
	.8byte	m_cstr303
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Ffirst_object:
	.8byte	m_gc_2Ffirst_object__code
	.8byte	m_ostr304
	.globl m_gc_2Ffirst_object__code
	.type m_gc_2Ffirst_object__code, @function
	.text
m_gc_2Fnext_object__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	test	%rax, %rax
	je	m_L305
	mov	-8(%rbp), %rax
	sub	$32, %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25next_object_from_header__code
	add	$0, %rsp
m_L305:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr307:
	.asciz "gc/next-object"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr308:
	.8byte	29
	.8byte	m_cstr307
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fnext_object:
	.8byte	m_gc_2Fnext_object__code
	.8byte	m_ostr308
	.globl m_gc_2Fnext_object__code
	.type m_gc_2Fnext_object__code, @function
	.text
m_gc_2Fsweep__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	xor	%rax, %rax
	lea	m_gc_2Fmemory_base(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -8(%rbp)
	xor	%rax, %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L310
m_L309:
	mov	-8(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	and	$4, %rax
	test	%rax, %rax
	je	m_L311
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	add	-48(%rbp),%rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	add	$1, %rax
	mov	%rax, -16(%rbp)
	mov	-40(%rbp), %rax
	xor	$4, %rax
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	jmp	m_L312
m_L311:
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	add	-48(%rbp),%rax
	mov	%rax, -32(%rbp)
	mov	-8(%rbp), %rax
	lea	16(%rax), %rcx
	mov	$0, %rax
	mov	%rax, (%rcx)
	mov	-8(%rbp), %rax
	lea	24(%rax), %rcx
	mov	$0, %rax
	mov	%rax, (%rcx)
m_L312:
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -8(%rbp)
	lea	m_gc_2Fmemory_base(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L313
	xor	%rax, %rax
	mov	%rax, -8(%rbp)
m_L313:
m_L310:
	mov	-8(%rbp), %rax
	test	%rax, %rax
	jne	m_L309
	mov	-16(%rbp), %rax
	lea	m_gc_2Fobjects_live(%rip), %rcx
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	lea	m_gc_2Fbytes_used(%rip), %rcx
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	lea	m_gc_2Fbytes_free(%rip), %rcx
	mov	%rax, (%rcx)
	xor	%rax, %rax
	xor	%rax, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr315:
	.asciz "gc/sweep"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr316:
	.8byte	17
	.8byte	m_cstr315
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fsweep:
	.8byte	m_gc_2Fsweep__code
	.8byte	m_ostr316
	.globl m_gc_2Fsweep__code
	.type m_gc_2Fsweep__code, @function
	.section .rodata
m_cstr320:
	.asciz "gc/mark-and-trace: reached a dead object: "
	.section .rodata
m_cstr321:
	.asciz "0x"
	.section .rodata
m_cstr322:
	.asciz "\012"
	.text
m_gc_2Fmark_and_trace__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	test	%rax, %rax
	je	m_L318
	mov	-8(%rbp), %rax
	and	$7, %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L318:
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L317
	lea	m_gc_2Flowest_memory_address(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	cmp	-16(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L317
	mov	-8(%rbp), %rax
	sub	$32, %rax
	mov	%rax, -16(%rbp)
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	and	-32(%rbp), %rax
	test	%rax, %rax
	jne	m_L319
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr320(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$42, %rdx
	syscall
	lea	m_cstr321(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$2, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	$16, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr322(%rip), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-32(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L319:
	mov	-24(%rbp), %rax
	and	$4, %rax
	test	%rax, %rax
	jne	m_L323
	mov	-24(%rbp), %rax
	or	$4, %rax
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	and	$2, %rax
	test	%rax, %rax
	jne	m_L324
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	xor	%rdx, %rdx
	mov	$8, %rcx
	idiv	%rcx
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	jmp	m_L326
m_L325:
	mov	-32(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	mov	-40(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fmark_and_trace__code
	add	$0, %rsp
m_L326:
	mov	-32(%rbp), %rax
	test	%rax, %rax
	jne	m_L325
m_L324:
m_L323:
m_L317:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr327:
	.asciz "gc/mark-and-trace"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr328:
	.8byte	35
	.8byte	m_cstr327
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fmark_and_trace:
	.8byte	m_gc_2Fmark_and_trace__code
	.8byte	m_ostr328
	.globl m_gc_2Fmark_and_trace__code
	.type m_gc_2Fmark_and_trace__code, @function
	.text
m_gc_2Fcollect__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	lea	m_gc_2Fcollection_count(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m_gc_2Fcollection_count(%rip), %rcx
	mov	%rax, (%rcx)
	xor	%rax, %rax
	xor	%rax, %rax
	lea	m_gc_2Froots(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fmark_and_trace__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -8(%rbp)
	lea	m_gc_2Froot_count(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	jmp	m_L330
m_L329:
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	m_gc_2Froots(%rip), %rax
	mov	(%rax), %rax
	mov	-24(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	movq	-32(%rbp), %rdi
	call	m_gc_2Fmark_and_trace__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	add	$1, %rax
	mov	%rax, -8(%rbp)
m_L330:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L329
	xor	%rax, %rax
	call	m_gc_2Fsweep__code
	add	$0, %rsp
	xor	%rax, %rax
	lea	m_gc_2Falloc_count(%rip), %rcx
	mov	%rax, (%rcx)
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr331:
	.asciz "gc/collect"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr332:
	.8byte	21
	.8byte	m_cstr331
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fcollect:
	.8byte	m_gc_2Fcollect__code
	.8byte	m_ostr332
	.globl m_gc_2Fcollect__code
	.type m_gc_2Fcollect__code, @function
	.text
m_gc_2Fallocate__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	mov	-16(%rbp), %rax
	add	$7, %rax
	and	$-8, %rax
	mov	%rax, -16(%rbp)
	lea	m_gc_2Fallocations_until_gc(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	lea	m_gc_2Falloc_count(%rip), %rax
	mov	(%rax), %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L333
	call	m_gc_2Fcollect__code
	add	$0, %rsp
m_L333:
	lea	m_gc_2Fmemory_last(%rip), %rax
	mov	(%rax), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	add	$32, %rax
	mov	%rax, -40(%rbp)
	jmp	m_L335
m_L334:
	jmp	m_L337
m_L336:
m_L337:
	xor	%rax, %rax
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	xor	%rax, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L338
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	jmp	m_L340
m_L339:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	-56(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-56(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -64(%rbp)
	mov	$32, %rax
	add	-64(%rbp),%rax
	mov	%rax, -64(%rbp)
	mov	-48(%rbp), %rax
	add	-64(%rbp),%rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	mov	%rax, -48(%rbp)
	lea	m_gc_2Fmemory_last(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -64(%rbp)
	mov	-56(%rbp), %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L341
	mov	-32(%rbp), %rax
	lea	m_gc_2Fmemory_last(%rip), %rcx
	mov	%rax, (%rcx)
m_L341:
m_L340:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L343
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$32, %rax
	add	-56(%rbp),%rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	add	-56(%rbp),%rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L343:
	test	%rax, %rax
	jne	m_L339
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L345
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L345:
	test	%rax, %rax
	je	m_L344
	xor	%rax, %rax
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-48(%rbp), %rax
	cmp	-56(%rbp), %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L346
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	add	-56(%rbp),%rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	mov	-40(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-48(%rbp), %rax
	sub	-64(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-56(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-56(%rbp), %rax
	lea	16(%rax), %rcx
	mov	$0, %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -64(%rbp)
	mov	-56(%rbp), %rax
	mov	%rax, %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -48(%rbp)
m_L346:
	xor	%rax, %rax
	mov	-32(%rbp), %rax
	lea	m_gc_2Fmemory_last(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_gc_2Falloc_count(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m_gc_2Falloc_count(%rip), %rcx
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-56(%rbp), %rax
	add	$32, %rax
	mov	%rax, -64(%rbp)
	mov	-56(%rbp), %rax
	lea	16(%rax), %rcx
	mov	$1, %rax
	mov	%rax, (%rcx)
	mov	-8(%rbp), %rax
	mov	%rax, -72(%rbp)
	mov	-56(%rbp), %rax
	lea	24(%rax), %rcx
	mov	-72(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-48(%rbp), %rax
	xor	%rdx, %rdx
	mov	$8, %rcx
	idiv	%rcx
	mov	%rax, %rbx
	movq	-64(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_platform_2Fclear_cells__code
	add	$0, %rsp
	xor	%rax, %rax
	xor	%rax, %rax
	xor	%rax, %rax
	xor	%rax, %rax
	mov	-64(%rbp), %rax
	jmp	m_L348
m_L344:
m_L338:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L336
	mov	-16(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	$32, %rax
	add	-48(%rbp),%rax
	mov	%rax, %rbx
	lea	m_gc_2Fminimum_growth_unit(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_max__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fgrow_heap__code
	add	$0, %rsp
m_L335:
	mov	$1, %rax
	test	%rax, %rax
	jne	m_L334
m_L348:
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr351:
	.asciz "gc/allocate"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr352:
	.8byte	23
	.8byte	m_cstr351
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fallocate:
	.8byte	m_gc_2Fallocate__code
	.8byte	m_ostr352
	.globl m_gc_2Fallocate__code
	.type m_gc_2Fallocate__code, @function
	.text
m_gc_2Fallocate_opaque__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_gc_2Fallocate__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	sub	$32, %rax
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	or	$2, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr353:
	.asciz "gc/allocate-opaque"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr354:
	.8byte	37
	.8byte	m_cstr353
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fallocate_opaque:
	.8byte	m_gc_2Fallocate_opaque__code
	.8byte	m_ostr354
	.globl m_gc_2Fallocate_opaque__code
	.type m_gc_2Fallocate_opaque__code, @function
	.text
m_gc_2Fgrow_root_vector__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	lea	m_gc_2Froot_max(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -8(%rbp)
	mov	$2, %rax
	mulq	-8(%rbp)
	mov	%rax, %rbx
	movq	$32, %rdi
	movq	%rbx, %rsi
	call	m_max__code
	add	$0, %rsp
	lea	m_gc_2Froot_max(%rip), %rcx
	mov	%rax, (%rcx)
	mov	$5, %rax
	mov	%rax, %rbx
	lea	m_gc_2Froot_max(%rip), %rax
	mov	(%rax), %rax
	mov	$8, %rcx
	mul	%rcx
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_gc_2Fallocate_opaque__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	lea	m_gc_2Froots(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_gc_2Froot_count(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	movq	%r12, %rdx
	call	m_copy_oops__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	m_gc_2Froots(%rip), %rcx
	mov	%rax, (%rcx)
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr355:
	.asciz "gc/grow-root-vector"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr356:
	.8byte	39
	.8byte	m_cstr355
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fgrow_root_vector:
	.8byte	m_gc_2Fgrow_root_vector__code
	.8byte	m_ostr356
	.globl m_gc_2Fgrow_root_vector__code
	.type m_gc_2Fgrow_root_vector__code, @function
	.text
m_gc_2Fpush_root__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	lea	m_gc_2Froot_count(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	lea	m_gc_2Froots(%rip), %rax
	mov	(%rax), %rax
	mov	-24(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	-16(%rbp), %rax
	mov	%rax, (%rcx)
	lea	m_gc_2Froot_count(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m_gc_2Froot_count(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_gc_2Froot_max(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	lea	m_gc_2Froot_count(%rip), %rax
	mov	(%rax), %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L357
	call	m_gc_2Fgrow_root_vector__code
	add	$0, %rsp
m_L357:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr359:
	.asciz "gc/push-root"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr360:
	.8byte	25
	.8byte	m_cstr359
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fpush_root:
	.8byte	m_gc_2Fpush_root__code
	.8byte	m_ostr360
	.globl m_gc_2Fpush_root__code
	.type m_gc_2Fpush_root__code, @function
	.text
m_gc_2Fpop_root__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	lea	m_gc_2Froot_count(%rip), %rax
	mov	(%rax), %rax
	sub	$1, %rax
	lea	m_gc_2Froot_count(%rip), %rcx
	mov	%rax, (%rcx)
	xor	%rax, %rax
	xor	%rax, %rax
	mov	%rax, -16(%rbp)
	lea	m_gc_2Froot_count(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	lea	m_gc_2Froots(%rip), %rax
	mov	(%rax), %rax
	mov	-24(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	-16(%rbp), %rax
	mov	%rax, (%rcx)
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr361:
	.asciz "gc/pop-root"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr362:
	.8byte	23
	.8byte	m_cstr361
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fpop_root:
	.8byte	m_gc_2Fpop_root__code
	.8byte	m_ostr362
	.globl m_gc_2Fpop_root__code
	.type m_gc_2Fpop_root__code, @function
	.text
m_gc_2Finitialize__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	xor	%rax, %rax
	lea	m_gc_2Fminimum_growth_unit(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Facquire_new_heap_space__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-8(%rbp), %rax
	lea	m_gc_2Fmemory_base(%rip), %rcx
	mov	%rax, (%rcx)
	mov	-8(%rbp), %rax
	lea	m_gc_2Flowest_memory_address(%rip), %rcx
	mov	%rax, (%rcx)
	mov	-8(%rbp), %rax
	lea	m_gc_2Fmemory_last(%rip), %rcx
	mov	%rax, (%rcx)
	call	m_gc_2Fgrow_root_vector__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr363:
	.asciz "gc/initialize"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr364:
	.8byte	27
	.8byte	m_cstr363
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Finitialize:
	.8byte	m_gc_2Finitialize__code
	.8byte	m_ostr364
	.globl m_gc_2Finitialize__code
	.type m_gc_2Finitialize__code, @function
	.section .rodata
m_cstr371:
	.asciz "type-of: encountered something unidentifiable: "
	.section .rodata
m_cstr372:
	.asciz "0x"
	.section .rodata
m_cstr373:
	.asciz "\012"
	.text
m_type_of__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L365
	mov	$6, %rax
	jmp	m_L366
m_L365:
	mov	-8(%rbp), %rax
	and	$7, %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L367
	mov	-8(%rbp), %rax
	sub	$32, %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	mov	-16(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	jmp	m_L368
m_L367:
	mov	-8(%rbp), %rax
	and	$1, %rax
	mov	%rax, -16(%rbp)
	mov	$1, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L369
	mov	$7, %rax
	jmp	m_L370
m_L369:
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr371(%rip), %rax
	mov	%rax, -16(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-16(%rbp), %rsi
	mov	$47, %rdx
	syscall
	lea	m_cstr372(%rip), %rax
	mov	%rax, -16(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-16(%rbp), %rsi
	mov	$2, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	$16, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr373(%rip), %rax
	mov	%rax, -16(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-16(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L370:
m_L368:
m_L366:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr374:
	.asciz "type-of"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr375:
	.8byte	15
	.8byte	m_cstr374
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_type_of:
	.8byte	m_type_of__code
	.8byte	m_ostr375
	.globl m_type_of__code
	.type m_type_of__code, @function
	.text
m__25allocate_boxed_word__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	$8, %rsi
	call	m_gc_2Fallocate_opaque__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr376:
	.asciz "%allocate-boxed-word"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr377:
	.8byte	41
	.8byte	m_cstr376
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25allocate_boxed_word:
	.8byte	m__25allocate_boxed_word__code
	.8byte	m_ostr377
	.globl m__25allocate_boxed_word__code
	.type m__25allocate_boxed_word__code, @function
	.text
m_long_3F__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$7, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr378:
	.asciz "long?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr379:
	.8byte	11
	.8byte	m_cstr378
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_long_3F:
	.8byte	m_long_3F__code
	.8byte	m_ostr379
	.globl m_long_3F__code
	.type m_long_3F__code, @function
	.text
m_pair_3F__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$18, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr380:
	.asciz "pair?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr381:
	.8byte	11
	.8byte	m_cstr380
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_pair_3F:
	.8byte	m_pair_3F__code
	.8byte	m_ostr381
	.globl m_pair_3F__code
	.type m_pair_3F__code, @function
	.text
m_string_3F__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$12, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr382:
	.asciz "string?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr383:
	.8byte	15
	.8byte	m_cstr382
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_3F:
	.8byte	m_string_3F__code
	.8byte	m_ostr383
	.globl m_string_3F__code
	.type m_string_3F__code, @function
	.text
m_symbol_3F__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$9, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr384:
	.asciz "symbol?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr385:
	.8byte	15
	.8byte	m_cstr384
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_symbol_3F:
	.8byte	m_symbol_3F__code
	.8byte	m_ostr385
	.globl m_symbol_3F__code
	.type m_symbol_3F__code, @function
	.text
m_array_3F__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$10, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr386:
	.asciz "array?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr387:
	.8byte	13
	.8byte	m_cstr386
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_3F:
	.8byte	m_array_3F__code
	.8byte	m_ostr387
	.globl m_array_3F__code
	.type m_array_3F__code, @function
	.section .data
m_symbol_2Ftrue:
	.8byte	0
	.section .data
m_symbol_2Fdefine:
	.8byte	0
	.section .data
m_symbol_2Fset:
	.8byte	0
	.section .data
m_symbol_2Fquote:
	.8byte	0
	.section .data
m_symbol_2Fquasiquote:
	.8byte	0
	.section .data
m_symbol_2Funquote:
	.8byte	0
	.section .data
m_symbol_2Funquote_splicing:
	.8byte	0
	.section .data
m_symbol_2Fexpand:
	.8byte	0
	.section .data
m_symbol_2Fencode:
	.8byte	0
	.section .data
m_symbol_2Fapply:
	.8byte	0
	.section .data
m_symbol_2F_2E:
	.8byte	0
	.section .data
m_symbol_2Flambda:
	.8byte	0
	.section .data
m_symbol_2Flet:
	.8byte	0
	.section .data
m_symbol_2F_2Aglobals_2A:
	.8byte	0
	.section .data
m_symbol_2F_2Aexpanders_2A:
	.8byte	0
	.section .data
m_symbol_2F_2Aencoders_2A:
	.8byte	0
	.section .data
m_symbol_2F_2Aevaluators_2A:
	.8byte	0
	.section .data
m_symbol_2F_2Aapplicators_2A:
	.8byte	0
	.section .data
m_symbol_2F_2Averbosity_2A:
	.8byte	0
	.section .data
m_symbol_2F_2Aoptimised_2A:
	.8byte	0
	.section .rodata
m_cstr388:
	.asciz "true"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr389:
	.8byte	9
	.8byte	m_cstr388
	.section .rodata
m_cstr390:
	.asciz "define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr391:
	.8byte	13
	.8byte	m_cstr390
	.section .rodata
m_cstr392:
	.asciz "set"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr393:
	.8byte	7
	.8byte	m_cstr392
	.section .rodata
m_cstr394:
	.asciz "quote"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr395:
	.8byte	11
	.8byte	m_cstr394
	.section .rodata
m_cstr396:
	.asciz "quasiquote"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr397:
	.8byte	21
	.8byte	m_cstr396
	.section .rodata
m_cstr398:
	.asciz "unquote"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr399:
	.8byte	15
	.8byte	m_cstr398
	.section .rodata
m_cstr400:
	.asciz "unquote-splicing"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr401:
	.8byte	33
	.8byte	m_cstr400
	.section .rodata
m_cstr402:
	.asciz "expand"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr403:
	.8byte	13
	.8byte	m_cstr402
	.section .rodata
m_cstr404:
	.asciz "encode"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr405:
	.8byte	13
	.8byte	m_cstr404
	.section .rodata
m_cstr406:
	.asciz "apply"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr407:
	.8byte	11
	.8byte	m_cstr406
	.section .rodata
m_cstr408:
	.asciz "."
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr409:
	.8byte	3
	.8byte	m_cstr408
	.section .rodata
m_cstr410:
	.asciz "lambda"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr411:
	.8byte	13
	.8byte	m_cstr410
	.section .rodata
m_cstr412:
	.asciz "let"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr413:
	.8byte	7
	.8byte	m_cstr412
	.section .rodata
m_cstr414:
	.asciz "*globals*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr415:
	.8byte	19
	.8byte	m_cstr414
	.section .rodata
m_cstr416:
	.asciz "*expanders*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr417:
	.8byte	23
	.8byte	m_cstr416
	.section .rodata
m_cstr418:
	.asciz "*encoders*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr419:
	.8byte	21
	.8byte	m_cstr418
	.section .rodata
m_cstr420:
	.asciz "*evaluators*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr421:
	.8byte	25
	.8byte	m_cstr420
	.section .rodata
m_cstr422:
	.asciz "*applicators*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr423:
	.8byte	27
	.8byte	m_cstr422
	.section .rodata
m_cstr424:
	.asciz "*standard-input*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr425:
	.8byte	33
	.8byte	m_cstr424
	.section .rodata
m_cstr426:
	.asciz "*standard-output*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr427:
	.8byte	35
	.8byte	m_cstr426
	.section .rodata
m_cstr428:
	.asciz "*error-output*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr429:
	.8byte	29
	.8byte	m_cstr428
	.section .rodata
m_cstr430:
	.asciz "*debug-output*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr431:
	.8byte	29
	.8byte	m_cstr430
	.section .rodata
m_cstr432:
	.asciz "*verbosity*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr433:
	.8byte	23
	.8byte	m_cstr432
	.section .rodata
m_cstr434:
	.asciz "*optimised*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr435:
	.8byte	23
	.8byte	m_cstr434
	.text
m_initialize_symbol_cache__code:
	push	%rbp
	mov	%rsp, %rbp
	push	%rbx
	sub	$8, %rsp
	xor	%rax, %rax
	lea	m_ostr389(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Ftrue(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr391(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Fdefine(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr393(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Fset(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr395(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Fquote(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr397(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Fquasiquote(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr399(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Funquote(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr401(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Funquote_splicing(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr403(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Fexpand(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr405(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Fencode(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr407(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Fapply(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr409(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2E(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr411(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Flambda(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr413(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2Flet(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr415(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Aglobals_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr417(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Aexpanders_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr419(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Aencoders_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr421(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Aevaluators_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr423(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Aapplicators_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr425(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Astandard_input_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr427(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr429(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr431(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr433(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Averbosity_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr435(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	lea	m_symbol_2F_2Aoptimised_2A(%rip), %rcx
	mov	%rax, (%rcx)
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr436:
	.asciz "initialize-symbol-cache"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr437:
	.8byte	47
	.8byte	m_cstr436
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_initialize_symbol_cache:
	.8byte	m_initialize_symbol_cache__code
	.8byte	m_ostr437
	.globl m_initialize_symbol_cache__code
	.type m_initialize_symbol_cache__code, @function
	.section .rodata
m_cstr440:
	.asciz "car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr441:
	.8byte	7
	.8byte	m_cstr440
	.section .rodata
m_cstr443:
	.asciz "car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr444:
	.8byte	7
	.8byte	m_cstr443
	.text
m_car_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L438
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L439
m_L438:
	lea	m_ostr441(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L439:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L442
	lea	m_ostr444(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L442:
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr446:
	.asciz "car/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr447:
	.8byte	37
	.8byte	m_cstr446
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_car_2Fevaluator_stub:
	.8byte	m_car_2Fevaluator_stub__code
	.8byte	m_ostr447
	.globl m_car_2Fevaluator_stub__code
	.type m_car_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr450:
	.asciz "cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr451:
	.8byte	7
	.8byte	m_cstr450
	.section .rodata
m_cstr453:
	.asciz "cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr454:
	.8byte	7
	.8byte	m_cstr453
	.text
m_cdr_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L448
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L449
m_L448:
	lea	m_ostr451(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L449:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L452
	lea	m_ostr454(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L452:
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr456:
	.asciz "cdr/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr457:
	.8byte	37
	.8byte	m_cstr456
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cdr_2Fevaluator_stub:
	.8byte	m_cdr_2Fevaluator_stub__code
	.8byte	m_ostr457
	.globl m_cdr_2Fevaluator_stub__code
	.type m_cdr_2Fevaluator_stub__code, @function
	.text
m_caar__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr458:
	.asciz "caar"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr459:
	.8byte	9
	.8byte	m_cstr458
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_caar:
	.8byte	m_caar__code
	.8byte	m_ostr459
	.globl m_caar__code
	.type m_caar__code, @function
	.text
m_cadr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr460:
	.asciz "cadr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr461:
	.8byte	9
	.8byte	m_cstr460
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cadr:
	.8byte	m_cadr__code
	.8byte	m_ostr461
	.globl m_cadr__code
	.type m_cadr__code, @function
	.text
m_cdar__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr462:
	.asciz "cdar"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr463:
	.8byte	9
	.8byte	m_cstr462
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cdar:
	.8byte	m_cdar__code
	.8byte	m_ostr463
	.globl m_cdar__code
	.type m_cdar__code, @function
	.text
m_cddr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr464:
	.asciz "cddr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr465:
	.8byte	9
	.8byte	m_cstr464
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cddr:
	.8byte	m_cddr__code
	.8byte	m_ostr465
	.globl m_cddr__code
	.type m_cddr__code, @function
	.text
m_cadar__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr466:
	.asciz "cadar"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr467:
	.8byte	11
	.8byte	m_cstr466
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cadar:
	.8byte	m_cadar__code
	.8byte	m_ostr467
	.globl m_cadar__code
	.type m_cadar__code, @function
	.text
m_caadr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr468:
	.asciz "caadr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr469:
	.8byte	11
	.8byte	m_cstr468
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_caadr:
	.8byte	m_caadr__code
	.8byte	m_ostr469
	.globl m_caadr__code
	.type m_caadr__code, @function
	.text
m_cdadr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr470:
	.asciz "cdadr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr471:
	.8byte	11
	.8byte	m_cstr470
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cdadr:
	.8byte	m_cdadr__code
	.8byte	m_ostr471
	.globl m_cdadr__code
	.type m_cdadr__code, @function
	.text
m_caddr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr472:
	.asciz "caddr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr473:
	.8byte	11
	.8byte	m_cstr472
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_caddr:
	.8byte	m_caddr__code
	.8byte	m_ostr473
	.globl m_caddr__code
	.type m_caddr__code, @function
	.text
m_cdddr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr474:
	.asciz "cdddr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr475:
	.8byte	11
	.8byte	m_cstr474
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cdddr:
	.8byte	m_cdddr__code
	.8byte	m_ostr475
	.globl m_cdddr__code
	.type m_cdddr__code, @function
	.text
m_caddar__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr476:
	.asciz "caddar"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr477:
	.8byte	13
	.8byte	m_cstr476
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_caddar:
	.8byte	m_caddar__code
	.8byte	m_ostr477
	.globl m_caddar__code
	.type m_caddar__code, @function
	.text
m_caaddr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr478:
	.asciz "caaddr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr479:
	.8byte	13
	.8byte	m_cstr478
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_caaddr:
	.8byte	m_caaddr__code
	.8byte	m_ostr479
	.globl m_caaddr__code
	.type m_caaddr__code, @function
	.text
m_cadddr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr480:
	.asciz "cadddr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr481:
	.8byte	13
	.8byte	m_cstr480
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cadddr:
	.8byte	m_cadddr__code
	.8byte	m_ostr481
	.globl m_cadddr__code
	.type m_cadddr__code, @function
	.text
m_cddddr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr482:
	.asciz "cddddr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr483:
	.8byte	13
	.8byte	m_cstr482
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cddddr:
	.8byte	m_cddddr__code
	.8byte	m_ostr483
	.globl m_cddddr__code
	.type m_cddddr__code, @function
	.text
m_first__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	test	%rax, %rax
	je	m_L484
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
m_L484:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr486:
	.asciz "first"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr487:
	.8byte	11
	.8byte	m_cstr486
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_first:
	.8byte	m_first__code
	.8byte	m_ostr487
	.globl m_first__code
	.type m_first__code, @function
	.text
m_second__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr488:
	.asciz "second"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr489:
	.8byte	13
	.8byte	m_cstr488
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_second:
	.8byte	m_second__code
	.8byte	m_ostr489
	.globl m_second__code
	.type m_second__code, @function
	.text
m_third__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr490:
	.asciz "third"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr491:
	.8byte	11
	.8byte	m_cstr490
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_third:
	.8byte	m_third__code
	.8byte	m_ostr491
	.globl m_third__code
	.type m_third__code, @function
	.text
m_rest__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	test	%rax, %rax
	je	m_L492
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
m_L492:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr494:
	.asciz "rest"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr495:
	.8byte	9
	.8byte	m_cstr494
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_rest:
	.8byte	m_rest__code
	.8byte	m_ostr495
	.globl m_rest__code
	.type m_rest__code, @function
	.text
m_allocate__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	$8, %rcx
	mul	%rcx
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_gc_2Fallocate__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr496:
	.asciz "allocate"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr497:
	.8byte	17
	.8byte	m_cstr496
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_allocate:
	.8byte	m_allocate__code
	.8byte	m_ostr497
	.globl m_allocate__code
	.type m_allocate__code, @function
	.section .rodata
m_cstr500:
	.asciz "allocate"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr501:
	.8byte	17
	.8byte	m_cstr500
	.section .rodata
m_cstr502:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr503:
	.8byte	15
	.8byte	m_cstr502
	.section .rodata
m_cstr504:
	.asciz "type"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr505:
	.8byte	9
	.8byte	m_cstr504
	.section .rodata
m_cstr506:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr507:
	.8byte	35
	.8byte	m_cstr506
	.section .rodata
m_cstr508:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr509:
	.8byte	13
	.8byte	m_cstr508
	.section .rodata
m_cstr511:
	.asciz "allocate"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr512:
	.8byte	17
	.8byte	m_cstr511
	.section .rodata
m_cstr515:
	.asciz "allocate"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr516:
	.8byte	17
	.8byte	m_cstr515
	.section .rodata
m_cstr517:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr518:
	.8byte	15
	.8byte	m_cstr517
	.section .rodata
m_cstr519:
	.asciz "slot-count"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr520:
	.8byte	21
	.8byte	m_cstr519
	.section .rodata
m_cstr521:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr522:
	.8byte	35
	.8byte	m_cstr521
	.section .rodata
m_cstr523:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr524:
	.8byte	13
	.8byte	m_cstr523
	.section .rodata
m_cstr526:
	.asciz "allocate"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr527:
	.8byte	17
	.8byte	m_cstr526
	.section .rodata
m_cstr529:
	.asciz "allocate"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr530:
	.8byte	17
	.8byte	m_cstr529
	.text
m_allocate_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L498
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L499
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr501(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr503(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr505(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr507(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr509(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L499:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L510
m_L498:
	lea	m_ostr512(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L510:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L513
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L514
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr516(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr518(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr520(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr522(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr524(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L514:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L525
m_L513:
	lea	m_ostr527(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L525:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L528
	lea	m_ostr530(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L528:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_allocate__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr532:
	.asciz "allocate/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr533:
	.8byte	47
	.8byte	m_cstr532
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_allocate_2Fevaluator_stub:
	.8byte	m_allocate_2Fevaluator_stub__code
	.8byte	m_ostr533
	.globl m_allocate_2Fevaluator_stub__code
	.type m_allocate_2Fevaluator_stub__code, @function
	.text
m_allocate_data__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	mov	$5, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_gc_2Fallocate_opaque__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr534:
	.asciz "allocate-data"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr535:
	.8byte	27
	.8byte	m_cstr534
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_allocate_data:
	.8byte	m_allocate_data__code
	.8byte	m_ostr535
	.globl m_allocate_data__code
	.type m_allocate_data__code, @function
	.section .rodata
m_cstr538:
	.asciz "allocate-data"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr539:
	.8byte	27
	.8byte	m_cstr538
	.section .rodata
m_cstr540:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr541:
	.8byte	15
	.8byte	m_cstr540
	.section .rodata
m_cstr542:
	.asciz "byte-size"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr543:
	.8byte	19
	.8byte	m_cstr542
	.section .rodata
m_cstr544:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr545:
	.8byte	35
	.8byte	m_cstr544
	.section .rodata
m_cstr546:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr547:
	.8byte	13
	.8byte	m_cstr546
	.section .rodata
m_cstr549:
	.asciz "allocate-data"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr550:
	.8byte	27
	.8byte	m_cstr549
	.section .rodata
m_cstr552:
	.asciz "allocate-data"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr553:
	.8byte	27
	.8byte	m_cstr552
	.text
m_allocate_data_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L536
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L537
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr539(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr541(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr543(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr545(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr547(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L537:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L548
m_L536:
	lea	m_ostr550(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L548:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L551
	lea	m_ostr553(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L551:
	movq	-32(%rbp), %rdi
	call	m_allocate_data__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr555:
	.asciz "allocate-data/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr556:
	.8byte	57
	.8byte	m_cstr555
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_allocate_data_2Fevaluator_stub:
	.8byte	m_allocate_data_2Fevaluator_stub__code
	.8byte	m_ostr556
	.globl m_allocate_data_2Fevaluator_stub__code
	.type m_allocate_data_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr562:
	.asciz "cons"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr563:
	.8byte	9
	.8byte	m_cstr562
	.text
m_cons_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L557
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L558
m_L557:
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
m_L558:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L559
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L560
m_L559:
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
m_L560:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L561
	lea	m_ostr563(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L561:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr565:
	.asciz "cons/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr566:
	.8byte	39
	.8byte	m_cstr565
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cons_2Fevaluator_stub:
	.8byte	m_cons_2Fevaluator_stub__code
	.8byte	m_ostr566
	.globl m_cons_2Fevaluator_stub__code
	.type m_cons_2Fevaluator_stub__code, @function
	.text
m_string__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	$12, %rdi
	movq	$2, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	cmp	-24(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L567
	movq	-8(%rbp), %rdi
	call	m_allocate_data__code
	add	$0, %rsp
m_L567:
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr569:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr570:
	.8byte	13
	.8byte	m_cstr569
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string:
	.8byte	m_string__code
	.8byte	m_ostr570
	.globl m_string__code
	.type m_string__code, @function
	.section .rodata
m_cstr573:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr574:
	.8byte	13
	.8byte	m_cstr573
	.section .rodata
m_cstr575:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr576:
	.8byte	15
	.8byte	m_cstr575
	.section .rodata
m_cstr577:
	.asciz "capacity"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr578:
	.8byte	17
	.8byte	m_cstr577
	.section .rodata
m_cstr579:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr580:
	.8byte	35
	.8byte	m_cstr579
	.section .rodata
m_cstr581:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr582:
	.8byte	13
	.8byte	m_cstr581
	.section .rodata
m_cstr585:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr586:
	.8byte	13
	.8byte	m_cstr585
	.text
m_string_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L571
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L572
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr574(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr576(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr578(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr580(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr582(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L572:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L583
m_L571:
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
m_L583:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L584
	lea	m_ostr586(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L584:
	movq	-32(%rbp), %rdi
	call	m_string__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr588:
	.asciz "string/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr589:
	.8byte	43
	.8byte	m_cstr588
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_2Fevaluator_stub:
	.8byte	m_string_2Fevaluator_stub__code
	.8byte	m_ostr589
	.globl m_string_2Fevaluator_stub__code
	.type m_string_2Fevaluator_stub__code, @function
	.text
m_ascii_bytes__3Estring__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-16(%rbp), %rdi
	call	m_string__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-16(%rbp), %rdx
	call	m_copy_bytes__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr590:
	.asciz "ascii-bytes->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr591:
	.8byte	39
	.8byte	m_cstr590
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_ascii_bytes__3Estring:
	.8byte	m_ascii_bytes__3Estring__code
	.8byte	m_ostr591
	.globl m_ascii_bytes__3Estring__code
	.type m_ascii_bytes__3Estring__code, @function
	.section .rodata
m_cstr593:
	.asciz "kernel assertion failed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr594:
	.8byte	47
	.8byte	m_cstr593
	.text
m_symbol__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L592
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr594(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L592:
	movq	$9, %rdi
	movq	$1, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr595:
	.asciz "symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr596:
	.8byte	13
	.8byte	m_cstr595
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_symbol:
	.8byte	m_symbol__code
	.8byte	m_ostr596
	.globl m_symbol__code
	.type m_symbol__code, @function
	.text
m_array__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	$10, %rdi
	movq	$2, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-8(%rbp), %rax
	test	%rax, %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L597
	mov	$5, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_allocate__code
	add	$0, %rsp
m_L597:
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr599:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr600:
	.8byte	11
	.8byte	m_cstr599
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array:
	.8byte	m_array__code
	.8byte	m_ostr600
	.globl m_array__code
	.type m_array__code, @function
	.section .rodata
m_cstr603:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr604:
	.8byte	11
	.8byte	m_cstr603
	.section .rodata
m_cstr605:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr606:
	.8byte	15
	.8byte	m_cstr605
	.section .rodata
m_cstr607:
	.asciz "capacity"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr608:
	.8byte	17
	.8byte	m_cstr607
	.section .rodata
m_cstr609:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr610:
	.8byte	35
	.8byte	m_cstr609
	.section .rodata
m_cstr611:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr612:
	.8byte	13
	.8byte	m_cstr611
	.section .rodata
m_cstr615:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr616:
	.8byte	11
	.8byte	m_cstr615
	.text
m_array_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L601
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L602
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr604(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr606(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr608(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr610(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr612(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L602:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L613
m_L601:
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
m_L613:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L614
	lea	m_ostr616(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L614:
	movq	-32(%rbp), %rdi
	call	m_array__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr618:
	.asciz "array/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr619:
	.8byte	41
	.8byte	m_cstr618
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_2Fevaluator_stub:
	.8byte	m_array_2Fevaluator_stub__code
	.8byte	m_ostr619
	.globl m_array_2Fevaluator_stub__code
	.type m_array_2Fevaluator_stub__code, @function
	.text
m_expr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	movq	$13, %rdi
	movq	$5, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	24(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr620:
	.asciz "expr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr621:
	.8byte	9
	.8byte	m_cstr620
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_expr:
	.8byte	m_expr__code
	.8byte	m_ostr621
	.globl m_expr__code
	.type m_expr__code, @function
	.section .rodata
m_cstr624:
	.asciz "form"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr625:
	.8byte	9
	.8byte	m_cstr624
	.section .rodata
m_cstr629:
	.asciz "form"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr630:
	.8byte	9
	.8byte	m_cstr629
	.text
m_form_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L622
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L623
m_L622:
	lea	m_ostr625(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L623:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L626
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L627
m_L626:
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
m_L627:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L628
	lea	m_ostr630(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L628:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_form__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr632:
	.asciz "form/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr633:
	.8byte	39
	.8byte	m_cstr632
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_form_2Fevaluator_stub:
	.8byte	m_form_2Fevaluator_stub__code
	.8byte	m_ostr633
	.globl m_form_2Fevaluator_stub__code
	.type m_form_2Fevaluator_stub__code, @function
	.text
m_fixed__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	$8, %rdi
	movq	$1, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr634:
	.asciz "fixed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr635:
	.8byte	11
	.8byte	m_cstr634
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_fixed:
	.8byte	m_fixed__code
	.8byte	m_ostr635
	.globl m_fixed__code
	.type m_fixed__code, @function
	.section .rodata
m_cstr638:
	.asciz "fixed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr639:
	.8byte	11
	.8byte	m_cstr638
	.section .rodata
m_cstr641:
	.asciz "fixed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr642:
	.8byte	11
	.8byte	m_cstr641
	.text
m_fixed_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L636
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L637
m_L636:
	lea	m_ostr639(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L637:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L640
	lea	m_ostr642(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L640:
	movq	-32(%rbp), %rdi
	call	m_fixed__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr644:
	.asciz "fixed/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr645:
	.8byte	41
	.8byte	m_cstr644
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_fixed_2Fevaluator_stub:
	.8byte	m_fixed_2Fevaluator_stub__code
	.8byte	m_ostr645
	.globl m_fixed_2Fevaluator_stub__code
	.type m_fixed_2Fevaluator_stub__code, @function
	.text
m_vm_function__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	movq	$19, %rdi
	movq	$2, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr646:
	.asciz "vm-function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr647:
	.8byte	23
	.8byte	m_cstr646
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_vm_function:
	.8byte	m_vm_function__code
	.8byte	m_ostr647
	.globl m_vm_function__code
	.type m_vm_function__code, @function
	.text
m_variable__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	movq	$15, %rdi
	movq	$4, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	24(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr648:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr649:
	.8byte	17
	.8byte	m_cstr648
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_variable:
	.8byte	m_variable__code
	.8byte	m_ostr649
	.globl m_variable__code
	.type m_variable__code, @function
	.section .rodata
m_cstr652:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr653:
	.8byte	17
	.8byte	m_cstr652
	.section .rodata
m_cstr654:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr655:
	.8byte	15
	.8byte	m_cstr654
	.section .rodata
m_cstr656:
	.asciz "name"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr657:
	.8byte	9
	.8byte	m_cstr656
	.section .rodata
m_cstr658:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr659:
	.8byte	35
	.8byte	m_cstr658
	.section .rodata
m_cstr660:
	.asciz "<symbol>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr661:
	.8byte	17
	.8byte	m_cstr660
	.section .rodata
m_cstr663:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr664:
	.8byte	17
	.8byte	m_cstr663
	.section .rodata
m_cstr667:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr668:
	.8byte	17
	.8byte	m_cstr667
	.section .rodata
m_cstr671:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr672:
	.8byte	17
	.8byte	m_cstr671
	.section .rodata
m_cstr673:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr674:
	.8byte	15
	.8byte	m_cstr673
	.section .rodata
m_cstr675:
	.asciz "env"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr676:
	.8byte	7
	.8byte	m_cstr675
	.section .rodata
m_cstr677:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr678:
	.8byte	35
	.8byte	m_cstr677
	.section .rodata
m_cstr679:
	.asciz "<env>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr680:
	.8byte	11
	.8byte	m_cstr679
	.section .rodata
m_cstr682:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr683:
	.8byte	17
	.8byte	m_cstr682
	.section .rodata
m_cstr686:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr687:
	.8byte	17
	.8byte	m_cstr686
	.section .rodata
m_cstr688:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr689:
	.8byte	15
	.8byte	m_cstr688
	.section .rodata
m_cstr690:
	.asciz "index"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr691:
	.8byte	11
	.8byte	m_cstr690
	.section .rodata
m_cstr692:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr693:
	.8byte	35
	.8byte	m_cstr692
	.section .rodata
m_cstr694:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr695:
	.8byte	13
	.8byte	m_cstr694
	.section .rodata
m_cstr697:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr698:
	.8byte	17
	.8byte	m_cstr697
	.section .rodata
m_cstr700:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr701:
	.8byte	17
	.8byte	m_cstr700
	.text
m_variable_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	xor	%rax, %rax
	mov	%rax, -56(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L650
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L651
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr653(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr655(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr657(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr659(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr661(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L651:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L662
m_L650:
	lea	m_ostr664(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L662:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L665
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L666
m_L665:
	lea	m_ostr668(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L666:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L669
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	movq	-48(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	$16, %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L670
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr672(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr674(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr676(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr678(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr680(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L670:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L681
m_L669:
	lea	m_ostr683(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L681:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L684
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L685
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr687(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr689(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr691(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr693(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr695(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L685:
	mov	-56(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -56(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L696
m_L684:
	lea	m_ostr698(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L696:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L699
	lea	m_ostr701(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L699:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	movq	-56(%rbp), %rcx
	call	m_variable__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr703:
	.asciz "variable/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr704:
	.8byte	47
	.8byte	m_cstr703
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_variable_2Fevaluator_stub:
	.8byte	m_variable_2Fevaluator_stub__code
	.8byte	m_ostr704
	.globl m_variable_2Fevaluator_stub__code
	.type m_variable_2Fevaluator_stub__code, @function
	.text
m_environment__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	movq	$16, %rdi
	movq	$6, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$16, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L705
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	add	-40(%rbp),%rax
	jmp	m_L706
m_L705:
	xor	%rax, %rax
m_L706:
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	movq	$0, %rdi
	call	m_array__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	24(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	lea	32(%rax), %rcx
	mov	$0, %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr707:
	.asciz "environment"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr708:
	.8byte	23
	.8byte	m_cstr707
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_environment:
	.8byte	m_environment__code
	.8byte	m_ostr708
	.globl m_environment__code
	.type m_environment__code, @function
	.section .rodata
m_cstr713:
	.asciz "environment"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr714:
	.8byte	23
	.8byte	m_cstr713
	.section .rodata
m_cstr715:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr716:
	.8byte	15
	.8byte	m_cstr715
	.section .rodata
m_cstr717:
	.asciz "level"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr718:
	.8byte	11
	.8byte	m_cstr717
	.section .rodata
m_cstr719:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr720:
	.8byte	35
	.8byte	m_cstr719
	.section .rodata
m_cstr721:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr722:
	.8byte	13
	.8byte	m_cstr721
	.section .rodata
m_cstr726:
	.asciz "environment"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr727:
	.8byte	23
	.8byte	m_cstr726
	.section .rodata
m_cstr728:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr729:
	.8byte	15
	.8byte	m_cstr728
	.section .rodata
m_cstr730:
	.asciz "offset"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr731:
	.8byte	13
	.8byte	m_cstr730
	.section .rodata
m_cstr732:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr733:
	.8byte	35
	.8byte	m_cstr732
	.section .rodata
m_cstr734:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr735:
	.8byte	13
	.8byte	m_cstr734
	.section .rodata
m_cstr740:
	.asciz "environment"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr741:
	.8byte	23
	.8byte	m_cstr740
	.text
m_environment_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L709
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L710
m_L709:
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
m_L710:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L711
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L712
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr714(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr716(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr718(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr720(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr722(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L712:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L723
m_L711:
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
m_L723:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L724
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	movq	-48(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L725
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr727(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr729(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr731(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr733(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr735(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L725:
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L736
m_L724:
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	$16, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L737
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	jmp	m_L738
m_L737:
	xor	%rax, %rax
m_L738:
	mov	%rax, -48(%rbp)
m_L736:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L739
	lea	m_ostr741(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L739:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_environment__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr743:
	.asciz "environment/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr744:
	.8byte	53
	.8byte	m_cstr743
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_environment_2Fevaluator_stub:
	.8byte	m_environment_2Fevaluator_stub__code
	.8byte	m_ostr744
	.globl m_environment_2Fevaluator_stub__code
	.type m_environment_2Fevaluator_stub__code, @function
	.text
m_base_context__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	$17, %rdi
	movq	$4, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	movq	$0, %rdi
	call	m_array__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr745:
	.asciz "base-context"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr746:
	.8byte	25
	.8byte	m_cstr745
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_base_context:
	.8byte	m_base_context__code
	.8byte	m_ostr746
	.globl m_base_context__code
	.type m_base_context__code, @function
	.text
m_context__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	-8(%rbp), %rdi
	movq	-24(%rbp), %rsi
	call	m_base_context__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	test	%rax, %rax
	je	m_L747
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	lea	24(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
m_L747:
	mov	-32(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr749:
	.asciz "context"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr750:
	.8byte	15
	.8byte	m_cstr749
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_context:
	.8byte	m_context__code
	.8byte	m_ostr750
	.globl m_context__code
	.type m_context__code, @function
	.text
m_list2__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-24(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr751:
	.asciz "list2"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr752:
	.8byte	11
	.8byte	m_cstr751
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_list2:
	.8byte	m_list2__code
	.8byte	m_ostr752
	.globl m_list2__code
	.type m_list2__code, @function
	.text
m_list3__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	-16(%rbp), %rdi
	movq	-24(%rbp), %rsi
	call	m_list2__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr753:
	.asciz "list3"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr754:
	.8byte	11
	.8byte	m_cstr753
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_list3:
	.8byte	m_list3__code
	.8byte	m_ostr754
	.globl m_list3__code
	.type m_list3__code, @function
	.text
m_concat_list__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L755
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_concat_list__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-24(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	jmp	m_L756
m_L755:
	mov	-16(%rbp), %rax
m_L756:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr757:
	.asciz "concat-list"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr758:
	.8byte	23
	.8byte	m_cstr757
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_concat_list:
	.8byte	m_concat_list__code
	.8byte	m_ostr758
	.globl m_concat_list__code
	.type m_concat_list__code, @function
	.text
m_array_length__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	sar	$1, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr759:
	.asciz "array-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr760:
	.8byte	25
	.8byte	m_cstr759
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_length:
	.8byte	m_array_length__code
	.8byte	m_ostr760
	.globl m_array_length__code
	.type m_array_length__code, @function
	.text
m_array_at__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	movq	-8(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L761
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	mov	-40(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
m_L761:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr762:
	.asciz "array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr763:
	.8byte	17
	.8byte	m_cstr762
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_at:
	.8byte	m_array_at__code
	.8byte	m_ostr763
	.globl m_array_at__code
	.type m_array_at__code, @function
	.text
m_set_array_at__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	movq	-8(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L764
	movq	-32(%rbp), %rdi
	call	m_gc_2Fobject_size__code
	add	$0, %rsp
	xor	%rdx, %rdx
	mov	$8, %rcx
	idiv	%rcx
	jmp	m_L765
m_L764:
	xor	%rax, %rax
m_L765:
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L766
	xor	%rax, %rax
	jmp	m_L767
m_L766:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L768
	mov	$4, %rax
	mov	%rax, -48(%rbp)
m_L768:
	jmp	m_L771
m_L770:
	mov	-48(%rbp), %rax
	mov	$2, %rcx
	mul	%rcx
	mov	%rax, -48(%rbp)
m_L771:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L770
	mov	$5, %rax
	mov	%rax, %rbx
	mov	-48(%rbp), %rax
	mov	$8, %rcx
	mul	%rcx
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	movq	-56(%rbp), %rsi
	movq	-40(%rbp), %rdx
	call	m_copy_oops__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	mov	%rax, -32(%rbp)
	mov	%rax, -64(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
m_L767:
	mov	-16(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L772
	mov	-16(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	add	-56(%rbp),%rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -56(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
m_L772:
	mov	-24(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	mov	-64(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr774:
	.asciz "set-array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr775:
	.8byte	25
	.8byte	m_cstr774
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_array_at:
	.8byte	m_set_array_at__code
	.8byte	m_ostr775
	.globl m_set_array_at__code
	.type m_set_array_at__code, @function
	.text
m_array_append__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-16(%rbp), %rdx
	call	m_set_array_at__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr776:
	.asciz "array-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr777:
	.8byte	25
	.8byte	m_cstr776
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_append:
	.8byte	m_array_append__code
	.8byte	m_ostr777
	.globl m_array_append__code
	.type m_array_append__code, @function
	.text
m_array_insert__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L778
	movq	-8(%rbp), %rdi
	movq	$0, %rsi
	call	m_array_append__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L779
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	mov	$8, %rcx
	mul	%rcx
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	add	-48(%rbp),%rax
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	add	$8, %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	sub	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	-48(%rbp), %rdi
	movq	-56(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_platform_2Fmove_oops__code
	add	$0, %rsp
m_L779:
m_L778:
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_set_array_at__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr782:
	.asciz "array-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr783:
	.8byte	25
	.8byte	m_cstr782
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_insert:
	.8byte	m_array_insert__code
	.8byte	m_ostr783
	.globl m_array_insert__code
	.type m_array_insert__code, @function
	.text
m_array_ensure_zero_terminated__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	lea	m_gc_2Flowest_memory_address(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	cmp	-16(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L784
	xor	%rax, %rax
	jmp	m_L785
m_L784:
	movq	-8(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	$0, %rdx
	call	m_set_array_at__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
m_L785:
	mov	-8(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr786:
	.asciz "array-ensure-zero-terminated"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr787:
	.8byte	57
	.8byte	m_cstr786
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_ensure_zero_terminated:
	.8byte	m_array_ensure_zero_terminated__code
	.8byte	m_ostr787
	.globl m_array_ensure_zero_terminated__code
	.type m_array_ensure_zero_terminated__code, @function
	.text
m_string_length__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	sar	$1, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr788:
	.asciz "string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr789:
	.8byte	27
	.8byte	m_cstr788
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_length:
	.8byte	m_string_length__code
	.8byte	m_ostr789
	.globl m_string_length__code
	.type m_string_length__code, @function
	.text
m_string_at__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	movq	-8(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L790
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	mov	-40(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
m_L790:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr791:
	.asciz "string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr792:
	.8byte	19
	.8byte	m_cstr791
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_at:
	.8byte	m_string_at__code
	.8byte	m_ostr792
	.globl m_string_at__code
	.type m_string_at__code, @function
	.text
m_set_string_at__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	movq	-8(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L793
	movq	-32(%rbp), %rdi
	call	m_gc_2Fobject_size__code
	add	$0, %rsp
	xor	%rdx, %rdx
	jmp	m_L794
m_L793:
	xor	%rax, %rax
m_L794:
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L795
	xor	%rax, %rax
	jmp	m_L796
m_L795:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L797
	mov	$4, %rax
	mov	%rax, -48(%rbp)
m_L797:
	jmp	m_L800
m_L799:
	mov	-48(%rbp), %rax
	mov	$2, %rcx
	mul	%rcx
	mov	%rax, -48(%rbp)
m_L800:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L799
	mov	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_allocate_data__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	movq	-56(%rbp), %rsi
	movq	-40(%rbp), %rdx
	call	m_copy_bytes__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	mov	%rax, -32(%rbp)
	mov	%rax, -64(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
m_L796:
	mov	-16(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L801
	mov	-16(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	add	-56(%rbp),%rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -56(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
m_L801:
	mov	-24(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	mov	-64(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	movb	-56(%rbp), %al
	movb	%al, (%rcx)
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr803:
	.asciz "set-string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr804:
	.8byte	27
	.8byte	m_cstr803
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_string_at:
	.8byte	m_set_string_at__code
	.8byte	m_ostr804
	.globl m_set_string_at__code
	.type m_set_string_at__code, @function
	.text
m_string_append__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-16(%rbp), %rdx
	call	m_set_string_at__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr805:
	.asciz "string-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr806:
	.8byte	27
	.8byte	m_cstr805
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_append:
	.8byte	m_string_append__code
	.8byte	m_ostr806
	.globl m_string_append__code
	.type m_string_append__code, @function
	.text
m_string_insert__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L807
	movq	-8(%rbp), %rdi
	movq	$0, %rsi
	call	m_string_append__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L808
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	add	-48(%rbp),%rax
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	add	$1, %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	sub	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	-48(%rbp), %rdi
	movq	-56(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_platform_2Fmove_bytes__code
	add	$0, %rsp
m_L808:
m_L807:
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_set_string_at__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr811:
	.asciz "string-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr812:
	.8byte	27
	.8byte	m_cstr811
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_insert:
	.8byte	m_string_insert__code
	.8byte	m_ostr812
	.globl m_string_insert__code
	.type m_string_insert__code, @function
	.text
m_string_ensure_zero_terminated__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	lea	m_gc_2Flowest_memory_address(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	cmp	-16(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L813
	xor	%rax, %rax
	jmp	m_L814
m_L813:
	movq	-8(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	$0, %rdx
	call	m_set_string_at__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
m_L814:
	mov	-8(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr815:
	.asciz "string-ensure-zero-terminated"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr816:
	.8byte	59
	.8byte	m_cstr815
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_ensure_zero_terminated:
	.8byte	m_string_ensure_zero_terminated__code
	.8byte	m_ostr816
	.globl m_string_ensure_zero_terminated__code
	.type m_string_ensure_zero_terminated__code, @function
	.text
m_memory_block_2Flength__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	sar	$1, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr817:
	.asciz "memory-block/length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr818:
	.8byte	39
	.8byte	m_cstr817
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block_2Flength:
	.8byte	m_memory_block_2Flength__code
	.8byte	m_ostr818
	.globl m_memory_block_2Flength__code
	.type m_memory_block_2Flength__code, @function
	.text
m_memory_block_2Fat__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	movq	-8(%rbp), %rdi
	call	m_memory_block_2Flength__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L819
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	mov	-40(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
m_L819:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr820:
	.asciz "memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr821:
	.8byte	31
	.8byte	m_cstr820
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block_2Fat:
	.8byte	m_memory_block_2Fat__code
	.8byte	m_ostr821
	.globl m_memory_block_2Fat__code
	.type m_memory_block_2Fat__code, @function
	.text
m_set_memory_block_2Fat__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	movq	-8(%rbp), %rdi
	call	m_memory_block_2Flength__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L822
	movq	-32(%rbp), %rdi
	call	m_gc_2Fobject_size__code
	add	$0, %rsp
	xor	%rdx, %rdx
	jmp	m_L823
m_L822:
	xor	%rax, %rax
m_L823:
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L824
	xor	%rax, %rax
	jmp	m_L825
m_L824:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L826
	mov	$4, %rax
	mov	%rax, -48(%rbp)
m_L826:
	jmp	m_L829
m_L828:
	mov	-48(%rbp), %rax
	mov	$2, %rcx
	mul	%rcx
	mov	%rax, -48(%rbp)
m_L829:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L828
	mov	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_allocate_data__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	movq	-56(%rbp), %rsi
	movq	-40(%rbp), %rdx
	call	m_copy_bytes__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	mov	%rax, -32(%rbp)
	mov	%rax, -64(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
m_L825:
	mov	-16(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L830
	mov	-16(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	add	-56(%rbp),%rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -56(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
m_L830:
	mov	-24(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	mov	-64(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	movb	-56(%rbp), %al
	movb	%al, (%rcx)
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr832:
	.asciz "set-memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr833:
	.8byte	39
	.8byte	m_cstr832
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_memory_block_2Fat:
	.8byte	m_set_memory_block_2Fat__code
	.8byte	m_ostr833
	.globl m_set_memory_block_2Fat__code
	.type m_set_memory_block_2Fat__code, @function
	.text
m_memory_block_2Fappend__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_memory_block_2Flength__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-16(%rbp), %rdx
	call	m_set_memory_block_2Fat__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr834:
	.asciz "memory-block/append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr835:
	.8byte	39
	.8byte	m_cstr834
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block_2Fappend:
	.8byte	m_memory_block_2Fappend__code
	.8byte	m_ostr835
	.globl m_memory_block_2Fappend__code
	.type m_memory_block_2Fappend__code, @function
	.text
m_memory_block_2Finsert__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	call	m_memory_block_2Flength__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L836
	movq	-8(%rbp), %rdi
	movq	$0, %rsi
	call	m_memory_block_2Fappend__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L837
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	add	-48(%rbp),%rax
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	add	$1, %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	sub	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	-48(%rbp), %rdi
	movq	-56(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_platform_2Fmove_bytes__code
	add	$0, %rsp
m_L837:
m_L836:
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_set_memory_block_2Fat__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr840:
	.asciz "memory-block/insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr841:
	.8byte	39
	.8byte	m_cstr840
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block_2Finsert:
	.8byte	m_memory_block_2Finsert__code
	.8byte	m_ostr841
	.globl m_memory_block_2Finsert__code
	.type m_memory_block_2Finsert__code, @function
	.text
m_memory_block_2Fensure_zero_terminated__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	lea	m_gc_2Flowest_memory_address(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	cmp	-16(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L842
	xor	%rax, %rax
	jmp	m_L843
m_L842:
	movq	-8(%rbp), %rdi
	call	m_memory_block_2Flength__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	$0, %rdx
	call	m_set_memory_block_2Fat__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
m_L843:
	mov	-8(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr844:
	.asciz "memory-block/ensure-zero-terminated"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr845:
	.8byte	71
	.8byte	m_cstr844
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block_2Fensure_zero_terminated:
	.8byte	m_memory_block_2Fensure_zero_terminated__code
	.8byte	m_ostr845
	.globl m_memory_block_2Fensure_zero_terminated__code
	.type m_memory_block_2Fensure_zero_terminated__code, @function
	.text
m_memory_block__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	$11, %rdi
	movq	$2, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-8(%rbp), %rax
	test	%rax, %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L846
	movq	-8(%rbp), %rdi
	call	m_allocate_data__code
	add	$0, %rsp
m_L846:
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr848:
	.asciz "memory-block"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr849:
	.8byte	25
	.8byte	m_cstr848
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block:
	.8byte	m_memory_block__code
	.8byte	m_ostr849
	.globl m_memory_block__code
	.type m_memory_block__code, @function
	.section .rodata
m_cstr852:
	.asciz "memory-block"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr853:
	.8byte	25
	.8byte	m_cstr852
	.section .rodata
m_cstr854:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr855:
	.8byte	15
	.8byte	m_cstr854
	.section .rodata
m_cstr856:
	.asciz "capacity"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr857:
	.8byte	17
	.8byte	m_cstr856
	.section .rodata
m_cstr858:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr859:
	.8byte	35
	.8byte	m_cstr858
	.section .rodata
m_cstr860:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr861:
	.8byte	13
	.8byte	m_cstr860
	.section .rodata
m_cstr864:
	.asciz "memory-block"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr865:
	.8byte	25
	.8byte	m_cstr864
	.text
m_memory_block_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L850
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L851
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr853(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr855(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr857(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr859(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr861(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L851:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L862
m_L850:
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
m_L862:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L863
	lea	m_ostr865(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L863:
	movq	-32(%rbp), %rdi
	call	m_memory_block__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr867:
	.asciz "memory-block/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr868:
	.8byte	55
	.8byte	m_cstr867
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block_2Fevaluator_stub:
	.8byte	m_memory_block_2Fevaluator_stub__code
	.8byte	m_ostr868
	.globl m_memory_block_2Fevaluator_stub__code
	.type m_memory_block_2Fevaluator_stub__code, @function
	.text
m_memory_block__3Elower_2Ffunction__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	$19, %rdi
	movq	$2, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr869:
	.asciz "memory-block->lower/function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr870:
	.8byte	57
	.8byte	m_cstr869
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block__3Elower_2Ffunction:
	.8byte	m_memory_block__3Elower_2Ffunction__code
	.8byte	m_ostr870
	.globl m_memory_block__3Elower_2Ffunction__code
	.type m_memory_block__3Elower_2Ffunction__code, @function
	.section .rodata
m_cstr873:
	.asciz "memory-block->lower/function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr874:
	.8byte	57
	.8byte	m_cstr873
	.section .rodata
m_cstr875:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr876:
	.8byte	15
	.8byte	m_cstr875
	.section .rodata
m_cstr877:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr878:
	.8byte	11
	.8byte	m_cstr877
	.section .rodata
m_cstr879:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr880:
	.8byte	35
	.8byte	m_cstr879
	.section .rodata
m_cstr881:
	.asciz "<memory-block>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr882:
	.8byte	29
	.8byte	m_cstr881
	.section .rodata
m_cstr884:
	.asciz "memory-block->lower/function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr885:
	.8byte	57
	.8byte	m_cstr884
	.section .rodata
m_cstr887:
	.asciz "memory-block->lower/function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr888:
	.8byte	57
	.8byte	m_cstr887
	.text
m_memory_block__3Elower_2Ffunction_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L871
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$11, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L872
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr874(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr876(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr878(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr880(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr882(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L872:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L883
m_L871:
	lea	m_ostr885(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L883:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L886
	lea	m_ostr888(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L886:
	movq	-32(%rbp), %rdi
	call	m_memory_block__3Elower_2Ffunction__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr890:
	.asciz "memory-block->lower/function/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr891:
	.8byte	87
	.8byte	m_cstr890
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block__3Elower_2Ffunction_2Fevaluator_stub:
	.8byte	m_memory_block__3Elower_2Ffunction_2Fevaluator_stub__code
	.8byte	m_ostr891
	.globl m_memory_block__3Elower_2Ffunction_2Fevaluator_stub__code
	.type m_memory_block__3Elower_2Ffunction_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr894:
	.asciz "memory-block/length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr895:
	.8byte	39
	.8byte	m_cstr894
	.section .rodata
m_cstr896:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr897:
	.8byte	15
	.8byte	m_cstr896
	.section .rodata
m_cstr898:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr899:
	.8byte	11
	.8byte	m_cstr898
	.section .rodata
m_cstr900:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr901:
	.8byte	35
	.8byte	m_cstr900
	.section .rodata
m_cstr902:
	.asciz "<memory-block>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr903:
	.8byte	29
	.8byte	m_cstr902
	.section .rodata
m_cstr905:
	.asciz "memory-block/length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr906:
	.8byte	39
	.8byte	m_cstr905
	.section .rodata
m_cstr908:
	.asciz "memory-block/length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr909:
	.8byte	39
	.8byte	m_cstr908
	.text
m_memory_block_2Flength_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L892
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$11, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L893
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr895(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr897(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr899(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr901(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr903(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L893:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L904
m_L892:
	lea	m_ostr906(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L904:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L907
	lea	m_ostr909(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L907:
	movq	-32(%rbp), %rdi
	call	m_memory_block_2Flength__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr911:
	.asciz "memory-block/length/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr912:
	.8byte	69
	.8byte	m_cstr911
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block_2Flength_2Fevaluator_stub:
	.8byte	m_memory_block_2Flength_2Fevaluator_stub__code
	.8byte	m_ostr912
	.globl m_memory_block_2Flength_2Fevaluator_stub__code
	.type m_memory_block_2Flength_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr915:
	.asciz "memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr916:
	.8byte	31
	.8byte	m_cstr915
	.section .rodata
m_cstr917:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr918:
	.8byte	15
	.8byte	m_cstr917
	.section .rodata
m_cstr919:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr920:
	.8byte	11
	.8byte	m_cstr919
	.section .rodata
m_cstr921:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr922:
	.8byte	35
	.8byte	m_cstr921
	.section .rodata
m_cstr923:
	.asciz "<memory-block>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr924:
	.8byte	29
	.8byte	m_cstr923
	.section .rodata
m_cstr926:
	.asciz "memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr927:
	.8byte	31
	.8byte	m_cstr926
	.section .rodata
m_cstr930:
	.asciz "memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr931:
	.8byte	31
	.8byte	m_cstr930
	.section .rodata
m_cstr932:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr933:
	.8byte	15
	.8byte	m_cstr932
	.section .rodata
m_cstr934:
	.asciz "idx"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr935:
	.8byte	7
	.8byte	m_cstr934
	.section .rodata
m_cstr936:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr937:
	.8byte	35
	.8byte	m_cstr936
	.section .rodata
m_cstr938:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr939:
	.8byte	13
	.8byte	m_cstr938
	.section .rodata
m_cstr941:
	.asciz "memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr942:
	.8byte	31
	.8byte	m_cstr941
	.section .rodata
m_cstr944:
	.asciz "memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr945:
	.8byte	31
	.8byte	m_cstr944
	.text
m_memory_block_2Fat_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L913
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$11, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L914
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr916(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr918(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr920(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr922(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr924(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L914:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L925
m_L913:
	lea	m_ostr927(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L925:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L928
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L929
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr931(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr933(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr935(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr937(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr939(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L929:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L940
m_L928:
	lea	m_ostr942(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L940:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L943
	lea	m_ostr945(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L943:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_memory_block_2Fat__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr947:
	.asciz "memory-block/at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr948:
	.8byte	61
	.8byte	m_cstr947
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block_2Fat_2Fevaluator_stub:
	.8byte	m_memory_block_2Fat_2Fevaluator_stub__code
	.8byte	m_ostr948
	.globl m_memory_block_2Fat_2Fevaluator_stub__code
	.type m_memory_block_2Fat_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr951:
	.asciz "set-memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr952:
	.8byte	39
	.8byte	m_cstr951
	.section .rodata
m_cstr953:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr954:
	.8byte	15
	.8byte	m_cstr953
	.section .rodata
m_cstr955:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr956:
	.8byte	11
	.8byte	m_cstr955
	.section .rodata
m_cstr957:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr958:
	.8byte	35
	.8byte	m_cstr957
	.section .rodata
m_cstr959:
	.asciz "<memory-block>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr960:
	.8byte	29
	.8byte	m_cstr959
	.section .rodata
m_cstr962:
	.asciz "set-memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr963:
	.8byte	39
	.8byte	m_cstr962
	.section .rodata
m_cstr966:
	.asciz "set-memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr967:
	.8byte	39
	.8byte	m_cstr966
	.section .rodata
m_cstr968:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr969:
	.8byte	15
	.8byte	m_cstr968
	.section .rodata
m_cstr970:
	.asciz "idx"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr971:
	.8byte	7
	.8byte	m_cstr970
	.section .rodata
m_cstr972:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr973:
	.8byte	35
	.8byte	m_cstr972
	.section .rodata
m_cstr974:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr975:
	.8byte	13
	.8byte	m_cstr974
	.section .rodata
m_cstr977:
	.asciz "set-memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr978:
	.8byte	39
	.8byte	m_cstr977
	.section .rodata
m_cstr981:
	.asciz "set-memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr982:
	.8byte	39
	.8byte	m_cstr981
	.section .rodata
m_cstr984:
	.asciz "set-memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr985:
	.8byte	39
	.8byte	m_cstr984
	.section .rodata
m_cstr991:
	.asciz "set-memory-block/at doesn't know how to handle value: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr992:
	.8byte	109
	.8byte	m_cstr991
	.text
m_set_memory_block_2Fat_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L949
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	$11, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L950
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr952(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr954(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr956(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr958(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr960(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L950:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L961
m_L949:
	lea	m_ostr963(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L961:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L964
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L965
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr967(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr969(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr971(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr973(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr975(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L965:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L976
m_L964:
	lea	m_ostr978(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L976:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L979
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L980
m_L979:
	lea	m_ostr982(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L980:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L983
	lea	m_ostr985(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L983:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	$7, %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L987
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, %rbx
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_set_memory_block_2Fat__code
	add	$0, %rsp
	jmp	m_L988
m_L987:
	movq	-56(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	$20, %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L989
	mov	-40(%rbp), %rax
	add	$8, %rax
	mov	%rax, %rbx
	movq	-32(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_set_memory_block_2Fat__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -64(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -72(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	-72(%rbp), %rcx
	lea	(%rax, %rcx, 1), %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	jmp	m_L990
m_L989:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr992(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-48(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L990:
m_L988:
	mov	-48(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr993:
	.asciz "set-memory-block/at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr994:
	.8byte	69
	.8byte	m_cstr993
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_memory_block_2Fat_2Fevaluator_stub:
	.8byte	m_set_memory_block_2Fat_2Fevaluator_stub__code
	.8byte	m_ostr994
	.globl m_set_memory_block_2Fat_2Fevaluator_stub__code
	.type m_set_memory_block_2Fat_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr997:
	.asciz "cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr998:
	.8byte	15
	.8byte	m_cstr997
	.section .rodata
m_cstr1001:
	.asciz "cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1002:
	.8byte	15
	.8byte	m_cstr1001
	.section .rodata
m_cstr1003:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1004:
	.8byte	15
	.8byte	m_cstr1003
	.section .rodata
m_cstr1005:
	.asciz "byteindex"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1006:
	.8byte	19
	.8byte	m_cstr1005
	.section .rodata
m_cstr1007:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1008:
	.8byte	35
	.8byte	m_cstr1007
	.section .rodata
m_cstr1009:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1010:
	.8byte	13
	.8byte	m_cstr1009
	.section .rodata
m_cstr1012:
	.asciz "cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1013:
	.8byte	15
	.8byte	m_cstr1012
	.section .rodata
m_cstr1015:
	.asciz "cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1016:
	.8byte	15
	.8byte	m_cstr1015
	.text
m_cell_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L995
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L996
m_L995:
	lea	m_ostr998(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L996:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L999
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1000
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1002(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1004(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1006(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1008(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1010(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1000:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1011
m_L999:
	lea	m_ostr1013(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1011:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1014
	lea	m_ostr1016(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1014:
	xor	%rax, %rax
	mov	$20, %rax
	mov	%rax, %rbx
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	mov	-48(%rbp), %rcx
	lea	(%rax, %rcx, 1), %rcx
	mov	(%rcx), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m__25allocate_boxed_word__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1018:
	.asciz "cell-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1019:
	.8byte	45
	.8byte	m_cstr1018
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_cell_at_2Fevaluator_stub:
	.8byte	m_cell_at_2Fevaluator_stub__code
	.8byte	m_ostr1019
	.globl m_cell_at_2Fevaluator_stub__code
	.type m_cell_at_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr1022:
	.asciz "set-cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1023:
	.8byte	23
	.8byte	m_cstr1022
	.section .rodata
m_cstr1026:
	.asciz "set-cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1027:
	.8byte	23
	.8byte	m_cstr1026
	.section .rodata
m_cstr1028:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1029:
	.8byte	15
	.8byte	m_cstr1028
	.section .rodata
m_cstr1030:
	.asciz "byteindex"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1031:
	.8byte	19
	.8byte	m_cstr1030
	.section .rodata
m_cstr1032:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1033:
	.8byte	35
	.8byte	m_cstr1032
	.section .rodata
m_cstr1034:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1035:
	.8byte	13
	.8byte	m_cstr1034
	.section .rodata
m_cstr1037:
	.asciz "set-cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1038:
	.8byte	23
	.8byte	m_cstr1037
	.section .rodata
m_cstr1041:
	.asciz "set-cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1042:
	.8byte	23
	.8byte	m_cstr1041
	.section .rodata
m_cstr1044:
	.asciz "set-cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1045:
	.8byte	23
	.8byte	m_cstr1044
	.section .rodata
m_cstr1051:
	.asciz "set-cell-at called with an unexpected type: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1052:
	.8byte	89
	.8byte	m_cstr1051
	.text
m_set_cell_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1020
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1021
m_L1020:
	lea	m_ostr1023(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1021:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1024
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1025
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1027(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1029(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1031(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1033(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1035(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1025:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1036
m_L1024:
	lea	m_ostr1038(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1036:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1039
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1040
m_L1039:
	lea	m_ostr1042(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1040:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1043
	lea	m_ostr1045(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1043:
	xor	%rax, %rax
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	$20, %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1047
	mov	-48(%rbp), %rax
	mov	(%rax), %rax
	jmp	m_L1048
m_L1047:
	movq	-56(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	$7, %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1049
	mov	-48(%rbp), %rax
	jmp	m_L1050
m_L1049:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1052(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-48(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1050:
m_L1048:
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	mov	-64(%rbp), %rcx
	lea	(%rax, %rcx, 1), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1053:
	.asciz "set-cell-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1054:
	.8byte	53
	.8byte	m_cstr1053
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_cell_at_2Fevaluator_stub:
	.8byte	m_set_cell_at_2Fevaluator_stub__code
	.8byte	m_ostr1054
	.globl m_set_cell_at_2Fevaluator_stub__code
	.type m_set_cell_at_2Fevaluator_stub__code, @function
	.text
m_memory_block_2Fensure_capacity_2Fcell__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	add	$1, %rax
	mov	$8, %rcx
	mul	%rcx
	sub	$1, %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_set_memory_block_2Fat__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1055:
	.asciz "memory-block/ensure-capacity/cell"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1056:
	.8byte	67
	.8byte	m_cstr1055
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_memory_block_2Fensure_capacity_2Fcell:
	.8byte	m_memory_block_2Fensure_capacity_2Fcell__code
	.8byte	m_ostr1056
	.globl m_memory_block_2Fensure_capacity_2Fcell__code
	.type m_memory_block_2Fensure_capacity_2Fcell__code, @function
	.section .rodata
m_cstr1067:
	.asciz "to-lower-array: cannot handle passed obj of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1068:
	.8byte	99
	.8byte	m_cstr1067
	.text
m_to_lower_array__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	$4, %rdi
	call	m_memory_block__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$6, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1057
	jmp	m_L1058
m_L1057:
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$10, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1059
	movq	-8(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$1, %rax
	add	-48(%rbp),%rax
	mov	%rax, -48(%rbp)
	jmp	m_L1061
m_L1060:
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_memory_block_2Fensure_capacity_2Fcell__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25string__3EC_string__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	-64(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	add	$1, %rax
	mov	%rax, -32(%rbp)
m_L1061:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1060
	jmp	m_L1062
m_L1059:
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$18, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1063
	jmp	m_L1065
m_L1064:
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_memory_block_2Fensure_capacity_2Fcell__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -48(%rbp)
	movq	-48(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-48(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25string__3EC_string__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	-56(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	add	$1, %rax
	mov	%rax, -32(%rbp)
m_L1065:
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1064
	jmp	m_L1066
m_L1063:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1068(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1066:
m_L1062:
m_L1058:
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1069:
	.asciz "to-lower-array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1070:
	.8byte	29
	.8byte	m_cstr1069
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_to_lower_array:
	.8byte	m_to_lower_array__code
	.8byte	m_ostr1070
	.globl m_to_lower_array__code
	.type m_to_lower_array__code, @function
	.text
m_string_insert_all__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	jmp	m_L1072
m_L1071:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_string_at__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-56(%rbp), %rdx
	call	m_string_insert__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	add	$1, %rax
	mov	%rax, -16(%rbp)
	mov	-40(%rbp), %rax
	add	$1, %rax
	mov	%rax, -40(%rbp)
m_L1072:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1071
	mov	-8(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1073:
	.asciz "string-insert-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1074:
	.8byte	35
	.8byte	m_cstr1073
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_insert_all:
	.8byte	m_string_insert_all__code
	.8byte	m_ostr1074
	.globl m_string_insert_all__code
	.type m_string_insert_all__code, @function
	.section .rodata
m_cstr1077:
	.asciz "string-insert-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1078:
	.8byte	35
	.8byte	m_cstr1077
	.section .rodata
m_cstr1079:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1080:
	.8byte	15
	.8byte	m_cstr1079
	.section .rodata
m_cstr1081:
	.asciz "str"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1082:
	.8byte	7
	.8byte	m_cstr1081
	.section .rodata
m_cstr1083:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1084:
	.8byte	35
	.8byte	m_cstr1083
	.section .rodata
m_cstr1085:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1086:
	.8byte	17
	.8byte	m_cstr1085
	.section .rodata
m_cstr1088:
	.asciz "string-insert-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1089:
	.8byte	35
	.8byte	m_cstr1088
	.section .rodata
m_cstr1092:
	.asciz "string-insert-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1093:
	.8byte	35
	.8byte	m_cstr1092
	.section .rodata
m_cstr1094:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1095:
	.8byte	15
	.8byte	m_cstr1094
	.section .rodata
m_cstr1096:
	.asciz "idx"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1097:
	.8byte	7
	.8byte	m_cstr1096
	.section .rodata
m_cstr1098:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1099:
	.8byte	35
	.8byte	m_cstr1098
	.section .rodata
m_cstr1100:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1101:
	.8byte	13
	.8byte	m_cstr1100
	.section .rodata
m_cstr1103:
	.asciz "string-insert-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1104:
	.8byte	35
	.8byte	m_cstr1103
	.section .rodata
m_cstr1107:
	.asciz "string-insert-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1108:
	.8byte	35
	.8byte	m_cstr1107
	.section .rodata
m_cstr1109:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1110:
	.8byte	15
	.8byte	m_cstr1109
	.section .rodata
m_cstr1111:
	.asciz "insertion"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1112:
	.8byte	19
	.8byte	m_cstr1111
	.section .rodata
m_cstr1113:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1114:
	.8byte	35
	.8byte	m_cstr1113
	.section .rodata
m_cstr1115:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1116:
	.8byte	17
	.8byte	m_cstr1115
	.section .rodata
m_cstr1118:
	.asciz "string-insert-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1119:
	.8byte	35
	.8byte	m_cstr1118
	.section .rodata
m_cstr1121:
	.asciz "string-insert-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1122:
	.8byte	35
	.8byte	m_cstr1121
	.text
m_string_insert_all_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1075
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1076
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1078(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1080(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1082(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1084(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1086(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1076:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1087
m_L1075:
	lea	m_ostr1089(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1087:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1090
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1091
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1093(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1095(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1097(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1099(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1101(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1091:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1102
m_L1090:
	lea	m_ostr1104(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1102:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1105
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	movq	-48(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1106
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1108(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1110(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1112(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1114(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1116(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1106:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1117
m_L1105:
	lea	m_ostr1119(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1117:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1120
	lea	m_ostr1122(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1120:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_string_insert_all__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1124:
	.asciz "string-insert-all/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1125:
	.8byte	65
	.8byte	m_cstr1124
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_insert_all_2Fevaluator_stub:
	.8byte	m_string_insert_all_2Fevaluator_stub__code
	.8byte	m_ostr1125
	.globl m_string_insert_all_2Fevaluator_stub__code
	.type m_string_insert_all_2Fevaluator_stub__code, @function
	.text
m_string_append_all__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-16(%rbp), %rdx
	call	m_string_insert_all__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1126:
	.asciz "string-append-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1127:
	.8byte	35
	.8byte	m_cstr1126
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_append_all:
	.8byte	m_string_append_all__code
	.8byte	m_ostr1127
	.globl m_string_append_all__code
	.type m_string_append_all__code, @function
	.text
m_set_string_length__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1128:
	.asciz "set-string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1129:
	.8byte	35
	.8byte	m_cstr1128
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_string_length:
	.8byte	m_set_string_length__code
	.8byte	m_ostr1129
	.globl m_set_string_length__code
	.type m_set_string_length__code, @function
	.section .rodata
m_cstr1132:
	.asciz "set-string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1133:
	.8byte	35
	.8byte	m_cstr1132
	.section .rodata
m_cstr1134:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1135:
	.8byte	15
	.8byte	m_cstr1134
	.section .rodata
m_cstr1136:
	.asciz "obj"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1137:
	.8byte	7
	.8byte	m_cstr1136
	.section .rodata
m_cstr1138:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1139:
	.8byte	35
	.8byte	m_cstr1138
	.section .rodata
m_cstr1140:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1141:
	.8byte	17
	.8byte	m_cstr1140
	.section .rodata
m_cstr1143:
	.asciz "set-string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1144:
	.8byte	35
	.8byte	m_cstr1143
	.section .rodata
m_cstr1147:
	.asciz "set-string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1148:
	.8byte	35
	.8byte	m_cstr1147
	.section .rodata
m_cstr1149:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1150:
	.8byte	15
	.8byte	m_cstr1149
	.section .rodata
m_cstr1151:
	.asciz "len"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1152:
	.8byte	7
	.8byte	m_cstr1151
	.section .rodata
m_cstr1153:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1154:
	.8byte	35
	.8byte	m_cstr1153
	.section .rodata
m_cstr1155:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1156:
	.8byte	13
	.8byte	m_cstr1155
	.section .rodata
m_cstr1158:
	.asciz "set-string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1159:
	.8byte	35
	.8byte	m_cstr1158
	.section .rodata
m_cstr1161:
	.asciz "set-string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1162:
	.8byte	35
	.8byte	m_cstr1161
	.text
m_set_string_length_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1130
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1131
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1133(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1135(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1137(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1139(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1141(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1131:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1142
m_L1130:
	lea	m_ostr1144(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1142:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1145
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1146
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1148(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1150(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1152(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1154(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1156(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1146:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1157
m_L1145:
	lea	m_ostr1159(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1157:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1160
	lea	m_ostr1162(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1160:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_set_string_length__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1164:
	.asciz "set-string-length/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1165:
	.8byte	65
	.8byte	m_cstr1164
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_string_length_2Fevaluator_stub:
	.8byte	m_set_string_length_2Fevaluator_stub__code
	.8byte	m_ostr1165
	.globl m_set_string_length_2Fevaluator_stub__code
	.type m_set_string_length_2Fevaluator_stub__code, @function
	.text
m_string_compare__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$96, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	movq	-16(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_min__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	xor	%rax, %rax
	mov	%rax, -72(%rbp)
	jmp	m_L1167
m_L1166:
	mov	-72(%rbp), %rax
	add	$1, %rax
	mov	%rax, -72(%rbp)
m_L1167:
	mov	-56(%rbp), %rax
	mov	%rax, -80(%rbp)
	mov	-72(%rbp), %rax
	cmp	-80(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1168
	mov	-72(%rbp), %rax
	mov	%rax, -80(%rbp)
	mov	-48(%rbp), %rax
	mov	-80(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
	mov	%rax, -80(%rbp)
	mov	-72(%rbp), %rax
	mov	%rax, -88(%rbp)
	mov	-40(%rbp), %rax
	mov	-88(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
	sub	-80(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	%rax, -80(%rbp)
	xor	%rax, %rax
	cmp	-80(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L1168:
	test	%rax, %rax
	jne	m_L1166
	mov	-64(%rbp), %rax
	mov	%rax, -80(%rbp)
	xor	%rax, %rax
	cmp	-80(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1170
	mov	-32(%rbp), %rax
	mov	%rax, -80(%rbp)
	mov	-24(%rbp), %rax
	cmp	-80(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L1170:
	test	%rax, %rax
	je	m_L1169
	mov	-64(%rbp), %rax
	jmp	m_L1171
m_L1169:
	mov	-32(%rbp), %rax
	mov	%rax, -80(%rbp)
	mov	-24(%rbp), %rax
	cmp	-80(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1172
	mov	-24(%rbp), %rax
	mov	%rax, -80(%rbp)
	mov	-48(%rbp), %rax
	mov	-80(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
	mov	%rax, -80(%rbp)
	xor	%rax, %rax
	sub	-80(%rbp), %rax
	jmp	m_L1173
m_L1172:
	mov	-32(%rbp), %rax
	mov	%rax, -80(%rbp)
	mov	-40(%rbp), %rax
	mov	-80(%rbp), %rcx
	lea	(%rax, %rcx), %rcx
	xor	%rax, %rax
	mov	(%rcx), %al
	sub	$0, %rax
m_L1173:
m_L1171:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1174:
	.asciz "string-compare"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1175:
	.8byte	29
	.8byte	m_cstr1174
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_compare:
	.8byte	m_string_compare__code
	.8byte	m_ostr1175
	.globl m_string_compare__code
	.type m_string_compare__code, @function
	.text
m_string_3D__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_string_compare__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1176:
	.asciz "string="
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1177:
	.8byte	15
	.8byte	m_cstr1176
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_3D:
	.8byte	m_string_3D__code
	.8byte	m_ostr1177
	.globl m_string_3D__code
	.type m_string_3D__code, @function
	.text
m_array_binary_search__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-8(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	sub	$1, %rax
	mov	%rax, -48(%rbp)
	jmp	m_L1179
m_L1178:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	add	-56(%rbp),%rax
	xor	%rdx, %rdx
	mov	$2, %rcx
	idiv	%rcx
	mov	%rax, -56(%rbp)
	movq	-8(%rbp), %rdi
	movq	-56(%rbp), %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	movq	-16(%rbp), %rdi
	movq	-64(%rbp), %rsi
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	mov	-72(%rbp), %rax
	test	%rax, %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1180
	mov	-56(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -48(%rbp)
	jmp	m_L1181
m_L1180:
	mov	-72(%rbp), %rax
	test	%rax, %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1182
	mov	-56(%rbp), %rax
	add	$1, %rax
	mov	%rax, -40(%rbp)
	jmp	m_L1183
m_L1182:
	mov	-64(%rbp), %rax
	jmp	m_L1184
m_L1183:
m_L1181:
m_L1179:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1178
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L1185
	movq	-8(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-16(%rbp), %rdx
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	jmp	m_L1186
m_L1185:
	xor	%rax, %rax
m_L1186:
m_L1184:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1187:
	.asciz "array-binary-search"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1188:
	.8byte	39
	.8byte	m_cstr1187
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_binary_search:
	.8byte	m_array_binary_search__code
	.8byte	m_ostr1188
	.globl m_array_binary_search__code
	.type m_array_binary_search__code, @function
	.text
m_C_string__3Estring_2A__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-16(%rbp), %rdi
	call	m_string__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-16(%rbp), %rdx
	call	m_copy_bytes__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1189:
	.asciz "C-string->string*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1190:
	.8byte	35
	.8byte	m_cstr1189
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_C_string__3Estring_2A:
	.8byte	m_C_string__3Estring_2A__code
	.8byte	m_ostr1190
	.globl m_C_string__3Estring_2A__code
	.type m_C_string__3Estring_2A__code, @function
	.text
m_C_string__3Estring__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_C_string_length__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_C_string__3Estring_2A__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1191:
	.asciz "C-string->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1192:
	.8byte	33
	.8byte	m_cstr1191
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_C_string__3Estring:
	.8byte	m_C_string__3Estring__code
	.8byte	m_ostr1192
	.globl m_C_string__3Estring__code
	.type m_C_string__3Estring__code, @function
	.text
m_digit__3Echar__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	cmp	$9, %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1193
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$48, %rax
	add	-16(%rbp),%rax
	jmp	m_L1194
m_L1193:
	mov	-8(%rbp), %rax
	sub	$10, %rax
	mov	%rax, -16(%rbp)
	mov	$97, %rax
	add	-16(%rbp),%rax
m_L1194:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1195:
	.asciz "digit->char"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1196:
	.8byte	23
	.8byte	m_cstr1195
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_digit__3Echar:
	.8byte	m_digit__3Echar__code
	.8byte	m_ostr1196
	.globl m_digit__3Echar__code
	.type m_digit__3Echar__code, @function
	.text
m_positive_long__3Estring__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-8(%rbp), %rax
	cmp	-32(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1197
	movq	-8(%rbp), %rdi
	call	m_digit__3Echar__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	jmp	m_L1198
m_L1197:
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-8(%rbp), %rax
	xor	%rdx, %rdx
	divq	-32(%rbp)
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_positive_long__3Estring__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	mulq	-40(%rbp)
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	sub	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_digit__3Echar__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
m_L1198:
	mov	-8(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1199:
	.asciz "positive-long->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1200:
	.8byte	43
	.8byte	m_cstr1199
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_positive_long__3Estring:
	.8byte	m_positive_long__3Estring__code
	.8byte	m_ostr1200
	.globl m_positive_long__3Estring__code
	.type m_positive_long__3Estring__code, @function
	.section .data
m__25long__3Estring_2Fbuffer:
	.8byte	0
	.section .rodata
m_cstr1203:
	.asciz "kernel assertion failed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1204:
	.8byte	47
	.8byte	m_cstr1203
	.text
m_code1205:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	lea	m__25long__3Estring_2Fbuffer(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_string_append__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure1206:
	.8byte	m_code1205
	.8byte	0
	.text
m_long__3Estring_2A__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	cmp	-24(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1202
	mov	-16(%rbp), %rax
	cmp	$35, %rax
	setle	%al
	movzb	%al, %rax
m_L1202:
	test	%rax, %rax
	jne	m_L1201
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1204(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1201:
	movq	$10, %rdi
	call	m_string__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	lea	m__25long__3Estring_2Fbuffer(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_oclosure1206(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1207:
	.asciz "long->string*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1208:
	.8byte	27
	.8byte	m_cstr1207
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_long__3Estring_2A:
	.8byte	m_long__3Estring_2A__code
	.8byte	m_ostr1208
	.globl m_long__3Estring_2A__code
	.type m_long__3Estring_2A__code, @function
	.text
m_long__3Estring__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	movq	$10, %rsi
	call	m_long__3Estring_2A__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1209:
	.asciz "long->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1210:
	.8byte	25
	.8byte	m_cstr1209
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_long__3Estring:
	.8byte	m_long__3Estring__code
	.8byte	m_ostr1210
	.globl m_long__3Estring__code
	.type m_long__3Estring__code, @function
	.section .rodata
m_cstr1213:
	.asciz "kernel assertion failed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1214:
	.8byte	47
	.8byte	m_cstr1213
	.text
m_string__3Elong_2A__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	cmp	-24(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1212
	mov	-16(%rbp), %rax
	cmp	$35, %rax
	setle	%al
	movzb	%al, %rax
m_L1212:
	test	%rax, %rax
	jne	m_L1211
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1214(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1211:
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-8(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1216
	movq	-8(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_string_at__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	$45, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L1216:
	test	%rax, %rax
	je	m_L1215
	mov	-48(%rbp), %rax
	neg	%rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	add	$1, %rax
	mov	%rax, -32(%rbp)
m_L1215:
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	sub	-56(%rbp), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1218
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	jmp	m_L1219
m_L1218:
	jmp	m_L1221
m_L1220:
	movq	-8(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_string_at__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	$48, %rax
	cmp	-64(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1223
	mov	-56(%rbp), %rax
	cmp	$57, %rax
	setle	%al
	movzb	%al, %rax
m_L1223:
	test	%rax, %rax
	je	m_L1222
	mov	-56(%rbp), %rax
	sub	$48, %rax
	jmp	m_L1224
m_L1222:
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	$65, %rax
	cmp	-64(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1226
	mov	-56(%rbp), %rax
	cmp	$90, %rax
	setle	%al
	movzb	%al, %rax
m_L1226:
	test	%rax, %rax
	je	m_L1225
	mov	-56(%rbp), %rax
	sub	$65, %rax
	mov	%rax, -64(%rbp)
	mov	$10, %rax
	add	-64(%rbp),%rax
	jmp	m_L1227
m_L1225:
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	$97, %rax
	cmp	-64(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1229
	mov	-56(%rbp), %rax
	cmp	$122, %rax
	setle	%al
	movzb	%al, %rax
m_L1229:
	test	%rax, %rax
	je	m_L1228
	mov	-56(%rbp), %rax
	sub	$97, %rax
	mov	%rax, -64(%rbp)
	mov	$10, %rax
	add	-64(%rbp),%rax
	jmp	m_L1230
m_L1228:
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	jmp	m_L1231
m_L1230:
m_L1227:
m_L1224:
	mov	%rax, -64(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -72(%rbp)
	mov	-64(%rbp), %rax
	cmp	-72(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1232
	xor	%rax, %rax
	jmp	m_L1233
m_L1232:
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	jmp	m_L1231
m_L1233:
	mov	-64(%rbp), %rax
	mov	%rax, -72(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -80(%rbp)
	mov	-16(%rbp), %rax
	mulq	-80(%rbp)
	add	-72(%rbp),%rax
	mov	%rax, -24(%rbp)
	mov	-32(%rbp), %rax
	add	$1, %rax
	mov	%rax, -32(%rbp)
m_L1221:
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1220
	mov	-24(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-48(%rbp), %rax
	mulq	-56(%rbp)
m_L1219:
m_L1231:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1234:
	.asciz "string->long*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1235:
	.8byte	27
	.8byte	m_cstr1234
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string__3Elong_2A:
	.8byte	m_string__3Elong_2A__code
	.8byte	m_ostr1235
	.globl m_string__3Elong_2A__code
	.type m_string__3Elong_2A__code, @function
	.section .rodata
m_cstr1237:
	.asciz "string->long: failed for "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1238:
	.8byte	51
	.8byte	m_cstr1237
	.text
m_string__3Elong__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	movq	$10, %rsi
	call	m_string__3Elong_2A__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1236
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1238(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1236:
	mov	-16(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1240:
	.asciz "string->long"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1241:
	.8byte	25
	.8byte	m_cstr1240
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string__3Elong:
	.8byte	m_string__3Elong__code
	.8byte	m_ostr1241
	.globl m_string__3Elong__code
	.type m_string__3Elong__code, @function
	.section .rodata
m_cstr1244:
	.asciz "string->symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1245:
	.8byte	29
	.8byte	m_cstr1244
	.section .rodata
m_cstr1246:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1247:
	.8byte	15
	.8byte	m_cstr1246
	.section .rodata
m_cstr1248:
	.asciz "str"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1249:
	.8byte	7
	.8byte	m_cstr1248
	.section .rodata
m_cstr1250:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1251:
	.8byte	35
	.8byte	m_cstr1250
	.section .rodata
m_cstr1252:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1253:
	.8byte	17
	.8byte	m_cstr1252
	.section .rodata
m_cstr1255:
	.asciz "string->symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1256:
	.8byte	29
	.8byte	m_cstr1255
	.section .rodata
m_cstr1258:
	.asciz "string->symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1259:
	.8byte	29
	.8byte	m_cstr1258
	.text
m_string__3Esymbol_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1242
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1243
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1245(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1247(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1249(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1251(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1253(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1243:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1254
m_L1242:
	lea	m_ostr1256(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1254:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1257
	lea	m_ostr1259(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1257:
	movq	-32(%rbp), %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1261:
	.asciz "string->symbol/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1262:
	.8byte	59
	.8byte	m_cstr1261
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string__3Esymbol_2Fevaluator_stub:
	.8byte	m_string__3Esymbol_2Fevaluator_stub__code
	.8byte	m_ostr1262
	.globl m_string__3Esymbol_2Fevaluator_stub__code
	.type m_string__3Esymbol_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr1267:
	.asciz "symbol->string: illegal value: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1268:
	.8byte	63
	.8byte	m_cstr1267
	.text
m_symbol__3Estring__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1263
	mov	-8(%rbp), %rax
	jmp	m_L1264
m_L1263:
	movq	-8(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1265
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	jmp	m_L1266
m_L1265:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1268(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1266:
m_L1264:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1269:
	.asciz "symbol->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1270:
	.8byte	29
	.8byte	m_cstr1269
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_symbol__3Estring:
	.8byte	m_symbol__3Estring__code
	.8byte	m_ostr1270
	.globl m_symbol__3Estring__code
	.type m_symbol__3Estring__code, @function
	.section .rodata
m_cstr1273:
	.asciz "symbol->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1274:
	.8byte	29
	.8byte	m_cstr1273
	.section .rodata
m_cstr1276:
	.asciz "symbol->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1277:
	.8byte	29
	.8byte	m_cstr1276
	.text
m_symbol__3Estring_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1271
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1272
m_L1271:
	lea	m_ostr1274(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1272:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1275
	lea	m_ostr1277(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1275:
	movq	-32(%rbp), %rdi
	call	m_symbol__3Estring__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1279:
	.asciz "symbol->string/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1280:
	.8byte	59
	.8byte	m_cstr1279
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_symbol__3Estring_2Fevaluator_stub:
	.8byte	m_symbol__3Estring_2Fevaluator_stub__code
	.8byte	m_ostr1280
	.globl m_symbol__3Estring_2Fevaluator_stub__code
	.type m_symbol__3Estring_2Fevaluator_stub__code, @function
	.text
m_maybe_variable_value__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	test	%rax, %rax
	je	m_L1281
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
m_L1281:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1283:
	.asciz "maybe-variable-value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1284:
	.8byte	41
	.8byte	m_cstr1283
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_maybe_variable_value:
	.8byte	m_maybe_variable_value__code
	.8byte	m_ostr1284
	.globl m_maybe_variable_value__code
	.type m_maybe_variable_value__code, @function
	.text
m_find_local_variable__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	jmp	m_L1286
m_L1285:
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-48(%rbp), %rax
	mov	-56(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, -56(%rbp)
	mov	-56(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -64(%rbp)
	mov	-16(%rbp), %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1287
	mov	-56(%rbp), %rax
m_L1287:
	mov	%rax, -40(%rbp)
m_L1286:
	mov	-40(%rbp), %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1288
	mov	-32(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -32(%rbp)
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
m_L1288:
	test	%rax, %rax
	jne	m_L1285
	mov	-40(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1289:
	.asciz "find-local-variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1290:
	.8byte	39
	.8byte	m_cstr1289
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_find_local_variable:
	.8byte	m_find_local_variable__code
	.8byte	m_ostr1290
	.globl m_find_local_variable__code
	.type m_find_local_variable__code, @function
	.section .rodata
m_cstr1293:
	.asciz "defined?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1294:
	.8byte	17
	.8byte	m_cstr1293
	.section .rodata
m_cstr1295:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1296:
	.8byte	15
	.8byte	m_cstr1295
	.section .rodata
m_cstr1297:
	.asciz "name"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1298:
	.8byte	9
	.8byte	m_cstr1297
	.section .rodata
m_cstr1299:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1300:
	.8byte	35
	.8byte	m_cstr1299
	.section .rodata
m_cstr1301:
	.asciz "<symbol>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1302:
	.8byte	17
	.8byte	m_cstr1301
	.section .rodata
m_cstr1304:
	.asciz "defined?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1305:
	.8byte	17
	.8byte	m_cstr1304
	.section .rodata
m_cstr1308:
	.asciz "defined?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1309:
	.8byte	17
	.8byte	m_cstr1308
	.section .rodata
m_cstr1310:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1311:
	.8byte	15
	.8byte	m_cstr1310
	.section .rodata
m_cstr1312:
	.asciz "env"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1313:
	.8byte	7
	.8byte	m_cstr1312
	.section .rodata
m_cstr1314:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1315:
	.8byte	35
	.8byte	m_cstr1314
	.section .rodata
m_cstr1316:
	.asciz "<env>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1317:
	.8byte	11
	.8byte	m_cstr1316
	.section .rodata
m_cstr1320:
	.asciz "defined?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1321:
	.8byte	17
	.8byte	m_cstr1320
	.text
m_defined_3F_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1291
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1292
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1294(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1296(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1298(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1300(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1302(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1292:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1303
m_L1291:
	lea	m_ostr1305(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1303:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1306
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$16, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1307
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1309(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1311(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1313(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1315(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1317(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1307:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1318
m_L1306:
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
m_L1318:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1319
	lea	m_ostr1321(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1319:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1323:
	.asciz "defined?/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1324:
	.8byte	47
	.8byte	m_cstr1323
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_defined_3F_2Fevaluator_stub:
	.8byte	m_defined_3F_2Fevaluator_stub__code
	.8byte	m_ostr1324
	.globl m_defined_3F_2Fevaluator_stub__code
	.type m_defined_3F_2Fevaluator_stub__code, @function
	.text
m_new_variable__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-8(%rbp), %rdx
	movq	-24(%rbp), %rcx
	call	m_variable__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$1, %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-8(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-32(%rbp), %rsi
	call	m_array_append__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1325:
	.asciz "new-variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1326:
	.8byte	25
	.8byte	m_cstr1325
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_new_variable:
	.8byte	m_new_variable__code
	.8byte	m_ostr1326
	.globl m_new_variable__code
	.type m_new_variable__code, @function
	.section .rodata
m_cstr1329:
	.asciz "environment-define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1330:
	.8byte	37
	.8byte	m_cstr1329
	.section .rodata
m_cstr1331:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1332:
	.8byte	15
	.8byte	m_cstr1331
	.section .rodata
m_cstr1333:
	.asciz "env"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1334:
	.8byte	7
	.8byte	m_cstr1333
	.section .rodata
m_cstr1335:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1336:
	.8byte	35
	.8byte	m_cstr1335
	.section .rodata
m_cstr1337:
	.asciz "<env>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1338:
	.8byte	11
	.8byte	m_cstr1337
	.section .rodata
m_cstr1340:
	.asciz "environment-define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1341:
	.8byte	37
	.8byte	m_cstr1340
	.section .rodata
m_cstr1344:
	.asciz "environment-define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1345:
	.8byte	37
	.8byte	m_cstr1344
	.section .rodata
m_cstr1346:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1347:
	.8byte	15
	.8byte	m_cstr1346
	.section .rodata
m_cstr1348:
	.asciz "name"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1349:
	.8byte	9
	.8byte	m_cstr1348
	.section .rodata
m_cstr1350:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1351:
	.8byte	35
	.8byte	m_cstr1350
	.section .rodata
m_cstr1352:
	.asciz "<symbol>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1353:
	.8byte	17
	.8byte	m_cstr1352
	.section .rodata
m_cstr1355:
	.asciz "environment-define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1356:
	.8byte	37
	.8byte	m_cstr1355
	.section .rodata
m_cstr1359:
	.asciz "environment-define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1360:
	.8byte	37
	.8byte	m_cstr1359
	.section .rodata
m_cstr1362:
	.asciz "environment-define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1363:
	.8byte	37
	.8byte	m_cstr1362
	.text
m_environment_define_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1327
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	$16, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1328
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1330(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1332(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1334(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1336(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1338(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1328:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1339
m_L1327:
	lea	m_ostr1341(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1339:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1342
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1343
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1345(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1347(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1349(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1351(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1353(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1343:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1354
m_L1342:
	lea	m_ostr1356(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1354:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1357
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1358
m_L1357:
	lea	m_ostr1360(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1358:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1361
	lea	m_ostr1363(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1361:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_environment_define__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1365:
	.asciz "environment-define/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1366:
	.8byte	67
	.8byte	m_cstr1365
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_environment_define_2Fevaluator_stub:
	.8byte	m_environment_define_2Fevaluator_stub__code
	.8byte	m_ostr1366
	.globl m_environment_define_2Fevaluator_stub__code
	.type m_environment_define_2Fevaluator_stub__code, @function
	.text
m_maybe_object_in_variable__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1367
	movq	-24(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	$15, %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1367
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	test	%rax, %rax
	je	m_L1367
	mov	-16(%rbp), %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1368
	movq	-24(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L1368:
	test	%rax, %rax
	je	m_L1367
	mov	-24(%rbp), %rax
m_L1367:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1369:
	.asciz "maybe-object-in-variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1370:
	.8byte	49
	.8byte	m_cstr1369
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_maybe_object_in_variable:
	.8byte	m_maybe_object_in_variable__code
	.8byte	m_ostr1370
	.globl m_maybe_object_in_variable__code
	.type m_maybe_object_in_variable__code, @function
	.text
m_maybe_object_in_env__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	-16(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1371
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-24(%rbp), %rsi
	call	m_maybe_object_in_variable__code
	add	$0, %rsp
m_L1371:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1373:
	.asciz "maybe-object-in-env"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1374:
	.8byte	39
	.8byte	m_cstr1373
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_maybe_object_in_env:
	.8byte	m_maybe_object_in_env__code
	.8byte	m_ostr1374
	.globl m_maybe_object_in_env__code
	.type m_maybe_object_in_env__code, @function
	.section .rodata
m_cstr1376:
	.asciz "current-globals"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1377:
	.8byte	31
	.8byte	m_cstr1376
	.text
m_current_globals_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1375
	lea	m_ostr1377(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1375:
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1379:
	.asciz "current-globals/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1380:
	.8byte	61
	.8byte	m_cstr1379
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_current_globals_2Fevaluator_stub:
	.8byte	m_current_globals_2Fevaluator_stub__code
	.8byte	m_ostr1380
	.globl m_current_globals_2Fevaluator_stub__code
	.type m_current_globals_2Fevaluator_stub__code, @function
	.text
m_set_current_globals__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	m__2Aglobals_2A(%rip), %rcx
	mov	%rax, (%rcx)
	call	m_capture_well_known_globals__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1381:
	.asciz "set-current-globals"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1382:
	.8byte	39
	.8byte	m_cstr1381
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_current_globals:
	.8byte	m_set_current_globals__code
	.8byte	m_ostr1382
	.globl m_set_current_globals__code
	.type m_set_current_globals__code, @function
	.section .rodata
m_cstr1385:
	.asciz "set-current-globals"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1386:
	.8byte	39
	.8byte	m_cstr1385
	.section .rodata
m_cstr1387:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1388:
	.8byte	15
	.8byte	m_cstr1387
	.section .rodata
m_cstr1389:
	.asciz "env"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1390:
	.8byte	7
	.8byte	m_cstr1389
	.section .rodata
m_cstr1391:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1392:
	.8byte	35
	.8byte	m_cstr1391
	.section .rodata
m_cstr1393:
	.asciz "<env>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1394:
	.8byte	11
	.8byte	m_cstr1393
	.section .rodata
m_cstr1396:
	.asciz "set-current-globals"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1397:
	.8byte	39
	.8byte	m_cstr1396
	.section .rodata
m_cstr1399:
	.asciz "set-current-globals"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1400:
	.8byte	39
	.8byte	m_cstr1399
	.text
m_set_current_globals_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1383
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$16, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1384
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1386(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1388(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1390(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1392(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1394(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1384:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1395
m_L1383:
	lea	m_ostr1397(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1395:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1398
	lea	m_ostr1400(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1398:
	movq	-32(%rbp), %rdi
	call	m_set_current_globals__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1402:
	.asciz "set-current-globals/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1403:
	.8byte	69
	.8byte	m_cstr1402
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_current_globals_2Fevaluator_stub:
	.8byte	m_set_current_globals_2Fevaluator_stub__code
	.8byte	m_ostr1403
	.globl m_set_current_globals_2Fevaluator_stub__code
	.type m_set_current_globals_2Fevaluator_stub__code, @function
	.text
m_global_variable_3F__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -16(%rbp)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1404:
	.asciz "global-variable?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1405:
	.8byte	33
	.8byte	m_cstr1404
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_global_variable_3F:
	.8byte	m_global_variable_3F__code
	.8byte	m_ostr1405
	.globl m_global_variable_3F__code
	.type m_global_variable_3F__code, @function
	.text
m_code1406:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m__25ensure_peeked__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	test	%rax, %rax
	setl	%al
	movzb	%al, %rax
	add	$0, %rsp
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure1407:
	.8byte	m_code1406
	.8byte	0
	.section .data
m__24at_end_3F_2Emethod_table:
	.8byte	m_oclosure1407
	.section .rodata
m_cstr1411:
	.asciz "selector '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1412:
	.8byte	21
	.8byte	m_cstr1411
	.section .rodata
m_cstr1413:
	.asciz "$at-end?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1414:
	.8byte	17
	.8byte	m_cstr1413
	.section .rodata
m_cstr1415:
	.asciz "' has no method for type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1416:
	.8byte	51
	.8byte	m_cstr1415
	.text
m__24at_end_3F__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$26, %rax
	cmp	-24(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1409
	mov	-16(%rbp), %rax
	cmp	$26, %rax
	setle	%al
	movzb	%al, %rax
m_L1409:
	test	%rax, %rax
	je	m_L1408
	xor	%rax, %rax
	jmp	m_L1410
m_L1408:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1412(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1414(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1416(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1410:
	mov	-16(%rbp), %rax
	sub	$26, %rax
	mov	%rax, -24(%rbp)
	lea	m__24at_end_3F_2Emethod_table(%rip), %rax
	mov	-24(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1417:
	.asciz "$at-end?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1418:
	.8byte	17
	.8byte	m_cstr1417
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__24at_end_3F:
	.8byte	m__24at_end_3F__code
	.8byte	m_ostr1418
	.globl m__24at_end_3F__code
	.type m__24at_end_3F__code, @function
	.text
m_code1419:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m__25ensure_peeked__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1420
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	jmp	m_L1421
m_L1420:
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
m_L1421:
	add	$0, %rsp
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure1422:
	.8byte	m_code1419
	.8byte	0
	.section .data
m__24peek_2Emethod_table:
	.8byte	m_oclosure1422
	.section .rodata
m_cstr1426:
	.asciz "selector '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1427:
	.8byte	21
	.8byte	m_cstr1426
	.section .rodata
m_cstr1428:
	.asciz "$peek"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1429:
	.8byte	11
	.8byte	m_cstr1428
	.section .rodata
m_cstr1430:
	.asciz "' has no method for type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1431:
	.8byte	51
	.8byte	m_cstr1430
	.text
m__24peek__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$26, %rax
	cmp	-24(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1424
	mov	-16(%rbp), %rax
	cmp	$26, %rax
	setle	%al
	movzb	%al, %rax
m_L1424:
	test	%rax, %rax
	je	m_L1423
	xor	%rax, %rax
	jmp	m_L1425
m_L1423:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1427(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1429(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1431(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1425:
	mov	-16(%rbp), %rax
	sub	$26, %rax
	mov	%rax, -24(%rbp)
	lea	m__24peek_2Emethod_table(%rip), %rax
	mov	-24(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1432:
	.asciz "$peek"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1433:
	.8byte	11
	.8byte	m_cstr1432
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__24peek:
	.8byte	m__24peek__code
	.8byte	m_ostr1433
	.globl m__24peek__code
	.type m__24peek__code, @function
	.text
m_code1434:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m__25ensure_peeked__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1435
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	$-1, %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	jmp	m_L1436
m_L1435:
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
m_L1436:
	add	$0, %rsp
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure1437:
	.8byte	m_code1434
	.8byte	0
	.section .data
m__24next_2Emethod_table:
	.8byte	m_oclosure1437
	.section .rodata
m_cstr1441:
	.asciz "selector '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1442:
	.8byte	21
	.8byte	m_cstr1441
	.section .rodata
m_cstr1443:
	.asciz "$next"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1444:
	.8byte	11
	.8byte	m_cstr1443
	.section .rodata
m_cstr1445:
	.asciz "' has no method for type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1446:
	.8byte	51
	.8byte	m_cstr1445
	.text
m__24next__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$26, %rax
	cmp	-24(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1439
	mov	-16(%rbp), %rax
	cmp	$26, %rax
	setle	%al
	movzb	%al, %rax
m_L1439:
	test	%rax, %rax
	je	m_L1438
	xor	%rax, %rax
	jmp	m_L1440
m_L1438:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1442(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1444(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1446(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1440:
	mov	-16(%rbp), %rax
	sub	$26, %rax
	mov	%rax, -24(%rbp)
	lea	m__24next_2Emethod_table(%rip), %rax
	mov	-24(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1447:
	.asciz "$next"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1448:
	.8byte	11
	.8byte	m_cstr1447
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__24next:
	.8byte	m__24next__code
	.8byte	m_ostr1448
	.globl m__24next__code
	.type m__24next__code, @function
	.section .rodata
m_cstr1452:
	.asciz "<fd-stream> $put: write failed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1453:
	.8byte	61
	.8byte	m_cstr1452
	.text
m_code1449:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	-16(%rbp), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$1, %rdx
	call	m_posix_2Fwrite__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	$1, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1450
	xor	%rax, %rax
	jmp	m_L1451
m_L1450:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1453(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1451:
	mov	-16(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure1454:
	.8byte	m_code1449
	.8byte	0
	.section .data
m__24put_2Emethod_table:
	.8byte	m_oclosure1454
	.section .rodata
m_cstr1458:
	.asciz "selector '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1459:
	.8byte	21
	.8byte	m_cstr1458
	.section .rodata
m_cstr1460:
	.asciz "$put"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1461:
	.8byte	9
	.8byte	m_cstr1460
	.section .rodata
m_cstr1462:
	.asciz "' has no method for type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1463:
	.8byte	51
	.8byte	m_cstr1462
	.text
m__24put__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	$26, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1456
	mov	-24(%rbp), %rax
	cmp	$26, %rax
	setle	%al
	movzb	%al, %rax
m_L1456:
	test	%rax, %rax
	je	m_L1455
	xor	%rax, %rax
	jmp	m_L1457
m_L1455:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1459(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1461(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1463(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1457:
	mov	-24(%rbp), %rax
	sub	$26, %rax
	mov	%rax, -32(%rbp)
	lea	m__24put_2Emethod_table(%rip), %rax
	mov	-32(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	%rbx, %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1464:
	.asciz "$put"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1465:
	.8byte	9
	.8byte	m_cstr1464
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__24put:
	.8byte	m__24put__code
	.8byte	m_ostr1465
	.globl m__24put__code
	.type m__24put__code, @function
	.section .rodata
m_cstr1471:
	.asciz "<fd-stream> $put-all: unexpected elements: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1472:
	.8byte	87
	.8byte	m_cstr1471
	.text
m_code1466:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	push	%r12
	push	%r13
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	$12, %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1467
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	call	m__25string__3EC_string__code
	add	$0, %rsp
	mov	%rax, %r12
	movq	-16(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, %r13
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	%r13, %rdx
	call	m__25put_all__code
	add	$0, %rsp
	jmp	m_L1468
m_L1467:
	movq	-24(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	$11, %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1469
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %r12
	movq	-16(%rbp), %rdi
	call	m_memory_block_2Flength__code
	add	$0, %rsp
	mov	%rax, %r13
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	%r13, %rdx
	call	m__25put_all__code
	add	$0, %rsp
	jmp	m_L1470
m_L1469:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1472(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1470:
m_L1468:
	mov	-16(%rbp), %rax
	add	$8, %rsp
	pop	%r13
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure1473:
	.8byte	m_code1466
	.8byte	0
	.section .data
m__24put_all_2Emethod_table:
	.8byte	m_oclosure1473
	.section .rodata
m_cstr1477:
	.asciz "selector '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1478:
	.8byte	21
	.8byte	m_cstr1477
	.section .rodata
m_cstr1479:
	.asciz "$put-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1480:
	.8byte	17
	.8byte	m_cstr1479
	.section .rodata
m_cstr1481:
	.asciz "' has no method for type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1482:
	.8byte	51
	.8byte	m_cstr1481
	.text
m__24put_all__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	$26, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1475
	mov	-24(%rbp), %rax
	cmp	$26, %rax
	setle	%al
	movzb	%al, %rax
m_L1475:
	test	%rax, %rax
	je	m_L1474
	xor	%rax, %rax
	jmp	m_L1476
m_L1474:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1478(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1480(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1482(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1476:
	mov	-24(%rbp), %rax
	sub	$26, %rax
	mov	%rax, -32(%rbp)
	lea	m__24put_all_2Emethod_table(%rip), %rax
	mov	-32(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	%rbx, %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1483:
	.asciz "$put-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1484:
	.8byte	17
	.8byte	m_cstr1483
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__24put_all:
	.8byte	m__24put_all__code
	.8byte	m_ostr1484
	.globl m__24put_all__code
	.type m__24put_all__code, @function
	.text
m_is_blank__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$32, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1485
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$9, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1485
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$10, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1485
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$11, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1485
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$12, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1485
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$13, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L1485:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1486:
	.asciz "is_blank"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1487:
	.8byte	17
	.8byte	m_cstr1486
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_is_blank:
	.8byte	m_is_blank__code
	.8byte	m_ostr1487
	.globl m_is_blank__code
	.type m_is_blank__code, @function
	.text
m_is_alpha__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$97, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1489
	mov	-8(%rbp), %rax
	cmp	$122, %rax
	setle	%al
	movzb	%al, %rax
m_L1489:
	test	%rax, %rax
	jne	m_L1488
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$65, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1490
	mov	-8(%rbp), %rax
	cmp	$90, %rax
	setle	%al
	movzb	%al, %rax
m_L1490:
m_L1488:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1491:
	.asciz "is_alpha"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1492:
	.8byte	17
	.8byte	m_cstr1491
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_is_alpha:
	.8byte	m_is_alpha__code
	.8byte	m_ostr1492
	.globl m_is_alpha__code
	.type m_is_alpha__code, @function
	.text
m_is_letter__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$33, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$35, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1494
	mov	-8(%rbp), %rax
	cmp	$38, %rax
	setle	%al
	movzb	%al, %rax
m_L1494:
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$42, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1495
	mov	-8(%rbp), %rax
	cmp	$47, %rax
	setle	%al
	movzb	%al, %rax
m_L1495:
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$58, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$60, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1496
	mov	-8(%rbp), %rax
	cmp	$90, %rax
	setle	%al
	movzb	%al, %rax
m_L1496:
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$92, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$94, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$95, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$97, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1497
	mov	-8(%rbp), %rax
	cmp	$122, %rax
	setle	%al
	movzb	%al, %rax
m_L1497:
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$124, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1493
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$126, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L1493:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1498:
	.asciz "is_letter"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1499:
	.8byte	19
	.8byte	m_cstr1498
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_is_letter:
	.8byte	m_is_letter__code
	.8byte	m_ostr1499
	.globl m_is_letter__code
	.type m_is_letter__code, @function
	.text
m_is_digit8__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$48, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1500
	mov	-8(%rbp), %rax
	cmp	$55, %rax
	setle	%al
	movzb	%al, %rax
m_L1500:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1501:
	.asciz "is_digit8"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1502:
	.8byte	19
	.8byte	m_cstr1501
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_is_digit8:
	.8byte	m_is_digit8__code
	.8byte	m_ostr1502
	.globl m_is_digit8__code
	.type m_is_digit8__code, @function
	.text
m_is_digit10__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$48, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1503
	mov	-8(%rbp), %rax
	cmp	$57, %rax
	setle	%al
	movzb	%al, %rax
m_L1503:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1504:
	.asciz "is_digit10"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1505:
	.8byte	21
	.8byte	m_cstr1504
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_is_digit10:
	.8byte	m_is_digit10__code
	.8byte	m_ostr1505
	.globl m_is_digit10__code
	.type m_is_digit10__code, @function
	.text
m_is_digit16__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$48, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1507
	mov	-8(%rbp), %rax
	cmp	$57, %rax
	setle	%al
	movzb	%al, %rax
m_L1507:
	test	%rax, %rax
	jne	m_L1506
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$97, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1508
	mov	-8(%rbp), %rax
	cmp	$102, %rax
	setle	%al
	movzb	%al, %rax
m_L1508:
	test	%rax, %rax
	jne	m_L1506
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$65, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1509
	mov	-8(%rbp), %rax
	cmp	$70, %rax
	setle	%al
	movzb	%al, %rax
m_L1509:
m_L1506:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1510:
	.asciz "is_digit16"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1511:
	.8byte	21
	.8byte	m_cstr1510
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_is_digit16:
	.8byte	m_is_digit16__code
	.8byte	m_ostr1511
	.globl m_is_digit16__code
	.type m_is_digit16__code, @function
	.section .rodata
m_cstr1521:
	.asciz "illegal digit in character escape: "
	.section .rodata
m_cstr1522:
	.asciz "\012"
	.text
m_digit_value__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$48, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1513
	mov	-8(%rbp), %rax
	cmp	$57, %rax
	setle	%al
	movzb	%al, %rax
m_L1513:
	test	%rax, %rax
	je	m_L1512
	mov	-8(%rbp), %rax
	sub	$48, %rax
	jmp	m_L1514
m_L1512:
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$97, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1516
	mov	-8(%rbp), %rax
	cmp	$122, %rax
	setle	%al
	movzb	%al, %rax
m_L1516:
	test	%rax, %rax
	je	m_L1515
	mov	$97, %rax
	sub	$10, %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	sub	-16(%rbp), %rax
	jmp	m_L1517
m_L1515:
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$65, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1519
	mov	-8(%rbp), %rax
	cmp	$90, %rax
	setle	%al
	movzb	%al, %rax
m_L1519:
	test	%rax, %rax
	je	m_L1518
	mov	$65, %rax
	sub	$10, %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	sub	-16(%rbp), %rax
	jmp	m_L1520
m_L1518:
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr1521(%rip), %rax
	mov	%rax, -16(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-16(%rbp), %rsi
	mov	$35, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	$10, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr1522(%rip), %rax
	mov	%rax, -16(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-16(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L1520:
m_L1517:
m_L1514:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1523:
	.asciz "digit_value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1524:
	.8byte	23
	.8byte	m_cstr1523
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_digit_value:
	.8byte	m_digit_value__code
	.8byte	m_ostr1524
	.globl m_digit_value__code
	.type m_digit_value__code, @function
	.section .rodata
m_cstr1554:
	.asciz "illegal character escape"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1555:
	.8byte	49
	.8byte	m_cstr1554
	.section .rodata
m_cstr1563:
	.asciz "illegal hexadecimal character escape"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1564:
	.8byte	73
	.8byte	m_cstr1563
	.section .rodata
m_cstr1572:
	.asciz "illegal octal character escape"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1573:
	.8byte	61
	.8byte	m_cstr1572
	.section .rodata
m_cstr1577:
	.asciz "illegal character escape: \\"
	.section .rodata
m_cstr1578:
	.asciz "\012"
	.text
m_read_2Fchar__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$92, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1525
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	cmp	$97, %rax
	sete	%al
	movzb	%al, %rax
m_L1527:
	test	%rax, %rax
	je	m_L1526
	mov	$7, %rax
	jmp	m_L1528
m_L1526:
	mov	-24(%rbp), %rax
	cmp	$98, %rax
	sete	%al
	movzb	%al, %rax
m_L1530:
	test	%rax, %rax
	je	m_L1529
	mov	$8, %rax
	jmp	m_L1531
m_L1529:
	mov	-24(%rbp), %rax
	cmp	$101, %rax
	sete	%al
	movzb	%al, %rax
m_L1533:
	test	%rax, %rax
	je	m_L1532
	mov	$27, %rax
	jmp	m_L1534
m_L1532:
	mov	-24(%rbp), %rax
	cmp	$102, %rax
	sete	%al
	movzb	%al, %rax
m_L1536:
	test	%rax, %rax
	je	m_L1535
	mov	$12, %rax
	jmp	m_L1537
m_L1535:
	mov	-24(%rbp), %rax
	cmp	$110, %rax
	sete	%al
	movzb	%al, %rax
m_L1539:
	test	%rax, %rax
	je	m_L1538
	mov	$10, %rax
	jmp	m_L1540
m_L1538:
	mov	-24(%rbp), %rax
	cmp	$114, %rax
	sete	%al
	movzb	%al, %rax
m_L1542:
	test	%rax, %rax
	je	m_L1541
	mov	$13, %rax
	jmp	m_L1543
m_L1541:
	mov	-24(%rbp), %rax
	cmp	$116, %rax
	sete	%al
	movzb	%al, %rax
m_L1545:
	test	%rax, %rax
	je	m_L1544
	mov	$9, %rax
	jmp	m_L1546
m_L1544:
	mov	-24(%rbp), %rax
	cmp	$118, %rax
	sete	%al
	movzb	%al, %rax
m_L1548:
	test	%rax, %rax
	je	m_L1547
	mov	$11, %rax
	jmp	m_L1549
m_L1547:
	mov	-24(%rbp), %rax
	cmp	$117, %rax
	sete	%al
	movzb	%al, %rax
m_L1551:
	test	%rax, %rax
	je	m_L1550
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-32(%rbp), %rdi
	call	m_is_digit16__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1553
	movq	-40(%rbp), %rdi
	call	m_is_digit16__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1553
	movq	-48(%rbp), %rdi
	call	m_is_digit16__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1553
	movq	-56(%rbp), %rdi
	call	m_is_digit16__code
	add	$0, %rsp
m_L1553:
	test	%rax, %rax
	jne	m_L1552
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1555(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1552:
	movq	-56(%rbp), %rdi
	call	m_digit_value__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	movq	-48(%rbp), %rdi
	call	m_digit_value__code
	add	$0, %rsp
	shl	$8, %rax
	add	-64(%rbp),%rax
	mov	%rax, -64(%rbp)
	movq	-40(%rbp), %rdi
	call	m_digit_value__code
	add	$0, %rsp
	shl	$16, %rax
	add	-64(%rbp),%rax
	mov	%rax, -64(%rbp)
	movq	-32(%rbp), %rdi
	call	m_digit_value__code
	add	$0, %rsp
	shl	$24, %rax
	add	-64(%rbp),%rax
	jmp	m_L1556
m_L1550:
	mov	-24(%rbp), %rax
	cmp	$120, %rax
	sete	%al
	movzb	%al, %rax
m_L1558:
	test	%rax, %rax
	je	m_L1557
	xor	%rax, %rax
	mov	%rax, -56(%rbp)
	movq	-16(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_is_digit16__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1560
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_digit_value__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	test	%rax, %rax
	jne	m_L1561
	mov	$1, %rax
m_L1561:
	test	%rax, %rax
	je	m_L1560
	movq	-16(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_is_digit16__code
	add	$0, %rsp
m_L1560:
	test	%rax, %rax
	je	m_L1559
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_digit_value__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-56(%rbp), %rax
	mov	$16, %rcx
	mul	%rcx
	add	-48(%rbp),%rax
	mov	%rax, -56(%rbp)
	jmp	m_L1562
m_L1559:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1564(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1562:
	mov	-56(%rbp), %rax
	jmp	m_L1565
m_L1557:
	mov	-8(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$48, %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1567
	mov	-8(%rbp), %rax
	cmp	$55, %rax
	setle	%al
	movzb	%al, %rax
m_L1567:
	test	%rax, %rax
	je	m_L1566
	movq	-8(%rbp), %rdi
	call	m_digit_value__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-16(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_is_digit8__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1569
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_digit_value__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-56(%rbp), %rax
	mov	$8, %rcx
	mul	%rcx
	add	-48(%rbp),%rax
	mov	%rax, -56(%rbp)
	test	%rax, %rax
	jne	m_L1570
	mov	$1, %rax
m_L1570:
	test	%rax, %rax
	je	m_L1569
	movq	-16(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_is_digit8__code
	add	$0, %rsp
m_L1569:
	test	%rax, %rax
	je	m_L1568
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_digit_value__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-56(%rbp), %rax
	mov	$8, %rcx
	mul	%rcx
	add	-48(%rbp),%rax
	mov	%rax, -56(%rbp)
	jmp	m_L1571
m_L1568:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1573(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1571:
	mov	-56(%rbp), %rax
	jmp	m_L1574
m_L1566:
	movq	-8(%rbp), %rdi
	call	m_is_alpha__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1576
	movq	-8(%rbp), %rdi
	call	m_is_digit10__code
	add	$0, %rsp
m_L1576:
	test	%rax, %rax
	je	m_L1575
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr1577(%rip), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-56(%rbp), %rsi
	mov	$27, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	$10, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr1578(%rip), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-56(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
	jmp	m_L1579
m_L1575:
	mov	-8(%rbp), %rax
m_L1579:
m_L1574:
m_L1565:
m_L1556:
m_L1549:
m_L1546:
m_L1543:
m_L1540:
m_L1537:
m_L1534:
m_L1531:
m_L1528:
	jmp	m_L1580
m_L1525:
	mov	-8(%rbp), %rax
m_L1580:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1581:
	.asciz "read/char"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1582:
	.8byte	19
	.8byte	m_cstr1581
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read_2Fchar:
	.8byte	m_read_2Fchar__code
	.8byte	m_ostr1582
	.globl m_read_2Fchar__code
	.type m_read_2Fchar__code, @function
	.section .rodata
m_cstr1593:
	.asciz "invalid number in source code, string->long* has failed for '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1594:
	.8byte	123
	.8byte	m_cstr1593
	.section .rodata
m_cstr1595:
	.asciz "' (it's printed without the sign here)"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1596:
	.8byte	77
	.8byte	m_cstr1595
	.text
m_read_2Fnumber__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	$16, %rdi
	call	m_string__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	mov	$10, %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	$45, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1583
	mov	$1, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L1584
m_L1583:
	movq	-24(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_string_append__code
	add	$0, %rsp
m_L1584:
	jmp	m_L1586
m_L1585:
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-24(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_string_append__code
	add	$0, %rsp
m_L1586:
	movq	-16(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_is_digit10__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1585
	mov	-8(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	$120, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1588
	movq	-24(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$1, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1588
	movq	-24(%rbp), %rdi
	movq	$0, %rsi
	call	m_string_at__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$48, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L1588:
	test	%rax, %rax
	je	m_L1587
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	$16, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	jmp	m_L1590
m_L1589:
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-24(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_string_append__code
	add	$0, %rsp
m_L1590:
	movq	-16(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_is_digit16__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1589
m_L1587:
	movq	-24(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_string__3Elong_2A__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1592
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1594(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-24(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1596(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1592:
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L1598
	mov	-48(%rbp), %rax
	neg	%rax
	jmp	m_L1599
m_L1598:
	mov	-48(%rbp), %rax
m_L1599:
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -40(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1600:
	.asciz "read/number"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1601:
	.8byte	23
	.8byte	m_cstr1600
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read_2Fnumber:
	.8byte	m_read_2Fnumber__code
	.8byte	m_ostr1601
	.globl m_read_2Fnumber__code
	.type m_read_2Fnumber__code, @function
	.section .rodata
m_cstr1604:
	.asciz "kernel assertion failed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1605:
	.8byte	47
	.8byte	m_cstr1604
	.text
m_read_2Fsymbol__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	$16, %rdi
	call	m_string__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m_is_letter__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1603
	movq	-8(%rbp), %rdi
	call	m_is_digit10__code
	add	$0, %rsp
m_L1603:
	test	%rax, %rax
	jne	m_L1602
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1605(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1602:
	movq	-24(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_string_append__code
	add	$0, %rsp
	jmp	m_L1607
m_L1606:
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-24(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_string_append__code
	add	$0, %rsp
m_L1607:
	movq	-16(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	test	%rax, %rax
	je	m_L1608
	movq	-8(%rbp), %rdi
	call	m_is_letter__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1609
	movq	-8(%rbp), %rdi
	call	m_is_digit10__code
	add	$0, %rsp
m_L1609:
m_L1608:
	test	%rax, %rax
	jne	m_L1606
	movq	-24(%rbp), %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1610:
	.asciz "read/symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1611:
	.8byte	23
	.8byte	m_cstr1610
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read_2Fsymbol:
	.8byte	m_read_2Fsymbol__code
	.8byte	m_ostr1611
	.globl m_read_2Fsymbol__code
	.type m_read_2Fsymbol__code, @function
	.section .rodata
m_cstr1615:
	.asciz "unterminated string literal"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1616:
	.8byte	55
	.8byte	m_cstr1615
	.text
m_read_2Fstring_literal__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	movq	$8, %rdi
	call	m_string__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1613
m_L1612:
	movq	-24(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fchar__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1614
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1616(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1614:
	movq	-16(%rbp), %rdi
	movq	-24(%rbp), %rsi
	call	m_string_append__code
	add	$0, %rsp
m_L1613:
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	%rax, -32(%rbp)
	mov	$34, %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1612
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1618:
	.asciz "read/string-literal"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1619:
	.8byte	39
	.8byte	m_cstr1618
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read_2Fstring_literal:
	.8byte	m_read_2Fstring_literal__code
	.8byte	m_ostr1619
	.globl m_read_2Fstring_literal__code
	.type m_read_2Fstring_literal__code, @function
	.section .rodata
m_cstr1664:
	.asciz "illegal character: "
	.section .rodata
m_cstr1665:
	.asciz "\012"
	.text
m_read_nested__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	jmp	m_L1621
m_L1620:
	movq	-8(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	movq	-16(%rbp), %rdi
	call	m_is_blank__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1622
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	jmp	m_L1623
m_L1622:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$63, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1624
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fchar__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	jmp	m_L1625
	jmp	m_L1626
m_L1624:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$45, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1627
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_is_digit10__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1628
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fnumber__code
	add	$0, %rsp
	jmp	m_L1629
m_L1628:
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fsymbol__code
	add	$0, %rsp
m_L1629:
	jmp	m_L1625
	jmp	m_L1630
m_L1627:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$39, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1631
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	lea	m_symbol_2Fquote(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fquote__code
	add	$0, %rsp
	jmp	m_L1625
	jmp	m_L1632
m_L1631:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$96, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1633
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	lea	m_symbol_2Fquasiquote(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fquote__code
	add	$0, %rsp
	jmp	m_L1625
	jmp	m_L1634
m_L1633:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$44, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1635
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	$64, %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1636
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	lea	m_symbol_2Funquote_splicing(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fquote__code
	add	$0, %rsp
	jmp	m_L1637
m_L1636:
	lea	m_symbol_2Funquote(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fquote__code
	add	$0, %rsp
m_L1637:
	jmp	m_L1625
	jmp	m_L1638
m_L1635:
	movq	-16(%rbp), %rdi
	call	m_is_letter__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1639
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fsymbol__code
	add	$0, %rsp
	jmp	m_L1625
	jmp	m_L1640
m_L1639:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$40, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1641
	movq	$41, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Flist__code
	add	$0, %rsp
	jmp	m_L1625
	jmp	m_L1642
m_L1641:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$41, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1643
	mov	$572732501, %rax
	jmp	m_L1625
	jmp	m_L1644
m_L1643:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$91, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1645
	movq	$93, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Flist__code
	add	$0, %rsp
	jmp	m_L1625
	jmp	m_L1646
m_L1645:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$93, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1647
	mov	$572732501, %rax
	jmp	m_L1625
	jmp	m_L1648
m_L1647:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$123, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1649
	movq	$125, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Flist__code
	add	$0, %rsp
	jmp	m_L1625
	jmp	m_L1650
m_L1649:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$125, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1651
	mov	$572732501, %rax
	jmp	m_L1625
	jmp	m_L1652
m_L1651:
	movq	-16(%rbp), %rdi
	call	m_is_digit10__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1653
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Fnumber__code
	add	$0, %rsp
	jmp	m_L1625
	jmp	m_L1654
m_L1653:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$59, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1655
	jmp	m_L1657
m_L1656:
m_L1657:
	movq	-8(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	%rax, -24(%rbp)
	mov	$10, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1658
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$13, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1658
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
m_L1658:
	test	%rax, %rax
	jne	m_L1656
	jmp	m_L1659
m_L1655:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$34, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1660
	movq	-8(%rbp), %rdi
	call	m_read_2Fstring_literal__code
	add	$0, %rsp
	jmp	m_L1625
	jmp	m_L1661
m_L1660:
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1662
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	jmp	m_L1625
	jmp	m_L1663
m_L1662:
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr1664(%rip), %rax
	mov	%rax, -24(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-24(%rbp), %rsi
	mov	$19, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	$10, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr1665(%rip), %rax
	mov	%rax, -24(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-24(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L1663:
m_L1661:
m_L1659:
m_L1654:
m_L1652:
m_L1650:
m_L1648:
m_L1646:
m_L1644:
m_L1642:
m_L1640:
m_L1638:
m_L1634:
m_L1632:
m_L1630:
m_L1626:
m_L1623:
m_L1621:
	mov	$1, %rax
	test	%rax, %rax
	jne	m_L1620
m_L1625:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1666:
	.asciz "read-nested"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1667:
	.8byte	23
	.8byte	m_cstr1666
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read_nested:
	.8byte	m_read_nested__code
	.8byte	m_ostr1667
	.globl m_read_nested__code
	.type m_read_nested__code, @function
	.section .rodata
m_cstr1677:
	.asciz "unexpected close paren"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1678:
	.8byte	45
	.8byte	m_cstr1677
	.text
m_read_toplevel__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m__24peek__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$40, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1668
	movq	$41, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Flist__code
	add	$0, %rsp
	jmp	m_L1669
	jmp	m_L1670
m_L1668:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$91, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1671
	movq	$93, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Flist__code
	add	$0, %rsp
	jmp	m_L1669
	jmp	m_L1672
m_L1671:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$123, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1673
	movq	$125, %rdi
	movq	-8(%rbp), %rsi
	call	m_read_2Flist__code
	add	$0, %rsp
	jmp	m_L1669
	jmp	m_L1674
m_L1673:
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$41, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1676
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$93, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1676
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	$125, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L1676:
	test	%rax, %rax
	je	m_L1675
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1678(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
	jmp	m_L1679
m_L1675:
	movq	-8(%rbp), %rdi
	call	m_read_nested__code
	add	$0, %rsp
	jmp	m_L1669
m_L1679:
m_L1674:
m_L1672:
m_L1670:
m_L1669:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1680:
	.asciz "read-toplevel"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1681:
	.8byte	27
	.8byte	m_cstr1680
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read_toplevel:
	.8byte	m_read_toplevel__code
	.8byte	m_ostr1681
	.globl m_read_toplevel__code
	.type m_read_toplevel__code, @function
	.section .rodata
m_cstr1688:
	.asciz "missing closing delimiter "
	.section .rodata
m_cstr1689:
	.asciz " after ."
	.section .rodata
m_cstr1690:
	.asciz "\012"
	.section .rodata
m_cstr1695:
	.asciz "missing closing delimiter "
	.section .rodata
m_cstr1696:
	.asciz " while reading list"
	.section .rodata
m_cstr1697:
	.asciz "\012"
	.text
m_read_2Flist__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, %rbx
	xor	%rax, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	jmp	m_L1683
m_L1682:
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-40(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	mov	%rax, -32(%rbp)
m_L1683:
	movq	-16(%rbp), %rdi
	call	m_read_nested__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	%rax, -48(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1684
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	$572732501, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1684
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	m_symbol_2F_2E(%rip), %rax
	mov	(%rax), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
m_L1684:
	test	%rax, %rax
	jne	m_L1682
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	m_symbol_2F_2E(%rip), %rax
	mov	(%rax), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1685
	movq	-16(%rbp), %rdi
	call	m_read_toplevel__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1686
	xor	%rax, %rax
	jmp	m_L1687
m_L1686:
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr1688(%rip), %rax
	mov	%rax, -48(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-48(%rbp), %rsi
	mov	$26, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	$10, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr1689(%rip), %rax
	mov	%rax, -48(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-48(%rbp), %rsi
	mov	$8, %rdx
	syscall
	lea	m_cstr1690(%rip), %rax
	mov	%rax, -48(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-48(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L1687:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	jmp	m_L1691
m_L1685:
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	$572732501, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1693
	movq	-16(%rbp), %rdi
	call	m__24next__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L1693:
	test	%rax, %rax
	je	m_L1692
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	jmp	m_L1694
m_L1692:
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr1695(%rip), %rax
	mov	%rax, -48(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-48(%rbp), %rsi
	mov	$26, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	$10, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr1696(%rip), %rax
	mov	%rax, -48(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-48(%rbp), %rsi
	mov	$19, %rdx
	syscall
	lea	m_cstr1697(%rip), %rax
	mov	%rax, -48(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-48(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L1694:
m_L1691:
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1698:
	.asciz "read/list"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1699:
	.8byte	19
	.8byte	m_cstr1698
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read_2Flist:
	.8byte	m_read_2Flist__code
	.8byte	m_ostr1699
	.globl m_read_2Flist__code
	.type m_read_2Flist__code, @function
	.section .rodata
m_cstr1701:
	.asciz "EOF while reading quoted literal"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1702:
	.8byte	65
	.8byte	m_cstr1701
	.text
m_read_2Fquote__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-16(%rbp), %rdi
	call	m_read_toplevel__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1700
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1702(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1700:
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-24(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	movq	-8(%rbp), %rdi
	movq	-24(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1704:
	.asciz "read/quote"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1705:
	.8byte	21
	.8byte	m_cstr1704
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read_2Fquote:
	.8byte	m_read_2Fquote__code
	.8byte	m_ostr1705
	.globl m_read_2Fquote__code
	.type m_read_2Fquote__code, @function
	.section .rodata
m_cstr1708:
	.asciz "read"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1709:
	.8byte	9
	.8byte	m_cstr1708
	.section .rodata
m_cstr1711:
	.asciz "read"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1712:
	.8byte	9
	.8byte	m_cstr1711
	.text
m_read_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1706
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1707
m_L1706:
	lea	m_ostr1709(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1707:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1710
	lea	m_ostr1712(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1710:
	movq	-32(%rbp), %rdi
	call	m_read__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1714:
	.asciz "read/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1715:
	.8byte	39
	.8byte	m_cstr1714
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_read_2Fevaluator_stub:
	.8byte	m_read_2Fevaluator_stub__code
	.8byte	m_ostr1715
	.globl m_read_2Fevaluator_stub__code
	.type m_read_2Fevaluator_stub__code, @function
	.text
m_do_dump_2Fstring__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	$34, %rsi
	call	m__24put__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	jmp	m_L1717
m_L1716:
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_string_at__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$32, %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1719
	mov	-48(%rbp), %rax
	cmp	$126, %rax
	setle	%al
	movzb	%al, %rax
m_L1719:
	test	%rax, %rax
	je	m_L1718
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-56(%rbp), %rax
	cmp	$34, %rax
	sete	%al
	movzb	%al, %rax
m_L1721:
	test	%rax, %rax
	je	m_L1720
	movq	-8(%rbp), %rdi
	movq	$92, %rsi
	call	m__24put__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	$34, %rsi
	call	m__24put__code
	add	$0, %rsp
	jmp	m_L1722
m_L1720:
	mov	-56(%rbp), %rax
	cmp	$92, %rax
	sete	%al
	movzb	%al, %rax
m_L1724:
	test	%rax, %rax
	je	m_L1723
	movq	-8(%rbp), %rdi
	movq	$92, %rsi
	call	m__24put__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	$92, %rsi
	call	m__24put__code
	add	$0, %rsp
	jmp	m_L1725
m_L1723:
	movq	-8(%rbp), %rdi
	movq	-48(%rbp), %rsi
	call	m__24put__code
	add	$0, %rsp
m_L1725:
m_L1722:
	jmp	m_L1726
m_L1718:
	movq	-8(%rbp), %rdi
	movq	$92, %rsi
	call	m__24put__code
	add	$0, %rsp
	movq	-48(%rbp), %rdi
	movq	$8, %rsi
	call	m_long__3Estring_2A__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	$3, %rax
	sub	-64(%rbp), %rax
	mov	%rax, -64(%rbp)
	jmp	m_L1728
m_L1727:
	movq	-8(%rbp), %rdi
	movq	$48, %rsi
	call	m__24put__code
	add	$0, %rsp
m_L1728:
	mov	-64(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -64(%rbp)
	mov	%rax, -72(%rbp)
	xor	%rax, %rax
	cmp	-72(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1727
	movq	-8(%rbp), %rdi
	movq	-56(%rbp), %rsi
	call	m__24put_all__code
	add	$0, %rsp
m_L1726:
	mov	-32(%rbp), %rax
	add	$1, %rax
	mov	%rax, -32(%rbp)
m_L1717:
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	cmp	-48(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1716
	movq	-8(%rbp), %rdi
	movq	$34, %rsi
	call	m__24put__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1729:
	.asciz "do-dump/string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1730:
	.8byte	29
	.8byte	m_cstr1729
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_do_dump_2Fstring:
	.8byte	m_do_dump_2Fstring__code
	.8byte	m_ostr1730
	.globl m_do_dump_2Fstring__code
	.type m_do_dump_2Fstring__code, @function
	.section .rodata
m_cstr1731:
	.asciz "cannot dump "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1732:
	.8byte	25
	.8byte	m_cstr1731
	.text
m_error_2Fcannot_dump_object__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1732(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1733:
	.asciz "error/cannot-dump-object"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1734:
	.8byte	49
	.8byte	m_cstr1733
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_error_2Fcannot_dump_object:
	.8byte	m_error_2Fcannot_dump_object__code
	.8byte	m_ostr1734
	.globl m_error_2Fcannot_dump_object__code
	.type m_error_2Fcannot_dump_object__code, @function
	.section .rodata
m_cstr1736:
	.asciz "()"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1737:
	.8byte	5
	.8byte	m_cstr1736
	.section .rodata
m_cstr1742:
	.asciz "0x"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1743:
	.8byte	5
	.8byte	m_cstr1742
	.section .rodata
m_cstr1757:
	.asciz " . "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1758:
	.8byte	7
	.8byte	m_cstr1757
	.section .rodata
m_cstr1764:
	.asciz "Array("
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1765:
	.8byte	13
	.8byte	m_cstr1764
	.section .rodata
m_cstr1773:
	.asciz "Expr<"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1774:
	.8byte	11
	.8byte	m_cstr1773
	.section .rodata
m_cstr1781:
	.asciz "Form<"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1782:
	.8byte	11
	.8byte	m_cstr1781
	.section .rodata
m_cstr1787:
	.asciz "Fixed<"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1788:
	.8byte	13
	.8byte	m_cstr1787
	.section .rodata
m_cstr1805:
	.asciz "Env<"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1806:
	.8byte	9
	.8byte	m_cstr1805
	.section .rodata
m_cstr1809:
	.asciz " Lv"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1810:
	.8byte	7
	.8byte	m_cstr1809
	.section .rodata
m_cstr1811:
	.asciz ",Off"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1812:
	.8byte	9
	.8byte	m_cstr1811
	.section .rodata
m_cstr1813:
	.asciz ",#"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1814:
	.8byte	5
	.8byte	m_cstr1813
	.section .rodata
m_cstr1816:
	.asciz ",parent: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1817:
	.8byte	19
	.8byte	m_cstr1816
	.section .rodata
m_cstr1820:
	.asciz "Env<?>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1821:
	.8byte	13
	.8byte	m_cstr1820
	.section .rodata
m_cstr1826:
	.asciz "Context<>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1827:
	.8byte	19
	.8byte	m_cstr1826
	.section .rodata
m_cstr1832:
	.asciz "Type"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1833:
	.8byte	9
	.8byte	m_cstr1832
	.section .rodata
m_cstr1835:
	.asciz "?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1836:
	.8byte	3
	.8byte	m_cstr1835
	.section .rodata
m_cstr1841:
	.asciz "Record"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1842:
	.8byte	13
	.8byte	m_cstr1841
	.section .rodata
m_cstr1844:
	.asciz "?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1845:
	.8byte	3
	.8byte	m_cstr1844
	.section .rodata
m_cstr1849:
	.asciz "[instof:"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1850:
	.8byte	17
	.8byte	m_cstr1849
	.text
m_do_print__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	movq	-16(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	$6, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1735
	lea	m_ostr1737(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	jmp	m_L1738
m_L1735:
	mov	$7, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1739
	mov	-16(%rbp), %rax
	sar	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_long__3Estring__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	jmp	m_L1740
m_L1739:
	mov	$20, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1741
	lea	m_ostr1743(%rip), %rax
	mov	%rax, %rbx
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%r12, %rdi
	movq	$16, %rsi
	call	m_long__3Estring_2A__code
	add	$0, %rsp
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	call	m__24put_all__code
	add	$0, %rsp
	jmp	m_L1744
m_L1741:
	mov	$9, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1745
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	jmp	m_L1746
m_L1745:
	mov	$12, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1747
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1748
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_do_dump_2Fstring__code
	add	$0, %rsp
	jmp	m_L1749
m_L1748:
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m__24put_all__code
	add	$0, %rsp
m_L1749:
	jmp	m_L1750
m_L1747:
	mov	$18, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1751
	movq	-8(%rbp), %rdi
	movq	$40, %rsi
	call	m__24put__code
	add	$0, %rsp
	jmp	m_L1753
m_L1752:
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -16(%rbp)
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1754
	movq	-8(%rbp), %rdi
	movq	$32, %rsi
	call	m__24put__code
	add	$0, %rsp
m_L1754:
m_L1753:
	movq	-16(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1752
	mov	-16(%rbp), %rax
	test	%rax, %rax
	je	m_L1756
	lea	m_ostr1758(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
m_L1756:
	movq	-8(%rbp), %rdi
	movq	$41, %rsi
	call	m__24put__code
	add	$0, %rsp
	jmp	m_L1760
m_L1751:
	mov	$10, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1761
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1762
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1762:
	movq	-16(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	m_ostr1765(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	jmp	m_L1767
m_L1766:
	mov	-48(%rbp), %rax
	test	%rax, %rax
	je	m_L1768
	movq	-8(%rbp), %rdi
	movq	$32, %rsi
	call	m__24put__code
	add	$0, %rsp
m_L1768:
	movq	-16(%rbp), %rdi
	movq	-48(%rbp), %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	add	$1, %rax
	mov	%rax, -48(%rbp)
m_L1767:
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-48(%rbp), %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L1766
	movq	-8(%rbp), %rdi
	movq	$41, %rsi
	call	m__24put__code
	add	$0, %rsp
	jmp	m_L1769
m_L1761:
	mov	$13, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1770
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1771
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1771:
	lea	m_ostr1774(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	lea	32(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	test	%rax, %rax
	je	m_L1775
	movq	-8(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	jmp	m_L1776
m_L1775:
	movq	-8(%rbp), %rdi
	movq	$63, %rsi
	call	m__24put__code
	add	$0, %rsp
m_L1776:
	movq	-8(%rbp), %rdi
	movq	$32, %rsi
	call	m__24put__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	$62, %rsi
	call	m__24put__code
	add	$0, %rsp
	jmp	m_L1777
m_L1770:
	mov	$14, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1778
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1779
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1779:
	lea	m_ostr1782(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	$44, %rsi
	call	m__24put__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	$62, %rsi
	call	m__24put__code
	add	$0, %rsp
	jmp	m_L1783
m_L1778:
	mov	$8, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1784
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1785
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1785:
	lea	m_ostr1788(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	$62, %rsi
	call	m__24put__code
	add	$0, %rsp
	jmp	m_L1789
m_L1784:
	mov	$19, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1790
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1791
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1791:
	movq	-8(%rbp), %rdi
	movq	$46, %rsi
	call	m__24put__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	jmp	m_L1793
m_L1790:
	mov	$15, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1794
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1795
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1795:
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	test	%rax, %rax
	je	m_L1797
	movq	-8(%rbp), %rdi
	movq	$46, %rsi
	call	m__24put__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	$43, %rsi
	call	m__24put__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
m_L1797:
	jmp	m_L1799
m_L1794:
	mov	$16, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1800
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1801
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1801:
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	test	%rax, %rax
	je	m_L1804
	mov	-56(%rbp), %rax
	test	%rax, %rax
	je	m_L1804
	mov	-48(%rbp), %rax
m_L1804:
	test	%rax, %rax
	je	m_L1803
	lea	m_ostr1806(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	mov	-16(%rbp), %rax
	lea	40(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -64(%rbp)
	test	%rax, %rax
	je	m_L1807
	movq	-8(%rbp), %rdi
	movq	-64(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
m_L1807:
	lea	m_ostr1810(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr1812(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-48(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m_ostr1814(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	movq	-56(%rbp), %rdi
	call	m_array_length__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -64(%rbp)
	test	%rax, %rax
	je	m_L1815
	lea	m_ostr1817(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-64(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
m_L1815:
	movq	-8(%rbp), %rdi
	movq	$62, %rsi
	call	m__24put__code
	add	$0, %rsp
	jmp	m_L1819
m_L1803:
	lea	m_ostr1821(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
m_L1819:
	jmp	m_L1822
m_L1800:
	mov	$17, %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1823
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1824
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1824:
	lea	m_ostr1827(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	jmp	m_L1828
m_L1823:
	mov	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1829
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1830
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1830:
	lea	m_ostr1833(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	test	%rax, %rax
	jne	m_L1834
	lea	m_ostr1836(%rip), %rax
m_L1834:
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	jmp	m_L1837
m_L1829:
	mov	$2, %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1838
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1839
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1839:
	lea	m_ostr1842(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	test	%rax, %rax
	jne	m_L1843
	lea	m_ostr1845(%rip), %rax
m_L1843:
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	jmp	m_L1846
m_L1838:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1847
	movq	-16(%rbp), %rdi
	call	m_error_2Fcannot_dump_object__code
	add	$0, %rsp
m_L1847:
	lea	m_ostr1850(%rip), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-24(%rbp), %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	$93, %rsi
	call	m__24put__code
	add	$0, %rsp
m_L1846:
m_L1837:
m_L1828:
m_L1822:
m_L1799:
m_L1793:
m_L1789:
m_L1783:
m_L1777:
m_L1769:
m_L1760:
m_L1750:
m_L1746:
m_L1744:
m_L1740:
m_L1738:
	mov	-16(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1851:
	.asciz "do-print"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1852:
	.8byte	17
	.8byte	m_cstr1851
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_do_print:
	.8byte	m_do_print__code
	.8byte	m_ostr1852
	.globl m_do_print__code
	.type m_do_print__code, @function
	.text
m_dump__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	movq	$1, %rdx
	call	m_do_print__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1853:
	.asciz "dump"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1854:
	.8byte	9
	.8byte	m_cstr1853
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_dump:
	.8byte	m_dump__code
	.8byte	m_ostr1854
	.globl m_dump__code
	.type m_dump__code, @function
	.text
m_dumpln__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_dump__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	$10, %rsi
	call	m__24put__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1855:
	.asciz "dumpln"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1856:
	.8byte	13
	.8byte	m_cstr1855
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_dumpln:
	.8byte	m_dumpln__code
	.8byte	m_ostr1856
	.globl m_dumpln__code
	.type m_dumpln__code, @function
	.text
m_dump_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1858
m_L1857:
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_dump__code
	add	$0, %rsp
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
m_L1858:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	jne	m_L1857
	movq	-8(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1859:
	.asciz "dump/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1860:
	.8byte	39
	.8byte	m_cstr1859
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_dump_2Fevaluator_stub:
	.8byte	m_dump_2Fevaluator_stub__code
	.8byte	m_ostr1860
	.globl m_dump_2Fevaluator_stub__code
	.type m_dump_2Fevaluator_stub__code, @function
	.text
m_print_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1862
m_L1861:
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_print__code
	add	$0, %rsp
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
m_L1862:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	jne	m_L1861
	movq	-8(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1863:
	.asciz "print/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1864:
	.8byte	41
	.8byte	m_cstr1863
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_print_2Fevaluator_stub:
	.8byte	m_print_2Fevaluator_stub__code
	.8byte	m_ostr1864
	.globl m_print_2Fevaluator_stub__code
	.type m_print_2Fevaluator_stub__code, @function
	.text
m_dump_all_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	jmp	m_L1866
m_L1865:
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	$1, %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
m_L1866:
	mov	-32(%rbp), %rax
	test	%rax, %rax
	jne	m_L1865
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1867:
	.asciz "dump-all/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1868:
	.8byte	47
	.8byte	m_cstr1867
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_dump_all_2Fevaluator_stub:
	.8byte	m_dump_all_2Fevaluator_stub__code
	.8byte	m_ostr1868
	.globl m_dump_all_2Fevaluator_stub__code
	.type m_dump_all_2Fevaluator_stub__code, @function
	.text
m_print_all_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	jmp	m_L1870
m_L1869:
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
m_L1870:
	mov	-32(%rbp), %rax
	test	%rax, %rax
	jne	m_L1869
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1871:
	.asciz "print-all/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1872:
	.8byte	49
	.8byte	m_cstr1871
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_print_all_2Fevaluator_stub:
	.8byte	m_print_all_2Fevaluator_stub__code
	.8byte	m_ostr1872
	.globl m_print_all_2Fevaluator_stub__code
	.type m_print_all_2Fevaluator_stub__code, @function
	.text
m__25new_call_frame__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	lea	m__2Acall_stack_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L1873
	xor	%rax, %rax
	jmp	m_L1874
m_L1873:
	movq	$25, %rdi
	movq	$4, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	lea	m__2Acall_stack_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-40(%rbp), %rdx
	call	m_set_array_at__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
m_L1874:
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1875:
	.asciz "%new-call-frame"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1876:
	.8byte	31
	.8byte	m_cstr1875
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25new_call_frame:
	.8byte	m__25new_call_frame__code
	.8byte	m_ostr1876
	.globl m__25new_call_frame__code
	.type m__25new_call_frame__code, @function
	.text
m_current_call_frame__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -8(%rbp)
	xor	%rax, %rax
	cmp	-8(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1877
	lea	m__2Acall_stack_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	sub	$1, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_array_at__code
	add	$0, %rsp
m_L1877:
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1879:
	.asciz "current-call-frame"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1880:
	.8byte	37
	.8byte	m_cstr1879
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_current_call_frame:
	.8byte	m_current_call_frame__code
	.8byte	m_ostr1880
	.globl m_current_call_frame__code
	.type m_current_call_frame__code, @function
	.section .rodata
m_cstr1886:
	.asciz "too few arguments for "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1887:
	.8byte	45
	.8byte	m_cstr1886
	.section .rodata
m_cstr1888:
	.asciz ": "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1889:
	.8byte	5
	.8byte	m_cstr1888
	.section .rodata
m_cstr1893:
	.asciz "too many arguments for "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1894:
	.8byte	47
	.8byte	m_cstr1893
	.section .rodata
m_cstr1895:
	.asciz ": "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1896:
	.8byte	5
	.8byte	m_cstr1895
	.text
m_apply_2Fexpr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	$3, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1881
	xor	%rax, %rax
m_L1881:
	mov	-8(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-24(%rbp), %rsi
	movq	-32(%rbp), %rdx
	call	m_context__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -64(%rbp)
	jmp	m_L1884
m_L1883:
	movq	-64(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1885
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1887(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1889(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1885:
	mov	-40(%rbp), %rax
	mov	(%rax), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, %rbx
	mov	-64(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	-56(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	call	m_set_array_at__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-64(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -64(%rbp)
m_L1884:
	movq	-40(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L1883
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	mov	$15, %rax
	cmp	-72(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1890
	mov	-40(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, %rbx
	movq	-56(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-64(%rbp), %rdx
	call	m_set_array_at__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
m_L1890:
	mov	-64(%rbp), %rax
	test	%rax, %rax
	je	m_L1892
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1894(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1896(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1892:
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -56(%rbp)
	jmp	m_L1899
m_L1898:
	movq	-56(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	movq	-72(%rbp), %rdi
	movq	-48(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	movq	-56(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
m_L1899:
	mov	-56(%rbp), %rax
	test	%rax, %rax
	jne	m_L1898
	mov	-32(%rbp), %rax
	lea	32(%rax), %rcx
	mov	(%rcx), %rax
	test	%rax, %rax
	je	m_L1900
	xor	%rax, %rax
	mov	%rax, -56(%rbp)
	mov	-48(%rbp), %rax
	lea	24(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
m_L1900:
	mov	-64(%rbp), %rax
	mov	%rax, -56(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1902:
	.asciz "apply/expr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1903:
	.8byte	21
	.8byte	m_cstr1902
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_apply_2Fexpr:
	.8byte	m_apply_2Fexpr__code
	.8byte	m_ostr1903
	.globl m_apply_2Fexpr__code
	.type m_apply_2Fexpr__code, @function
	.section .rodata
m_cstr1905:
	.asciz "infinite recursion guard triggered at call depth "
	.section .rodata
m_cstr1906:
	.asciz "\012"
	.section .rodata
m_cstr1915:
	.asciz "cannot apply: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1916:
	.8byte	29
	.8byte	m_cstr1915
	.section .rodata
m_cstr1917:
	.asciz " of type: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1918:
	.8byte	21
	.8byte	m_cstr1917
	.section .rodata
m_cstr1919:
	.asciz ", *globals*: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1920:
	.8byte	27
	.8byte	m_cstr1919
	.section .rodata
m_cstr1921:
	.asciz ", *applicators* is: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1922:
	.8byte	41
	.8byte	m_cstr1921
	.text
m_apply__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	lea	m_symbol_2Fapply(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	movq	-16(%rbp), %rdx
	call	m__25new_call_frame__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m__2Acall_stack_index_2A(%rip), %rcx
	mov	%rax, (%rcx)
	cmp	$10000, %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1904
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr1905(%rip), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-40(%rbp), %rsi
	mov	$49, %rdx
	syscall
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	$10, %rsi
	movq	%r12, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr1906(%rip), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-40(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L1904:
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$13, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1908
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_apply_2Fexpr__code
	add	$0, %rsp
	jmp	m_L1909
m_L1908:
	mov	$19, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1910
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	movq	-16(%rbp), %rdi
	movq	-24(%rbp), %rsi
	mov	-48(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	mov	-56(%rbp), %rax
	jmp	m_L1911
m_L1910:
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	lea	m__2Aapplicators_var_2A(%rip), %rax
	mov	(%rax), %rax
	test	%rax, %rax
	je	m_L1912
	lea	m__2Aapplicators_var_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	mov	$10, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_maybe_object_in_variable__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	test	%rax, %rax
	je	m_L1912
	movq	-48(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_array_at__code
	add	$0, %rsp
m_L1912:
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	test	%rax, %rax
	je	m_L1913
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-48(%rbp), %rdi
	movq	-56(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_apply__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	jmp	m_L1914
m_L1913:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1916(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1918(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1920(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1922(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m__2Aapplicators_var_2A(%rip), %rax
	mov	(%rax), %rax
	test	%rax, %rax
	je	m_L1923
	lea	m__2Aapplicators_var_2A(%rip), %rax
	mov	(%rax), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
m_L1923:
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1914:
m_L1911:
m_L1909:
	mov	%rax, -32(%rbp)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	sub	$1, %rax
	lea	m__2Acall_stack_index_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	cmp	-40(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1924
	lea	m__2Acall_stack_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
m_L1924:
	mov	-32(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1926:
	.asciz "apply"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1927:
	.8byte	11
	.8byte	m_cstr1926
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_apply:
	.8byte	m_apply__code
	.8byte	m_ostr1927
	.globl m_apply__code
	.type m_apply__code, @function
	.section .rodata
m_cstr1930:
	.asciz "apply"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1931:
	.8byte	11
	.8byte	m_cstr1930
	.section .rodata
m_cstr1934:
	.asciz "apply"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1935:
	.8byte	11
	.8byte	m_cstr1934
	.section .rodata
m_cstr1937:
	.asciz "apply"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1938:
	.8byte	11
	.8byte	m_cstr1937
	.text
m_apply_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1928
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1929
m_L1928:
	lea	m_ostr1931(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1929:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1932
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L1933
m_L1932:
	lea	m_ostr1935(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L1933:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1936
	lea	m_ostr1938(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L1936:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-16(%rbp), %rdx
	call	m_apply__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1940:
	.asciz "apply/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1941:
	.8byte	41
	.8byte	m_cstr1940
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_apply_2Fevaluator_stub:
	.8byte	m_apply_2Fevaluator_stub__code
	.8byte	m_ostr1941
	.globl m_apply_2Fevaluator_stub__code
	.type m_apply_2Fevaluator_stub__code, @function
	.text
m_maybe_form_in_env_2Ffunction__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	mov	$14, %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_maybe_object_in_env__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	test	%rax, %rax
	je	m_L1942
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
m_L1942:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1944:
	.asciz "maybe-form-in-env/function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1945:
	.8byte	53
	.8byte	m_cstr1944
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_maybe_form_in_env_2Ffunction:
	.8byte	m_maybe_form_in_env_2Ffunction__code
	.8byte	m_ostr1945
	.globl m_maybe_form_in_env_2Ffunction__code
	.type m_maybe_form_in_env_2Ffunction__code, @function
	.text
m_maybe_form_in_env_2Fsymbol__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	mov	$14, %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_maybe_object_in_env__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	test	%rax, %rax
	je	m_L1946
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
m_L1946:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1948:
	.asciz "maybe-form-in-env/symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1949:
	.8byte	49
	.8byte	m_cstr1948
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_maybe_form_in_env_2Fsymbol:
	.8byte	m_maybe_form_in_env_2Fsymbol__code
	.8byte	m_ostr1949
	.globl m_maybe_form_in_env_2Fsymbol__code
	.type m_maybe_form_in_env_2Fsymbol__code, @function
	.text
m_expand_all__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1950
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand_all__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	jmp	m_L1951
m_L1950:
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
m_L1951:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1952:
	.asciz "expand-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1953:
	.8byte	21
	.8byte	m_cstr1952
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_expand_all:
	.8byte	m_expand_all__code
	.8byte	m_ostr1953
	.globl m_expand_all__code
	.type m_expand_all__code, @function
	.section .rodata
m_cstr1954:
	.asciz "set-"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1955:
	.8byte	9
	.8byte	m_cstr1954
	.text
m_setter_name_for__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	lea	m_ostr1955(%rip), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_length__code
	add	$0, %rsp
	add	-40(%rbp),%rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-40(%rbp), %rdi
	movq	-24(%rbp), %rsi
	call	m_string_append_all__code
	add	$0, %rsp
	movq	-40(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_string_append_all__code
	add	$0, %rsp
	movq	-40(%rbp), %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	-48(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_maybe_object_in_env__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1956
	mov	-48(%rbp), %rax
m_L1956:
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1958:
	.asciz "setter-name-for"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1959:
	.8byte	31
	.8byte	m_cstr1958
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_setter_name_for:
	.8byte	m_setter_name_for__code
	.8byte	m_ostr1959
	.globl m_setter_name_for__code
	.type m_setter_name_for__code, @function
	.text
m_maybe_fn_name_from_expr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1960
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	movq	-16(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1961
	mov	-16(%rbp), %rax
m_L1961:
m_L1960:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr1964:
	.asciz "maybe-fn-name-from-expr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1965:
	.8byte	47
	.8byte	m_cstr1964
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_maybe_fn_name_from_expr:
	.8byte	m_maybe_fn_name_from_expr__code
	.8byte	m_ostr1965
	.globl m_maybe_fn_name_from_expr__code
	.type m_maybe_fn_name_from_expr__code, @function
	.text
m_attempt_set_convert__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	movq	-8(%rbp), %rdi
	call	m_maybe_fn_name_from_expr__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	test	%rax, %rax
	je	m_L1966
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-40(%rbp), %rdi
	movq	-24(%rbp), %rsi
	call	m_setter_name_for__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	test	%rax, %rax
	je	m_L1967
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-56(%rbp), %rdi
	movq	-24(%rbp), %rsi
	movq	-32(%rbp), %rdx
	call	m_expand_all__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	movq	-64(%rbp), %rsi
	call	m_concat_list__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-48(%rbp), %rdi
	movq	-56(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
	mov	%rax, -64(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
m_L1967:
m_L1966:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr1970:
	.asciz "attempt-set-convert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1971:
	.8byte	39
	.8byte	m_cstr1970
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_attempt_set_convert:
	.8byte	m_attempt_set_convert__code
	.8byte	m_ostr1971
	.globl m_attempt_set_convert__code
	.type m_attempt_set_convert__code, @function
	.section .rodata
m_cstr1980:
	.asciz "\012WARNING: "
	.section .rodata
m_cstr1981:
	.asciz "LET binding for '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1982:
	.8byte	35
	.8byte	m_cstr1981
	.section .rodata
m_cstr1983:
	.asciz "' while it also has a binding for a symbol form\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1984:
	.8byte	97
	.8byte	m_cstr1983
	.section .rodata
m_cstr1994:
	.asciz "illegal set form: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr1995:
	.8byte	37
	.8byte	m_cstr1994
	.section .rodata
m_cstr2011:
	.asciz "illegal define form: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2012:
	.8byte	43
	.8byte	m_cstr2011
	.text
m_expand_2Fpair__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$128, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1972
	xor	%rax, %rax
	jmp	m_L1973
m_L1972:
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
m_L1973:
	mov	-8(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	lea	m_symbol_2Flet(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1974
	xor	%rax, %rax
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m_cadr__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	xor	%rax, %rax
	mov	%rax, -72(%rbp)
	mov	-64(%rbp), %rax
	mov	%rax, -80(%rbp)
	jmp	m_L1976
m_L1975:
	movq	-80(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -88(%rbp)
	xor	%rax, %rax
	mov	%rax, -96(%rbp)
	xor	%rax, %rax
	mov	%rax, -104(%rbp)
	lea	-104(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-88(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1977
	mov	-88(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -96(%rbp)
	mov	-88(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand_all__code
	add	$0, %rsp
	mov	%rax, -104(%rbp)
	jmp	m_L1978
m_L1977:
	mov	-88(%rbp), %rax
	mov	%rax, -96(%rbp)
	xor	%rax, %rax
	mov	%rax, %rbx
	xor	%rax, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -104(%rbp)
m_L1978:
	movq	-16(%rbp), %rdi
	movq	-96(%rbp), %rsi
	call	m_maybe_form_in_env_2Fsymbol__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1979
	lea	m_cstr1980(%rip), %rax
	mov	%rax, -112(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-112(%rbp), %rsi
	mov	$10, %rdx
	syscall
	lea	m_ostr1982(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-96(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr1984(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
m_L1979:
	movq	-96(%rbp), %rdi
	movq	-104(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -112(%rbp)
	lea	-112(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	test	%rax, %rax
	je	m_L1986
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-112(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -120(%rbp)
	mov	-72(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-120(%rbp), %rax
	mov	%rax, (%rcx)
	jmp	m_L1987
m_L1986:
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-112(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
m_L1987:
	mov	%rax, -72(%rbp)
	mov	%rax, -120(%rbp)
	lea	-112(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-120(%rbp), %rax
	mov	%rax, -112(%rbp)
	lea	-104(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-112(%rbp), %rax
	movq	-80(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
m_L1976:
	mov	-80(%rbp), %rax
	test	%rax, %rax
	jne	m_L1975
	movq	-8(%rbp), %rdi
	call	m_cddr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand_all__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	lea	-72(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-56(%rbp), %rdi
	movq	-72(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	lea	m_symbol_2Flet(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-72(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	mov	-72(%rbp), %rax
	mov	%rax, -64(%rbp)
	lea	-72(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	mov	%rax, -72(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
	jmp	m_L1988
m_L1974:
	lea	m_symbol_2Fquote(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1989
	lea	m_symbol_2Fquote(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_cons__code
	add	$0, %rsp
	jmp	m_L1990
m_L1989:
	lea	m_symbol_2Fset(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L1991
	movq	-8(%rbp), %rdi
	call	m_cddr__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L1993
	movq	-8(%rbp), %rdi
	call	m_cdddr__code
	add	$0, %rsp
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
m_L1993:
	test	%rax, %rax
	jne	m_L1992
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr1995(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L1992:
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	call	m_second__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-8(%rbp), %rdi
	call	m_third__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	lea	-72(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-56(%rbp), %rdi
	movq	-72(%rbp), %rsi
	movq	-16(%rbp), %rdx
	movq	-24(%rbp), %rcx
	call	m_attempt_set_convert__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	test	%rax, %rax
	je	m_L1996
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L1997
	mov	-64(%rbp), %rax
	jmp	m_L1998
m_L1997:
	movq	-64(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
m_L1998:
	jmp	m_L1999
m_L1996:
	movq	-56(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	$1, %rdx
	call	m_expand__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
	lea	-80(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-80(%rbp), %rdi
	movq	-72(%rbp), %rsi
	movq	-16(%rbp), %rdx
	movq	-24(%rbp), %rcx
	call	m_attempt_set_convert__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	test	%rax, %rax
	je	m_L2000
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2001
	mov	-64(%rbp), %rax
	jmp	m_L2002
m_L2001:
	movq	-64(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
m_L2002:
	jmp	m_L2003
m_L2000:
	movq	-80(%rbp), %rdi
	call	m_maybe_fn_name_from_expr__code
	add	$0, %rsp
	mov	%rax, -88(%rbp)
	lea	m_symbol_2Fset(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-80(%rbp), %rsi
	movq	-72(%rbp), %rdx
	call	m_list3__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	-24(%rbp), %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2005
	mov	-88(%rbp), %rax
	test	%rax, %rax
	je	m_L2005
	mov	$14, %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	-88(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_maybe_object_in_env__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2006
	movq	-88(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_setter_name_for__code
	add	$0, %rsp
m_L2006:
m_L2005:
	test	%rax, %rax
	je	m_L2004
	movq	-64(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
	jmp	m_L2007
m_L2004:
	mov	-64(%rbp), %rax
m_L2007:
m_L2003:
	mov	%rax, -88(%rbp)
	lea	-80(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-88(%rbp), %rax
m_L1999:
	mov	%rax, -80(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-80(%rbp), %rax
	mov	%rax, -64(%rbp)
	lea	-72(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	jmp	m_L2008
m_L1991:
	lea	m_symbol_2Fdefine(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2009
	movq	-8(%rbp), %rdi
	call	m_cdddr__code
	add	$0, %rsp
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2010
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2012(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2010:
	movq	-8(%rbp), %rdi
	call	m_second__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-8(%rbp), %rdi
	call	m_third__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	movq	-72(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	lea	m_symbol_2Fdefine(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-56(%rbp), %rsi
	movq	-64(%rbp), %rdx
	call	m_list3__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-80(%rbp), %rax
	jmp	m_L2013
m_L2009:
	lea	m_symbol_2Flambda(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -72(%rbp)
	mov	-40(%rbp), %rax
	cmp	-72(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2014
	movq	-8(%rbp), %rdi
	call	m_cadr__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cddr__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand_all__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-72(%rbp), %rdi
	movq	-64(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	m_symbol_2Flambda(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-64(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-80(%rbp), %rax
	jmp	m_L2015
m_L2014:
	movq	-16(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_maybe_form_in_env_2Ffunction__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	test	%rax, %rax
	je	m_L2016
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-48(%rbp), %rdi
	movq	-56(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_apply__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	lea	-72(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2017
	mov	-72(%rbp), %rax
	jmp	m_L2018
m_L2017:
	movq	-72(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
m_L2018:
	mov	%rax, -64(%rbp)
	lea	-72(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	mov	%rax, -72(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
	jmp	m_L2019
m_L2016:
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand_all__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-40(%rbp), %rdi
	movq	-56(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
m_L2019:
m_L2015:
m_L2013:
m_L2008:
m_L1990:
m_L1988:
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2020:
	.asciz "expand/pair"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2021:
	.8byte	23
	.8byte	m_cstr2020
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_expand_2Fpair:
	.8byte	m_expand_2Fpair__code
	.8byte	m_ostr2021
	.globl m_expand_2Fpair__code
	.type m_expand_2Fpair__code, @function
	.text
m_expand_2Fsymbol__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_maybe_form_in_env_2Fsymbol__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L2022
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_list2__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_apply__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2023
	mov	-48(%rbp), %rax
	jmp	m_L2024
m_L2023:
	movq	-48(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
m_L2024:
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	jmp	m_L2025
m_L2022:
	mov	-8(%rbp), %rax
m_L2025:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2026:
	.asciz "expand/symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2027:
	.8byte	27
	.8byte	m_cstr2026
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_expand_2Fsymbol:
	.8byte	m_expand_2Fsymbol__code
	.8byte	m_ostr2027
	.globl m_expand_2Fsymbol__code
	.type m_expand_2Fsymbol__code, @function
	.section .rodata
m_cstr2030:
	.asciz "expand"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2031:
	.8byte	13
	.8byte	m_cstr2030
	.section .rodata
m_cstr2034:
	.asciz "expand"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2035:
	.8byte	13
	.8byte	m_cstr2034
	.section .rodata
m_cstr2036:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2037:
	.8byte	15
	.8byte	m_cstr2036
	.section .rodata
m_cstr2038:
	.asciz "env"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2039:
	.8byte	7
	.8byte	m_cstr2038
	.section .rodata
m_cstr2040:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2041:
	.8byte	35
	.8byte	m_cstr2040
	.section .rodata
m_cstr2042:
	.asciz "<env>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2043:
	.8byte	11
	.8byte	m_cstr2042
	.section .rodata
m_cstr2047:
	.asciz "expand"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2048:
	.8byte	13
	.8byte	m_cstr2047
	.section .rodata
m_cstr2049:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2050:
	.8byte	15
	.8byte	m_cstr2049
	.section .rodata
m_cstr2051:
	.asciz "one-step?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2052:
	.8byte	19
	.8byte	m_cstr2051
	.section .rodata
m_cstr2053:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2054:
	.8byte	35
	.8byte	m_cstr2053
	.section .rodata
m_cstr2055:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2056:
	.8byte	13
	.8byte	m_cstr2055
	.section .rodata
m_cstr2059:
	.asciz "expand"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2060:
	.8byte	13
	.8byte	m_cstr2059
	.text
m_expand_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2028
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2029
m_L2028:
	lea	m_ostr2031(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2029:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2032
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	$16, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2033
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2035(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2037(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2039(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2041(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2043(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2033:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2044
m_L2032:
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
m_L2044:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2045
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	movq	-48(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2046
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2048(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2050(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2052(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2054(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2056(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2046:
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2057
m_L2045:
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
m_L2057:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2058
	lea	m_ostr2060(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2058:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_expand__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2062:
	.asciz "expand/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2063:
	.8byte	43
	.8byte	m_cstr2062
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_expand_2Fevaluator_stub:
	.8byte	m_expand_2Fevaluator_stub__code
	.8byte	m_ostr2063
	.globl m_expand_2Fevaluator_stub__code
	.type m_expand_2Fevaluator_stub__code, @function
	.text
m_encode_all__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2064
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_encode__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_encode_all__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	jmp	m_L2065
m_L2064:
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_encode__code
	add	$0, %rsp
m_L2065:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2066:
	.asciz "encode-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2067:
	.8byte	21
	.8byte	m_cstr2066
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_encode_all:
	.8byte	m_encode_all__code
	.8byte	m_ostr2067
	.globl m_encode_all__code
	.type m_encode_all__code, @function
	.section .rodata
m_cstr2095:
	.asciz "set: undefined variable: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2096:
	.8byte	51
	.8byte	m_cstr2095
	.section .rodata
m_cstr2099:
	.asciz "encode: malformed SET expression: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2100:
	.8byte	69
	.8byte	m_cstr2099
	.section .rodata
m_cstr2104:
	.asciz "encode/pair encountered an unexpected set form: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2105:
	.8byte	97
	.8byte	m_cstr2104
	.text
m_encode_2Fpair__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$112, %rsp
	push	%rbx
	push	%r12
	push	%r13
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_encode__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	lea	m_fixed_primitive_function_2Flet(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2068
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$16, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2069
	xor	%rax, %rax
	jmp	m_L2070
m_L2069:
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	$0, %rsi
	movq	%rbx, %rdx
	call	m_environment__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -56(%rbp)
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	jmp	m_L2072
m_L2071:
	movq	-64(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	xor	%rax, %rax
	movq	-72(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-48(%rbp), %rdi
	movq	-80(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_environment_define__code
	add	$0, %rsp
	mov	%rax, -88(%rbp)
	mov	-40(%rbp), %rax
	test	%rax, %rax
	je	m_L2073
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-88(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -96(%rbp)
	mov	-56(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-96(%rbp), %rax
	mov	%rax, (%rcx)
	jmp	m_L2074
m_L2073:
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-88(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
m_L2074:
	mov	%rax, -56(%rbp)
	movq	-64(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
m_L2072:
	mov	-64(%rbp), %rax
	test	%rax, %rax
	jne	m_L2071
	mov	-48(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -72(%rbp)
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
	jmp	m_L2076
m_L2075:
	movq	-80(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -88(%rbp)
	mov	-88(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_encode_all__code
	add	$0, %rsp
	mov	%rax, -96(%rbp)
	lea	-96(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	mov	%rax, -104(%rbp)
	movq	-104(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -112(%rbp)
	movq	-104(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	-112(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-96(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -104(%rbp)
	lea	-104(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	test	%rax, %rax
	je	m_L2077
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-104(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -112(%rbp)
	mov	-72(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-112(%rbp), %rax
	mov	%rax, (%rcx)
	jmp	m_L2078
m_L2077:
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-104(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
m_L2078:
	mov	%rax, -72(%rbp)
	mov	%rax, -112(%rbp)
	lea	-104(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-112(%rbp), %rax
	mov	%rax, -104(%rbp)
	lea	-96(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-104(%rbp), %rax
	movq	-80(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
m_L2076:
	mov	-80(%rbp), %rax
	test	%rax, %rax
	jne	m_L2075
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -72(%rbp)
	mov	-48(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-72(%rbp), %rax
	mov	%rax, (%rcx)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-48(%rbp), %rsi
	call	m_encode_all__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-64(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-48(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	%rax, -72(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
	mov	%rax, -64(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
m_L2070:
	jmp	m_L2079
m_L2068:
	lea	m_fixed_primitive_function_2Flambda(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2080
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$16, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2081
	xor	%rax, %rax
	jmp	m_L2082
m_L2081:
	movq	-16(%rbp), %rdi
	movq	$1, %rsi
	movq	$0, %rdx
	call	m_environment__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	jmp	m_L2084
m_L2083:
	mov	-40(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	xor	%rax, %rax
	mov	%rax, %r12
	movq	-48(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	call	m_environment_define__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
m_L2084:
	movq	-40(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2083
	mov	-40(%rbp), %rax
	test	%rax, %rax
	je	m_L2085
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-48(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	%rbx, %rdx
	call	m_environment_define__code
	add	$0, %rsp
m_L2085:
	movq	-32(%rbp), %rdi
	movq	-48(%rbp), %rsi
	call	m_encode_all__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-48(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
m_L2082:
	jmp	m_L2087
m_L2080:
	lea	m_fixed_primitive_function_2Fdefine(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2088
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$15, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2089
	xor	%rax, %rax
	jmp	m_L2090
m_L2089:
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, %r12
	xor	%rax, %rax
	mov	%rax, %r13
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	%r13, %rdx
	call	m_environment_define__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_encode_all__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-40(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
m_L2090:
	jmp	m_L2091
m_L2088:
	lea	m_fixed_primitive_function_2Fset(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2092
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$9, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2093
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2094
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2096(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2094:
	mov	%rax, -48(%rbp)
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2098
	movq	-32(%rbp), %rdi
	call	m_cddr__code
	add	$0, %rsp
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
m_L2098:
	test	%rax, %rax
	jne	m_L2097
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2100(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2097:
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_encode_all__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-48(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	jmp	m_L2101
m_L2093:
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$15, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2102
	jmp	m_L2103
m_L2102:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2105(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2103:
m_L2101:
	jmp	m_L2106
m_L2092:
	lea	m_fixed_primitive_function_2Fquote(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2107
	xor	%rax, %rax
	jmp	m_L2108
m_L2107:
	movq	-32(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_encode_all__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
m_L2108:
m_L2106:
m_L2091:
m_L2087:
m_L2079:
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%r13
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2109:
	.asciz "encode/pair"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2110:
	.8byte	23
	.8byte	m_cstr2109
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_encode_2Fpair:
	.8byte	m_encode_2Fpair__code
	.8byte	m_ostr2110
	.globl m_encode_2Fpair__code
	.type m_encode_2Fpair__code, @function
	.section .rodata
m_cstr2112:
	.asciz "encode/symbol: failed for "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2113:
	.8byte	53
	.8byte	m_cstr2112
	.section .rodata
m_cstr2114:
	.asciz ", *globals* "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2115:
	.8byte	25
	.8byte	m_cstr2114
	.section .rodata
m_cstr2116:
	.asciz ", env "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2117:
	.8byte	13
	.8byte	m_cstr2116
	.section .rodata
m_cstr2125:
	.asciz "kernel assertion failed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2126:
	.8byte	47
	.8byte	m_cstr2125
	.text
m_encode_2Fsymbol__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2111
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2113(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2115(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2117(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2111:
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_global_variable_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2118
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$14, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2120
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$8, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L2120:
	test	%rax, %rax
	je	m_L2119
	mov	-32(%rbp), %rax
	jmp	m_L2121
m_L2119:
	jmp	m_L2123
m_L2118:
	mov	-24(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2124
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2126(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2124:
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2127
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	lea	32(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
m_L2127:
m_L2123:
	mov	-24(%rbp), %rax
m_L2121:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2129:
	.asciz "encode/symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2130:
	.8byte	27
	.8byte	m_cstr2129
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_encode_2Fsymbol:
	.8byte	m_encode_2Fsymbol__code
	.8byte	m_ostr2130
	.globl m_encode_2Fsymbol__code
	.type m_encode_2Fsymbol__code, @function
	.section .rodata
m_cstr2133:
	.asciz "encode"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2134:
	.8byte	13
	.8byte	m_cstr2133
	.section .rodata
m_cstr2137:
	.asciz "encode"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2138:
	.8byte	13
	.8byte	m_cstr2137
	.section .rodata
m_cstr2139:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2140:
	.8byte	15
	.8byte	m_cstr2139
	.section .rodata
m_cstr2141:
	.asciz "env"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2142:
	.8byte	7
	.8byte	m_cstr2141
	.section .rodata
m_cstr2143:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2144:
	.8byte	35
	.8byte	m_cstr2143
	.section .rodata
m_cstr2145:
	.asciz "<env>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2146:
	.8byte	11
	.8byte	m_cstr2145
	.section .rodata
m_cstr2149:
	.asciz "encode"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2150:
	.8byte	13
	.8byte	m_cstr2149
	.text
m_encode_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2131
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2132
m_L2131:
	lea	m_ostr2134(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2132:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2135
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$16, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2136
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2138(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2140(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2142(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2144(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2146(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2136:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2147
m_L2135:
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
m_L2147:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2148
	lea	m_ostr2150(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2148:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_encode__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2152:
	.asciz "encode/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2153:
	.8byte	43
	.8byte	m_cstr2152
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_encode_2Fevaluator_stub:
	.8byte	m_encode_2Fevaluator_stub__code
	.8byte	m_ostr2153
	.globl m_encode_2Fevaluator_stub__code
	.type m_encode_2Fevaluator_stub__code, @function
	.text
m_eval_all__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2154
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_eval_all__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	jmp	m_L2155
m_L2154:
	mov	-8(%rbp), %rax
m_L2155:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2156:
	.asciz "eval-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2157:
	.8byte	17
	.8byte	m_cstr2156
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_eval_all:
	.8byte	m_eval_all__code
	.8byte	m_ostr2157
	.globl m_eval_all__code
	.type m_eval_all__code, @function
	.section .rodata
m_cstr2159:
	.asciz "infinite recursion guard triggered at call depth "
	.section .rodata
m_cstr2160:
	.asciz "\012"
	.text
m_eval_2Fwith_call_frame__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	push	%r12
	push	%r13
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, %rbx
	xor	%rax, %rax
	mov	%rax, %r12
	xor	%rax, %rax
	mov	%rax, %r13
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	%r13, %rdx
	call	m__25new_call_frame__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m__2Acall_stack_index_2A(%rip), %rcx
	mov	%rax, (%rcx)
	cmp	$10000, %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2158
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr2159(%rip), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-40(%rbp), %rsi
	mov	$49, %rdx
	syscall
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	$10, %rsi
	movq	%r12, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr2160(%rip), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-40(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L2158:
	mov	$18, %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2162
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-24(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$8, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2163
	mov	-40(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-24(%rbp), %rdx
	call	m_apply__code
	add	$0, %rsp
	jmp	m_L2164
m_L2163:
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-24(%rbp), %rsi
	call	m_eval_all__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	movq	-40(%rbp), %rdi
	movq	-48(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_apply__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
m_L2164:
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	jmp	m_L2165
m_L2162:
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	lea	m__2Aevaluators_var_2A(%rip), %rax
	mov	(%rax), %rax
	test	%rax, %rax
	je	m_L2166
	lea	m__2Aevaluators_var_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	mov	$10, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_maybe_object_in_variable__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	test	%rax, %rax
	je	m_L2166
	movq	-40(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_array_at__code
	add	$0, %rsp
m_L2166:
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	test	%rax, %rax
	je	m_L2167
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	movq	-40(%rbp), %rdi
	movq	-48(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_apply__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	jmp	m_L2168
m_L2167:
	mov	-16(%rbp), %rax
m_L2168:
m_L2165:
	mov	%rax, -32(%rbp)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	sub	$1, %rax
	lea	m__2Acall_stack_index_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	cmp	-40(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2169
	lea	m__2Acall_stack_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m__2Acall_stack_index_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	lea	16(%rax), %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
m_L2169:
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%r13
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2171:
	.asciz "eval/with-call-frame"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2172:
	.8byte	41
	.8byte	m_cstr2171
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_eval_2Fwith_call_frame:
	.8byte	m_eval_2Fwith_call_frame__code
	.8byte	m_ostr2172
	.globl m_eval_2Fwith_call_frame__code
	.type m_eval_2Fwith_call_frame__code, @function
	.text
m_eval_2Fvariable__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_global_variable_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2173
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	jmp	m_L2174
m_L2173:
	mov	-8(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	sub	-24(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	jmp	m_L2176
m_L2175:
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	mov	-24(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -24(%rbp)
m_L2176:
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	cmp	-32(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2175
	mov	-8(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-32(%rbp), %rsi
	call	m_array_at__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	-40(%rbp), %rax
m_L2174:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2177:
	.asciz "eval/variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2178:
	.8byte	27
	.8byte	m_cstr2177
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_eval_2Fvariable:
	.8byte	m_eval_2Fvariable__code
	.8byte	m_ostr2178
	.globl m_eval_2Fvariable__code
	.type m_eval_2Fvariable__code, @function
	.text
m_expand_encode_eval_2A__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	$2, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2179
	xor	%rax, %rax
m_L2179:
	movq	-24(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	$0, %rdx
	call	m_expand__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	$2, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2181
	xor	%rax, %rax
m_L2181:
	movq	-24(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_encode__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	$2, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2183
	xor	%rax, %rax
m_L2183:
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_base_context__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	$2, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2185
	xor	%rax, %rax
m_L2185:
	xor	%rax, %rax
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2187:
	.asciz "expand-encode-eval*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2188:
	.8byte	39
	.8byte	m_cstr2187
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_expand_encode_eval_2A:
	.8byte	m_expand_encode_eval_2A__code
	.8byte	m_ostr2188
	.globl m_expand_encode_eval_2A__code
	.type m_expand_encode_eval_2A__code, @function
	.text
m_expand_encode_eval__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	$1, %rsi
	movq	$0, %rdx
	call	m_environment__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_expand_encode_eval_2A__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2189:
	.asciz "expand-encode-eval"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2190:
	.8byte	37
	.8byte	m_cstr2189
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_expand_encode_eval:
	.8byte	m_expand_encode_eval__code
	.8byte	m_ostr2190
	.globl m_expand_encode_eval__code
	.type m_expand_encode_eval__code, @function
	.text
m_expand_encode_eval_stream__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	xor	%rax, %rax
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	jmp	m_L2192
m_L2191:
	movq	-16(%rbp), %rdi
	call	m_expand_encode_eval__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
m_L2192:
	movq	-8(%rbp), %rdi
	call	m_read__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	%rax, -32(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2191
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2193:
	.asciz "expand-encode-eval-stream"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2194:
	.8byte	51
	.8byte	m_cstr2193
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_expand_encode_eval_stream:
	.8byte	m_expand_encode_eval_stream__code
	.8byte	m_ostr2194
	.globl m_expand_encode_eval_stream__code
	.type m_expand_encode_eval_stream__code, @function
	.section .rodata
m_cstr2196:
	.asciz "syscall*: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2197:
	.8byte	21
	.8byte	m_cstr2196
	.section .rodata
m_cstr2198:
	.asciz " returned with: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2199:
	.8byte	33
	.8byte	m_cstr2198
	.section .rodata
m_cstr2200:
	.asciz "\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2201:
	.8byte	3
	.8byte	m_cstr2200
	.text
m__25syscall_rc_assert__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	cmp	-24(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2195
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2197(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2199(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2201(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2195:
	mov	-16(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2202:
	.asciz "%syscall-rc-assert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2203:
	.8byte	37
	.8byte	m_cstr2202
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25syscall_rc_assert:
	.8byte	m__25syscall_rc_assert__code
	.8byte	m_ostr2203
	.globl m__25syscall_rc_assert__code
	.type m__25syscall_rc_assert__code, @function
	.section .rodata
m_cstr2207:
	.asciz "waitpid returned with "
	.section .rodata
m_cstr2208:
	.asciz "\012"
	.text
m_posix_2Fwaitpid__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L2205
m_L2204:
m_L2205:
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$61, %rax
	mov	-40(%rbp), %rdi
	mov	-48(%rbp), %rsi
	mov	-56(%rbp), %rdx
	mov	$0, %r10
	syscall
	mov	%rax, -32(%rbp)
	mov	%rax, -40(%rbp)
	mov	$4, %rax
	neg	%rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2204
	mov	-32(%rbp), %rax
	test	%rax, %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2206
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr2207(%rip), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-40(%rbp), %rsi
	mov	$22, %rdx
	syscall
	lea	m_platform_2Fdiag_print_char(%rip), %rax
	mov	%rax, %rbx
	movq	-32(%rbp), %rdi
	movq	$10, %rsi
	movq	%rbx, %rdx
	call	m_long__3Estring_2Femit__code
	add	$0, %rsp
	lea	m_cstr2208(%rip), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-40(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
	jmp	m_L2209
m_L2206:
	mov	-24(%rbp), %rax
	and	$127, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2210
	mov	-24(%rbp), %rax
	sar	$8, %rax
	and	$255, %rax
	jmp	m_L2211
m_L2210:
	mov	-24(%rbp), %rax
	and	$127, %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	add	-40(%rbp),%rax
	cmp	$2, %rax
	setge	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2212
	mov	-24(%rbp), %rax
	and	$127, %rax
	mov	%rax, -40(%rbp)
	mov	$128, %rax
	add	-40(%rbp),%rax
	jmp	m_L2213
m_L2212:
	mov	$-1, %rax
m_L2213:
m_L2211:
m_L2209:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2214:
	.asciz "posix/waitpid"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2215:
	.8byte	27
	.8byte	m_cstr2214
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_posix_2Fwaitpid:
	.8byte	m_posix_2Fwaitpid__code
	.8byte	m_ostr2215
	.globl m_posix_2Fwaitpid__code
	.type m_posix_2Fwaitpid__code, @function
	.text
m_posix_2Fspawn_program__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	movq	%r8, -40(%rbp)
	mov	$56, %rax
	mov	$17, %rdi
	mov	$0, %rsi
	syscall
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2216
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2217
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$292, %rax
	mov	-56(%rbp), %rdi
	mov	$1, %rsi
	mov	$0, %rdx
	syscall
	mov	%rax, %rbx
	movq	$292, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$3, %rax
	mov	-56(%rbp), %rdi
	syscall
	mov	%rax, %rbx
	movq	$3, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
m_L2217:
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	cmp	-56(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2219
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$292, %rax
	mov	-56(%rbp), %rdi
	mov	$2, %rsi
	mov	$0, %rdx
	syscall
	mov	%rax, %rbx
	movq	$292, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$3, %rax
	mov	-56(%rbp), %rdi
	syscall
	mov	%rax, %rbx
	movq	$3, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
m_L2219:
	mov	-8(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -72(%rbp)
	mov	$59, %rax
	mov	-56(%rbp), %rdi
	mov	-64(%rbp), %rsi
	mov	-72(%rbp), %rdx
	syscall
	mov	%rax, %rbx
	movq	$59, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
	mov	$60, %rax
	mov	$127, %rdi
	syscall
	jmp	m_L2221
m_L2216:
	mov	-48(%rbp), %rax
m_L2221:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2222:
	.asciz "posix/spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2223:
	.8byte	39
	.8byte	m_cstr2222
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_posix_2Fspawn_program:
	.8byte	m_posix_2Fspawn_program__code
	.8byte	m_ostr2223
	.globl m_posix_2Fspawn_program__code
	.type m_posix_2Fspawn_program__code, @function
	.text
m_working_directory__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	$4096, %rdi
	call	m_allocate_data__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	lea	-8(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$79, %rax
	mov	-16(%rbp), %rdi
	mov	$4096, %rsi
	syscall
	mov	%rax, %rbx
	movq	$79, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	-16(%rbp), %rax
	sub	$1, %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_C_string__3Estring_2A__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-8(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2224:
	.asciz "working-directory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2225:
	.8byte	35
	.8byte	m_cstr2224
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_working_directory:
	.8byte	m_working_directory__code
	.8byte	m_ostr2225
	.globl m_working_directory__code
	.type m_working_directory__code, @function
	.section .rodata
m_cstr2227:
	.asciz "working-directory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2228:
	.8byte	35
	.8byte	m_cstr2227
	.text
m_working_directory_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2226
	lea	m_ostr2228(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2226:
	call	m_working_directory__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2230:
	.asciz "working-directory/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2231:
	.8byte	65
	.8byte	m_cstr2230
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_working_directory_2Fevaluator_stub:
	.8byte	m_working_directory_2Fevaluator_stub__code
	.8byte	m_ostr2231
	.globl m_working_directory_2Fevaluator_stub__code
	.type m_working_directory_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2233:
	.asciz "changing working directory to: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2234:
	.8byte	63
	.8byte	m_cstr2233
	.section .rodata
m_cstr2235:
	.asciz "\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2236:
	.8byte	3
	.8byte	m_cstr2235
	.text
m_set_working_directory__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	mov	$1, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2232
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_ostr2234(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_ostr2236(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
m_L2232:
	movq	-8(%rbp), %rdi
	call	m__25string__3EC_string__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$80, %rax
	mov	-16(%rbp), %rdi
	syscall
	mov	%rax, %rbx
	movq	$80, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2238:
	.asciz "set-working-directory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2239:
	.8byte	43
	.8byte	m_cstr2238
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_working_directory:
	.8byte	m_set_working_directory__code
	.8byte	m_ostr2239
	.globl m_set_working_directory__code
	.type m_set_working_directory__code, @function
	.section .rodata
m_cstr2242:
	.asciz "set-working-directory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2243:
	.8byte	43
	.8byte	m_cstr2242
	.section .rodata
m_cstr2244:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2245:
	.8byte	15
	.8byte	m_cstr2244
	.section .rodata
m_cstr2246:
	.asciz "path"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2247:
	.8byte	9
	.8byte	m_cstr2246
	.section .rodata
m_cstr2248:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2249:
	.8byte	35
	.8byte	m_cstr2248
	.section .rodata
m_cstr2250:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2251:
	.8byte	17
	.8byte	m_cstr2250
	.section .rodata
m_cstr2253:
	.asciz "set-working-directory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2254:
	.8byte	43
	.8byte	m_cstr2253
	.section .rodata
m_cstr2256:
	.asciz "set-working-directory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2257:
	.8byte	43
	.8byte	m_cstr2256
	.text
m_set_working_directory_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2240
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2241
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2243(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2245(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2247(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2249(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2251(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2241:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2252
m_L2240:
	lea	m_ostr2254(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2252:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2255
	lea	m_ostr2257(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2255:
	movq	-32(%rbp), %rdi
	call	m_set_working_directory__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2259:
	.asciz "set-working-directory/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2260:
	.8byte	73
	.8byte	m_cstr2259
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_working_directory_2Fevaluator_stub:
	.8byte	m_set_working_directory_2Fevaluator_stub__code
	.8byte	m_ostr2260
	.globl m_set_working_directory_2Fevaluator_stub__code
	.type m_set_working_directory_2Fevaluator_stub__code, @function
	.text
m_posix_2Fopen__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	$257, %rax
	mov	$-100, %rdi
	mov	-32(%rbp), %rsi
	mov	-40(%rbp), %rdx
	mov	-48(%rbp), %r10
	syscall
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2261:
	.asciz "posix/open"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2262:
	.8byte	21
	.8byte	m_cstr2261
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_posix_2Fopen:
	.8byte	m_posix_2Fopen__code
	.8byte	m_ostr2262
	.globl m_posix_2Fopen__code
	.type m_posix_2Fopen__code, @function
	.text
m_posix_2Fclose__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$3, %rax
	mov	-16(%rbp), %rdi
	syscall
	mov	%rax, %rbx
	movq	$3, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2263:
	.asciz "posix/close"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2264:
	.8byte	23
	.8byte	m_cstr2263
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_posix_2Fclose:
	.8byte	m_posix_2Fclose__code
	.8byte	m_ostr2264
	.globl m_posix_2Fclose__code
	.type m_posix_2Fclose__code, @function
	.text
m_posix_2Fread_byte__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	xor	%rax, %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2266
m_L2265:
m_L2266:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	$0, %rax
	mov	-32(%rbp), %rdi
	mov	-40(%rbp), %rsi
	mov	$1, %rdx
	syscall
	mov	%rax, -24(%rbp)
	mov	%rax, -32(%rbp)
	mov	$4, %rax
	neg	%rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2265
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
m_L2268:
	test	%rax, %rax
	je	m_L2267
	mov	$-1, %rax
	jmp	m_L2269
m_L2267:
	mov	-32(%rbp), %rax
	cmp	$1, %rax
	sete	%al
	movzb	%al, %rax
m_L2271:
	test	%rax, %rax
	je	m_L2270
	mov	-16(%rbp), %rax
	jmp	m_L2272
m_L2270:
	mov	-24(%rbp), %rax
	neg	%rax
m_L2272:
m_L2269:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2273:
	.asciz "posix/read-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2274:
	.8byte	31
	.8byte	m_cstr2273
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_posix_2Fread_byte:
	.8byte	m_posix_2Fread_byte__code
	.8byte	m_ostr2274
	.globl m_posix_2Fread_byte__code
	.type m_posix_2Fread_byte__code, @function
	.text
m_posix_2Fwrite__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L2276
m_L2275:
m_L2276:
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	mov	-40(%rbp), %rdi
	mov	-48(%rbp), %rsi
	mov	-56(%rbp), %rdx
	syscall
	mov	%rax, -32(%rbp)
	mov	%rax, -40(%rbp)
	mov	$4, %rax
	neg	%rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2275
	mov	-32(%rbp), %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2277:
	.asciz "posix/write"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2278:
	.8byte	23
	.8byte	m_cstr2277
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_posix_2Fwrite:
	.8byte	m_posix_2Fwrite__code
	.8byte	m_ostr2278
	.globl m_posix_2Fwrite__code
	.type m_posix_2Fwrite__code, @function
	.section .rodata
m_cstr2281:
	.asciz "r"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2282:
	.8byte	3
	.8byte	m_cstr2281
	.section .rodata
m_cstr2285:
	.asciz "rw"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2286:
	.8byte	5
	.8byte	m_cstr2285
	.section .rodata
m_cstr2289:
	.asciz "w"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2290:
	.8byte	3
	.8byte	m_cstr2289
	.section .rodata
m_cstr2292:
	.asciz "file-open: unexpected mode "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2293:
	.8byte	55
	.8byte	m_cstr2292
	.section .rodata
m_cstr2294:
	.asciz " while opening "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2295:
	.8byte	31
	.8byte	m_cstr2294
	.text
m_file_open__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m__25string__3EC_string__code
	add	$0, %rsp
	mov	%rax, %rbx
	mov	-16(%rbp), %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2280
	lea	m_ostr2282(%rip), %rax
	mov	%rax, %r12
	movq	-16(%rbp), %rdi
	movq	%r12, %rsi
	call	m_string_3D__code
	add	$0, %rsp
m_L2280:
	test	%rax, %rax
	je	m_L2279
	xor	%rax, %rax
	jmp	m_L2283
m_L2279:
	lea	m_ostr2286(%rip), %rax
	mov	%rax, %r12
	movq	-16(%rbp), %rdi
	movq	%r12, %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2284
	mov	$64, %rax
	or	$512, %rax
	mov	%rax, -24(%rbp)
	mov	$2, %rax
	or	-24(%rbp), %rax
	jmp	m_L2287
m_L2284:
	lea	m_ostr2290(%rip), %rax
	mov	%rax, %r12
	movq	-16(%rbp), %rdi
	movq	%r12, %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2288
	mov	$64, %rax
	or	$512, %rax
	mov	%rax, -24(%rbp)
	mov	$1, %rax
	or	-24(%rbp), %rax
	jmp	m_L2291
m_L2288:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2293(%rip), %rax
	mov	%rax, %r12
	movq	%r12, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2295(%rip), %rax
	mov	%rax, %r12
	movq	%r12, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2291:
m_L2287:
m_L2283:
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$420, %rdx
	call	m_posix_2Fopen__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	cmp	-32(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2296
	xor	%rax, %rax
	mov	$20, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-24(%rbp), %rsi
	call	m__25allocate_boxed_word__code
	add	$0, %rsp
m_L2296:
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2298:
	.asciz "file-open"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2299:
	.8byte	19
	.8byte	m_cstr2298
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_open:
	.8byte	m_file_open__code
	.8byte	m_ostr2299
	.globl m_file_open__code
	.type m_file_open__code, @function
	.section .rodata
m_cstr2302:
	.asciz "file-open"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2303:
	.8byte	19
	.8byte	m_cstr2302
	.section .rodata
m_cstr2304:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2305:
	.8byte	15
	.8byte	m_cstr2304
	.section .rodata
m_cstr2306:
	.asciz "path"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2307:
	.8byte	9
	.8byte	m_cstr2306
	.section .rodata
m_cstr2308:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2309:
	.8byte	35
	.8byte	m_cstr2308
	.section .rodata
m_cstr2310:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2311:
	.8byte	17
	.8byte	m_cstr2310
	.section .rodata
m_cstr2313:
	.asciz "file-open"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2314:
	.8byte	19
	.8byte	m_cstr2313
	.section .rodata
m_cstr2317:
	.asciz "file-open"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2318:
	.8byte	19
	.8byte	m_cstr2317
	.section .rodata
m_cstr2319:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2320:
	.8byte	15
	.8byte	m_cstr2319
	.section .rodata
m_cstr2321:
	.asciz "mode"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2322:
	.8byte	9
	.8byte	m_cstr2321
	.section .rodata
m_cstr2323:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2324:
	.8byte	35
	.8byte	m_cstr2323
	.section .rodata
m_cstr2325:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2326:
	.8byte	17
	.8byte	m_cstr2325
	.section .rodata
m_cstr2328:
	.asciz "file-open"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2329:
	.8byte	19
	.8byte	m_cstr2328
	.section .rodata
m_cstr2331:
	.asciz "file-open"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2332:
	.8byte	19
	.8byte	m_cstr2331
	.text
m_file_open_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2300
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2301
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2303(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2305(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2307(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2309(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2311(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2301:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2312
m_L2300:
	lea	m_ostr2314(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2312:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2315
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2316
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2318(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2320(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2322(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2324(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2326(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2316:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2327
m_L2315:
	lea	m_ostr2329(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2327:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2330
	lea	m_ostr2332(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2330:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_file_open__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2334:
	.asciz "file-open/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2335:
	.8byte	49
	.8byte	m_cstr2334
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_open_2Fevaluator_stub:
	.8byte	m_file_open_2Fevaluator_stub__code
	.8byte	m_ostr2335
	.globl m_file_open_2Fevaluator_stub__code
	.type m_file_open_2Fevaluator_stub__code, @function
	.text
m_file_close__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -16(%rbp)
	mov	$3, %rax
	mov	-16(%rbp), %rdi
	syscall
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2336
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2336:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2338:
	.asciz "file-close"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2339:
	.8byte	21
	.8byte	m_cstr2338
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_close:
	.8byte	m_file_close__code
	.8byte	m_ostr2339
	.globl m_file_close__code
	.type m_file_close__code, @function
	.section .rodata
m_cstr2342:
	.asciz "file-close"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2343:
	.8byte	21
	.8byte	m_cstr2342
	.section .rodata
m_cstr2344:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2345:
	.8byte	15
	.8byte	m_cstr2344
	.section .rodata
m_cstr2346:
	.asciz "fd"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2347:
	.8byte	5
	.8byte	m_cstr2346
	.section .rodata
m_cstr2348:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2349:
	.8byte	35
	.8byte	m_cstr2348
	.section .rodata
m_cstr2350:
	.asciz "<lower-cell>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2351:
	.8byte	25
	.8byte	m_cstr2350
	.section .rodata
m_cstr2353:
	.asciz "file-close"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2354:
	.8byte	21
	.8byte	m_cstr2353
	.section .rodata
m_cstr2356:
	.asciz "file-close"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2357:
	.8byte	21
	.8byte	m_cstr2356
	.text
m_file_close_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2340
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$20, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2341
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2343(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2345(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2347(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2349(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2351(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2341:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2352
m_L2340:
	lea	m_ostr2354(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2352:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2355
	lea	m_ostr2357(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2355:
	movq	-32(%rbp), %rdi
	call	m_file_close__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2359:
	.asciz "file-close/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2360:
	.8byte	51
	.8byte	m_cstr2359
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_close_2Fevaluator_stub:
	.8byte	m_file_close_2Fevaluator_stub__code
	.8byte	m_ostr2360
	.globl m_file_close_2Fevaluator_stub__code
	.type m_file_close_2Fevaluator_stub__code, @function
	.text
m_file_read_byte__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	xor	%rax, %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2362
m_L2361:
m_L2362:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	$0, %rax
	mov	-32(%rbp), %rdi
	mov	-40(%rbp), %rsi
	mov	$1, %rdx
	syscall
	mov	%rax, -24(%rbp)
	mov	$4, %rax
	neg	%rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2361
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	$1, %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2363
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	jmp	m_L2364
m_L2363:
	xor	%rax, %rax
m_L2364:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2365:
	.asciz "file-read-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2366:
	.8byte	29
	.8byte	m_cstr2365
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_read_byte:
	.8byte	m_file_read_byte__code
	.8byte	m_ostr2366
	.globl m_file_read_byte__code
	.type m_file_read_byte__code, @function
	.section .rodata
m_cstr2369:
	.asciz "file-read-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2370:
	.8byte	29
	.8byte	m_cstr2369
	.section .rodata
m_cstr2371:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2372:
	.8byte	15
	.8byte	m_cstr2371
	.section .rodata
m_cstr2373:
	.asciz "fd"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2374:
	.8byte	5
	.8byte	m_cstr2373
	.section .rodata
m_cstr2375:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2376:
	.8byte	35
	.8byte	m_cstr2375
	.section .rodata
m_cstr2377:
	.asciz "<lower-cell>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2378:
	.8byte	25
	.8byte	m_cstr2377
	.section .rodata
m_cstr2380:
	.asciz "file-read-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2381:
	.8byte	29
	.8byte	m_cstr2380
	.section .rodata
m_cstr2383:
	.asciz "file-read-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2384:
	.8byte	29
	.8byte	m_cstr2383
	.text
m_file_read_byte_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2367
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$20, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2368
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2370(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2372(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2374(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2376(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2378(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2368:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2379
m_L2367:
	lea	m_ostr2381(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2379:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2382
	lea	m_ostr2384(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2382:
	movq	-32(%rbp), %rdi
	call	m_file_read_byte__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2386:
	.asciz "file-read-byte/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2387:
	.8byte	59
	.8byte	m_cstr2386
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_read_byte_2Fevaluator_stub:
	.8byte	m_file_read_byte_2Fevaluator_stub__code
	.8byte	m_ostr2387
	.globl m_file_read_byte_2Fevaluator_stub__code
	.type m_file_read_byte_2Fevaluator_stub__code, @function
	.text
m_file_write_byte__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	lea	-8(%rbp), %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$1, %rdx
	call	m_posix_2Fwrite__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	$1, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2388
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2388:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2390:
	.asciz "file-write-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2391:
	.8byte	31
	.8byte	m_cstr2390
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_write_byte:
	.8byte	m_file_write_byte__code
	.8byte	m_ostr2391
	.globl m_file_write_byte__code
	.type m_file_write_byte__code, @function
	.section .rodata
m_cstr2394:
	.asciz "file-write-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2395:
	.8byte	31
	.8byte	m_cstr2394
	.section .rodata
m_cstr2396:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2397:
	.8byte	15
	.8byte	m_cstr2396
	.section .rodata
m_cstr2398:
	.asciz "char"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2399:
	.8byte	9
	.8byte	m_cstr2398
	.section .rodata
m_cstr2400:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2401:
	.8byte	35
	.8byte	m_cstr2400
	.section .rodata
m_cstr2402:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2403:
	.8byte	13
	.8byte	m_cstr2402
	.section .rodata
m_cstr2405:
	.asciz "file-write-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2406:
	.8byte	31
	.8byte	m_cstr2405
	.section .rodata
m_cstr2409:
	.asciz "file-write-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2410:
	.8byte	31
	.8byte	m_cstr2409
	.section .rodata
m_cstr2411:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2412:
	.8byte	15
	.8byte	m_cstr2411
	.section .rodata
m_cstr2413:
	.asciz "fd"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2414:
	.8byte	5
	.8byte	m_cstr2413
	.section .rodata
m_cstr2415:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2416:
	.8byte	35
	.8byte	m_cstr2415
	.section .rodata
m_cstr2417:
	.asciz "<lower-cell>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2418:
	.8byte	25
	.8byte	m_cstr2417
	.section .rodata
m_cstr2420:
	.asciz "file-write-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2421:
	.8byte	31
	.8byte	m_cstr2420
	.section .rodata
m_cstr2423:
	.asciz "file-write-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2424:
	.8byte	31
	.8byte	m_cstr2423
	.text
m_file_write_byte_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2392
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2393
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2395(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2397(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2399(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2401(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2403(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2393:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2404
m_L2392:
	lea	m_ostr2406(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2404:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2407
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$20, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2408
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2410(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2412(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2414(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2416(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2418(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2408:
	mov	-40(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2419
m_L2407:
	lea	m_ostr2421(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2419:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2422
	lea	m_ostr2424(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2422:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_file_write_byte__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2426:
	.asciz "file-write-byte/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2427:
	.8byte	61
	.8byte	m_cstr2426
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_write_byte_2Fevaluator_stub:
	.8byte	m_file_write_byte_2Fevaluator_stub__code
	.8byte	m_ostr2427
	.globl m_file_write_byte_2Fevaluator_stub__code
	.type m_file_write_byte_2Fevaluator_stub__code, @function
	.text
m_file_modification_time__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	$256, %rdi
	call	m_allocate_data__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m__25string__3EC_string__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	$332, %rax
	mov	$-100, %rdi
	mov	-24(%rbp), %rsi
	mov	$0, %rdx
	mov	$2047, %r10
	mov	-32(%rbp), %r8
	syscall
	mov	%rax, %rbx
	movq	$332, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	mov	$112, %rcx
	lea	(%rax, %rcx, 1), %rcx
	mov	(%rcx), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2428:
	.asciz "file-modification-time"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2429:
	.8byte	45
	.8byte	m_cstr2428
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_modification_time:
	.8byte	m_file_modification_time__code
	.8byte	m_ostr2429
	.globl m_file_modification_time__code
	.type m_file_modification_time__code, @function
	.section .rodata
m_cstr2432:
	.asciz "file-modification-time"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2433:
	.8byte	45
	.8byte	m_cstr2432
	.section .rodata
m_cstr2434:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2435:
	.8byte	15
	.8byte	m_cstr2434
	.section .rodata
m_cstr2436:
	.asciz "path"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2437:
	.8byte	9
	.8byte	m_cstr2436
	.section .rodata
m_cstr2438:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2439:
	.8byte	35
	.8byte	m_cstr2438
	.section .rodata
m_cstr2440:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2441:
	.8byte	17
	.8byte	m_cstr2440
	.section .rodata
m_cstr2443:
	.asciz "file-modification-time"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2444:
	.8byte	45
	.8byte	m_cstr2443
	.section .rodata
m_cstr2446:
	.asciz "file-modification-time"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2447:
	.8byte	45
	.8byte	m_cstr2446
	.text
m_file_modification_time_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2430
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2431
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2433(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2435(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2437(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2439(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2441(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2431:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2442
m_L2430:
	lea	m_ostr2444(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2442:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2445
	lea	m_ostr2447(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2445:
	movq	-32(%rbp), %rdi
	call	m_file_modification_time__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2449:
	.asciz "file-modification-time/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2450:
	.8byte	75
	.8byte	m_cstr2449
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_modification_time_2Fevaluator_stub:
	.8byte	m_file_modification_time_2Fevaluator_stub__code
	.8byte	m_ostr2450
	.globl m_file_modification_time_2Fevaluator_stub__code
	.type m_file_modification_time_2Fevaluator_stub__code, @function
	.text
m_file_stream__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	mov	$26, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	$16, %rsi
	call	m_gc_2Fallocate_opaque__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	$-1, %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2451:
	.asciz "file-stream"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2452:
	.8byte	23
	.8byte	m_cstr2451
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_stream:
	.8byte	m_file_stream__code
	.8byte	m_ostr2452
	.globl m_file_stream__code
	.type m_file_stream__code, @function
	.section .rodata
m_cstr2455:
	.asciz "file-stream"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2456:
	.8byte	23
	.8byte	m_cstr2455
	.section .rodata
m_cstr2457:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2458:
	.8byte	15
	.8byte	m_cstr2457
	.section .rodata
m_cstr2459:
	.asciz "fd"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2460:
	.8byte	5
	.8byte	m_cstr2459
	.section .rodata
m_cstr2461:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2462:
	.8byte	35
	.8byte	m_cstr2461
	.section .rodata
m_cstr2463:
	.asciz "<lower-cell>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2464:
	.8byte	25
	.8byte	m_cstr2463
	.section .rodata
m_cstr2466:
	.asciz "file-stream"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2467:
	.8byte	23
	.8byte	m_cstr2466
	.section .rodata
m_cstr2469:
	.asciz "file-stream"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2470:
	.8byte	23
	.8byte	m_cstr2469
	.text
m_file_stream_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2453
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$20, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2454
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2456(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2458(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2460(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2462(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2464(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2454:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2465
m_L2453:
	lea	m_ostr2467(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2465:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2468
	lea	m_ostr2470(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2468:
	movq	-32(%rbp), %rdi
	call	m_file_stream__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2472:
	.asciz "file-stream/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2473:
	.8byte	53
	.8byte	m_cstr2472
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_stream_2Fevaluator_stub:
	.8byte	m_file_stream_2Fevaluator_stub__code
	.8byte	m_ostr2473
	.globl m_file_stream_2Fevaluator_stub__code
	.type m_file_stream_2Fevaluator_stub__code, @function
	.text
m__25ensure_peeked__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	cmp	-16(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2474
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	$0, %rax
	mov	-32(%rbp), %rdi
	mov	-40(%rbp), %rsi
	mov	$1, %rdx
	syscall
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	$1, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2475
	mov	-24(%rbp), %rax
	jmp	m_L2476
m_L2475:
	mov	$-1, %rax
m_L2476:
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
m_L2474:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2477:
	.asciz "%ensure-peeked"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2478:
	.8byte	29
	.8byte	m_cstr2477
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25ensure_peeked:
	.8byte	m__25ensure_peeked__code
	.8byte	m_ostr2478
	.globl m__25ensure_peeked__code
	.type m__25ensure_peeked__code, @function
	.section .rodata
m_cstr2481:
	.asciz "<fd-stream> $put-all: write failed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2482:
	.8byte	69
	.8byte	m_cstr2481
	.text
m__25put_all__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	call	m_posix_2Fwrite__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2479
	xor	%rax, %rax
	jmp	m_L2480
m_L2479:
	xor	%rax, %rax
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2482(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2480:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2483:
	.asciz "%put-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2484:
	.8byte	17
	.8byte	m_cstr2483
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25put_all:
	.8byte	m__25put_all__code
	.8byte	m_ostr2484
	.globl m__25put_all__code
	.type m__25put_all__code, @function
	.section .rodata
m_cstr2486:
	.asciz "file-open failed for path '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2487:
	.8byte	55
	.8byte	m_cstr2486
	.section .rodata
m_cstr2488:
	.asciz "', mode '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2489:
	.8byte	19
	.8byte	m_cstr2488
	.section .rodata
m_cstr2490:
	.asciz "', cwd '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2491:
	.8byte	17
	.8byte	m_cstr2490
	.section .rodata
m_cstr2492:
	.asciz "'"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2493:
	.8byte	3
	.8byte	m_cstr2492
	.text
m_file_open_or_die__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_file_open__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2485
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2487(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2489(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2491(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_working_directory__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2493(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2485:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2494:
	.asciz "file-open-or-die"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2495:
	.8byte	33
	.8byte	m_cstr2494
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_open_or_die:
	.8byte	m_file_open_or_die__code
	.8byte	m_ostr2495
	.globl m_file_open_or_die__code
	.type m_file_open_or_die__code, @function
	.section .rodata
m_cstr2497:
	.asciz "file-close failed for handle "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2498:
	.8byte	59
	.8byte	m_cstr2497
	.text
m_file_close_or_die__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	call	m_file_close__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2496
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2498(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2496:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2499:
	.asciz "file-close-or-die"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2500:
	.8byte	35
	.8byte	m_cstr2499
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_close_or_die:
	.8byte	m_file_close_or_die__code
	.8byte	m_ostr2500
	.globl m_file_close_or_die__code
	.type m_file_close_or_die__code, @function
	.section .rodata
m_cstr2502:
	.asciz "file-write-byte failed for stream "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2503:
	.8byte	69
	.8byte	m_cstr2502
	.section .rodata
m_cstr2504:
	.asciz ", char "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2505:
	.8byte	15
	.8byte	m_cstr2504
	.text
m_file_write_byte_or_die__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_file_write_byte__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2501
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2503(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2505(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2501:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2506:
	.asciz "file-write-byte-or-die"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2507:
	.8byte	45
	.8byte	m_cstr2506
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_file_write_byte_or_die:
	.8byte	m_file_write_byte_or_die__code
	.8byte	m_ostr2507
	.globl m_file_write_byte_or_die__code
	.type m_file_write_byte_or_die__code, @function
	.text
m_initialize_streams__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	-8(%rbp), %rdi
	call	m_file_stream__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_input_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-32(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_input_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-32(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	movq	-16(%rbp), %rdi
	call	m_file_stream__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-32(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-32(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	movq	-24(%rbp), %rdi
	call	m_file_stream__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-32(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-32(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	movq	-24(%rbp), %rdi
	call	m_file_stream__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-32(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-32(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2508:
	.asciz "initialize-streams"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2509:
	.8byte	37
	.8byte	m_cstr2508
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_initialize_streams:
	.8byte	m_initialize_streams__code
	.8byte	m_ostr2509
	.globl m_initialize_streams__code
	.type m_initialize_streams__code, @function
	.section .rodata
m_cstr2524:
	.asciz "maru> "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2525:
	.8byte	13
	.8byte	m_cstr2524
	.section .rodata
m_cstr2528:
	.asciz "\012morituri te salutant\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2529:
	.8byte	45
	.8byte	m_cstr2528
	.text
m_repl_stream__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L2512
	mov	-32(%rbp), %rax
	and	$7, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L2512:
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2511
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	$10000, %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2513
	mov	$1, %rax
m_L2513:
m_L2511:
	test	%rax, %rax
	jne	m_L2510
	call	m_error_prologue__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L2515
	mov	-32(%rbp), %rax
	and	$7, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L2515:
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2514
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	$10000, %rax
	cmp	-40(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2516
	mov	$1, %rax
m_L2516:
m_L2514:
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2510:
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	jmp	m_L2518
m_L2517:
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2519
	xor	%rax, %rax
	jmp	m_L2520
m_L2519:
	movq	-32(%rbp), %rdi
	call	m_expand_encode_eval__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2521
	movq	-16(%rbp), %rdi
	movq	-32(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-16(%rbp), %rdi
	movq	$10, %rsi
	call	m__24put__code
	add	$0, %rsp
	call	m_platform_2Fflush_streams__code
	add	$0, %rsp
m_L2521:
m_L2520:
m_L2518:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2523
	lea	m_ostr2525(%rip), %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
	call	m_platform_2Fflush_streams__code
	add	$0, %rsp
m_L2523:
	movq	-8(%rbp), %rdi
	call	m_read__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	%rax, -40(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2517
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2527
	lea	m_ostr2529(%rip), %rax
	mov	%rax, %rbx
	movq	-16(%rbp), %rdi
	movq	%rbx, %rsi
	call	m__24put_all__code
	add	$0, %rsp
m_L2527:
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2531:
	.asciz "repl-stream"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2532:
	.8byte	23
	.8byte	m_cstr2531
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_repl_stream:
	.8byte	m_repl_stream__code
	.8byte	m_ostr2532
	.globl m_repl_stream__code
	.type m_repl_stream__code, @function
	.section .rodata
m_cstr2540:
	.asciz "repl-stream"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2541:
	.8byte	23
	.8byte	m_cstr2540
	.text
m_repl_stream_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2533
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2534
m_L2533:
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_input_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
m_L2534:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2535
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2536
m_L2535:
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
m_L2536:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2537
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2538
m_L2537:
	mov	$1, %rax
	mov	%rax, -48(%rbp)
m_L2538:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2539
	lea	m_ostr2541(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2539:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_repl_stream__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2543:
	.asciz "repl-stream/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2544:
	.8byte	53
	.8byte	m_cstr2543
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_repl_stream_2Fevaluator_stub:
	.8byte	m_repl_stream_2Fevaluator_stub__code
	.8byte	m_ostr2544
	.globl m_repl_stream_2Fevaluator_stub__code
	.type m_repl_stream_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2547:
	.asciz "load"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2548:
	.8byte	9
	.8byte	m_cstr2547
	.section .rodata
m_cstr2549:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2550:
	.8byte	15
	.8byte	m_cstr2549
	.section .rodata
m_cstr2551:
	.asciz "path"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2552:
	.8byte	9
	.8byte	m_cstr2551
	.section .rodata
m_cstr2553:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2554:
	.8byte	35
	.8byte	m_cstr2553
	.section .rodata
m_cstr2555:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2556:
	.8byte	17
	.8byte	m_cstr2555
	.section .rodata
m_cstr2558:
	.asciz "load"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2559:
	.8byte	9
	.8byte	m_cstr2558
	.section .rodata
m_cstr2561:
	.asciz "load"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2562:
	.8byte	9
	.8byte	m_cstr2561
	.section .rodata
m_cstr2564:
	.asciz "r"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2565:
	.8byte	3
	.8byte	m_cstr2564
	.text
m_load_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2545
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2546
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2548(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2550(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2552(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2554(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2556(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2546:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2557
m_L2545:
	lea	m_ostr2559(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2557:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2560
	lea	m_ostr2562(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2560:
	lea	m_ostr2565(%rip), %rax
	mov	%rax, %rbx
	movq	-32(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_file_open_or_die__code
	add	$0, %rsp
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_file_stream__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-48(%rbp), %rdi
	call	m_expand_encode_eval_stream__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-40(%rbp), %rdi
	call	m_file_close__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2566:
	.asciz "load/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2567:
	.8byte	39
	.8byte	m_cstr2566
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_load_2Fevaluator_stub:
	.8byte	m_load_2Fevaluator_stub__code
	.8byte	m_ostr2567
	.globl m_load_2Fevaluator_stub__code
	.type m_load_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2568:
	.asciz "*command-line-arguments*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2569:
	.8byte	49
	.8byte	m_cstr2568
	.section .rodata
m_cstr2575:
	.asciz "-v"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2576:
	.8byte	5
	.8byte	m_cstr2575
	.section .rodata
m_cstr2579:
	.asciz "-d"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2580:
	.8byte	5
	.8byte	m_cstr2579
	.section .rodata
m_cstr2581:
	.asciz "WARNING: (feature debug-output) was not enabled while compiling this build, ignoring -d\012"
	.section .rodata
m_cstr2584:
	.asciz "-O"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2585:
	.8byte	5
	.8byte	m_cstr2584
	.section .rodata
m_cstr2588:
	.asciz "-p"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2589:
	.8byte	5
	.8byte	m_cstr2588
	.section .rodata
m_cstr2590:
	.asciz "WARNING: this build has no profiler, ignoring -p\012"
	.section .rodata
m_cstr2593:
	.asciz "-"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2594:
	.8byte	3
	.8byte	m_cstr2593
	.section .rodata
m_cstr2597:
	.asciz "--call"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2598:
	.8byte	13
	.8byte	m_cstr2597
	.section .rodata
m_cstr2601:
	.asciz "--call requires an argument"
	.section .rodata
m_cstr2602:
	.asciz "\012"
	.section .rodata
m_cstr2605:
	.asciz "--define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2606:
	.8byte	17
	.8byte	m_cstr2605
	.section .rodata
m_cstr2610:
	.asciz "--define requires two arguments"
	.section .rodata
m_cstr2611:
	.asciz "\012"
	.section .rodata
m_cstr2613:
	.asciz "true"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2614:
	.8byte	9
	.8byte	m_cstr2613
	.section .rodata
m_cstr2617:
	.asciz "false"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2618:
	.8byte	11
	.8byte	m_cstr2617
	.section .rodata
m_cstr2624:
	.asciz "loading file: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2625:
	.8byte	29
	.8byte	m_cstr2624
	.section .rodata
m_cstr2626:
	.asciz "\011(as a CLA)\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2627:
	.8byte	25
	.8byte	m_cstr2626
	.section .rodata
m_cstr2629:
	.asciz "r"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2630:
	.8byte	3
	.8byte	m_cstr2629
	.text
m_process_command_line_arguments__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	push	%r12
	push	%r13
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_ostr2569(%rip), %rax
	mov	%rax, %r12
	movq	%r12, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, %r12
	xor	%rax, %rax
	mov	%rax, %r13
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	%r13, %rdx
	call	m_environment_define__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	jmp	m_L2571
m_L2570:
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-32(%rbp), %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-16(%rbp), %rax
	mov	-48(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_C_string__3Estring__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	mov	%rax, %rcx
	mov	-48(%rbp), %rax
	mov	%rax, (%rcx)
m_L2571:
	mov	-40(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -40(%rbp)
	mov	%rax, -48(%rbp)
	xor	%rax, %rax
	cmp	-48(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2570
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-40(%rbp), %rax
	mov	%rax, (%rcx)
	mov	%rax, -40(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	xor	%rax, %rax
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	jmp	m_L2573
m_L2572:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	mov	%rax, -56(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	lea	m_ostr2576(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-40(%rbp), %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2574
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m__2Averbosity_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -48(%rbp)
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-48(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	jmp	m_L2577
m_L2574:
	lea	m_ostr2580(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-40(%rbp), %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2578
	lea	m_cstr2581(%rip), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-56(%rbp), %rsi
	mov	$88, %rdx
	syscall
	jmp	m_L2582
m_L2578:
	lea	m_ostr2585(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-40(%rbp), %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2583
	lea	m__2Aoptimised_2A(%rip), %rax
	mov	(%rax), %rax
	add	$1, %rax
	lea	m__2Aoptimised_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m__2Aoptimised_2A(%rip), %rax
	mov	(%rax), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -48(%rbp)
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aoptimised_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-48(%rbp), %rdx
	call	m_set_variable_value__code
	add	$0, %rsp
	jmp	m_L2586
m_L2583:
	lea	m_ostr2589(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-40(%rbp), %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2587
	lea	m_cstr2590(%rip), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-56(%rbp), %rsi
	mov	$49, %rdx
	syscall
	jmp	m_L2591
m_L2587:
	lea	m_ostr2594(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-40(%rbp), %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2592
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_input_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r13
	movq	%r12, %rdi
	movq	%r13, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$1, %rdx
	call	m_repl_stream__code
	add	$0, %rsp
	jmp	m_L2595
m_L2592:
	lea	m_ostr2598(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-40(%rbp), %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2596
	xor	%rax, %rax
	movq	-32(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2599
	xor	%rax, %rax
	jmp	m_L2600
m_L2599:
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr2601(%rip), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-56(%rbp), %rsi
	mov	$27, %rdx
	syscall
	lea	m_cstr2602(%rip), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-56(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L2600:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	mov	%rax, -56(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	movq	-40(%rbp), %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	-56(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_cons__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-64(%rbp), %rdi
	call	m_expand_encode_eval__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
	jmp	m_L2603
m_L2596:
	lea	m_ostr2606(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-40(%rbp), %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2604
	xor	%rax, %rax
	movq	-32(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2608
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_pair_3F__code
	add	$0, %rsp
m_L2608:
	test	%rax, %rax
	je	m_L2607
	xor	%rax, %rax
	jmp	m_L2609
m_L2607:
	call	m_fatal_prologue__code
	add	$0, %rsp
	lea	m_cstr2610(%rip), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-56(%rbp), %rsi
	mov	$31, %rdx
	syscall
	lea	m_cstr2611(%rip), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	mov	$2, %rdi
	mov	-56(%rbp), %rsi
	mov	$1, %rdx
	syscall
	movq	$20, %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
m_L2609:
	movq	-32(%rbp), %rdi
	call	m_first__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	call	m_second__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	mov	%rax, -72(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-72(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	mov	%rax, -72(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-72(%rbp), %rax
	mov	%rax, (%rcx)
	lea	m_ostr2614(%rip), %rax
	mov	%rax, %rbx
	movq	-64(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2612
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -64(%rbp)
	jmp	m_L2615
m_L2612:
	lea	m_ostr2618(%rip), %rax
	mov	%rax, %rbx
	movq	-64(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_string_3D__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2616
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	jmp	m_L2619
m_L2616:
	movq	-64(%rbp), %rdi
	movq	$10, %rsi
	call	m_string__3Elong_2A__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	mov	-72(%rbp), %rax
	mov	%rax, -80(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	cmp	-80(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2620
	xor	%rax, %rax
	jmp	m_L2621
m_L2620:
	mov	-72(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -64(%rbp)
m_L2621:
m_L2619:
m_L2615:
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-56(%rbp), %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	-64(%rbp), %rdx
	call	m_environment_define__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
	mov	%rax, -64(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	jmp	m_L2622
m_L2604:
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	mov	$1, %rax
	cmp	-56(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2623
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_ostr2625(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-40(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Adebug_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_ostr2627(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
m_L2623:
	lea	m_ostr2630(%rip), %rax
	mov	%rax, %rbx
	movq	-40(%rbp), %rdi
	movq	%rbx, %rsi
	call	m_file_open_or_die__code
	add	$0, %rsp
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	call	m_file_stream__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Astandard_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-64(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$0, %rdx
	call	m_repl_stream__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	movq	-56(%rbp), %rdi
	call	m_file_close__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
	mov	%rax, -72(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
m_L2622:
m_L2603:
m_L2595:
m_L2591:
m_L2586:
m_L2582:
m_L2577:
m_L2573:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -32(%rbp)
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2572
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	add	$8, %rsp
	pop	%r13
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2631:
	.asciz "process-command-line-arguments"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2632:
	.8byte	61
	.8byte	m_cstr2631
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_process_command_line_arguments:
	.8byte	m_process_command_line_arguments__code
	.8byte	m_ostr2632
	.globl m_process_command_line_arguments__code
	.type m_process_command_line_arguments__code, @function
	.section .rodata
m_cstr2635:
	.asciz "define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2636:
	.8byte	13
	.8byte	m_cstr2635
	.section .rodata
m_cstr2637:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2638:
	.8byte	15
	.8byte	m_cstr2637
	.section .rodata
m_cstr2639:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2640:
	.8byte	17
	.8byte	m_cstr2639
	.section .rodata
m_cstr2641:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2642:
	.8byte	35
	.8byte	m_cstr2641
	.section .rodata
m_cstr2643:
	.asciz "<variable>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2644:
	.8byte	21
	.8byte	m_cstr2643
	.section .rodata
m_cstr2646:
	.asciz "define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2647:
	.8byte	13
	.8byte	m_cstr2646
	.section .rodata
m_cstr2650:
	.asciz "define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2651:
	.8byte	13
	.8byte	m_cstr2650
	.section .rodata
m_cstr2653:
	.asciz "define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2654:
	.8byte	13
	.8byte	m_cstr2653
	.text
m_define_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2633
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$15, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2634
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2636(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2638(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2640(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2642(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2644(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2634:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2645
m_L2633:
	lea	m_ostr2647(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2645:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2648
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2649
m_L2648:
	lea	m_ostr2651(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2649:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2652
	lea	m_ostr2654(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2652:
	movq	-40(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	$14, %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2656
	mov	-56(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
m_L2656:
	movq	-56(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	$13, %rax
	cmp	-64(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2659
	mov	-56(%rbp), %rax
	lea	32(%rax), %rcx
	mov	(%rcx), %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
m_L2659:
	test	%rax, %rax
	je	m_L2658
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -64(%rbp)
	mov	-56(%rbp), %rax
	lea	32(%rax), %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
m_L2658:
	mov	-48(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2661:
	.asciz "define/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2662:
	.8byte	43
	.8byte	m_cstr2661
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_define_2Fevaluator_stub:
	.8byte	m_define_2Fevaluator_stub__code
	.8byte	m_ostr2662
	.globl m_define_2Fevaluator_stub__code
	.type m_define_2Fevaluator_stub__code, @function
	.text
m_eval_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2663
	movq	-8(%rbp), %rdi
	call	m_cadr__code
	add	$0, %rsp
	jmp	m_L2664
m_L2663:
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
m_L2664:
	mov	%rax, -24(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	mov	%rax, -32(%rbp)
	lea	m__2Aglobals_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L2665
	movq	-24(%rbp), %rdi
	call	m_set_current_globals__code
	add	$0, %rsp
m_L2665:
	movq	-24(%rbp), %rdi
	movq	$1, %rsi
	movq	$0, %rdx
	call	m_environment__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-56(%rbp), %rsi
	call	m_expand_encode_eval_2A__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	lea	-56(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L2667
	movq	-40(%rbp), %rdi
	call	m_set_current_globals__code
	add	$0, %rsp
m_L2667:
	mov	-48(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2669:
	.asciz "eval/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2670:
	.8byte	39
	.8byte	m_cstr2669
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_eval_2Fevaluator_stub:
	.8byte	m_eval_2Fevaluator_stub__code
	.8byte	m_ostr2670
	.globl m_eval_2Fevaluator_stub__code
	.type m_eval_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2673:
	.asciz "lambda"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2674:
	.8byte	13
	.8byte	m_cstr2673
	.section .rodata
m_cstr2675:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2676:
	.8byte	15
	.8byte	m_cstr2675
	.section .rodata
m_cstr2677:
	.asciz "env"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2678:
	.8byte	7
	.8byte	m_cstr2677
	.section .rodata
m_cstr2679:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2680:
	.8byte	35
	.8byte	m_cstr2679
	.section .rodata
m_cstr2681:
	.asciz "<env>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2682:
	.8byte	11
	.8byte	m_cstr2681
	.section .rodata
m_cstr2684:
	.asciz "lambda"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2685:
	.8byte	13
	.8byte	m_cstr2684
	.section .rodata
m_cstr2688:
	.asciz "lambda"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2689:
	.8byte	13
	.8byte	m_cstr2688
	.section .rodata
m_cstr2692:
	.asciz "lambda vm-function: parameters is of wrong type: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2693:
	.8byte	99
	.8byte	m_cstr2692
	.text
m_lambda_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2671
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	$16, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2672
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2674(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2676(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2678(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2680(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2682(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2672:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2683
m_L2671:
	lea	m_ostr2685(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2683:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2686
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2687
m_L2686:
	lea	m_ostr2689(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2687:
	mov	-24(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-40(%rbp), %rax
	test	%rax, %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2691
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	$15, %rax
	cmp	-56(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2691
	movq	-40(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
m_L2691:
	test	%rax, %rax
	jne	m_L2690
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2693(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-40(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2690:
	movq	-40(%rbp), %rdi
	movq	-48(%rbp), %rsi
	movq	-32(%rbp), %rdx
	movq	-16(%rbp), %rcx
	call	m_expr__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2694:
	.asciz "lambda/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2695:
	.8byte	43
	.8byte	m_cstr2694
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_lambda_2Fevaluator_stub:
	.8byte	m_lambda_2Fevaluator_stub__code
	.8byte	m_ostr2695
	.globl m_lambda_2Fevaluator_stub__code
	.type m_lambda_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2698:
	.asciz "let"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2699:
	.8byte	7
	.8byte	m_cstr2698
	.section .rodata
m_cstr2702:
	.asciz "let"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2703:
	.8byte	7
	.8byte	m_cstr2702
	.text
m_let_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$96, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2696
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2697
m_L2696:
	lea	m_ostr2699(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2697:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2700
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2701
m_L2700:
	lea	m_ostr2703(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2701:
	mov	-24(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-40(%rbp), %rax
	mov	%rax, -72(%rbp)
	jmp	m_L2705
m_L2704:
	movq	-72(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
	movq	-80(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2706
	mov	-80(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -88(%rbp)
	mov	-80(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -96(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	jmp	m_L2708
m_L2707:
	mov	-96(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	mov	-96(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -96(%rbp)
m_L2708:
	movq	-96(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2707
	xor	%rax, %rax
	mov	-88(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, %rbx
	movq	-56(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-64(%rbp), %rdx
	call	m_set_array_at__code
	add	$0, %rsp
m_L2706:
	movq	-72(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
m_L2705:
	mov	-72(%rbp), %rax
	test	%rax, %rax
	jne	m_L2704
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -72(%rbp)
	jmp	m_L2711
m_L2710:
	movq	-72(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -80(%rbp)
	movq	-80(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	movq	-72(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
m_L2711:
	mov	-72(%rbp), %rax
	test	%rax, %rax
	jne	m_L2710
	mov	-64(%rbp), %rax
	mov	%rax, -72(%rbp)
	lea	-64(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-72(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2712:
	.asciz "let/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2713:
	.8byte	37
	.8byte	m_cstr2712
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_let_2Fevaluator_stub:
	.8byte	m_let_2Fevaluator_stub__code
	.8byte	m_ostr2713
	.globl m_let_2Fevaluator_stub__code
	.type m_let_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2716:
	.asciz "set"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2717:
	.8byte	7
	.8byte	m_cstr2716
	.section .rodata
m_cstr2718:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2719:
	.8byte	15
	.8byte	m_cstr2718
	.section .rodata
m_cstr2720:
	.asciz "var"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2721:
	.8byte	7
	.8byte	m_cstr2720
	.section .rodata
m_cstr2722:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2723:
	.8byte	35
	.8byte	m_cstr2722
	.section .rodata
m_cstr2724:
	.asciz "<variable>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2725:
	.8byte	21
	.8byte	m_cstr2724
	.section .rodata
m_cstr2727:
	.asciz "set"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2728:
	.8byte	7
	.8byte	m_cstr2727
	.section .rodata
m_cstr2731:
	.asciz "set"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2732:
	.8byte	7
	.8byte	m_cstr2731
	.section .rodata
m_cstr2734:
	.asciz "set"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2735:
	.8byte	7
	.8byte	m_cstr2734
	.text
m_set_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2714
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$15, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2715
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2717(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2719(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2721(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2723(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2725(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2715:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2726
m_L2714:
	lea	m_ostr2728(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2726:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2729
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2730
m_L2729:
	lea	m_ostr2732(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2730:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2733
	lea	m_ostr2735(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2733:
	xor	%rax, %rax
	movq	-40(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	call	m_global_variable_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2737
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-32(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	jmp	m_L2738
m_L2737:
	mov	-32(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, -56(%rbp)
	mov	-16(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	sub	-56(%rbp), %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	jmp	m_L2740
m_L2739:
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -16(%rbp)
	mov	-56(%rbp), %rax
	sub	$1, %rax
	mov	%rax, -56(%rbp)
m_L2740:
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	xor	%rax, %rax
	cmp	-64(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L2739
	mov	-32(%rbp), %rax
	lea	24(%rax), %rcx
	mov	(%rcx), %rax
	sar	$1, %rax
	mov	%rax, -64(%rbp)
	xor	%rax, %rax
	mov	-16(%rbp), %rax
	lea	16(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-64(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_set_array_at__code
	add	$0, %rsp
m_L2738:
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2741:
	.asciz "set/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2742:
	.8byte	37
	.8byte	m_cstr2741
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_2Fevaluator_stub:
	.8byte	m_set_2Fevaluator_stub__code
	.8byte	m_ostr2742
	.globl m_set_2Fevaluator_stub__code
	.type m_set_2Fevaluator_stub__code, @function
	.text
m_while_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	jmp	m_L2744
m_L2743:
	mov	-32(%rbp), %rax
	mov	%rax, -40(%rbp)
	jmp	m_L2746
m_L2745:
	mov	-40(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
m_L2746:
	movq	-40(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2745
m_L2744:
	movq	-24(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2743
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2747:
	.asciz "while/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2748:
	.8byte	41
	.8byte	m_cstr2747
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_while_2Fevaluator_stub:
	.8byte	m_while_2Fevaluator_stub__code
	.8byte	m_ostr2748
	.globl m_while_2Fevaluator_stub__code
	.type m_while_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2751:
	.asciz "if"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2752:
	.8byte	5
	.8byte	m_cstr2751
	.section .rodata
m_cstr2755:
	.asciz "if"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2756:
	.8byte	5
	.8byte	m_cstr2755
	.text
m_if_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2749
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2750
m_L2749:
	lea	m_ostr2752(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2750:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2753
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2754
m_L2753:
	lea	m_ostr2756(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2754:
	mov	-24(%rbp), %rax
	mov	%rax, -48(%rbp)
	movq	-32(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2757
	movq	-40(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	jmp	m_L2758
m_L2757:
	xor	%rax, %rax
	mov	%rax, -56(%rbp)
	jmp	m_L2760
m_L2759:
	mov	-48(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-48(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
m_L2760:
	movq	-48(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2759
	mov	-56(%rbp), %rax
m_L2758:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2761:
	.asciz "if/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2762:
	.8byte	35
	.8byte	m_cstr2761
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_if_2Fevaluator_stub:
	.8byte	m_if_2Fevaluator_stub__code
	.8byte	m_ostr2762
	.globl m_if_2Fevaluator_stub__code
	.type m_if_2Fevaluator_stub__code, @function
	.text
m_or_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2764
m_L2763:
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	test	%rax, %rax
	je	m_L2765
	mov	-24(%rbp), %rax
	jmp	m_L2766
m_L2765:
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -8(%rbp)
m_L2764:
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2763
m_L2766:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2767:
	.asciz "or/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2768:
	.8byte	35
	.8byte	m_cstr2767
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_or_2Fevaluator_stub:
	.8byte	m_or_2Fevaluator_stub__code
	.8byte	m_ostr2768
	.globl m_or_2Fevaluator_stub__code
	.type m_or_2Fevaluator_stub__code, @function
	.text
m_and_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2770
m_L2769:
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-16(%rbp), %rsi
	call	m_eval__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	test	%rax, %rax
	jne	m_L2771
	xor	%rax, %rax
	jmp	m_L2772
m_L2771:
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -8(%rbp)
m_L2770:
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2769
	mov	-24(%rbp), %rax
m_L2772:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2773:
	.asciz "and/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2774:
	.8byte	37
	.8byte	m_cstr2773
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_and_2Fevaluator_stub:
	.8byte	m_and_2Fevaluator_stub__code
	.8byte	m_ostr2774
	.globl m_and_2Fevaluator_stub__code
	.type m_and_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2777:
	.asciz "quote"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2778:
	.8byte	11
	.8byte	m_cstr2777
	.section .rodata
m_cstr2780:
	.asciz "quote"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2781:
	.8byte	11
	.8byte	m_cstr2780
	.text
m_quote_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2775
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2776
m_L2775:
	lea	m_ostr2778(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2776:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2779
	lea	m_ostr2781(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2779:
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2783:
	.asciz "quote/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2784:
	.8byte	41
	.8byte	m_cstr2783
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_quote_2Fevaluator_stub:
	.8byte	m_quote_2Fevaluator_stub__code
	.8byte	m_ostr2784
	.globl m_quote_2Fevaluator_stub__code
	.type m_quote_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2787:
	.asciz "not"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2788:
	.8byte	7
	.8byte	m_cstr2787
	.section .rodata
m_cstr2790:
	.asciz "not"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2791:
	.8byte	7
	.8byte	m_cstr2790
	.text
m_not_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2785
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2786
m_L2785:
	lea	m_ostr2788(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2786:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2789
	lea	m_ostr2791(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2789:
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L2793
	xor	%rax, %rax
	jmp	m_L2794
m_L2793:
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2794:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2795:
	.asciz "not/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2796:
	.8byte	37
	.8byte	m_cstr2795
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_not_2Fevaluator_stub:
	.8byte	m_not_2Fevaluator_stub__code
	.8byte	m_ostr2796
	.globl m_not_2Fevaluator_stub__code
	.type m_not_2Fevaluator_stub__code, @function
	.text
m___2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2797
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2798
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	sar	$1, %rax
	jmp	m_L2799
m_L2798:
	xor	%rax, %rax
m_L2799:
	mov	%rax, -24(%rbp)
	jmp	m_L2801
m_L2800:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	sub	-32(%rbp), %rax
	mov	%rax, -24(%rbp)
m_L2801:
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2800
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	jmp	m_L2802
m_L2797:
	xor	%rax, %rax
	shl	$1, %rax
	or	$1, %rax
m_L2802:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2803:
	.asciz "-/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2804:
	.8byte	33
	.8byte	m_cstr2803
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m___2Fevaluator_stub:
	.8byte	m___2Fevaluator_stub__code
	.8byte	m_ostr2804
	.globl m___2Fevaluator_stub__code
	.type m___2Fevaluator_stub__code, @function
	.text
m__2B_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	xor	%rax, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2806
m_L2805:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	add	-32(%rbp),%rax
	mov	%rax, -24(%rbp)
m_L2806:
	mov	-8(%rbp), %rax
	test	%rax, %rax
	jne	m_L2805
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2807:
	.asciz "+/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2808:
	.8byte	33
	.8byte	m_cstr2807
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__2B_2Fevaluator_stub:
	.8byte	m__2B_2Fevaluator_stub__code
	.8byte	m_ostr2808
	.globl m__2B_2Fevaluator_stub__code
	.type m__2B_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2813:
	.asciz "operator '/' needs at least one argument"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2814:
	.8byte	81
	.8byte	m_cstr2813
	.text
m__2F_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2809
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2811
m_L2810:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	xor	%rdx, %rdx
	divq	-32(%rbp)
	mov	%rax, -24(%rbp)
m_L2811:
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2810
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	jmp	m_L2812
m_L2809:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2814(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2812:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2815:
	.asciz "//evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2816:
	.8byte	33
	.8byte	m_cstr2815
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__2F_2Fevaluator_stub:
	.8byte	m__2F_2Fevaluator_stub__code
	.8byte	m_ostr2816
	.globl m__2F_2Fevaluator_stub__code
	.type m__2F_2Fevaluator_stub__code, @function
	.text
m__2A_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	$1, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2818
m_L2817:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mulq	-32(%rbp)
	mov	%rax, -24(%rbp)
m_L2818:
	mov	-8(%rbp), %rax
	test	%rax, %rax
	jne	m_L2817
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2819:
	.asciz "*/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2820:
	.8byte	33
	.8byte	m_cstr2819
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__2A_2Fevaluator_stub:
	.8byte	m__2A_2Fevaluator_stub__code
	.8byte	m_ostr2820
	.globl m__2A_2Fevaluator_stub__code
	.type m__2A_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2822:
	.asciz "operator 'bitwise-and': called with zero arguments"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2823:
	.8byte	101
	.8byte	m_cstr2822
	.text
m_bitwise_and_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2821
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2823(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2821:
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2825
m_L2824:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	and	-32(%rbp), %rax
	mov	%rax, -24(%rbp)
m_L2825:
	mov	-8(%rbp), %rax
	test	%rax, %rax
	jne	m_L2824
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2826:
	.asciz "bitwise-and/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2827:
	.8byte	53
	.8byte	m_cstr2826
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_bitwise_and_2Fevaluator_stub:
	.8byte	m_bitwise_and_2Fevaluator_stub__code
	.8byte	m_ostr2827
	.globl m_bitwise_and_2Fevaluator_stub__code
	.type m_bitwise_and_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2829:
	.asciz "operator 'bitwise-or': called with zero arguments"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2830:
	.8byte	99
	.8byte	m_cstr2829
	.text
m_bitwise_or_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2828
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2830(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2828:
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2832
m_L2831:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	or	-32(%rbp), %rax
	mov	%rax, -24(%rbp)
m_L2832:
	mov	-8(%rbp), %rax
	test	%rax, %rax
	jne	m_L2831
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2833:
	.asciz "bitwise-or/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2834:
	.8byte	51
	.8byte	m_cstr2833
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_bitwise_or_2Fevaluator_stub:
	.8byte	m_bitwise_or_2Fevaluator_stub__code
	.8byte	m_ostr2834
	.globl m_bitwise_or_2Fevaluator_stub__code
	.type m_bitwise_or_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2836:
	.asciz "operator 'bitwise-xor': called with zero arguments"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2837:
	.8byte	101
	.8byte	m_cstr2836
	.text
m_bitwise_xor_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2835
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2837(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2835:
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2839
m_L2838:
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	xor	-32(%rbp), %rax
	mov	%rax, -24(%rbp)
m_L2839:
	mov	-8(%rbp), %rax
	test	%rax, %rax
	jne	m_L2838
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2840:
	.asciz "bitwise-xor/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2841:
	.8byte	53
	.8byte	m_cstr2840
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_bitwise_xor_2Fevaluator_stub:
	.8byte	m_bitwise_xor_2Fevaluator_stub__code
	.8byte	m_ostr2841
	.globl m_bitwise_xor_2Fevaluator_stub__code
	.type m_bitwise_xor_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2844:
	.asciz "bitwise-not"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2845:
	.8byte	23
	.8byte	m_cstr2844
	.section .rodata
m_cstr2846:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2847:
	.8byte	15
	.8byte	m_cstr2846
	.section .rodata
m_cstr2848:
	.asciz "value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2849:
	.8byte	11
	.8byte	m_cstr2848
	.section .rodata
m_cstr2850:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2851:
	.8byte	35
	.8byte	m_cstr2850
	.section .rodata
m_cstr2852:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2853:
	.8byte	13
	.8byte	m_cstr2852
	.section .rodata
m_cstr2855:
	.asciz "bitwise-not"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2856:
	.8byte	23
	.8byte	m_cstr2855
	.section .rodata
m_cstr2858:
	.asciz "bitwise-not"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2859:
	.8byte	23
	.8byte	m_cstr2858
	.text
m_bitwise_not_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2842
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2843
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2845(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2847(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2849(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2851(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2853(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2843:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2854
m_L2842:
	lea	m_ostr2856(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2854:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2857
	lea	m_ostr2859(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2857:
	mov	-32(%rbp), %rax
	not	%rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2861:
	.asciz "bitwise-not/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2862:
	.8byte	53
	.8byte	m_cstr2861
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_bitwise_not_2Fevaluator_stub:
	.8byte	m_bitwise_not_2Fevaluator_stub__code
	.8byte	m_ostr2862
	.globl m_bitwise_not_2Fevaluator_stub__code
	.type m_bitwise_not_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2865:
	.asciz "bitwise-shift"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2866:
	.8byte	27
	.8byte	m_cstr2865
	.section .rodata
m_cstr2867:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2868:
	.8byte	15
	.8byte	m_cstr2867
	.section .rodata
m_cstr2869:
	.asciz "value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2870:
	.8byte	11
	.8byte	m_cstr2869
	.section .rodata
m_cstr2871:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2872:
	.8byte	35
	.8byte	m_cstr2871
	.section .rodata
m_cstr2873:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2874:
	.8byte	13
	.8byte	m_cstr2873
	.section .rodata
m_cstr2876:
	.asciz "bitwise-shift"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2877:
	.8byte	27
	.8byte	m_cstr2876
	.section .rodata
m_cstr2880:
	.asciz "bitwise-shift"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2881:
	.8byte	27
	.8byte	m_cstr2880
	.section .rodata
m_cstr2882:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2883:
	.8byte	15
	.8byte	m_cstr2882
	.section .rodata
m_cstr2884:
	.asciz "shift"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2885:
	.8byte	11
	.8byte	m_cstr2884
	.section .rodata
m_cstr2886:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2887:
	.8byte	35
	.8byte	m_cstr2886
	.section .rodata
m_cstr2888:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2889:
	.8byte	13
	.8byte	m_cstr2888
	.section .rodata
m_cstr2891:
	.asciz "bitwise-shift"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2892:
	.8byte	27
	.8byte	m_cstr2891
	.section .rodata
m_cstr2894:
	.asciz "bitwise-shift"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2895:
	.8byte	27
	.8byte	m_cstr2894
	.text
m_bitwise_shift_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2863
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2864
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2866(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2868(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2870(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2872(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2874(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2864:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2875
m_L2863:
	lea	m_ostr2877(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2875:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2878
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2879
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2881(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2883(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2885(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2887(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2889(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2879:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2890
m_L2878:
	lea	m_ostr2892(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2890:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2893
	lea	m_ostr2895(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2893:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m__25bitwise_shift__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2897:
	.asciz "bitwise-shift/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2898:
	.8byte	57
	.8byte	m_cstr2897
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_bitwise_shift_2Fevaluator_stub:
	.8byte	m_bitwise_shift_2Fevaluator_stub__code
	.8byte	m_ostr2898
	.globl m_bitwise_shift_2Fevaluator_stub__code
	.type m_bitwise_shift_2Fevaluator_stub__code, @function
	.text
m__3C_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2899
	xor	%rax, %rax
	jmp	m_L2900
m_L2899:
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	jmp	m_L2901
m_L2900:
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L2903
m_L2902:
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	movq	-40(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	cmp	-48(%rbp), %rax
	setl	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2904
	xor	%rax, %rax
	jmp	m_L2905
m_L2904:
	xor	%rax, %rax
	jmp	m_L2901
m_L2905:
	mov	-40(%rbp), %rax
	mov	%rax, -24(%rbp)
m_L2903:
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2902
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2901:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2906:
	.asciz "</evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2907:
	.8byte	33
	.8byte	m_cstr2906
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__3C_2Fevaluator_stub:
	.8byte	m__3C_2Fevaluator_stub__code
	.8byte	m_ostr2907
	.globl m__3C_2Fevaluator_stub__code
	.type m__3C_2Fevaluator_stub__code, @function
	.text
m__3C_3D_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2908
	xor	%rax, %rax
	jmp	m_L2909
m_L2908:
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	jmp	m_L2910
m_L2909:
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L2912
m_L2911:
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	movq	-40(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	cmp	-48(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2913
	xor	%rax, %rax
	jmp	m_L2914
m_L2913:
	xor	%rax, %rax
	jmp	m_L2910
m_L2914:
	mov	-40(%rbp), %rax
	mov	%rax, -24(%rbp)
m_L2912:
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2911
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2910:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2915:
	.asciz "<=/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2916:
	.8byte	35
	.8byte	m_cstr2915
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__3C_3D_2Fevaluator_stub:
	.8byte	m__3C_3D_2Fevaluator_stub__code
	.8byte	m_ostr2916
	.globl m__3C_3D_2Fevaluator_stub__code
	.type m__3C_3D_2Fevaluator_stub__code, @function
	.text
m__3E_3D_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2917
	xor	%rax, %rax
	jmp	m_L2918
m_L2917:
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	jmp	m_L2919
m_L2918:
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L2921
m_L2920:
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	movq	-40(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	cmp	-48(%rbp), %rax
	setge	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2922
	xor	%rax, %rax
	jmp	m_L2923
m_L2922:
	xor	%rax, %rax
	jmp	m_L2919
m_L2923:
	mov	-40(%rbp), %rax
	mov	%rax, -24(%rbp)
m_L2921:
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2920
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2919:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2924:
	.asciz ">=/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2925:
	.8byte	35
	.8byte	m_cstr2924
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__3E_3D_2Fevaluator_stub:
	.8byte	m__3E_3D_2Fevaluator_stub__code
	.8byte	m_ostr2925
	.globl m__3E_3D_2Fevaluator_stub__code
	.type m__3E_3D_2Fevaluator_stub__code, @function
	.text
m__3E_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2926
	xor	%rax, %rax
	jmp	m_L2927
m_L2926:
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	jmp	m_L2928
m_L2927:
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	jmp	m_L2930
m_L2929:
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	movq	-40(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	cmp	-48(%rbp), %rax
	setg	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2931
	xor	%rax, %rax
	jmp	m_L2932
m_L2931:
	xor	%rax, %rax
	jmp	m_L2928
m_L2932:
	mov	-40(%rbp), %rax
	mov	%rax, -24(%rbp)
m_L2930:
	movq	-8(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2929
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2928:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2933:
	.asciz ">/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2934:
	.8byte	33
	.8byte	m_cstr2933
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__3E_2Fevaluator_stub:
	.8byte	m__3E_2Fevaluator_stub__code
	.8byte	m_ostr2934
	.globl m__3E_2Fevaluator_stub__code
	.type m__3E_2Fevaluator_stub__code, @function
	.text
m__3D_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$7, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2935
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2936
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	sar	$1, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2936
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2936:
	jmp	m_L2937
m_L2935:
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$12, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2938
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2939
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	call	m_string_compare__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	xor	%rax, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2939
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2939:
	jmp	m_L2940
m_L2938:
	movq	-40(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$20, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2941
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	mov	$20, %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2942
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L2942:
	jmp	m_L2943
m_L2941:
	mov	-32(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	cmp	-48(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L2944
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2944:
m_L2943:
m_L2940:
m_L2937:
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr2945:
	.asciz "=/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2946:
	.8byte	33
	.8byte	m_cstr2945
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__3D_2Fevaluator_stub:
	.8byte	m__3D_2Fevaluator_stub__code
	.8byte	m_ostr2946
	.globl m__3D_2Fevaluator_stub__code
	.type m__3D_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2949:
	.asciz "exit"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2950:
	.8byte	9
	.8byte	m_cstr2949
	.section .rodata
m_cstr2951:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2952:
	.8byte	15
	.8byte	m_cstr2951
	.section .rodata
m_cstr2953:
	.asciz "exit-code"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2954:
	.8byte	19
	.8byte	m_cstr2953
	.section .rodata
m_cstr2955:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2956:
	.8byte	35
	.8byte	m_cstr2955
	.section .rodata
m_cstr2957:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2958:
	.8byte	13
	.8byte	m_cstr2957
	.section .rodata
m_cstr2961:
	.asciz "exit"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2962:
	.8byte	9
	.8byte	m_cstr2961
	.text
m_exit_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2947
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L2948
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr2950(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2952(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2954(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2956(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr2958(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L2948:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2959
m_L2947:
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
m_L2959:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2960
	lea	m_ostr2962(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2960:
	xor	%rax, %rax
	call	m_platform_2Fflush_streams__code
	add	$0, %rsp
	movq	-32(%rbp), %rdi
	call	m_platform_2Fhalt__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2964:
	.asciz "exit/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2965:
	.8byte	39
	.8byte	m_cstr2964
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_exit_2Fevaluator_stub:
	.8byte	m_exit_2Fevaluator_stub__code
	.8byte	m_ostr2965
	.globl m_exit_2Fevaluator_stub__code
	.type m_exit_2Fevaluator_stub__code, @function
	.text
m_warn_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2967
m_L2966:
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-32(%rbp), %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
m_L2967:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	jne	m_L2966
	call	m_platform_2Fflush_streams__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2968:
	.asciz "warn/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2969:
	.8byte	39
	.8byte	m_cstr2968
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_warn_2Fevaluator_stub:
	.8byte	m_warn_2Fevaluator_stub__code
	.8byte	m_ostr2969
	.globl m_warn_2Fevaluator_stub__code
	.type m_warn_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2972:
	.asciz "type-of"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2973:
	.8byte	15
	.8byte	m_cstr2972
	.section .rodata
m_cstr2975:
	.asciz "type-of"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2976:
	.8byte	15
	.8byte	m_cstr2975
	.text
m_type_of_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2970
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2971
m_L2970:
	lea	m_ostr2973(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2971:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2974
	lea	m_ostr2976(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2974:
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2978:
	.asciz "type-of/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2979:
	.8byte	45
	.8byte	m_cstr2978
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_type_of_2Fevaluator_stub:
	.8byte	m_type_of_2Fevaluator_stub__code
	.8byte	m_ostr2979
	.globl m_type_of_2Fevaluator_stub__code
	.type m_type_of_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2982:
	.asciz "string?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2983:
	.8byte	15
	.8byte	m_cstr2982
	.section .rodata
m_cstr2985:
	.asciz "string?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2986:
	.8byte	15
	.8byte	m_cstr2985
	.text
m_string_3F_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2980
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2981
m_L2980:
	lea	m_ostr2983(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2981:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2984
	lea	m_ostr2986(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2984:
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2988
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2988:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr2989:
	.asciz "string?/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2990:
	.8byte	45
	.8byte	m_cstr2989
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_3F_2Fevaluator_stub:
	.8byte	m_string_3F_2Fevaluator_stub__code
	.8byte	m_ostr2990
	.globl m_string_3F_2Fevaluator_stub__code
	.type m_string_3F_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr2993:
	.asciz "symbol?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2994:
	.8byte	15
	.8byte	m_cstr2993
	.section .rodata
m_cstr2996:
	.asciz "symbol?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr2997:
	.8byte	15
	.8byte	m_cstr2996
	.text
m_symbol_3F_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2991
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L2992
m_L2991:
	lea	m_ostr2994(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L2992:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L2995
	lea	m_ostr2997(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L2995:
	movq	-32(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L2999
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L2999:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3000:
	.asciz "symbol?/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3001:
	.8byte	45
	.8byte	m_cstr3000
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_symbol_3F_2Fevaluator_stub:
	.8byte	m_symbol_3F_2Fevaluator_stub__code
	.8byte	m_ostr3001
	.globl m_symbol_3F_2Fevaluator_stub__code
	.type m_symbol_3F_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3004:
	.asciz "pair?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3005:
	.8byte	11
	.8byte	m_cstr3004
	.section .rodata
m_cstr3007:
	.asciz "pair?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3008:
	.8byte	11
	.8byte	m_cstr3007
	.text
m_pair_3F_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3002
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3003
m_L3002:
	lea	m_ostr3005(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3003:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3006
	lea	m_ostr3008(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3006:
	movq	-32(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3010
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L3010:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3011:
	.asciz "pair?/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3012:
	.8byte	41
	.8byte	m_cstr3011
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_pair_3F_2Fevaluator_stub:
	.8byte	m_pair_3F_2Fevaluator_stub__code
	.8byte	m_ostr3012
	.globl m_pair_3F_2Fevaluator_stub__code
	.type m_pair_3F_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3015:
	.asciz "array?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3016:
	.8byte	13
	.8byte	m_cstr3015
	.section .rodata
m_cstr3018:
	.asciz "array?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3019:
	.8byte	13
	.8byte	m_cstr3018
	.text
m_array_3F_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3013
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3014
m_L3013:
	lea	m_ostr3016(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3014:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3017
	lea	m_ostr3019(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3017:
	movq	-32(%rbp), %rdi
	call	m_array_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3021
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
m_L3021:
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3022:
	.asciz "array?/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3023:
	.8byte	43
	.8byte	m_cstr3022
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_3F_2Fevaluator_stub:
	.8byte	m_array_3F_2Fevaluator_stub__code
	.8byte	m_ostr3023
	.globl m_array_3F_2Fevaluator_stub__code
	.type m_array_3F_2Fevaluator_stub__code, @function
	.text
m_set_car__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr3024:
	.asciz "set-car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3025:
	.8byte	15
	.8byte	m_cstr3024
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_car:
	.8byte	m_set_car__code
	.8byte	m_ostr3025
	.globl m_set_car__code
	.type m_set_car__code, @function
	.section .rodata
m_cstr3028:
	.asciz "set-car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3029:
	.8byte	15
	.8byte	m_cstr3028
	.section .rodata
m_cstr3030:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3031:
	.8byte	15
	.8byte	m_cstr3030
	.section .rodata
m_cstr3032:
	.asciz "pair"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3033:
	.8byte	9
	.8byte	m_cstr3032
	.section .rodata
m_cstr3034:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3035:
	.8byte	35
	.8byte	m_cstr3034
	.section .rodata
m_cstr3036:
	.asciz "<pair>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3037:
	.8byte	13
	.8byte	m_cstr3036
	.section .rodata
m_cstr3039:
	.asciz "set-car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3040:
	.8byte	15
	.8byte	m_cstr3039
	.section .rodata
m_cstr3043:
	.asciz "set-car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3044:
	.8byte	15
	.8byte	m_cstr3043
	.section .rodata
m_cstr3046:
	.asciz "set-car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3047:
	.8byte	15
	.8byte	m_cstr3046
	.text
m_set_car_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3026
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3027
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3029(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3031(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3033(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3035(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3037(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3027:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3038
m_L3026:
	lea	m_ostr3040(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3038:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3041
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3042
m_L3041:
	lea	m_ostr3044(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3042:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3045
	lea	m_ostr3047(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3045:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_set_car__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3049:
	.asciz "set-car/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3050:
	.8byte	45
	.8byte	m_cstr3049
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_car_2Fevaluator_stub:
	.8byte	m_set_car_2Fevaluator_stub__code
	.8byte	m_ostr3050
	.globl m_set_car_2Fevaluator_stub__code
	.type m_set_car_2Fevaluator_stub__code, @function
	.text
m_set_cdr__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	lea	8(%rax), %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr3051:
	.asciz "set-cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3052:
	.8byte	15
	.8byte	m_cstr3051
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_cdr:
	.8byte	m_set_cdr__code
	.8byte	m_ostr3052
	.globl m_set_cdr__code
	.type m_set_cdr__code, @function
	.section .rodata
m_cstr3055:
	.asciz "set-cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3056:
	.8byte	15
	.8byte	m_cstr3055
	.section .rodata
m_cstr3057:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3058:
	.8byte	15
	.8byte	m_cstr3057
	.section .rodata
m_cstr3059:
	.asciz "pair"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3060:
	.8byte	9
	.8byte	m_cstr3059
	.section .rodata
m_cstr3061:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3062:
	.8byte	35
	.8byte	m_cstr3061
	.section .rodata
m_cstr3063:
	.asciz "<pair>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3064:
	.8byte	13
	.8byte	m_cstr3063
	.section .rodata
m_cstr3066:
	.asciz "set-cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3067:
	.8byte	15
	.8byte	m_cstr3066
	.section .rodata
m_cstr3070:
	.asciz "set-cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3071:
	.8byte	15
	.8byte	m_cstr3070
	.section .rodata
m_cstr3073:
	.asciz "set-cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3074:
	.8byte	15
	.8byte	m_cstr3073
	.text
m_set_cdr_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3053
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3054
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3056(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3058(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3060(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3062(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3064(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3054:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3065
m_L3053:
	lea	m_ostr3067(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3065:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3068
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3069
m_L3068:
	lea	m_ostr3071(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3069:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3072
	lea	m_ostr3074(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3072:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_set_cdr__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3076:
	.asciz "set-cdr/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3077:
	.8byte	45
	.8byte	m_cstr3076
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_cdr_2Fevaluator_stub:
	.8byte	m_set_cdr_2Fevaluator_stub__code
	.8byte	m_ostr3077
	.globl m_set_cdr_2Fevaluator_stub__code
	.type m_set_cdr_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3080:
	.asciz "oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3081:
	.8byte	13
	.8byte	m_cstr3080
	.section .rodata
m_cstr3084:
	.asciz "oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3085:
	.8byte	13
	.8byte	m_cstr3084
	.section .rodata
m_cstr3086:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3087:
	.8byte	15
	.8byte	m_cstr3086
	.section .rodata
m_cstr3088:
	.asciz "cellindex"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3089:
	.8byte	19
	.8byte	m_cstr3088
	.section .rodata
m_cstr3090:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3091:
	.8byte	35
	.8byte	m_cstr3090
	.section .rodata
m_cstr3092:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3093:
	.8byte	13
	.8byte	m_cstr3092
	.section .rodata
m_cstr3095:
	.asciz "oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3096:
	.8byte	13
	.8byte	m_cstr3095
	.section .rodata
m_cstr3098:
	.asciz "oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3099:
	.8byte	13
	.8byte	m_cstr3098
	.text
m_oop_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3078
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3079
m_L3078:
	lea	m_ostr3081(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3079:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3082
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3083
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3085(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3087(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3089(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3091(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3093(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3083:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3094
m_L3082:
	lea	m_ostr3096(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3094:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3097
	lea	m_ostr3099(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3097:
	xor	%rax, %rax
	mov	-40(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-32(%rbp), %rax
	mov	-48(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	(%rcx), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3101:
	.asciz "oop-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3102:
	.8byte	43
	.8byte	m_cstr3101
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oop_at_2Fevaluator_stub:
	.8byte	m_oop_at_2Fevaluator_stub__code
	.8byte	m_ostr3102
	.globl m_oop_at_2Fevaluator_stub__code
	.type m_oop_at_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3105:
	.asciz "set-oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3106:
	.8byte	21
	.8byte	m_cstr3105
	.section .rodata
m_cstr3109:
	.asciz "set-oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3110:
	.8byte	21
	.8byte	m_cstr3109
	.section .rodata
m_cstr3111:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3112:
	.8byte	15
	.8byte	m_cstr3111
	.section .rodata
m_cstr3113:
	.asciz "cellindex"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3114:
	.8byte	19
	.8byte	m_cstr3113
	.section .rodata
m_cstr3115:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3116:
	.8byte	35
	.8byte	m_cstr3115
	.section .rodata
m_cstr3117:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3118:
	.8byte	13
	.8byte	m_cstr3117
	.section .rodata
m_cstr3120:
	.asciz "set-oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3121:
	.8byte	21
	.8byte	m_cstr3120
	.section .rodata
m_cstr3124:
	.asciz "set-oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3125:
	.8byte	21
	.8byte	m_cstr3124
	.section .rodata
m_cstr3127:
	.asciz "set-oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3128:
	.8byte	21
	.8byte	m_cstr3127
	.text
m_set_oop_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3103
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3104
m_L3103:
	lea	m_ostr3106(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3104:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3107
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3108
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3110(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3112(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3114(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3116(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3118(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3108:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3119
m_L3107:
	lea	m_ostr3121(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3119:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3122
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3123
m_L3122:
	lea	m_ostr3125(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3123:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3126
	lea	m_ostr3128(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3126:
	xor	%rax, %rax
	mov	-48(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-32(%rbp), %rax
	mov	-64(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	-56(%rbp), %rax
	mov	%rax, (%rcx)
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3130:
	.asciz "set-oop-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3131:
	.8byte	51
	.8byte	m_cstr3130
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_oop_at_2Fevaluator_stub:
	.8byte	m_set_oop_at_2Fevaluator_stub__code
	.8byte	m_ostr3131
	.globl m_set_oop_at_2Fevaluator_stub__code
	.type m_set_oop_at_2Fevaluator_stub__code, @function
	.text
m_lower_cell__3Elong__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	mov	-8(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr3132:
	.asciz "lower-cell->long"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3133:
	.8byte	33
	.8byte	m_cstr3132
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_lower_cell__3Elong:
	.8byte	m_lower_cell__3Elong__code
	.8byte	m_ostr3133
	.globl m_lower_cell__3Elong__code
	.type m_lower_cell__3Elong__code, @function
	.section .rodata
m_cstr3136:
	.asciz "lower-cell->long"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3137:
	.8byte	33
	.8byte	m_cstr3136
	.section .rodata
m_cstr3138:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3139:
	.8byte	15
	.8byte	m_cstr3138
	.section .rodata
m_cstr3140:
	.asciz "value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3141:
	.8byte	11
	.8byte	m_cstr3140
	.section .rodata
m_cstr3142:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3143:
	.8byte	35
	.8byte	m_cstr3142
	.section .rodata
m_cstr3144:
	.asciz "<lower-cell>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3145:
	.8byte	25
	.8byte	m_cstr3144
	.section .rodata
m_cstr3147:
	.asciz "lower-cell->long"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3148:
	.8byte	33
	.8byte	m_cstr3147
	.section .rodata
m_cstr3150:
	.asciz "lower-cell->long"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3151:
	.8byte	33
	.8byte	m_cstr3150
	.text
m_lower_cell__3Elong_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3134
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	mov	$20, %rax
	cmp	-40(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L3135
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3137(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3139(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3141(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3143(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3145(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3135:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3146
m_L3134:
	lea	m_ostr3148(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3146:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3149
	lea	m_ostr3151(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3149:
	movq	-32(%rbp), %rdi
	call	m_lower_cell__3Elong__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3153:
	.asciz "lower-cell->long/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3154:
	.8byte	63
	.8byte	m_cstr3153
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_lower_cell__3Elong_2Fevaluator_stub:
	.8byte	m_lower_cell__3Elong_2Fevaluator_stub__code
	.8byte	m_ostr3154
	.globl m_lower_cell__3Elong_2Fevaluator_stub__code
	.type m_lower_cell__3Elong_2Fevaluator_stub__code, @function
	.text
m_long__3Elower_cell__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	mov	$20, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25allocate_boxed_word__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3155:
	.asciz "long->lower-cell"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3156:
	.8byte	33
	.8byte	m_cstr3155
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_long__3Elower_cell:
	.8byte	m_long__3Elower_cell__code
	.8byte	m_ostr3156
	.globl m_long__3Elower_cell__code
	.type m_long__3Elower_cell__code, @function
	.section .rodata
m_cstr3159:
	.asciz "long->lower-cell"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3160:
	.8byte	33
	.8byte	m_cstr3159
	.section .rodata
m_cstr3161:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3162:
	.8byte	15
	.8byte	m_cstr3161
	.section .rodata
m_cstr3163:
	.asciz "value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3164:
	.8byte	11
	.8byte	m_cstr3163
	.section .rodata
m_cstr3165:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3166:
	.8byte	35
	.8byte	m_cstr3165
	.section .rodata
m_cstr3167:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3168:
	.8byte	13
	.8byte	m_cstr3167
	.section .rodata
m_cstr3170:
	.asciz "long->lower-cell"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3171:
	.8byte	33
	.8byte	m_cstr3170
	.section .rodata
m_cstr3173:
	.asciz "long->lower-cell"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3174:
	.8byte	33
	.8byte	m_cstr3173
	.text
m_long__3Elower_cell_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3157
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3158
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3160(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3162(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3164(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3166(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3168(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3158:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3169
m_L3157:
	lea	m_ostr3171(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3169:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3172
	lea	m_ostr3174(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3172:
	movq	-32(%rbp), %rdi
	call	m_long__3Elower_cell__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3176:
	.asciz "long->lower-cell/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3177:
	.8byte	63
	.8byte	m_cstr3176
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_long__3Elower_cell_2Fevaluator_stub:
	.8byte	m_long__3Elower_cell_2Fevaluator_stub__code
	.8byte	m_ostr3177
	.globl m_long__3Elower_cell_2Fevaluator_stub__code
	.type m_long__3Elower_cell_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3180:
	.asciz "array-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3181:
	.8byte	25
	.8byte	m_cstr3180
	.section .rodata
m_cstr3182:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3183:
	.8byte	15
	.8byte	m_cstr3182
	.section .rodata
m_cstr3184:
	.asciz "arg"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3185:
	.8byte	7
	.8byte	m_cstr3184
	.section .rodata
m_cstr3186:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3187:
	.8byte	35
	.8byte	m_cstr3186
	.section .rodata
m_cstr3188:
	.asciz "<array>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3189:
	.8byte	15
	.8byte	m_cstr3188
	.section .rodata
m_cstr3191:
	.asciz "array-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3192:
	.8byte	25
	.8byte	m_cstr3191
	.section .rodata
m_cstr3194:
	.asciz "array-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3195:
	.8byte	25
	.8byte	m_cstr3194
	.text
m_array_length_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3178
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_array_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3179
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3181(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3183(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3185(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3187(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3189(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3179:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3190
m_L3178:
	lea	m_ostr3192(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3190:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3193
	lea	m_ostr3195(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3193:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3197:
	.asciz "array-length/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3198:
	.8byte	55
	.8byte	m_cstr3197
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_length_2Fevaluator_stub:
	.8byte	m_array_length_2Fevaluator_stub__code
	.8byte	m_ostr3198
	.globl m_array_length_2Fevaluator_stub__code
	.type m_array_length_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3201:
	.asciz "string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3202:
	.8byte	27
	.8byte	m_cstr3201
	.section .rodata
m_cstr3203:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3204:
	.8byte	15
	.8byte	m_cstr3203
	.section .rodata
m_cstr3205:
	.asciz "arg"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3206:
	.8byte	7
	.8byte	m_cstr3205
	.section .rodata
m_cstr3207:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3208:
	.8byte	35
	.8byte	m_cstr3207
	.section .rodata
m_cstr3209:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3210:
	.8byte	17
	.8byte	m_cstr3209
	.section .rodata
m_cstr3212:
	.asciz "string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3213:
	.8byte	27
	.8byte	m_cstr3212
	.section .rodata
m_cstr3215:
	.asciz "string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3216:
	.8byte	27
	.8byte	m_cstr3215
	.text
m_string_length_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3199
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3200
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3202(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3204(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3206(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3208(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3210(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3200:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3211
m_L3199:
	lea	m_ostr3213(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3211:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3214
	lea	m_ostr3216(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3214:
	mov	-32(%rbp), %rax
	mov	(%rax), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3218:
	.asciz "string-length/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3219:
	.8byte	57
	.8byte	m_cstr3218
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_length_2Fevaluator_stub:
	.8byte	m_string_length_2Fevaluator_stub__code
	.8byte	m_ostr3219
	.globl m_string_length_2Fevaluator_stub__code
	.type m_string_length_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3222:
	.asciz "string-compare"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3223:
	.8byte	29
	.8byte	m_cstr3222
	.section .rodata
m_cstr3224:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3225:
	.8byte	15
	.8byte	m_cstr3224
	.section .rodata
m_cstr3226:
	.asciz "s1"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3227:
	.8byte	5
	.8byte	m_cstr3226
	.section .rodata
m_cstr3228:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3229:
	.8byte	35
	.8byte	m_cstr3228
	.section .rodata
m_cstr3230:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3231:
	.8byte	17
	.8byte	m_cstr3230
	.section .rodata
m_cstr3233:
	.asciz "string-compare"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3234:
	.8byte	29
	.8byte	m_cstr3233
	.section .rodata
m_cstr3237:
	.asciz "string-compare"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3238:
	.8byte	29
	.8byte	m_cstr3237
	.section .rodata
m_cstr3239:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3240:
	.8byte	15
	.8byte	m_cstr3239
	.section .rodata
m_cstr3241:
	.asciz "s2"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3242:
	.8byte	5
	.8byte	m_cstr3241
	.section .rodata
m_cstr3243:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3244:
	.8byte	35
	.8byte	m_cstr3243
	.section .rodata
m_cstr3245:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3246:
	.8byte	17
	.8byte	m_cstr3245
	.section .rodata
m_cstr3248:
	.asciz "string-compare"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3249:
	.8byte	29
	.8byte	m_cstr3248
	.section .rodata
m_cstr3251:
	.asciz "string-compare"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3252:
	.8byte	29
	.8byte	m_cstr3251
	.text
m_string_compare_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3220
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3221
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3223(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3225(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3227(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3229(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3231(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3221:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3232
m_L3220:
	lea	m_ostr3234(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3232:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3235
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3236
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3238(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3240(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3242(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3244(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3246(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3236:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3247
m_L3235:
	lea	m_ostr3249(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3247:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3250
	lea	m_ostr3252(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3250:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_string_compare__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3254:
	.asciz "string-compare/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3255:
	.8byte	59
	.8byte	m_cstr3254
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_compare_2Fevaluator_stub:
	.8byte	m_string_compare_2Fevaluator_stub__code
	.8byte	m_ostr3255
	.globl m_string_compare_2Fevaluator_stub__code
	.type m_string_compare_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3258:
	.asciz "array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3259:
	.8byte	17
	.8byte	m_cstr3258
	.section .rodata
m_cstr3260:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3261:
	.8byte	15
	.8byte	m_cstr3260
	.section .rodata
m_cstr3262:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3263:
	.8byte	11
	.8byte	m_cstr3262
	.section .rodata
m_cstr3264:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3265:
	.8byte	35
	.8byte	m_cstr3264
	.section .rodata
m_cstr3266:
	.asciz "<array>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3267:
	.8byte	15
	.8byte	m_cstr3266
	.section .rodata
m_cstr3269:
	.asciz "array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3270:
	.8byte	17
	.8byte	m_cstr3269
	.section .rodata
m_cstr3273:
	.asciz "array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3274:
	.8byte	17
	.8byte	m_cstr3273
	.section .rodata
m_cstr3275:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3276:
	.8byte	15
	.8byte	m_cstr3275
	.section .rodata
m_cstr3277:
	.asciz "index"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3278:
	.8byte	11
	.8byte	m_cstr3277
	.section .rodata
m_cstr3279:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3280:
	.8byte	35
	.8byte	m_cstr3279
	.section .rodata
m_cstr3281:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3282:
	.8byte	13
	.8byte	m_cstr3281
	.section .rodata
m_cstr3284:
	.asciz "array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3285:
	.8byte	17
	.8byte	m_cstr3284
	.section .rodata
m_cstr3287:
	.asciz "array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3288:
	.8byte	17
	.8byte	m_cstr3287
	.text
m_array_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3256
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_array_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3257
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3259(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3261(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3263(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3265(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3267(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3257:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3268
m_L3256:
	lea	m_ostr3270(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3268:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3271
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3272
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3274(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3276(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3278(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3280(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3282(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3272:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3283
m_L3271:
	lea	m_ostr3285(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3283:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3286
	lea	m_ostr3288(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3286:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_array_at__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3290:
	.asciz "array-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3291:
	.8byte	47
	.8byte	m_cstr3290
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_at_2Fevaluator_stub:
	.8byte	m_array_at_2Fevaluator_stub__code
	.8byte	m_ostr3291
	.globl m_array_at_2Fevaluator_stub__code
	.type m_array_at_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3294:
	.asciz "string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3295:
	.8byte	19
	.8byte	m_cstr3294
	.section .rodata
m_cstr3296:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3297:
	.8byte	15
	.8byte	m_cstr3296
	.section .rodata
m_cstr3298:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3299:
	.8byte	13
	.8byte	m_cstr3298
	.section .rodata
m_cstr3300:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3301:
	.8byte	35
	.8byte	m_cstr3300
	.section .rodata
m_cstr3302:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3303:
	.8byte	17
	.8byte	m_cstr3302
	.section .rodata
m_cstr3305:
	.asciz "string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3306:
	.8byte	19
	.8byte	m_cstr3305
	.section .rodata
m_cstr3309:
	.asciz "string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3310:
	.8byte	19
	.8byte	m_cstr3309
	.section .rodata
m_cstr3311:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3312:
	.8byte	15
	.8byte	m_cstr3311
	.section .rodata
m_cstr3313:
	.asciz "index"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3314:
	.8byte	11
	.8byte	m_cstr3313
	.section .rodata
m_cstr3315:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3316:
	.8byte	35
	.8byte	m_cstr3315
	.section .rodata
m_cstr3317:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3318:
	.8byte	13
	.8byte	m_cstr3317
	.section .rodata
m_cstr3320:
	.asciz "string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3321:
	.8byte	19
	.8byte	m_cstr3320
	.section .rodata
m_cstr3323:
	.asciz "string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3324:
	.8byte	19
	.8byte	m_cstr3323
	.text
m_string_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3292
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3293
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3295(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3297(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3299(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3301(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3303(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3293:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3304
m_L3292:
	lea	m_ostr3306(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3304:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3307
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3308
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3310(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3312(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3314(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3316(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3318(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3308:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3319
m_L3307:
	lea	m_ostr3321(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3319:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3322
	lea	m_ostr3324(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3322:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_string_at__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3326:
	.asciz "string-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3327:
	.8byte	49
	.8byte	m_cstr3326
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_at_2Fevaluator_stub:
	.8byte	m_string_at_2Fevaluator_stub__code
	.8byte	m_ostr3327
	.globl m_string_at_2Fevaluator_stub__code
	.type m_string_at_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3330:
	.asciz "char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3331:
	.8byte	15
	.8byte	m_cstr3330
	.section .rodata
m_cstr3332:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3333:
	.8byte	15
	.8byte	m_cstr3332
	.section .rodata
m_cstr3334:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3335:
	.8byte	13
	.8byte	m_cstr3334
	.section .rodata
m_cstr3336:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3337:
	.8byte	35
	.8byte	m_cstr3336
	.section .rodata
m_cstr3338:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3339:
	.8byte	17
	.8byte	m_cstr3338
	.section .rodata
m_cstr3341:
	.asciz "char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3342:
	.8byte	15
	.8byte	m_cstr3341
	.section .rodata
m_cstr3345:
	.asciz "char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3346:
	.8byte	15
	.8byte	m_cstr3345
	.section .rodata
m_cstr3347:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3348:
	.8byte	15
	.8byte	m_cstr3347
	.section .rodata
m_cstr3349:
	.asciz "index"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3350:
	.8byte	11
	.8byte	m_cstr3349
	.section .rodata
m_cstr3351:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3352:
	.8byte	35
	.8byte	m_cstr3351
	.section .rodata
m_cstr3353:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3354:
	.8byte	13
	.8byte	m_cstr3353
	.section .rodata
m_cstr3356:
	.asciz "char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3357:
	.8byte	15
	.8byte	m_cstr3356
	.section .rodata
m_cstr3359:
	.asciz "char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3360:
	.8byte	15
	.8byte	m_cstr3359
	.text
m_char_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3328
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3329
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3331(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3333(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3335(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3337(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3339(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3329:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3340
m_L3328:
	lea	m_ostr3342(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3340:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3343
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3344
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3346(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3348(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3350(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3352(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3354(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3344:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3355
m_L3343:
	lea	m_ostr3357(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3355:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3358
	lea	m_ostr3360(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3358:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_string_at__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3362:
	.asciz "char-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3363:
	.8byte	45
	.8byte	m_cstr3362
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_char_at_2Fevaluator_stub:
	.8byte	m_char_at_2Fevaluator_stub__code
	.8byte	m_ostr3363
	.globl m_char_at_2Fevaluator_stub__code
	.type m_char_at_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3366:
	.asciz "set-array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3367:
	.8byte	25
	.8byte	m_cstr3366
	.section .rodata
m_cstr3368:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3369:
	.8byte	15
	.8byte	m_cstr3368
	.section .rodata
m_cstr3370:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3371:
	.8byte	11
	.8byte	m_cstr3370
	.section .rodata
m_cstr3372:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3373:
	.8byte	35
	.8byte	m_cstr3372
	.section .rodata
m_cstr3374:
	.asciz "<array>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3375:
	.8byte	15
	.8byte	m_cstr3374
	.section .rodata
m_cstr3377:
	.asciz "set-array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3378:
	.8byte	25
	.8byte	m_cstr3377
	.section .rodata
m_cstr3381:
	.asciz "set-array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3382:
	.8byte	25
	.8byte	m_cstr3381
	.section .rodata
m_cstr3383:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3384:
	.8byte	15
	.8byte	m_cstr3383
	.section .rodata
m_cstr3385:
	.asciz "index"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3386:
	.8byte	11
	.8byte	m_cstr3385
	.section .rodata
m_cstr3387:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3388:
	.8byte	35
	.8byte	m_cstr3387
	.section .rodata
m_cstr3389:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3390:
	.8byte	13
	.8byte	m_cstr3389
	.section .rodata
m_cstr3392:
	.asciz "set-array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3393:
	.8byte	25
	.8byte	m_cstr3392
	.section .rodata
m_cstr3396:
	.asciz "set-array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3397:
	.8byte	25
	.8byte	m_cstr3396
	.section .rodata
m_cstr3399:
	.asciz "set-array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3400:
	.8byte	25
	.8byte	m_cstr3399
	.text
m_set_array_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3364
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_array_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3365
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3367(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3369(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3371(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3373(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3375(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3365:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3376
m_L3364:
	lea	m_ostr3378(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3376:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3379
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3380
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3382(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3384(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3386(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3388(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3390(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3380:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3391
m_L3379:
	lea	m_ostr3393(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3391:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3394
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3395
m_L3394:
	lea	m_ostr3397(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3395:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3398
	lea	m_ostr3400(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3398:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_set_array_at__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3402:
	.asciz "set-array-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3403:
	.8byte	55
	.8byte	m_cstr3402
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_array_at_2Fevaluator_stub:
	.8byte	m_set_array_at_2Fevaluator_stub__code
	.8byte	m_ostr3403
	.globl m_set_array_at_2Fevaluator_stub__code
	.type m_set_array_at_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3406:
	.asciz "set-string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3407:
	.8byte	27
	.8byte	m_cstr3406
	.section .rodata
m_cstr3408:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3409:
	.8byte	15
	.8byte	m_cstr3408
	.section .rodata
m_cstr3410:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3411:
	.8byte	13
	.8byte	m_cstr3410
	.section .rodata
m_cstr3412:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3413:
	.8byte	35
	.8byte	m_cstr3412
	.section .rodata
m_cstr3414:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3415:
	.8byte	17
	.8byte	m_cstr3414
	.section .rodata
m_cstr3417:
	.asciz "set-string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3418:
	.8byte	27
	.8byte	m_cstr3417
	.section .rodata
m_cstr3421:
	.asciz "set-string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3422:
	.8byte	27
	.8byte	m_cstr3421
	.section .rodata
m_cstr3423:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3424:
	.8byte	15
	.8byte	m_cstr3423
	.section .rodata
m_cstr3425:
	.asciz "index"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3426:
	.8byte	11
	.8byte	m_cstr3425
	.section .rodata
m_cstr3427:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3428:
	.8byte	35
	.8byte	m_cstr3427
	.section .rodata
m_cstr3429:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3430:
	.8byte	13
	.8byte	m_cstr3429
	.section .rodata
m_cstr3432:
	.asciz "set-string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3433:
	.8byte	27
	.8byte	m_cstr3432
	.section .rodata
m_cstr3436:
	.asciz "set-string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3437:
	.8byte	27
	.8byte	m_cstr3436
	.section .rodata
m_cstr3438:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3439:
	.8byte	15
	.8byte	m_cstr3438
	.section .rodata
m_cstr3440:
	.asciz "value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3441:
	.8byte	11
	.8byte	m_cstr3440
	.section .rodata
m_cstr3442:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3443:
	.8byte	35
	.8byte	m_cstr3442
	.section .rodata
m_cstr3444:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3445:
	.8byte	13
	.8byte	m_cstr3444
	.section .rodata
m_cstr3447:
	.asciz "set-string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3448:
	.8byte	27
	.8byte	m_cstr3447
	.section .rodata
m_cstr3450:
	.asciz "set-string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3451:
	.8byte	27
	.8byte	m_cstr3450
	.text
m_set_string_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3404
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3405
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3407(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3409(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3411(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3413(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3415(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3405:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3416
m_L3404:
	lea	m_ostr3418(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3416:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3419
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3420
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3422(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3424(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3426(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3428(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3430(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3420:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3431
m_L3419:
	lea	m_ostr3433(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3431:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3434
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	movq	-48(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3435
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3437(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3439(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3441(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3443(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3445(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3435:
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3446
m_L3434:
	lea	m_ostr3448(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3446:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3449
	lea	m_ostr3451(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3449:
	xor	%rax, %rax
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_set_string_at__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3453:
	.asciz "set-string-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3454:
	.8byte	57
	.8byte	m_cstr3453
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_string_at_2Fevaluator_stub:
	.8byte	m_set_string_at_2Fevaluator_stub__code
	.8byte	m_ostr3454
	.globl m_set_string_at_2Fevaluator_stub__code
	.type m_set_string_at_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3457:
	.asciz "set-char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3458:
	.8byte	23
	.8byte	m_cstr3457
	.section .rodata
m_cstr3459:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3460:
	.8byte	15
	.8byte	m_cstr3459
	.section .rodata
m_cstr3461:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3462:
	.8byte	13
	.8byte	m_cstr3461
	.section .rodata
m_cstr3463:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3464:
	.8byte	35
	.8byte	m_cstr3463
	.section .rodata
m_cstr3465:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3466:
	.8byte	17
	.8byte	m_cstr3465
	.section .rodata
m_cstr3468:
	.asciz "set-char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3469:
	.8byte	23
	.8byte	m_cstr3468
	.section .rodata
m_cstr3472:
	.asciz "set-char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3473:
	.8byte	23
	.8byte	m_cstr3472
	.section .rodata
m_cstr3474:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3475:
	.8byte	15
	.8byte	m_cstr3474
	.section .rodata
m_cstr3476:
	.asciz "index"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3477:
	.8byte	11
	.8byte	m_cstr3476
	.section .rodata
m_cstr3478:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3479:
	.8byte	35
	.8byte	m_cstr3478
	.section .rodata
m_cstr3480:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3481:
	.8byte	13
	.8byte	m_cstr3480
	.section .rodata
m_cstr3483:
	.asciz "set-char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3484:
	.8byte	23
	.8byte	m_cstr3483
	.section .rodata
m_cstr3487:
	.asciz "set-char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3488:
	.8byte	23
	.8byte	m_cstr3487
	.section .rodata
m_cstr3489:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3490:
	.8byte	15
	.8byte	m_cstr3489
	.section .rodata
m_cstr3491:
	.asciz "value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3492:
	.8byte	11
	.8byte	m_cstr3491
	.section .rodata
m_cstr3493:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3494:
	.8byte	35
	.8byte	m_cstr3493
	.section .rodata
m_cstr3495:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3496:
	.8byte	13
	.8byte	m_cstr3495
	.section .rodata
m_cstr3498:
	.asciz "set-char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3499:
	.8byte	23
	.8byte	m_cstr3498
	.section .rodata
m_cstr3501:
	.asciz "set-char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3502:
	.8byte	23
	.8byte	m_cstr3501
	.text
m_set_char_at_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3455
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3456
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3458(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3460(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3462(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3464(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3466(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3456:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3467
m_L3455:
	lea	m_ostr3469(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3467:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3470
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3471
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3473(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3475(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3477(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3479(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3481(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3471:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3482
m_L3470:
	lea	m_ostr3484(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3482:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3485
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	movq	-48(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3486
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3488(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3490(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3492(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3494(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3496(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3486:
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3497
m_L3485:
	lea	m_ostr3499(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3497:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3500
	lea	m_ostr3502(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3500:
	xor	%rax, %rax
	xor	%rax, %rax
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_set_string_at__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3504:
	.asciz "set-char-at/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3505:
	.8byte	53
	.8byte	m_cstr3504
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_set_char_at_2Fevaluator_stub:
	.8byte	m_set_char_at_2Fevaluator_stub__code
	.8byte	m_ostr3505
	.globl m_set_char_at_2Fevaluator_stub__code
	.type m_set_char_at_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3508:
	.asciz "array-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3509:
	.8byte	25
	.8byte	m_cstr3508
	.section .rodata
m_cstr3510:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3511:
	.8byte	15
	.8byte	m_cstr3510
	.section .rodata
m_cstr3512:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3513:
	.8byte	11
	.8byte	m_cstr3512
	.section .rodata
m_cstr3514:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3515:
	.8byte	35
	.8byte	m_cstr3514
	.section .rodata
m_cstr3516:
	.asciz "<array>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3517:
	.8byte	15
	.8byte	m_cstr3516
	.section .rodata
m_cstr3519:
	.asciz "array-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3520:
	.8byte	25
	.8byte	m_cstr3519
	.section .rodata
m_cstr3523:
	.asciz "array-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3524:
	.8byte	25
	.8byte	m_cstr3523
	.section .rodata
m_cstr3525:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3526:
	.8byte	15
	.8byte	m_cstr3525
	.section .rodata
m_cstr3527:
	.asciz "index"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3528:
	.8byte	11
	.8byte	m_cstr3527
	.section .rodata
m_cstr3529:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3530:
	.8byte	35
	.8byte	m_cstr3529
	.section .rodata
m_cstr3531:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3532:
	.8byte	13
	.8byte	m_cstr3531
	.section .rodata
m_cstr3534:
	.asciz "array-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3535:
	.8byte	25
	.8byte	m_cstr3534
	.section .rodata
m_cstr3538:
	.asciz "array-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3539:
	.8byte	25
	.8byte	m_cstr3538
	.section .rodata
m_cstr3541:
	.asciz "array-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3542:
	.8byte	25
	.8byte	m_cstr3541
	.text
m_array_insert_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3506
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_array_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3507
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3509(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3511(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3513(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3515(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3517(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3507:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3518
m_L3506:
	lea	m_ostr3520(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3518:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3521
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3522
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3524(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3526(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3528(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3530(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3532(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3522:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3533
m_L3521:
	lea	m_ostr3535(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3533:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3536
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3537
m_L3536:
	lea	m_ostr3539(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3537:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3540
	lea	m_ostr3542(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3540:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_array_insert__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3544:
	.asciz "array-insert/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3545:
	.8byte	55
	.8byte	m_cstr3544
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_insert_2Fevaluator_stub:
	.8byte	m_array_insert_2Fevaluator_stub__code
	.8byte	m_ostr3545
	.globl m_array_insert_2Fevaluator_stub__code
	.type m_array_insert_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3548:
	.asciz "string-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3549:
	.8byte	27
	.8byte	m_cstr3548
	.section .rodata
m_cstr3550:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3551:
	.8byte	15
	.8byte	m_cstr3550
	.section .rodata
m_cstr3552:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3553:
	.8byte	13
	.8byte	m_cstr3552
	.section .rodata
m_cstr3554:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3555:
	.8byte	35
	.8byte	m_cstr3554
	.section .rodata
m_cstr3556:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3557:
	.8byte	17
	.8byte	m_cstr3556
	.section .rodata
m_cstr3559:
	.asciz "string-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3560:
	.8byte	27
	.8byte	m_cstr3559
	.section .rodata
m_cstr3563:
	.asciz "string-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3564:
	.8byte	27
	.8byte	m_cstr3563
	.section .rodata
m_cstr3565:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3566:
	.8byte	15
	.8byte	m_cstr3565
	.section .rodata
m_cstr3567:
	.asciz "index"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3568:
	.8byte	11
	.8byte	m_cstr3567
	.section .rodata
m_cstr3569:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3570:
	.8byte	35
	.8byte	m_cstr3569
	.section .rodata
m_cstr3571:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3572:
	.8byte	13
	.8byte	m_cstr3571
	.section .rodata
m_cstr3574:
	.asciz "string-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3575:
	.8byte	27
	.8byte	m_cstr3574
	.section .rodata
m_cstr3578:
	.asciz "string-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3579:
	.8byte	27
	.8byte	m_cstr3578
	.section .rodata
m_cstr3580:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3581:
	.8byte	15
	.8byte	m_cstr3580
	.section .rodata
m_cstr3582:
	.asciz "value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3583:
	.8byte	11
	.8byte	m_cstr3582
	.section .rodata
m_cstr3584:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3585:
	.8byte	35
	.8byte	m_cstr3584
	.section .rodata
m_cstr3586:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3587:
	.8byte	13
	.8byte	m_cstr3586
	.section .rodata
m_cstr3589:
	.asciz "string-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3590:
	.8byte	27
	.8byte	m_cstr3589
	.section .rodata
m_cstr3592:
	.asciz "string-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3593:
	.8byte	27
	.8byte	m_cstr3592
	.text
m_string_insert_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3546
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3547
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3549(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3551(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3553(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3555(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3557(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3547:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3558
m_L3546:
	lea	m_ostr3560(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3558:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3561
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3562
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3564(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3566(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3568(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3570(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3572(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3562:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3573
m_L3561:
	lea	m_ostr3575(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3573:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3576
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	movq	-48(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3577
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3579(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3581(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3583(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3585(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3587(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3577:
	mov	-48(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3588
m_L3576:
	lea	m_ostr3590(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3588:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3591
	lea	m_ostr3593(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3591:
	xor	%rax, %rax
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	call	m_string_insert__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3595:
	.asciz "string-insert/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3596:
	.8byte	57
	.8byte	m_cstr3595
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_insert_2Fevaluator_stub:
	.8byte	m_string_insert_2Fevaluator_stub__code
	.8byte	m_ostr3596
	.globl m_string_insert_2Fevaluator_stub__code
	.type m_string_insert_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3599:
	.asciz "array-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3600:
	.8byte	25
	.8byte	m_cstr3599
	.section .rodata
m_cstr3601:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3602:
	.8byte	15
	.8byte	m_cstr3601
	.section .rodata
m_cstr3603:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3604:
	.8byte	11
	.8byte	m_cstr3603
	.section .rodata
m_cstr3605:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3606:
	.8byte	35
	.8byte	m_cstr3605
	.section .rodata
m_cstr3607:
	.asciz "<array>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3608:
	.8byte	15
	.8byte	m_cstr3607
	.section .rodata
m_cstr3610:
	.asciz "array-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3611:
	.8byte	25
	.8byte	m_cstr3610
	.section .rodata
m_cstr3614:
	.asciz "array-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3615:
	.8byte	25
	.8byte	m_cstr3614
	.section .rodata
m_cstr3617:
	.asciz "array-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3618:
	.8byte	25
	.8byte	m_cstr3617
	.text
m_array_append_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3597
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_array_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3598
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3600(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3602(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3604(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3606(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3608(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3598:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3609
m_L3597:
	lea	m_ostr3611(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3609:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3612
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3613
m_L3612:
	lea	m_ostr3615(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3613:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3616
	lea	m_ostr3618(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3616:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_array_append__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3620:
	.asciz "array-append/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3621:
	.8byte	55
	.8byte	m_cstr3620
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_array_append_2Fevaluator_stub:
	.8byte	m_array_append_2Fevaluator_stub__code
	.8byte	m_ostr3621
	.globl m_array_append_2Fevaluator_stub__code
	.type m_array_append_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3624:
	.asciz "string-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3625:
	.8byte	27
	.8byte	m_cstr3624
	.section .rodata
m_cstr3626:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3627:
	.8byte	15
	.8byte	m_cstr3626
	.section .rodata
m_cstr3628:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3629:
	.8byte	13
	.8byte	m_cstr3628
	.section .rodata
m_cstr3630:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3631:
	.8byte	35
	.8byte	m_cstr3630
	.section .rodata
m_cstr3632:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3633:
	.8byte	17
	.8byte	m_cstr3632
	.section .rodata
m_cstr3635:
	.asciz "string-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3636:
	.8byte	27
	.8byte	m_cstr3635
	.section .rodata
m_cstr3639:
	.asciz "string-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3640:
	.8byte	27
	.8byte	m_cstr3639
	.section .rodata
m_cstr3641:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3642:
	.8byte	15
	.8byte	m_cstr3641
	.section .rodata
m_cstr3643:
	.asciz "value"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3644:
	.8byte	11
	.8byte	m_cstr3643
	.section .rodata
m_cstr3645:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3646:
	.8byte	35
	.8byte	m_cstr3645
	.section .rodata
m_cstr3647:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3648:
	.8byte	13
	.8byte	m_cstr3647
	.section .rodata
m_cstr3650:
	.asciz "string-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3651:
	.8byte	27
	.8byte	m_cstr3650
	.section .rodata
m_cstr3653:
	.asciz "string-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3654:
	.8byte	27
	.8byte	m_cstr3653
	.text
m_string_append_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3622
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3623
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3625(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3627(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3629(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3631(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3633(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3623:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3634
m_L3622:
	lea	m_ostr3636(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3634:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3637
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3638
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3640(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3642(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3644(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3646(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3648(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3638:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3649
m_L3637:
	lea	m_ostr3651(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3649:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3652
	lea	m_ostr3654(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3652:
	xor	%rax, %rax
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_string_append__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3656:
	.asciz "string-append/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3657:
	.8byte	57
	.8byte	m_cstr3656
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string_append_2Fevaluator_stub:
	.8byte	m_string_append_2Fevaluator_stub__code
	.8byte	m_ostr3657
	.globl m_string_append_2Fevaluator_stub__code
	.type m_string_append_2Fevaluator_stub__code, @function
	.text
m_number__3Estring__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_long__3Estring_2A__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr3658:
	.asciz "number->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3659:
	.8byte	29
	.8byte	m_cstr3658
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_number__3Estring:
	.8byte	m_number__3Estring__code
	.8byte	m_ostr3659
	.globl m_number__3Estring__code
	.type m_number__3Estring__code, @function
	.section .rodata
m_cstr3662:
	.asciz "number->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3663:
	.8byte	29
	.8byte	m_cstr3662
	.section .rodata
m_cstr3664:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3665:
	.8byte	15
	.8byte	m_cstr3664
	.section .rodata
m_cstr3666:
	.asciz "num"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3667:
	.8byte	7
	.8byte	m_cstr3666
	.section .rodata
m_cstr3668:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3669:
	.8byte	35
	.8byte	m_cstr3668
	.section .rodata
m_cstr3670:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3671:
	.8byte	13
	.8byte	m_cstr3670
	.section .rodata
m_cstr3673:
	.asciz "number->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3674:
	.8byte	29
	.8byte	m_cstr3673
	.section .rodata
m_cstr3677:
	.asciz "number->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3678:
	.8byte	29
	.8byte	m_cstr3677
	.section .rodata
m_cstr3679:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3680:
	.8byte	15
	.8byte	m_cstr3679
	.section .rodata
m_cstr3681:
	.asciz "radix"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3682:
	.8byte	11
	.8byte	m_cstr3681
	.section .rodata
m_cstr3683:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3684:
	.8byte	35
	.8byte	m_cstr3683
	.section .rodata
m_cstr3685:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3686:
	.8byte	13
	.8byte	m_cstr3685
	.section .rodata
m_cstr3689:
	.asciz "number->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3690:
	.8byte	29
	.8byte	m_cstr3689
	.text
m_number__3Estring_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3660
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3661
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3663(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3665(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3667(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3669(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3671(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3661:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3672
m_L3660:
	lea	m_ostr3674(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3672:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3675
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3676
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3678(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3680(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3682(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3684(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3686(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3676:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3687
m_L3675:
	mov	$10, %rax
	mov	%rax, -40(%rbp)
m_L3687:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3688
	lea	m_ostr3690(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3688:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_number__3Estring__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3692:
	.asciz "number->string/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3693:
	.8byte	59
	.8byte	m_cstr3692
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_number__3Estring_2Fevaluator_stub:
	.8byte	m_number__3Estring_2Fevaluator_stub__code
	.8byte	m_ostr3693
	.globl m_number__3Estring_2Fevaluator_stub__code
	.type m_number__3Estring_2Fevaluator_stub__code, @function
	.text
m_integer__3Estring__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_long__3Estring_2A__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr3694:
	.asciz "integer->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3695:
	.8byte	31
	.8byte	m_cstr3694
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_integer__3Estring:
	.8byte	m_integer__3Estring__code
	.8byte	m_ostr3695
	.globl m_integer__3Estring__code
	.type m_integer__3Estring__code, @function
	.section .rodata
m_cstr3698:
	.asciz "integer->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3699:
	.8byte	31
	.8byte	m_cstr3698
	.section .rodata
m_cstr3700:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3701:
	.8byte	15
	.8byte	m_cstr3700
	.section .rodata
m_cstr3702:
	.asciz "num"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3703:
	.8byte	7
	.8byte	m_cstr3702
	.section .rodata
m_cstr3704:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3705:
	.8byte	35
	.8byte	m_cstr3704
	.section .rodata
m_cstr3706:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3707:
	.8byte	13
	.8byte	m_cstr3706
	.section .rodata
m_cstr3709:
	.asciz "integer->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3710:
	.8byte	31
	.8byte	m_cstr3709
	.section .rodata
m_cstr3713:
	.asciz "integer->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3714:
	.8byte	31
	.8byte	m_cstr3713
	.section .rodata
m_cstr3715:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3716:
	.8byte	15
	.8byte	m_cstr3715
	.section .rodata
m_cstr3717:
	.asciz "radix"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3718:
	.8byte	11
	.8byte	m_cstr3717
	.section .rodata
m_cstr3719:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3720:
	.8byte	35
	.8byte	m_cstr3719
	.section .rodata
m_cstr3721:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3722:
	.8byte	13
	.8byte	m_cstr3721
	.section .rodata
m_cstr3725:
	.asciz "integer->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3726:
	.8byte	31
	.8byte	m_cstr3725
	.text
m_integer__3Estring_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3696
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3697
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3699(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3701(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3703(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3705(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3707(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3697:
	mov	-32(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3708
m_L3696:
	lea	m_ostr3710(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3708:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3711
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3712
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3714(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3716(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3718(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3720(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3722(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3712:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3723
m_L3711:
	mov	$10, %rax
	mov	%rax, -40(%rbp)
m_L3723:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3724
	lea	m_ostr3726(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3724:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_integer__3Estring__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3728:
	.asciz "integer->string/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3729:
	.8byte	61
	.8byte	m_cstr3728
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_integer__3Estring_2Fevaluator_stub:
	.8byte	m_integer__3Estring_2Fevaluator_stub__code
	.8byte	m_ostr3729
	.globl m_integer__3Estring_2Fevaluator_stub__code
	.type m_integer__3Estring_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3731:
	.asciz "string->number: failed for "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3732:
	.8byte	55
	.8byte	m_cstr3731
	.text
m_string__3Enumber__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_string__3Elong_2A__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L3730
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3732(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3730:
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3734:
	.asciz "string->number"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3735:
	.8byte	29
	.8byte	m_cstr3734
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string__3Enumber:
	.8byte	m_string__3Enumber__code
	.8byte	m_ostr3735
	.globl m_string__3Enumber__code
	.type m_string__3Enumber__code, @function
	.section .rodata
m_cstr3738:
	.asciz "string->number"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3739:
	.8byte	29
	.8byte	m_cstr3738
	.section .rodata
m_cstr3740:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3741:
	.8byte	15
	.8byte	m_cstr3740
	.section .rodata
m_cstr3742:
	.asciz "str"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3743:
	.8byte	7
	.8byte	m_cstr3742
	.section .rodata
m_cstr3744:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3745:
	.8byte	35
	.8byte	m_cstr3744
	.section .rodata
m_cstr3746:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3747:
	.8byte	17
	.8byte	m_cstr3746
	.section .rodata
m_cstr3749:
	.asciz "string->number"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3750:
	.8byte	29
	.8byte	m_cstr3749
	.section .rodata
m_cstr3753:
	.asciz "string->number"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3754:
	.8byte	29
	.8byte	m_cstr3753
	.section .rodata
m_cstr3755:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3756:
	.8byte	15
	.8byte	m_cstr3755
	.section .rodata
m_cstr3757:
	.asciz "radix"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3758:
	.8byte	11
	.8byte	m_cstr3757
	.section .rodata
m_cstr3759:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3760:
	.8byte	35
	.8byte	m_cstr3759
	.section .rodata
m_cstr3761:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3762:
	.8byte	13
	.8byte	m_cstr3761
	.section .rodata
m_cstr3765:
	.asciz "string->number"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3766:
	.8byte	29
	.8byte	m_cstr3765
	.text
m_string__3Enumber_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3736
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3737
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3739(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3741(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3743(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3745(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3747(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3737:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3748
m_L3736:
	lea	m_ostr3750(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3748:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3751
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3752
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3754(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3756(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3758(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3760(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3762(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3752:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3763
m_L3751:
	mov	$10, %rax
	mov	%rax, -40(%rbp)
m_L3763:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3764
	lea	m_ostr3766(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3764:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_string__3Enumber__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3768:
	.asciz "string->number/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3769:
	.8byte	59
	.8byte	m_cstr3768
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string__3Enumber_2Fevaluator_stub:
	.8byte	m_string__3Enumber_2Fevaluator_stub__code
	.8byte	m_ostr3769
	.globl m_string__3Enumber_2Fevaluator_stub__code
	.type m_string__3Enumber_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3771:
	.asciz "string->integer: failed for "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3772:
	.8byte	57
	.8byte	m_cstr3771
	.text
m_string__3Einteger__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_string__3Elong_2A__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	cmp	-32(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L3770
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3772(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3770:
	mov	-24(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3774:
	.asciz "string->integer"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3775:
	.8byte	31
	.8byte	m_cstr3774
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string__3Einteger:
	.8byte	m_string__3Einteger__code
	.8byte	m_ostr3775
	.globl m_string__3Einteger__code
	.type m_string__3Einteger__code, @function
	.section .rodata
m_cstr3778:
	.asciz "string->integer"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3779:
	.8byte	31
	.8byte	m_cstr3778
	.section .rodata
m_cstr3780:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3781:
	.8byte	15
	.8byte	m_cstr3780
	.section .rodata
m_cstr3782:
	.asciz "str"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3783:
	.8byte	7
	.8byte	m_cstr3782
	.section .rodata
m_cstr3784:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3785:
	.8byte	35
	.8byte	m_cstr3784
	.section .rodata
m_cstr3786:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3787:
	.8byte	17
	.8byte	m_cstr3786
	.section .rodata
m_cstr3789:
	.asciz "string->integer"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3790:
	.8byte	31
	.8byte	m_cstr3789
	.section .rodata
m_cstr3793:
	.asciz "string->integer"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3794:
	.8byte	31
	.8byte	m_cstr3793
	.section .rodata
m_cstr3795:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3796:
	.8byte	15
	.8byte	m_cstr3795
	.section .rodata
m_cstr3797:
	.asciz "radix"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3798:
	.8byte	11
	.8byte	m_cstr3797
	.section .rodata
m_cstr3799:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3800:
	.8byte	35
	.8byte	m_cstr3799
	.section .rodata
m_cstr3801:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3802:
	.8byte	13
	.8byte	m_cstr3801
	.section .rodata
m_cstr3805:
	.asciz "string->integer"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3806:
	.8byte	31
	.8byte	m_cstr3805
	.text
m_string__3Einteger_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3776
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3777
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3779(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3781(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3783(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3785(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3787(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3777:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3788
m_L3776:
	lea	m_ostr3790(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3788:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3791
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3792
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3794(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3796(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3798(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3800(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3802(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3792:
	mov	-40(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3803
m_L3791:
	mov	$10, %rax
	mov	%rax, -40(%rbp)
m_L3803:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3804
	lea	m_ostr3806(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3804:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_string__3Einteger__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3808:
	.asciz "string->integer/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3809:
	.8byte	61
	.8byte	m_cstr3808
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_string__3Einteger_2Fevaluator_stub:
	.8byte	m_string__3Einteger_2Fevaluator_stub__code
	.8byte	m_ostr3809
	.globl m_string__3Einteger_2Fevaluator_stub__code
	.type m_string__3Einteger_2Fevaluator_stub__code, @function
	.text
m_lower_2F_24put_all__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m__24put_all__code
	add	$0, %rsp
	add	$0, %rsp
	leave
	ret
	.section .rodata
m_cstr3810:
	.asciz "lower/$put-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3811:
	.8byte	29
	.8byte	m_cstr3810
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_lower_2F_24put_all:
	.8byte	m_lower_2F_24put_all__code
	.8byte	m_ostr3811
	.globl m_lower_2F_24put_all__code
	.type m_lower_2F_24put_all__code, @function
	.section .rodata
m_cstr3814:
	.asciz "lower/$put-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3815:
	.8byte	29
	.8byte	m_cstr3814
	.section .rodata
m_cstr3818:
	.asciz "lower/$put-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3819:
	.8byte	29
	.8byte	m_cstr3818
	.section .rodata
m_cstr3821:
	.asciz "lower/$put-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3822:
	.8byte	29
	.8byte	m_cstr3821
	.text
m_lower_2F_24put_all_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3812
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3813
m_L3812:
	lea	m_ostr3815(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3813:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3816
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3817
m_L3816:
	lea	m_ostr3819(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3817:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3820
	lea	m_ostr3822(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3820:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	m_lower_2F_24put_all__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3824:
	.asciz "lower/$put-all/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3825:
	.8byte	59
	.8byte	m_cstr3824
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_lower_2F_24put_all_2Fevaluator_stub:
	.8byte	m_lower_2F_24put_all_2Fevaluator_stub__code
	.8byte	m_ostr3825
	.globl m_lower_2F_24put_all_2Fevaluator_stub__code
	.type m_lower_2F_24put_all_2Fevaluator_stub__code, @function
	.text
m_pointer__3Etarget_function__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	$19, %rdi
	movq	$2, %rsi
	call	m_allocate__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, %rcx
	mov	-24(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3826:
	.asciz "pointer->target-function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3827:
	.8byte	49
	.8byte	m_cstr3826
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_pointer__3Etarget_function:
	.8byte	m_pointer__3Etarget_function__code
	.8byte	m_ostr3827
	.globl m_pointer__3Etarget_function__code
	.type m_pointer__3Etarget_function__code, @function
	.section .rodata
m_cstr3830:
	.asciz "pointer->target-function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3831:
	.8byte	49
	.8byte	m_cstr3830
	.section .rodata
m_cstr3833:
	.asciz "pointer->target-function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3834:
	.8byte	49
	.8byte	m_cstr3833
	.text
m_pointer__3Etarget_function_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3828
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3829
m_L3828:
	lea	m_ostr3831(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3829:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3832
	lea	m_ostr3834(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3832:
	movq	-32(%rbp), %rdi
	call	m_pointer__3Etarget_function__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3836:
	.asciz "pointer->target-function/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3837:
	.8byte	79
	.8byte	m_cstr3836
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_pointer__3Etarget_function_2Fevaluator_stub:
	.8byte	m_pointer__3Etarget_function_2Fevaluator_stub__code
	.8byte	m_ostr3837
	.globl m_pointer__3Etarget_function_2Fevaluator_stub__code
	.type m_pointer__3Etarget_function_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3839:
	.asciz "call-x86-64-machine-code: cannot call object of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3840:
	.8byte	107
	.8byte	m_cstr3839
	.section .rodata
m_cstr3841:
	.asciz ", printing as "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3842:
	.8byte	29
	.8byte	m_cstr3841
	.text
m_call_x86_64_machine_code__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	xor	%rax, %rax
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$19, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L3838
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3840(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3842(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-8(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3838:
	mov	-8(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -16(%rbp)
	xor	%rax, %rax
	mov	-16(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3843:
	.asciz "call-x86-64-machine-code"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3844:
	.8byte	49
	.8byte	m_cstr3843
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_call_x86_64_machine_code:
	.8byte	m_call_x86_64_machine_code__code
	.8byte	m_ostr3844
	.globl m_call_x86_64_machine_code__code
	.type m_call_x86_64_machine_code__code, @function
	.section .rodata
m_cstr3847:
	.asciz "call-x86-64-machine-code"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3848:
	.8byte	49
	.8byte	m_cstr3847
	.section .rodata
m_cstr3850:
	.asciz "call-x86-64-machine-code"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3851:
	.8byte	49
	.8byte	m_cstr3850
	.text
m_call_x86_64_machine_code_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3845
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3846
m_L3845:
	lea	m_ostr3848(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3846:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3849
	lea	m_ostr3851(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3849:
	movq	-32(%rbp), %rdi
	call	m_call_x86_64_machine_code__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3853:
	.asciz "call-x86-64-machine-code/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3854:
	.8byte	79
	.8byte	m_cstr3853
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_call_x86_64_machine_code_2Fevaluator_stub:
	.8byte	m_call_x86_64_machine_code_2Fevaluator_stub__code
	.8byte	m_ostr3854
	.globl m_call_x86_64_machine_code_2Fevaluator_stub__code
	.type m_call_x86_64_machine_code_2Fevaluator_stub__code, @function
	.text
m_spawn_program__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	movq	%r8, -40(%rbp)
	xor	%rax, %rax
	movq	-16(%rbp), %rdi
	movq	$1, %rsi
	call	m_to_lower_array__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	movq	-8(%rbp), %rdi
	call	m__25string__3EC_string__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	mov	-56(%rbp), %rax
	mov	%rax, -64(%rbp)
	mov	-48(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rcx
	mov	-64(%rbp), %rax
	mov	%rax, (%rcx)
	movq	-48(%rbp), %rdi
	call	m_memory_block_2Flength__code
	add	$0, %rsp
	xor	%rdx, %rdx
	mov	$8, %rcx
	idiv	%rcx
	mov	%rax, -64(%rbp)
	movq	-48(%rbp), %rdi
	movq	-64(%rbp), %rsi
	call	m_memory_block_2Fensure_capacity_2Fcell__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	mov	%rax, -72(%rbp)
	mov	-48(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	-72(%rbp), %rcx
	lea	(%rax, %rcx, 8), %rcx
	mov	$0, %rax
	mov	%rax, (%rcx)
	mov	-48(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, %rbx
	call	m_posix_2Fenvp__code
	add	$0, %rsp
	mov	%rax, %r12
	movq	-56(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	-32(%rbp), %rcx
	movq	-40(%rbp), %r8
	call	m_posix_2Fspawn_program__code
	add	$0, %rsp
	shl	$1, %rax
	or	$1, %rax
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3855:
	.asciz "spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3856:
	.8byte	27
	.8byte	m_cstr3855
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_spawn_program:
	.8byte	m_spawn_program__code
	.8byte	m_ostr3856
	.globl m_spawn_program__code
	.type m_spawn_program__code, @function
	.section .rodata
m_cstr3859:
	.asciz "spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3860:
	.8byte	27
	.8byte	m_cstr3859
	.section .rodata
m_cstr3861:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3862:
	.8byte	15
	.8byte	m_cstr3861
	.section .rodata
m_cstr3863:
	.asciz "path"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3864:
	.8byte	9
	.8byte	m_cstr3863
	.section .rodata
m_cstr3865:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3866:
	.8byte	35
	.8byte	m_cstr3865
	.section .rodata
m_cstr3867:
	.asciz "<string>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3868:
	.8byte	17
	.8byte	m_cstr3867
	.section .rodata
m_cstr3870:
	.asciz "spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3871:
	.8byte	27
	.8byte	m_cstr3870
	.section .rodata
m_cstr3874:
	.asciz "spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3875:
	.8byte	27
	.8byte	m_cstr3874
	.section .rodata
m_cstr3878:
	.asciz "spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3879:
	.8byte	27
	.8byte	m_cstr3878
	.section .rodata
m_cstr3882:
	.asciz "spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3883:
	.8byte	27
	.8byte	m_cstr3882
	.section .rodata
m_cstr3884:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3885:
	.8byte	15
	.8byte	m_cstr3884
	.section .rodata
m_cstr3886:
	.asciz "stdout-fd"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3887:
	.8byte	19
	.8byte	m_cstr3886
	.section .rodata
m_cstr3888:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3889:
	.8byte	35
	.8byte	m_cstr3888
	.section .rodata
m_cstr3890:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3891:
	.8byte	13
	.8byte	m_cstr3890
	.section .rodata
m_cstr3895:
	.asciz "spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3896:
	.8byte	27
	.8byte	m_cstr3895
	.section .rodata
m_cstr3897:
	.asciz ": arg '"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3898:
	.8byte	15
	.8byte	m_cstr3897
	.section .rodata
m_cstr3899:
	.asciz "stderr-fd"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3900:
	.8byte	19
	.8byte	m_cstr3899
	.section .rodata
m_cstr3901:
	.asciz "' is not of type "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3902:
	.8byte	35
	.8byte	m_cstr3901
	.section .rodata
m_cstr3903:
	.asciz "<long>"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3904:
	.8byte	13
	.8byte	m_cstr3903
	.section .rodata
m_cstr3907:
	.asciz "spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3908:
	.8byte	27
	.8byte	m_cstr3907
	.text
m_spawn_program_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	xor	%rax, %rax
	mov	%rax, -56(%rbp)
	xor	%rax, %rax
	mov	%rax, -64(%rbp)
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3857
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3858
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3860(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3862(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3864(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3866(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3868(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3858:
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3869
m_L3857:
	lea	m_ostr3871(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3869:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3872
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -40(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3873
m_L3872:
	lea	m_ostr3875(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3873:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3876
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -48(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3877
m_L3876:
	lea	m_ostr3879(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25not_enough_arguments__code
	add	$0, %rsp
m_L3877:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3880
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3881
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3883(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3885(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3887(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3889(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3891(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3881:
	mov	-56(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -56(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3892
m_L3880:
	mov	$-1, %rax
	mov	%rax, -56(%rbp)
m_L3892:
	movq	-24(%rbp), %rdi
	call	m_pair_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3893
	mov	-24(%rbp), %rax
	mov	(%rax), %rax
	mov	%rax, -64(%rbp)
	movq	-64(%rbp), %rdi
	call	m_long_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L3894
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3896(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3898(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3900(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3902(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	lea	m_ostr3904(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3894:
	mov	-64(%rbp), %rax
	sar	$1, %rax
	mov	%rax, -64(%rbp)
	mov	-24(%rbp), %rax
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	mov	%rax, -24(%rbp)
	jmp	m_L3905
m_L3893:
	mov	$-1, %rax
	mov	%rax, -64(%rbp)
m_L3905:
	mov	-24(%rbp), %rax
	test	%rax, %rax
	je	m_L3906
	lea	m_ostr3908(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m__25too_many_arguments__code
	add	$0, %rsp
m_L3906:
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	movq	-48(%rbp), %rdx
	movq	-56(%rbp), %rcx
	movq	-64(%rbp), %r8
	call	m_spawn_program__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3910:
	.asciz "spawn-program/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3911:
	.8byte	57
	.8byte	m_cstr3910
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_spawn_program_2Fevaluator_stub:
	.8byte	m_spawn_program_2Fevaluator_stub__code
	.8byte	m_ostr3911
	.globl m_spawn_program_2Fevaluator_stub__code
	.type m_spawn_program_2Fevaluator_stub__code, @function
	.section .rodata
m_cstr3914:
	.asciz "spawn-program returned exit code: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3915:
	.8byte	69
	.8byte	m_cstr3914
	.text
m_waitpid_or_die__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rdi
	movq	$0, %rsi
	call	m_posix_2Fwaitpid__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	-16(%rbp), %rax
	mov	%rax, -24(%rbp)
	xor	%rax, %rax
	cmp	-24(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L3912
	xor	%rax, %rax
	jmp	m_L3913
m_L3912:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3915(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	mov	-16(%rbp), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3913:
	mov	-16(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3916:
	.asciz "waitpid-or-die"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3917:
	.8byte	29
	.8byte	m_cstr3916
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_waitpid_or_die:
	.8byte	m_waitpid_or_die__code
	.8byte	m_ostr3917
	.globl m_waitpid_or_die__code
	.type m_waitpid_or_die__code, @function
	.text
m_run_program_2Fstdout_2Fslurp__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	xor	%rax, %rax
	mov	%rax, -32(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	xor	%rax, %rax
	mov	%rax, -48(%rbp)
	lea	-32(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	$293, %rax
	mov	-56(%rbp), %rdi
	mov	$0, %rsi
	syscall
	mov	%rax, %rbx
	movq	$293, %rdi
	movq	%rbx, %rsi
	call	m__25syscall_rc_assert__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	movq	$4294967295, %rbx
	and	%rbx, %rax
	mov	%rax, -40(%rbp)
	mov	-32(%rbp), %rax
	sar	$32, %rax
	mov	%rax, -48(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	movq	-48(%rbp), %rcx
	movq	$-1, %r8
	call	m_spawn_program__code
	add	$0, %rsp
	sar	$1, %rax
	mov	%rax, -56(%rbp)
	movq	-48(%rbp), %rdi
	call	m_posix_2Fclose__code
	add	$0, %rsp
	movq	$16, %rdi
	call	m_string__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	xor	%rax, %rax
	mov	%rax, -72(%rbp)
	jmp	m_L3919
m_L3918:
	movq	-64(%rbp), %rdi
	movq	-72(%rbp), %rsi
	call	m_string_append__code
	add	$0, %rsp
m_L3919:
	movq	-40(%rbp), %rdi
	call	m_posix_2Fread_byte__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	mov	%rax, -80(%rbp)
	xor	%rax, %rax
	cmp	-80(%rbp), %rax
	setle	%al
	movzb	%al, %rax
	test	%rax, %rax
	jne	m_L3918
	movq	-40(%rbp), %rdi
	call	m_posix_2Fclose__code
	add	$0, %rsp
	movq	-56(%rbp), %rdi
	call	m_waitpid_or_die__code
	add	$0, %rsp
	mov	-64(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3920:
	.asciz "run-program/stdout/slurp"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3921:
	.8byte	49
	.8byte	m_cstr3920
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_run_program_2Fstdout_2Fslurp:
	.8byte	m_run_program_2Fstdout_2Fslurp__code
	.8byte	m_ostr3921
	.globl m_run_program_2Fstdout_2Fslurp__code
	.type m_run_program_2Fstdout_2Fslurp__code, @function
	.text
m_run_program_2Fstdout_2Ffile__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$48, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	mov	$1, %rax
	or	$64, %rax
	or	$512, %rax
	mov	%rax, %rbx
	movq	-32(%rbp), %rdi
	movq	%rbx, %rsi
	movq	$420, %rdx
	call	m_posix_2Fopen__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	movq	-24(%rbp), %rdx
	movq	-40(%rbp), %rcx
	movq	$-1, %r8
	call	m_spawn_program__code
	add	$0, %rsp
	sar	$1, %rax
	mov	%rax, -48(%rbp)
	movq	-40(%rbp), %rdi
	call	m_posix_2Fclose__code
	add	$0, %rsp
	movq	-48(%rbp), %rdi
	call	m_waitpid_or_die__code
	add	$0, %rsp
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3922:
	.asciz "run-program/stdout/file"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3923:
	.8byte	47
	.8byte	m_cstr3922
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_run_program_2Fstdout_2Ffile:
	.8byte	m_run_program_2Fstdout_2Ffile__code
	.8byte	m_ostr3923
	.globl m_run_program_2Fstdout_2Ffile__code
	.type m_run_program_2Fstdout_2Ffile__code, @function
	.section .rodata
m_cstr3925:
	.asciz "run-program/capture: path is mandatory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3926:
	.8byte	77
	.8byte	m_cstr3925
	.section .rodata
m_cstr3931:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3932:
	.8byte	13
	.8byte	m_cstr3931
	.section .rodata
m_cstr3936:
	.asciz "run-program: unexpected stdout value: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3937:
	.8byte	77
	.8byte	m_cstr3936
	.text
m_run_program_2Fevaluator_stub__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$80, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -24(%rbp)
	movq	-24(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -32(%rbp)
	movq	-24(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-32(%rbp), %rax
	test	%rax, %rax
	jne	m_L3924
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3926(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3924:
	mov	%rax, -24(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -32(%rbp)
	movq	-32(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	movq	-32(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-40(%rbp), %rax
	mov	%rax, -32(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -40(%rbp)
	movq	-40(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	movq	-40(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-48(%rbp), %rax
	mov	%rax, -40(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -48(%rbp)
	movq	-48(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	movq	-48(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-56(%rbp), %rax
	mov	%rax, -48(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -56(%rbp)
	movq	-56(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -64(%rbp)
	movq	-56(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-64(%rbp), %rax
	mov	%rax, -56(%rbp)
	mov	-8(%rbp), %rax
	mov	%rax, -64(%rbp)
	movq	-64(%rbp), %rdi
	call	m_car__code
	add	$0, %rsp
	mov	%rax, -72(%rbp)
	movq	-64(%rbp), %rdi
	call	m_cdr__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	mov	-72(%rbp), %rax
	mov	%rax, -64(%rbp)
	xor	%rax, %rax
	mov	%rax, -40(%rbp)
	movq	-56(%rbp), %rdi
	call	m_string_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3927
	movq	-56(%rbp), %rdi
	call	m__25string__3EC_string__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	movq	-40(%rbp), %rdx
	movq	%rbx, %rcx
	call	m_run_program_2Fstdout_2Ffile__code
	add	$0, %rsp
	jmp	m_L3928
m_L3927:
	movq	-56(%rbp), %rdi
	call	m_symbol_3F__code
	add	$0, %rsp
	test	%rax, %rax
	je	m_L3930
	lea	m_ostr3932(%rip), %rax
	mov	%rax, %rbx
	movq	-56(%rbp), %rdi
	call	m_symbol__3Estring__code
	add	$0, %rsp
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_string_3D__code
	add	$0, %rsp
m_L3930:
	test	%rax, %rax
	je	m_L3929
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	movq	-40(%rbp), %rdx
	call	m_run_program_2Fstdout_2Fslurp__code
	add	$0, %rsp
	jmp	m_L3933
m_L3929:
	mov	-56(%rbp), %rax
	mov	%rax, -72(%rbp)
	xor	%rax, %rax
	cmp	-72(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L3934
	movq	-24(%rbp), %rdi
	movq	-32(%rbp), %rsi
	movq	-40(%rbp), %rdx
	movq	$-1, %rcx
	movq	$-1, %r8
	call	m_spawn_program__code
	add	$0, %rsp
	sar	$1, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_waitpid_or_die__code
	add	$0, %rsp
	jmp	m_L3935
m_L3934:
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr3937(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	movq	-56(%rbp), %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L3935:
m_L3933:
m_L3928:
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3938:
	.asciz "run-program/evaluator-stub"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3939:
	.8byte	53
	.8byte	m_cstr3938
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_run_program_2Fevaluator_stub:
	.8byte	m_run_program_2Fevaluator_stub__code
	.8byte	m_ostr3939
	.globl m_run_program_2Fevaluator_stub__code
	.type m_run_program_2Fevaluator_stub__code, @function
	.text
m__25instantiate_vm_function__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$64, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	movq	%rcx, -32(%rbp)
	xor	%rax, %rax
	mov	$20, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-24(%rbp), %rsi
	call	m__25allocate_boxed_word__code
	add	$0, %rsp
	mov	%rax, -40(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	-40(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_vm_function__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	test	%rax, %rax
	je	m_L3940
	movq	-48(%rbp), %rdi
	call	m_fixed__code
	add	$0, %rsp
	mov	%rax, -48(%rbp)
m_L3940:
	movq	-16(%rbp), %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-48(%rbp), %rdx
	call	m_environment_define__code
	add	$0, %rsp
	mov	%rax, -56(%rbp)
	lea	-48(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-56(%rbp), %rax
	mov	%rax, -48(%rbp)
	lea	-40(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-48(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr3942:
	.asciz "%instantiate-vm-function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3943:
	.8byte	49
	.8byte	m_cstr3942
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m__25instantiate_vm_function:
	.8byte	m__25instantiate_vm_function__code
	.8byte	m_ostr3943
	.globl m__25instantiate_vm_function__code
	.type m__25instantiate_vm_function__code, @function
	.section .rodata
m_cstr3945:
	.asciz "+end+"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3946:
	.8byte	11
	.8byte	m_cstr3945
	.section .rodata
m_cstr3947:
	.asciz "+end+"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3948:
	.8byte	11
	.8byte	m_cstr3947
	.section .rodata
m_cstr3949:
	.asciz "run-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3950:
	.8byte	23
	.8byte	m_cstr3949
	.section .rodata
m_cstr3951:
	.asciz "spawn-program"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3952:
	.8byte	27
	.8byte	m_cstr3951
	.section .rodata
m_cstr3953:
	.asciz "call-x86-64-machine-code"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3954:
	.8byte	49
	.8byte	m_cstr3953
	.section .rodata
m_cstr3955:
	.asciz "pointer->target-function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3956:
	.8byte	49
	.8byte	m_cstr3955
	.section .rodata
m_cstr3957:
	.asciz "lower/$put-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3958:
	.8byte	29
	.8byte	m_cstr3957
	.section .rodata
m_cstr3959:
	.asciz "string->integer"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3960:
	.8byte	31
	.8byte	m_cstr3959
	.section .rodata
m_cstr3961:
	.asciz "string->number"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3962:
	.8byte	29
	.8byte	m_cstr3961
	.section .rodata
m_cstr3963:
	.asciz "integer->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3964:
	.8byte	31
	.8byte	m_cstr3963
	.section .rodata
m_cstr3965:
	.asciz "number->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3966:
	.8byte	29
	.8byte	m_cstr3965
	.section .rodata
m_cstr3967:
	.asciz "string-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3968:
	.8byte	27
	.8byte	m_cstr3967
	.section .rodata
m_cstr3969:
	.asciz "array-append"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3970:
	.8byte	25
	.8byte	m_cstr3969
	.section .rodata
m_cstr3971:
	.asciz "string-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3972:
	.8byte	27
	.8byte	m_cstr3971
	.section .rodata
m_cstr3973:
	.asciz "array-insert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3974:
	.8byte	25
	.8byte	m_cstr3973
	.section .rodata
m_cstr3975:
	.asciz "set-char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3976:
	.8byte	23
	.8byte	m_cstr3975
	.section .rodata
m_cstr3977:
	.asciz "set-string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3978:
	.8byte	27
	.8byte	m_cstr3977
	.section .rodata
m_cstr3979:
	.asciz "set-array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3980:
	.8byte	25
	.8byte	m_cstr3979
	.section .rodata
m_cstr3981:
	.asciz "char-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3982:
	.8byte	15
	.8byte	m_cstr3981
	.section .rodata
m_cstr3983:
	.asciz "string-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3984:
	.8byte	19
	.8byte	m_cstr3983
	.section .rodata
m_cstr3985:
	.asciz "array-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3986:
	.8byte	17
	.8byte	m_cstr3985
	.section .rodata
m_cstr3987:
	.asciz "string-compare"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3988:
	.8byte	29
	.8byte	m_cstr3987
	.section .rodata
m_cstr3989:
	.asciz "string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3990:
	.8byte	27
	.8byte	m_cstr3989
	.section .rodata
m_cstr3991:
	.asciz "array-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3992:
	.8byte	25
	.8byte	m_cstr3991
	.section .rodata
m_cstr3993:
	.asciz "long->lower-cell"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3994:
	.8byte	33
	.8byte	m_cstr3993
	.section .rodata
m_cstr3995:
	.asciz "lower-cell->long"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3996:
	.8byte	33
	.8byte	m_cstr3995
	.section .rodata
m_cstr3997:
	.asciz "set-oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr3998:
	.8byte	21
	.8byte	m_cstr3997
	.section .rodata
m_cstr3999:
	.asciz "oop-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4000:
	.8byte	13
	.8byte	m_cstr3999
	.section .rodata
m_cstr4001:
	.asciz "set-cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4002:
	.8byte	15
	.8byte	m_cstr4001
	.section .rodata
m_cstr4003:
	.asciz "set-car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4004:
	.8byte	15
	.8byte	m_cstr4003
	.section .rodata
m_cstr4005:
	.asciz "array?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4006:
	.8byte	13
	.8byte	m_cstr4005
	.section .rodata
m_cstr4007:
	.asciz "pair?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4008:
	.8byte	11
	.8byte	m_cstr4007
	.section .rodata
m_cstr4009:
	.asciz "symbol?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4010:
	.8byte	15
	.8byte	m_cstr4009
	.section .rodata
m_cstr4011:
	.asciz "string?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4012:
	.8byte	15
	.8byte	m_cstr4011
	.section .rodata
m_cstr4013:
	.asciz "type-of"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4014:
	.8byte	15
	.8byte	m_cstr4013
	.section .rodata
m_cstr4015:
	.asciz "warn"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4016:
	.8byte	9
	.8byte	m_cstr4015
	.section .rodata
m_cstr4017:
	.asciz "exit"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4018:
	.8byte	9
	.8byte	m_cstr4017
	.section .rodata
m_cstr4019:
	.asciz "="
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4020:
	.8byte	3
	.8byte	m_cstr4019
	.section .rodata
m_cstr4021:
	.asciz ">"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4022:
	.8byte	3
	.8byte	m_cstr4021
	.section .rodata
m_cstr4023:
	.asciz ">="
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4024:
	.8byte	5
	.8byte	m_cstr4023
	.section .rodata
m_cstr4025:
	.asciz "<="
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4026:
	.8byte	5
	.8byte	m_cstr4025
	.section .rodata
m_cstr4027:
	.asciz "<"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4028:
	.8byte	3
	.8byte	m_cstr4027
	.section .rodata
m_cstr4029:
	.asciz "bitwise-shift"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4030:
	.8byte	27
	.8byte	m_cstr4029
	.section .rodata
m_cstr4031:
	.asciz "bitwise-not"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4032:
	.8byte	23
	.8byte	m_cstr4031
	.section .rodata
m_cstr4033:
	.asciz "bitwise-xor"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4034:
	.8byte	23
	.8byte	m_cstr4033
	.section .rodata
m_cstr4035:
	.asciz "bitwise-or"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4036:
	.8byte	21
	.8byte	m_cstr4035
	.section .rodata
m_cstr4037:
	.asciz "bitwise-and"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4038:
	.8byte	23
	.8byte	m_cstr4037
	.section .rodata
m_cstr4039:
	.asciz "*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4040:
	.8byte	3
	.8byte	m_cstr4039
	.section .rodata
m_cstr4041:
	.asciz "/"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4042:
	.8byte	3
	.8byte	m_cstr4041
	.section .rodata
m_cstr4043:
	.asciz "+"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4044:
	.8byte	3
	.8byte	m_cstr4043
	.section .rodata
m_cstr4045:
	.asciz "-"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4046:
	.8byte	3
	.8byte	m_cstr4045
	.section .rodata
m_cstr4047:
	.asciz "not"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4048:
	.8byte	7
	.8byte	m_cstr4047
	.section .rodata
m_cstr4049:
	.asciz "quote"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4050:
	.8byte	11
	.8byte	m_cstr4049
	.section .rodata
m_cstr4051:
	.asciz "and"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4052:
	.8byte	7
	.8byte	m_cstr4051
	.section .rodata
m_cstr4053:
	.asciz "or"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4054:
	.8byte	5
	.8byte	m_cstr4053
	.section .rodata
m_cstr4055:
	.asciz "if"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4056:
	.8byte	5
	.8byte	m_cstr4055
	.section .rodata
m_cstr4057:
	.asciz "while"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4058:
	.8byte	11
	.8byte	m_cstr4057
	.section .rodata
m_cstr4059:
	.asciz "set"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4060:
	.8byte	7
	.8byte	m_cstr4059
	.section .rodata
m_cstr4061:
	.asciz "let"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4062:
	.8byte	7
	.8byte	m_cstr4061
	.section .rodata
m_cstr4063:
	.asciz "lambda"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4064:
	.8byte	13
	.8byte	m_cstr4063
	.section .rodata
m_cstr4065:
	.asciz "eval"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4066:
	.8byte	9
	.8byte	m_cstr4065
	.section .rodata
m_cstr4067:
	.asciz "define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4068:
	.8byte	13
	.8byte	m_cstr4067
	.section .rodata
m_cstr4069:
	.asciz "load"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4070:
	.8byte	9
	.8byte	m_cstr4069
	.section .rodata
m_cstr4071:
	.asciz "repl-stream"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4072:
	.8byte	23
	.8byte	m_cstr4071
	.section .rodata
m_cstr4073:
	.asciz "file-stream"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4074:
	.8byte	23
	.8byte	m_cstr4073
	.section .rodata
m_cstr4075:
	.asciz "file-modification-time"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4076:
	.8byte	45
	.8byte	m_cstr4075
	.section .rodata
m_cstr4077:
	.asciz "file-write-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4078:
	.8byte	31
	.8byte	m_cstr4077
	.section .rodata
m_cstr4079:
	.asciz "file-read-byte"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4080:
	.8byte	29
	.8byte	m_cstr4079
	.section .rodata
m_cstr4081:
	.asciz "file-close"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4082:
	.8byte	21
	.8byte	m_cstr4081
	.section .rodata
m_cstr4083:
	.asciz "file-open"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4084:
	.8byte	19
	.8byte	m_cstr4083
	.section .rodata
m_cstr4085:
	.asciz "set-working-directory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4086:
	.8byte	43
	.8byte	m_cstr4085
	.section .rodata
m_cstr4087:
	.asciz "working-directory"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4088:
	.8byte	35
	.8byte	m_cstr4087
	.section .rodata
m_cstr4089:
	.asciz "encode"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4090:
	.8byte	13
	.8byte	m_cstr4089
	.section .rodata
m_cstr4091:
	.asciz "expand"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4092:
	.8byte	13
	.8byte	m_cstr4091
	.section .rodata
m_cstr4093:
	.asciz "apply"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4094:
	.8byte	11
	.8byte	m_cstr4093
	.section .rodata
m_cstr4095:
	.asciz "print-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4096:
	.8byte	19
	.8byte	m_cstr4095
	.section .rodata
m_cstr4097:
	.asciz "dump-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4098:
	.8byte	17
	.8byte	m_cstr4097
	.section .rodata
m_cstr4099:
	.asciz "print"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4100:
	.8byte	11
	.8byte	m_cstr4099
	.section .rodata
m_cstr4101:
	.asciz "dump"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4102:
	.8byte	9
	.8byte	m_cstr4101
	.section .rodata
m_cstr4103:
	.asciz "read"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4104:
	.8byte	9
	.8byte	m_cstr4103
	.section .rodata
m_cstr4105:
	.asciz "set-current-globals"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4106:
	.8byte	39
	.8byte	m_cstr4105
	.section .rodata
m_cstr4107:
	.asciz "current-globals"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4108:
	.8byte	31
	.8byte	m_cstr4107
	.section .rodata
m_cstr4109:
	.asciz "environment-define"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4110:
	.8byte	37
	.8byte	m_cstr4109
	.section .rodata
m_cstr4111:
	.asciz "defined?"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4112:
	.8byte	17
	.8byte	m_cstr4111
	.section .rodata
m_cstr4113:
	.asciz "symbol->string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4114:
	.8byte	29
	.8byte	m_cstr4113
	.section .rodata
m_cstr4115:
	.asciz "string->symbol"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4116:
	.8byte	29
	.8byte	m_cstr4115
	.section .rodata
m_cstr4117:
	.asciz "set-string-length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4118:
	.8byte	35
	.8byte	m_cstr4117
	.section .rodata
m_cstr4119:
	.asciz "string-insert-all"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4120:
	.8byte	35
	.8byte	m_cstr4119
	.section .rodata
m_cstr4121:
	.asciz "set-cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4122:
	.8byte	23
	.8byte	m_cstr4121
	.section .rodata
m_cstr4123:
	.asciz "cell-at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4124:
	.8byte	15
	.8byte	m_cstr4123
	.section .rodata
m_cstr4125:
	.asciz "set-memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4126:
	.8byte	39
	.8byte	m_cstr4125
	.section .rodata
m_cstr4127:
	.asciz "memory-block/at"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4128:
	.8byte	31
	.8byte	m_cstr4127
	.section .rodata
m_cstr4129:
	.asciz "memory-block/length"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4130:
	.8byte	39
	.8byte	m_cstr4129
	.section .rodata
m_cstr4131:
	.asciz "memory-block->lower/function"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4132:
	.8byte	57
	.8byte	m_cstr4131
	.section .rodata
m_cstr4133:
	.asciz "memory-block"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4134:
	.8byte	25
	.8byte	m_cstr4133
	.section .rodata
m_cstr4135:
	.asciz "environment"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4136:
	.8byte	23
	.8byte	m_cstr4135
	.section .rodata
m_cstr4137:
	.asciz "variable"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4138:
	.8byte	17
	.8byte	m_cstr4137
	.section .rodata
m_cstr4139:
	.asciz "fixed"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4140:
	.8byte	11
	.8byte	m_cstr4139
	.section .rodata
m_cstr4141:
	.asciz "form"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4142:
	.8byte	9
	.8byte	m_cstr4141
	.section .rodata
m_cstr4143:
	.asciz "array"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4144:
	.8byte	11
	.8byte	m_cstr4143
	.section .rodata
m_cstr4145:
	.asciz "string"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4146:
	.8byte	13
	.8byte	m_cstr4145
	.section .rodata
m_cstr4147:
	.asciz "cons"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4148:
	.8byte	9
	.8byte	m_cstr4147
	.section .rodata
m_cstr4149:
	.asciz "allocate-data"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4150:
	.8byte	27
	.8byte	m_cstr4149
	.section .rodata
m_cstr4151:
	.asciz "allocate"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4152:
	.8byte	17
	.8byte	m_cstr4151
	.section .rodata
m_cstr4153:
	.asciz "cdr"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4154:
	.8byte	7
	.8byte	m_cstr4153
	.section .rodata
m_cstr4155:
	.asciz "car"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4156:
	.8byte	7
	.8byte	m_cstr4155
	.section .rodata
m_cstr4157:
	.asciz "abort"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4158:
	.8byte	11
	.8byte	m_cstr4157
	.text
m_code4159:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	sub	$8, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	$0, %rdi
	call	m_array__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	mov	%rax, -32(%rbp)
	movq	-16(%rbp), %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	test	%rax, %rax
	jne	m_L4160
	movq	-8(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	m_new_variable__code
	add	$0, %rsp
m_L4160:
	lea	8(%rax), %rcx
	mov	-32(%rbp), %rax
	mov	%rax, (%rcx)
	mov	%rax, -32(%rbp)
	lea	-24(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-32(%rbp), %rax
	add	$8, %rsp
	pop	%rbx
	leave
	ret
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_oclosure4161:
	.8byte	m_code4159
	.8byte	0
	.section .rodata
m_cstr4164:
	.asciz "populate-env-with-maru-primitives: final assert"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4165:
	.8byte	95
	.8byte	m_cstr4164
	.text
m_populate_env_with_maru_primitives__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$32, %rsp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	movq	%rdi, -8(%rbp)
	xor	%rax, %rax
	xor	%rax, %rax
	mov	%rax, -16(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	lea	m__2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -16(%rbp)
	lea	m_symbol_2F_2Averbosity_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-16(%rbp), %rdx
	call	m_environment_define__code
	add	$0, %rsp
	lea	m__2Aoptimised_2A(%rip), %rax
	mov	(%rax), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, -16(%rbp)
	lea	m_symbol_2F_2Aoptimised_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	-16(%rbp), %rdx
	call	m_environment_define__code
	add	$0, %rsp
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	test	%rax, %rax
	jne	m_L3944
	lea	m_ostr3946(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_symbol__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
m_L3944:
	lea	m__2Bend_2B(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr3948(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m__2Bend_2B(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	call	m_environment_define__code
	add	$0, %rsp
	mov	%rax, -24(%rbp)
	lea	-16(%rbp), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpop_root__code
	add	$0, %rsp
	mov	-24(%rbp), %rax
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2Ftrue(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	call	m_environment_define__code
	add	$0, %rsp
	xor	%rax, %rax
	lea	m_ostr3950(%rip), %rax
	mov	%rax, %rbx
	lea	m_run_program_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3952(%rip), %rax
	mov	%rax, %rbx
	lea	m_spawn_program_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3954(%rip), %rax
	mov	%rax, %rbx
	lea	m_call_x86_64_machine_code_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3956(%rip), %rax
	mov	%rax, %rbx
	lea	m_pointer__3Etarget_function_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3958(%rip), %rax
	mov	%rax, %rbx
	lea	m_lower_2F_24put_all_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3960(%rip), %rax
	mov	%rax, %rbx
	lea	m_string__3Einteger_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3962(%rip), %rax
	mov	%rax, %rbx
	lea	m_string__3Enumber_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3964(%rip), %rax
	mov	%rax, %rbx
	lea	m_integer__3Estring_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3966(%rip), %rax
	mov	%rax, %rbx
	lea	m_number__3Estring_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3968(%rip), %rax
	mov	%rax, %rbx
	lea	m_string_append_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3970(%rip), %rax
	mov	%rax, %rbx
	lea	m_array_append_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3972(%rip), %rax
	mov	%rax, %rbx
	lea	m_string_insert_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3974(%rip), %rax
	mov	%rax, %rbx
	lea	m_array_insert_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3976(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_char_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3978(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_string_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3980(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_array_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3982(%rip), %rax
	mov	%rax, %rbx
	lea	m_char_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3984(%rip), %rax
	mov	%rax, %rbx
	lea	m_string_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3986(%rip), %rax
	mov	%rax, %rbx
	lea	m_array_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3988(%rip), %rax
	mov	%rax, %rbx
	lea	m_string_compare_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3990(%rip), %rax
	mov	%rax, %rbx
	lea	m_string_length_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3992(%rip), %rax
	mov	%rax, %rbx
	lea	m_array_length_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3994(%rip), %rax
	mov	%rax, %rbx
	lea	m_long__3Elower_cell_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3996(%rip), %rax
	mov	%rax, %rbx
	lea	m_lower_cell__3Elong_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr3998(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_oop_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4000(%rip), %rax
	mov	%rax, %rbx
	lea	m_oop_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4002(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_cdr_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4004(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_car_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4006(%rip), %rax
	mov	%rax, %rbx
	lea	m_array_3F_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4008(%rip), %rax
	mov	%rax, %rbx
	lea	m_pair_3F_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4010(%rip), %rax
	mov	%rax, %rbx
	lea	m_symbol_3F_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4012(%rip), %rax
	mov	%rax, %rbx
	lea	m_string_3F_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4014(%rip), %rax
	mov	%rax, %rbx
	lea	m_type_of_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4016(%rip), %rax
	mov	%rax, %rbx
	lea	m_warn_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4018(%rip), %rax
	mov	%rax, %rbx
	lea	m_exit_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4020(%rip), %rax
	mov	%rax, %rbx
	lea	m__3D_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4022(%rip), %rax
	mov	%rax, %rbx
	lea	m__3E_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4024(%rip), %rax
	mov	%rax, %rbx
	lea	m__3E_3D_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4026(%rip), %rax
	mov	%rax, %rbx
	lea	m__3C_3D_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4028(%rip), %rax
	mov	%rax, %rbx
	lea	m__3C_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4030(%rip), %rax
	mov	%rax, %rbx
	lea	m_bitwise_shift_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4032(%rip), %rax
	mov	%rax, %rbx
	lea	m_bitwise_not_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4034(%rip), %rax
	mov	%rax, %rbx
	lea	m_bitwise_xor_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4036(%rip), %rax
	mov	%rax, %rbx
	lea	m_bitwise_or_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4038(%rip), %rax
	mov	%rax, %rbx
	lea	m_bitwise_and_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4040(%rip), %rax
	mov	%rax, %rbx
	lea	m__2A_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4042(%rip), %rax
	mov	%rax, %rbx
	lea	m__2F_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4044(%rip), %rax
	mov	%rax, %rbx
	lea	m__2B_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4046(%rip), %rax
	mov	%rax, %rbx
	lea	m___2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4048(%rip), %rax
	mov	%rax, %rbx
	lea	m_not_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4050(%rip), %rax
	mov	%rax, %rbx
	lea	m_quote_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$1, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4052(%rip), %rax
	mov	%rax, %rbx
	lea	m_and_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$1, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4054(%rip), %rax
	mov	%rax, %rbx
	lea	m_or_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$1, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4056(%rip), %rax
	mov	%rax, %rbx
	lea	m_if_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$1, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4058(%rip), %rax
	mov	%rax, %rbx
	lea	m_while_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$1, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4060(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$1, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4062(%rip), %rax
	mov	%rax, %rbx
	lea	m_let_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$1, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4064(%rip), %rax
	mov	%rax, %rbx
	lea	m_lambda_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$1, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4066(%rip), %rax
	mov	%rax, %rbx
	lea	m_eval_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4068(%rip), %rax
	mov	%rax, %rbx
	lea	m_define_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$1, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4070(%rip), %rax
	mov	%rax, %rbx
	lea	m_load_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4072(%rip), %rax
	mov	%rax, %rbx
	lea	m_repl_stream_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4074(%rip), %rax
	mov	%rax, %rbx
	lea	m_file_stream_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4076(%rip), %rax
	mov	%rax, %rbx
	lea	m_file_modification_time_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4078(%rip), %rax
	mov	%rax, %rbx
	lea	m_file_write_byte_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4080(%rip), %rax
	mov	%rax, %rbx
	lea	m_file_read_byte_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4082(%rip), %rax
	mov	%rax, %rbx
	lea	m_file_close_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4084(%rip), %rax
	mov	%rax, %rbx
	lea	m_file_open_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4086(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_working_directory_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4088(%rip), %rax
	mov	%rax, %rbx
	lea	m_working_directory_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4090(%rip), %rax
	mov	%rax, %rbx
	lea	m_encode_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4092(%rip), %rax
	mov	%rax, %rbx
	lea	m_expand_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4094(%rip), %rax
	mov	%rax, %rbx
	lea	m_apply_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4096(%rip), %rax
	mov	%rax, %rbx
	lea	m_print_all_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4098(%rip), %rax
	mov	%rax, %rbx
	lea	m_dump_all_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4100(%rip), %rax
	mov	%rax, %rbx
	lea	m_print_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4102(%rip), %rax
	mov	%rax, %rbx
	lea	m_dump_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4104(%rip), %rax
	mov	%rax, %rbx
	lea	m_read_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4106(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_current_globals_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4108(%rip), %rax
	mov	%rax, %rbx
	lea	m_current_globals_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4110(%rip), %rax
	mov	%rax, %rbx
	lea	m_environment_define_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4112(%rip), %rax
	mov	%rax, %rbx
	lea	m_defined_3F_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4114(%rip), %rax
	mov	%rax, %rbx
	lea	m_symbol__3Estring_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4116(%rip), %rax
	mov	%rax, %rbx
	lea	m_string__3Esymbol_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4118(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_string_length_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4120(%rip), %rax
	mov	%rax, %rbx
	lea	m_string_insert_all_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4122(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_cell_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4124(%rip), %rax
	mov	%rax, %rbx
	lea	m_cell_at_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4126(%rip), %rax
	mov	%rax, %rbx
	lea	m_set_memory_block_2Fat_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4128(%rip), %rax
	mov	%rax, %rbx
	lea	m_memory_block_2Fat_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4130(%rip), %rax
	mov	%rax, %rbx
	lea	m_memory_block_2Flength_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4132(%rip), %rax
	mov	%rax, %rbx
	lea	m_memory_block__3Elower_2Ffunction_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4134(%rip), %rax
	mov	%rax, %rbx
	lea	m_memory_block_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4136(%rip), %rax
	mov	%rax, %rbx
	lea	m_environment_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4138(%rip), %rax
	mov	%rax, %rbx
	lea	m_variable_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4140(%rip), %rax
	mov	%rax, %rbx
	lea	m_fixed_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4142(%rip), %rax
	mov	%rax, %rbx
	lea	m_form_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4144(%rip), %rax
	mov	%rax, %rbx
	lea	m_array_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4146(%rip), %rax
	mov	%rax, %rbx
	lea	m_string_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4148(%rip), %rax
	mov	%rax, %rbx
	lea	m_cons_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4150(%rip), %rax
	mov	%rax, %rbx
	lea	m_allocate_data_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4152(%rip), %rax
	mov	%rax, %rbx
	lea	m_allocate_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4154(%rip), %rax
	mov	%rax, %rbx
	lea	m_cdr_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4156(%rip), %rax
	mov	%rax, %rbx
	lea	m_car_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_ostr4158(%rip), %rax
	mov	%rax, %rbx
	lea	m_abort_2Fevaluator_stub(%rip), %rax
	mov	%rax, %r12
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	movq	%r12, %rdx
	movq	$0, %rcx
	call	m__25instantiate_vm_function__code
	add	$0, %rsp
	lea	m_symbol_2Fquote(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	lea	m_fixed_primitive_function_2Fquote(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_symbol_2Flambda(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	lea	m_fixed_primitive_function_2Flambda(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_symbol_2Flet(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	lea	m_fixed_primitive_function_2Flet(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_symbol_2Fdefine(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	lea	m_fixed_primitive_function_2Fdefine(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_symbol_2Fset(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	-8(%rbp), %rsi
	call	m_defined_3F__code
	add	$0, %rsp
	lea	8(%rax), %rcx
	mov	(%rcx), %rax
	lea	m_fixed_primitive_function_2Fset(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_oclosure4161(%rip), %rax
	mov	%rax, -16(%rbp)
	lea	m_symbol_2F_2Aexpanders_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	lea	m_symbol_2F_2Aencoders_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	lea	m_symbol_2F_2Aevaluators_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	lea	m_symbol_2F_2Aapplicators_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	-8(%rbp), %rdi
	movq	%rbx, %rsi
	mov	-16(%rbp), %rax
	mov	(%rax), %rax
	call	*%rax
	add	$0, %rsp
	lea	m_fixed_primitive_function_2Fquote(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$8, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L4163
	lea	m_fixed_primitive_function_2Flambda(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$8, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L4163
	lea	m_fixed_primitive_function_2Flet(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$8, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L4163
	lea	m_fixed_primitive_function_2Fdefine(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$8, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
	test	%rax, %rax
	je	m_L4163
	lea	m_fixed_primitive_function_2Fset(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_type_of__code
	add	$0, %rsp
	mov	%rax, -16(%rbp)
	mov	$8, %rax
	cmp	-16(%rbp), %rax
	sete	%al
	movzb	%al, %rax
m_L4163:
	test	%rax, %rax
	jne	m_L4162
	call	m_error_prologue__code
	add	$0, %rsp
	lea	m_ostr4165(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m__25error__code
	add	$0, %rsp
	call	m_error_epilogue__code
	add	$0, %rsp
m_L4162:
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr4166:
	.asciz "populate-env-with-maru-primitives"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4167:
	.8byte	67
	.8byte	m_cstr4166
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_populate_env_with_maru_primitives:
	.8byte	m_populate_env_with_maru_primitives__code
	.8byte	m_ostr4167
	.globl m_populate_env_with_maru_primitives__code
	.type m_populate_env_with_maru_primitives__code, @function
	.section .rodata
m_cstr4168:
	.asciz "maru"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4169:
	.8byte	9
	.8byte	m_cstr4168
	.section .rodata
m_cstr4170:
	.asciz "*maru*"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4171:
	.8byte	13
	.8byte	m_cstr4170
	.section .rodata
m_cstr4172:
	.asciz "maru-user"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4173:
	.8byte	19
	.8byte	m_cstr4172
	.text
m_initialize_vm__code:
	push	%rbp
	mov	%rsp, %rbp
	sub	$16, %rsp
	push	%rbx
	push	%r12
	push	%r13
	sub	$8, %rsp
	xor	%rax, %rax
	xor	%rax, %rax
	call	m_gc_2Finitialize__code
	add	$0, %rsp
	xor	%rax, %rax
	xor	%rax, %rax
	lea	m__2Aglobals_2A(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	lea	m__2Asymbols_2A(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	xor	%rax, %rax
	movq	$32, %rdi
	call	m_array__code
	add	$0, %rsp
	lea	m__2Asymbols_2A(%rip), %rcx
	mov	%rax, (%rcx)
	call	m_initialize_symbol_cache__code
	add	$0, %rsp
	xor	%rax, %rax
	xor	%rax, %rax
	xor	%rax, %rax
	lea	m__2Acall_stack_2A(%rip), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_gc_2Fpush_root__code
	add	$0, %rsp
	movq	$32, %rdi
	call	m_array__code
	add	$0, %rsp
	lea	m__2Acall_stack_2A(%rip), %rcx
	mov	%rax, (%rcx)
	xor	%rax, %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	$0, %rsi
	movq	$0, %rdx
	call	m_environment__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rcx
	mov	%rax, (%rcx)
	lea	m_ostr4169(%rip), %rax
	mov	%rax, -8(%rbp)
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	lea	40(%rax), %rcx
	mov	-8(%rbp), %rax
	mov	%rax, (%rcx)
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	call	m_populate_env_with_maru_primitives__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_ostr4171(%rip), %rax
	mov	%rax, %r12
	movq	%r12, %rdi
	call	m_string__3Esymbol__code
	add	$0, %rsp
	mov	%rax, %r12
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r13
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	%r13, %rdx
	call	m_environment_define__code
	add	$0, %rsp
	xor	%rax, %rax
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	movq	%rbx, %rdi
	movq	$0, %rsi
	movq	$0, %rdx
	call	m_environment__code
	add	$0, %rsp
	mov	%rax, -8(%rbp)
	lea	m_ostr4173(%rip), %rax
	mov	%rax, -16(%rbp)
	mov	-8(%rbp), %rax
	lea	40(%rax), %rcx
	mov	-16(%rbp), %rax
	mov	%rax, (%rcx)
	mov	-8(%rbp), %rax
	lea	m__2Aglobals_2A(%rip), %rcx
	mov	%rax, (%rcx)
	call	m_capture_well_known_globals__code
	add	$0, %rsp
	xor	%rax, %rax
	add	$8, %rsp
	pop	%r13
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr4174:
	.asciz "initialize-vm"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4175:
	.8byte	27
	.8byte	m_cstr4174
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_initialize_vm:
	.8byte	m_initialize_vm__code
	.8byte	m_ostr4175
	.globl m_initialize_vm__code
	.type m_initialize_vm__code, @function
	.section .rodata
m_cstr4176:
	.asciz "Heap: "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4177:
	.8byte	13
	.8byte	m_cstr4176
	.section .rodata
m_cstr4178:
	.asciz " objects in "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4179:
	.8byte	25
	.8byte	m_cstr4178
	.section .rodata
m_cstr4180:
	.asciz " bytes, "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4181:
	.8byte	17
	.8byte	m_cstr4180
	.section .rodata
m_cstr4182:
	.asciz " bytes free, "
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4183:
	.8byte	27
	.8byte	m_cstr4182
	.section .rodata
m_cstr4184:
	.asciz " GC runs\012"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4185:
	.8byte	19
	.8byte	m_cstr4184
	.text
m_gc_2Fprint_statistics__code:
	push	%rbp
	mov	%rsp, %rbp
	push	%rbx
	push	%r12
	sub	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_ostr4177(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_gc_2Fobjects_live(%rip), %rax
	mov	(%rax), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_ostr4179(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_gc_2Fbytes_used(%rip), %rax
	mov	(%rax), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_ostr4181(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_gc_2Fbytes_free(%rip), %rax
	mov	(%rax), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_ostr4183(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_gc_2Fcollection_count(%rip), %rax
	mov	(%rax), %rax
	shl	$1, %rax
	or	$1, %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	lea	m__2Amaru_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %rbx
	lea	m_symbol_2F_2Aerror_output_2A(%rip), %rax
	mov	(%rax), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	call	m_variable_value__code
	add	$0, %rsp
	mov	%rax, %rbx
	lea	m_ostr4185(%rip), %rax
	mov	%rax, %r12
	movq	%rbx, %rdi
	movq	%r12, %rsi
	movq	$0, %rdx
	call	m_do_print__code
	add	$0, %rsp
	add	$0, %rsp
	pop	%r12
	pop	%rbx
	leave
	ret
	.section .rodata
m_cstr4186:
	.asciz "gc/print-statistics"
	.section .data
	.align 8
	.8byte	3
	.8byte	12
m_ostr4187:
	.8byte	39
	.8byte	m_cstr4186
	.section .data
	.align 8
	.8byte	3
	.8byte	19
m_gc_2Fprint_statistics:
	.8byte	m_gc_2Fprint_statistics__code
	.8byte	m_ostr4187
	.globl m_gc_2Fprint_statistics__code
	.type m_gc_2Fprint_statistics__code, @function
