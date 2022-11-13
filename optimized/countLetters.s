.file	"countLetters.s"
.intel_syntax noprefix


    .text
    #	функция unsigned int count_uppercase(char *str)
	.globl	count_uppercase
	.type	count_uppercase, @function
										#	точка входа в функцию count_uppercase
count_uppercase:
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp (rsp не сдвигаем, т.к функции внутри не вызываются)

	#	в rdi хранится char *str - передан как аргумент функции
	#	unsigned int count = 0;	
	xor rsi, rsi						#	count = 0 - сохраняем счетчик в регистре rsi

	#	цикл while - проход по строке
	jmp	.L12

	#	тело цикла while
.L14:
	#	if ('A' <= *str && *str <= 'Z')
	movzx	eax, BYTE PTR [rdi]			#	eax = *str
	cmp	al, 64							#	cmp *str, 64 =('A' - 1)
	jle	.L13							#	if (*str < 'A') {goto .L13}
	cmp	al, 90							#	cmp *str, 90 =('Z')
	jg	.L13							#	if (*str > 'Z') then {goto .L13}

	add	rsi, 1							#	count += 1 (rsi) (если 'A' <= *str <= 'Z')

.L13:	#	++str; - сдвигаем указатель на следующий символ
	add	rdi, 1							#	++str (rdi)
	
.L12:	#	условие while: *str
	movzx	eax, BYTE PTR [rdi]			#	eax = *str
	test	al, al						
	jne	.L14							#	if (*str != 0) {goto .L14 - тело цикла while}

	#	return count;
	mov	rax, rsi						#	rax = count (rsi) - возвращаемое значение
	pop	rbp								#	восстанавливаем rbp
	ret									#	выходим из функции и возвращаем eax = count
	.size	count_uppercase, .-count_uppercase


	#	функция unsigned int count_lowercase(char *str)
	.globl	count_lowercase
	.type	count_lowercase, @function
										#	точка входа в функцию count_lowercase
count_lowercase:
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp (rsp не сдвигаем, т.к функции внутри не вызываются)
	
	#	в rdi хранится char *str - передан как аргумент функции
	#	unsigned int count = 0;	
	xor rsi, rsi						#	count = 0 - сохраняем счетчик в регистре rsi

	#	цикл while - проход по строке
	jmp	.L17
	#	тело цикла while
.L19:
#	if ('a' <= *str && *str <= 'b')
	movzx	eax, BYTE PTR [rdi]			#	eax = *str
	cmp	al, 96							#	cmp *str, 64 =('a' - 1)
	jle	.L18							#	if (*str < 'a') {goto .L18}
	cmp	al, 122							#	cmp *str, 122 =('z')
	jg	.L18							#	if (*str > 'z') then {goto .L18}

	add	rsi, 1							#	count += 1 (rsi) (если 'a' <= *str <= 'z')

.L18:	#	++str; - сдвигаем указатель на следующий символ
	add	rdi, 1							#	++str (rdi)

.L17:		#	условие while: *str
	movzx	eax, BYTE PTR [rdi]			#	eax = *str
	test	al, al						
	jne	.L19							#	if (*str != 0) {goto .L14 - тело цикла while}

	#	return count;
	mov	rax, rsi						#	eax = count (-4[rbp]) - возвращаемое значение
	pop	rbp								#	восстанавливаем rbp
	ret									#	выходим из функции и возвращаем eax = count
	.size	count_lowercase, .-count_lowercase
