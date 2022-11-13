.file	"fileStreams.s"
.intel_syntax noprefix
    
    .section	.rodata
	#	функция char *read_string(char *file_name)
	#	строковой литерал (константа), которая используется в read_string
.LC0:
	.string	"r"

	.text
	.globl	read_string
	.type	read_string, @function
										#	точка входа в функцию array_input
read_string:
	#	ввод массива из файла
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp
	push 	rbx							#	сохраняем регистр rbx на стеке (будем его изменять)
	push	r12							#	сохраняем регистр r12 на стеке (будем его изменять)
	push	r13							#	сохраняем регистр r13 на стеке (будем его изменять)
	push	r14							#	сохраняем регистр r14 на стеке (будем его изменять)
	
	#	FILE *istream = fopen(file_name, "r");
	lea	rsi, .LC0[rip]					#	rsi = "r" (pointer to the string) - второй аргумент
	#	в rdi уже хранится file_name (как аргумент функции), но больше он нам не понадобится, поэтому можно его не сохранять
	call	fopen@PLT					#	rax = fopen(rdi = file_name, rsi = "r")
	mov	rbx, rax						#	rbx = istream = fopen(file_name, "r") - сохраняем указатель на файл istream в регистр rbx
	
	#	fseek(istream, 0, SEEK_END);
	mov	edx, 2							#	edx = 2 = SEEK_END (макрос) - третий аргумент
	xor esi, esi						#	esi = 0 (смещение) - второй аргумент
	mov	rdi, rbx						#	rdi = istream - первый аргумент
	call	fseek@PLT					#	fseek(rdi = istream, esi = 0, edx = SEEK_END) - вызов функции

	#	size_t istream_size = ftell(istream);
	mov	rdi, rbx						#	rdi = istream (rbx) - первый аргумент
	call	ftell@PLT					#	rax = ftell(rdi = istream) - считываем позицию каретки в файле (то есть размер файла)
	mov	r12, rax						#	r12 = istream_size = ftell(istream) - сохраняем локальную переменную в регистре

	#	fseek(istream, 0, SEEK_SET);
	xor edx, edx						#	edx = 0 = SEEK_SET (макрос) - третий аргумент
	xor	esi, esi						#	esi = 0 (смещение) - второй аргумент
	mov	rdi, rbx						#	rdi = istream (rbx) - первый аргумент
	call	fseek@PLT					#	fseek(rdi = istream, esi = 0, edx= SEEK_SET) - вызов функции

	#	char *str = malloc(istream_size + 1);
	mov	rdi, r12						#	rdi = istream_size (r12)
	add	rdi, 1							#	rdi = istream_size + 1 - первый аргумент (размер строки с учетом '\0')
	call	malloc@PLT					#	rax = malloc(istream_size + 1) (т.к sizeof(char) = 1)
	mov	r13, rax						#	r13 = str - сохраняем указатель на строку в регистре r13

	#	for (size_t i = 0; i < istream_size; ++i)
	xor r14, r14						#	size_t i = 0 - сохраняем счетчик в регистре r14
	jmp	.L2

	#	тело цикла for
.L3:
	#	str[i] = fgetc(istream);
	mov	rdi, rbx						#	rdi = istream (rbx) - первый аргумент
	call	fgetc@PLT					#	eax = fgetc(rdi = istream) - считываем символ
	mov	BYTE PTR [r13 + r14], al		#	str[i] = fgetc(istream) (r13 + r14 = str + i = &str[i])

	#	++i - "обновление" цикла for
	add	r14, 1							#	i += 1
	#	условие цикла for: i < istream_size
.L2:
	cmp r14, r12						#	cmp i(r14), istream_size(r12)
	jb	.L3								#	if (i < istream_size) {goto .L3} - еще есть непрочитанные символы

	#	str[istream_size] = 0; - устанавливаем конец строки
	mov	BYTE PTR [r13 + r12], 0				#	str[istream_size] = 0

	#	fclose(istream);
	mov	rdi, rbx						#	rdi = istream (rbx) - первый аргумент
	call	fclose@PLT					#	fclose(rdi = istream) - закрываем файл

	#	return str;
	mov	rax, r13						#	rax = str  - возвращаемое значение
	#	восстанавливаем регистры, которые изначально сохранили на стеке
	pop		r14
	pop 	r13
	pop		r12
	pop		rbx
	pop 	rbp
	ret									#	return rax = str
	.size	read_string, .-read_string


	.section	.rodata
	#	функция void write_string(char *str, char *file_name)
	#	строковой литерал (константа), которая используется в read_string
.LC1:
	.string	"w"

	.text
	.globl	write_string
	.type	write_string, @function
										#	точка входа в функцию array_input
write_string:
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp
	push	rbx							#	сохраняем регистр rbx на стеке (будем его изменять)
	push	r12							#	сохраняем регистр r12 на стеке (будем его изменять)

	# сохраняем в регистры переданные аргументы
	mov	rbx, rdi						#	сохраняет в регистр rbx первый аргумент из rdi (char *str в Си)

	#	FILE *ostream = fopen(file_name, "w");
	mov rdi, rsi						#	rdi = file_name - перекладываем второй аргумент функции в первый для вызова функции
	lea	rsi, .LC1[rip]					#	rsi = "w" (pointer to the string) - второй аргумент
	call	fopen@PLT					#	rax = fopen(rdi = file_name, rsi = "w") - вызов функции
	mov	r12, rax						#	r12 = ostream = fopen(file_name, "w") - сохраняем указатель в регистре r12

	#	fprintf(ostream, "%s", str);
	mov	rsi, r12						#	rsi = ostream (r12) - второй аргумент
	mov	rdi, rbx						#	rdi = str (rbx) - первый аргумент
	call	fputs@PLT					#	fputs(rdi = str, rsi = ostream) - вывод строки в файл

	#	fclose(ostream);
	mov	rdi, r12						#	rdi = ostream
	call	fclose@PLT					#	fclose(rdi = ostream) - закрываем файл

	nop
	#	восстанавливаем регистры, которые изначально сохранили на стеке
	pop		r12
	pop		rbx
	pop 	rbp
	ret									#	return - выход из функции
	.size	write_string, .-write_string

	.section	.rodata
	#	функция void write_result(unsigned int uppercase, unsigned int lowercase, char *file_name)
	#	строковые литералы (константы), которые используются в write_result
	.align 8
.LC2:
	.string	"Number of uppercase letters: %u\n"
	.align 8
.LC3:
	.string	"Number of lowercase letters: %u\n"
	.text
	.globl	write_result
	.type	write_result, @function
										#	точка входа в функцию write_result
write_result:
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp
	push 	rbx							#	сохраняем регистр rbx на стеке (будем его изменять)
	push	r12							#	сохраняем регистр r12 на стеке (будем его изменять)
	push	r13							#	сохраняем регистр r13 на стеке (будем его изменять)
	sub	rsp, 8							#	конец фрейма rsp -= 8 (размер фрейма 40 байтов + 8 адрес возврата)
	
	# сохраняем на стек переданные через регистры аргументы
	mov r12d, edi						#	сохраняет в регистр r12 первый аргумент из edi (unsigned int uppercase в Си)
	mov r13d, esi						#	сохраняет в регистр r13 второй аргумент из esi (unsigned int lowercase в Си)
	mov	rbx, rdx						#	сохраняет в регистр rbx третий аргумент из rdx (char *file_name в Си)
	
	#	FILE *ostream = fopen(file_name, "w");
	lea	rsi, .LC1[rip]					#	rsi = "r" (pointer to the string) - второй аргумент
	mov	rdi, rbx						#	rdi = file_name (rbx) - первый аргумент
	call	fopen@PLT					#	rax = fopen(rdi = file_name, rsi = "r")
	mov	rbx, rax						#	ostream = fopen(file_name, "r") - сохраняем указатель в регистр rbp (file_name больше не нужен)

	#	fprintf(ostream, "Number of uppercase letters: %u\n", uppercase);
	mov	edx, r12d						#	rdx = uppercase (r12) - третий аргумент
	lea	rsi, .LC2[rip]					#	rsi = "Number of uppercase letters: %u\n" (pointer to string) - второй аргумент
	mov	rdi, rbx						#	rdi = ostream (rbx) - первый аргумент
	mov	eax, 0	
	call	fprintf@PLT					#	fprintf(rdi = ostream, rsi, edx=uppercase) - вывод результата
	
	#	fprintf(ostream, "Number of lowercase letters: %u\n", lowercase);
	mov	edx, r13d						#	rdx = lowercase (r13) - третий аргумент
	lea	rsi, .LC3[rip]					#	rsi = "Number of lowercase letters: %u\n" (pointer to string) - второй аргумент
	mov	rdi, rbx						#	rdi = ostream (rbx)- первый аргумент
	mov	eax, 0
	call	fprintf@PLT					#	fprintf(rdi = ostream, rsi, edx=lowercase) - вывод результата
	
	#	 fclose(ostream);
	mov	rdi, rbx						#	rdi = ostream (rbx) - первый аргумент
	call	fclose@PLT					#	fclose(rdi = ostream) - закрытие файла

	#	восстанавливаем регистры, которые изначально сохранили на стеке
	add rsp, 8
	pop 	r13
	pop		r12
	pop		rbx
	pop 	rbp
	ret									#	выход из функции
	.size	write_result, .-write_result
