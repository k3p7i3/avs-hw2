	.file	"code.c"
	.intel_syntax noprefix
	.text

	.globl	TIME_FLAG
	.bss	#	секция с глобальными переменными
	.type	TIME_FLAG, @object
	.size	TIME_FLAG, 1
TIME_FLAG:
	.zero	1


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
	sub	rsp, 48							#	конец фрейма rsp -= 48 (размер фрейма 56 байтов + 8 байтов адрес возврата)
	mov	QWORD PTR -40[rbp], rdi			#	сохраняет на стек (-40[rbp]) первый аргумент из rdi (char *file_name)

	#	FILE *istream = fopen(file_name, "r");
	mov	rax, QWORD PTR -40[rbp]			#	rax = file_name (-40[rbp]) (pointer to the string)
	lea	rsi, .LC0[rip]					#	rsi = "r" (pointer to the string) - второй аргумент
	mov	rdi, rax						#	rdi = file_name - первый аргумент
	call	fopen@PLT					#	rax = fopen(rdi = file_name, rsi = "r")
	mov	QWORD PTR -24[rbp], rax			#	-24[rbp] = istream = fopen(file_name, "r") - сохраняем указатель на файл на стек
	
	#	fseek(istream, 0, SEEK_END);
	mov	rax, QWORD PTR -24[rbp]			#	rax = -24[rbp] = istream
	mov	edx, 2							#	edx = 2 = SEEK_END (макрос) - третий аргумент
	mov	esi, 0							#	esi = 0 (смещение) - второй аргумент
	mov	rdi, rax						#	rdi = istream - первый аргумент
	call	fseek@PLT					#	fseek(rdi = istream, esi = 0, edx = SEEK_END) - вызов функции

	#	size_t istream_size = ftell(istream);
	mov	rax, QWORD PTR -24[rbp]			#	rax = -24[rbp] = istream
	mov	rdi, rax						#	rdi = istream - первый аргумент
	call	ftell@PLT					#	rax = ftell(rdi = istream) - считываем позицию каретки в файле (то есть размер файла)
	mov	QWORD PTR -16[rbp], rax			#	istream_size = -16[rbp] = rax = ftell(istream)

	#	fseek(istream, 0, SEEK_SET);
	mov	rax, QWORD PTR -24[rbp]			#	rax = -24[rbp] = istream
	mov	edx, 0							#	edx = 0 = SEEK_SET (макрос) - третий аргумент
	mov	esi, 0							#	esi = 0 (смещение) - второй аргумент
	mov	rdi, rax						#	rdi = istream - первый аргумент
	call	fseek@PLT					#	fseek(rdi = istream, esi = 0, edx= SEEK_SET) - вызов функции

	#	char *str = malloc(istream_size + 1);
	mov	rax, QWORD PTR -16[rbp]			#	rax = istream_size (-16[rbp])
	add	rax, 1							
	mov	rdi, rax						#	rdi = istream_size + 1 - первый аргумент (размер строки с учетом '\0')
	call	malloc@PLT					#	rax = malloc(istream_size + 1) (т.к sizeof(char) = 1)
	mov	QWORD PTR -8[rbp], rax			#	-8[rbp] = str = malloc(istream_size + 1)


	#	size_t i = 0 - начало цикла for
	mov	QWORD PTR -32[rbp], 0			#	-32[rbp] = i = 0 - сохраняем на стек			
	jmp	.L2

	#	тело цикла for
.L3:
	#	str[i] = fgetc(istream);
	mov	rax, QWORD PTR -24[rbp]			#	rax = istream (-24[rbp])
	mov	rdi, rax						#	rdi = rax - первый аргумент
	call	fgetc@PLT					#	eax = fgetc(rdi = istream) - считываем символ
	mov	ecx, eax						#	ecx = fgetc(istream)
	mov	rdx, QWORD PTR -8[rbp]			#	rdx = -8[rbp] = str
	mov	rax, QWORD PTR -32[rbp]			#	rax = i (-32[rbp])
	add	rax, rdx						#	rax = i + str = &str[i]
	mov	edx, ecx						#	edx = fgetc(istream)
	mov	BYTE PTR [rax], dl				#	str[i] = fgetc(istream) - сохранили считанный символ в массив

	#	++i - "обновление" цикла for
	add	QWORD PTR -32[rbp], 1			#	i += 1 (-32[rbp])

	#	условие цикла for i < istream_size
.L2:
	mov	rax, QWORD PTR -32[rbp]			#	rax = i (-32[rbp])
	cmp	rax, QWORD PTR -16[rbp]			#	cmp i, istream_size (-16[rbp])
	jb	.L3								#	if (i < istream_size) {goto .L3}

	#	str[istream_size] = 0;
	mov	rdx, QWORD PTR -8[rbp]			#	rdx = str (-8[rbp])
	mov	rax, QWORD PTR -16[rbp]			#	rax = istream_size (-16[rbp])
	add	rax, rdx						#	rax = str + istream_size = &str[istream_size]
	mov	BYTE PTR [rax], 0				#	str[istream_size] = 0

	#	fclose(istream);
	mov	rax, QWORD PTR -24[rbp]			#	rax = istream
	mov	rdi, rax						#	rdi = istream - первый аргумент
	call	fclose@PLT					#	fclose(rdi = istream) - закрываем файл

	#	return str;
	mov	rax, QWORD PTR -8[rbp]			#	rax = str			
	leave								#	восстанавливаем регистры состояния стека
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
	sub	rsp, 32							#	конец фрейма rsp -= 32 (размер фрейма 40 байтов + 8 адрес возврата)

	# сохраняем на стек переданные через регистры аргументы
	mov	QWORD PTR -24[rbp], rdi			#	сохраняет на стек (-24[rbp]) первый аргумент из rdi (char *str в Си)
	mov	QWORD PTR -32[rbp], rsi			#	сохраняет на стек (-32[rbp]) второй аргумент из rsi (char *file_name в Си)

	#	FILE *ostream = fopen(file_name, "w");
	mov	rax, QWORD PTR -32[rbp]			#	rax = -32[rbp] = file_name (pointer to the string)
	lea	rsi, .LC1[rip]					#	rsi = "w" (pointer to the string) - второй аргумент
	mov	rdi, rax						#	rdi = file_name - первый аргумент
	call	fopen@PLT					#	rax = fopen(rdi = file_name, rsi = "w") - вызов функции
	mov	QWORD PTR -8[rbp], rax			#	ostream = rax = fopen(file_name, "w") - сохраняем указатель на стеке

	#	fprintf(ostream, "%s", str);
	mov	rdx, QWORD PTR -8[rbp]			#	rdx = ostream (-8[rbp])
	mov	rax, QWORD PTR -24[rbp]			#	rax = str
	mov	rsi, rdx						#	rsi = ostream - второй аргумент
	mov	rdi, rax						#	rdi = str - первый аргумент
	call	fputs@PLT					#	fputs(rdi = str, rsi = ostream) - вывод строки в файл

	#	fclose(ostream);
	mov	rax, QWORD PTR -8[rbp]			#	rax = ostream
	mov	rdi, rax						#	rdi = ostream
	call	fclose@PLT					#	fclose(rdi = ostream) - закрываем файл

	nop
	leave								#	восстанавливаем регистры состояния стека
	ret									#	return - выход из функции
	.size	write_string, .-write_string


	#	функция char *random_string(size_t size)
	.globl	random_string
	.type	random_string, @function
										#	точка входа в функцию random_string
random_string:
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp
	sub	rsp, 32							#	конец фрейма rsp -= 32 (размер фрейма 40 байтов + 8 адрес возврата)

	# сохраняем на стек переданные через регистры аргументы
	mov	QWORD PTR -24[rbp], rdi			#	сохраняет на стек (-24[rbp]) первый аргумент из rdi (size_t size в Си)

	#	char *str = malloc(size + 1);
	mov	rax, QWORD PTR -24[rbp]			#	rax = size (-24[rbp])
	add	rax, 1							#	rax = size + 1
	mov	rdi, rax						#	rdi = size + 1 - первый аргумент (размер строки с учетом '\0')
	call	malloc@PLT					#	rax = malloc(rdi = size + 1) (т.к. sizeof(char) = 1)
	mov	QWORD PTR -8[rbp], rax			#	str = malloc(size + 1) (сохраняем указател на стеке -8[rbp])

	#	srand(time(NULL)); задаем "начало" для рандома на основе системного времени для уникальности
	mov	edi, 0							#	edi = 0 - первый аргумент
	call	time@PLT					#	eax = time(edi = 0) - получаем системное время
	mov	edi, eax						#	edi = time(NULL) - первый аргумент
	call	srand@PLT					#	srand(edi = time(NULL)) - вызываем функцию

	#	начало цикла for: size_t i = 0;
	mov	QWORD PTR -16[rbp], 0			#	i = 0 (сохраняем на стеке в -16[rbp])
	jmp	.L7

	#	тело цикла for
.L9:
	#	генерация рандомного числа и какая-то магия для взятия по модулю 95....???
	call	rand@PLT					#	randval = eax = rand() - вызываем рандомный генератор
	movsx	rdx, eax					#	rdx = randval (с расширением знака)					
	imul	rdx, rdx, -1401515643		#	rdx = randval * (2^64) * (94/95) (! -1401515643 ~ (2^64) * (94/95) в беззнаковой записи uint_64)
	shr	rdx, 32							#	rdx >>= 32 (rdx /= 2^32 -> rdx = randval * (94/95) * (2^32))
	add	edx, eax						#	rdx += randval -> rdx = randval * (94/95 * (2^32) + 1) (но по модулю 2^32)
	mov	ecx, edx						#	ecx = edx
	sar	ecx, 6							#	ecx >> 6 = edx /= 64 = (randval * (94/95 * (2^32) + 1)) // 64)
	cdq									#	расширение eax до rax
	sub	ecx, edx						#	ecx -= edx = (randval * (94/95 * (2^32) + 1)) // 64) - randval * (94/95 * (2^32) + 1) = -63/64 * (randval * (94/95 * (2^32) + 1)))
	mov	edx, ecx						#	edx = -63/64 * (randval * (94/95 * (2^32) + 1)))
	imul	edx, edx, 95				#	edx *= 95; (127 - 32)
	sub	eax, edx						
	mov	edx, eax						#	edx = randval - edx
	mov	eax, edx						#	eax = randval - edx
	lea	ecx, 32[rax]					#	ecx = randval % 95 + 32

	#	str[i] = rand() % (127 - 32) + 32;
	mov	rdx, QWORD PTR -8[rbp]			#	rdx = str (-8[rbp])
	mov	rax, QWORD PTR -16[rbp]			#	rax = i (-16[rbp])
	add	rax, rdx						#	rax = str + i = &str[i]
	mov	edx, ecx						#	edx = rand() % 95 + 32 
	mov	BYTE PTR [rax], dl				#	str[i] = edx = rand() % 95 + 32

	#	++i - "обновление" цикла for
.L8:
	add	QWORD PTR -16[rbp], 1			#	i += 1 (-16[rbp])

	#	условие цикла for: i < size;
.L7:
	mov	rax, QWORD PTR -16[rbp]			#	rax = i (-16[rbp])
	cmp	rax, QWORD PTR -24[rbp]			#	cmp i, size (-24[rbp])
	jb	.L9								#	if (i < size) {goto .L9 - тело цикла}

	#	str[size] = 0;
	mov	rdx, QWORD PTR -8[rbp]			#	rdx = str (-8[rbp])
	mov	rax, QWORD PTR -24[rbp]			#	rax = size (-24[rbp])
	add	rax, rdx						#	rax = str + size = &str[size]
	mov	BYTE PTR [rax], 0				#	str[size] = '\0' - конец строки

	#	return str;
	mov	rax, QWORD PTR -8[rbp]			#	rax = str (-8[rbp]) - возвращаемое значение
	leave								#	восстанавливаем регистры состояния стека
	ret									#	return str
	.size	random_string, .-random_string


	#	функция unsigned int count_uppercase(char *str)
	.globl	count_uppercase
	.type	count_uppercase, @function
										#	точка входа в функцию count_uppercase
count_uppercase:
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp (rsp не сдвигаем, т.к функции внутри не вызываются)

	#	сохраняем на стек переданные через регистры аргументы
	mov	QWORD PTR -24[rbp], rdi			#	сохраняет на стек (-24[rbp]) первый аргумент из rdi (char *str в Си)

	#	unsigned int count = 0;	
	mov	DWORD PTR -4[rbp], 0			#	count = 0 (-4[rbp]) - сохраняем счетчик на стеке

	#	цикл while - проход по строке
	jmp	.L12

	#	тело цикла while
.L14:
	#	if ('A' <= *str && *str <= 'Z')
	mov	rax, QWORD PTR -24[rbp]			#	rax = str (-24[rbp])
	movzx	eax, BYTE PTR [rax]			#	eax = *str
	cmp	al, 64							#	cmp *str, 64 =('A' - 1)
	jle	.L13							#	if (*str < 'A') {goto .L13}
	mov	rax, QWORD PTR -24[rbp]			#	rax = str (-24[rbp])
	movzx	eax, BYTE PTR [rax]			#	rax = *str
	cmp	al, 90							#	cmp *str, 90 =('Z')
	jg	.L13							#	if (*str > 'Z') then {goto .L13}

	add	DWORD PTR -4[rbp], 1			#	count += 1 (-4[rbp]) (если 'A' <= *str <= 'Z')

	#	++str; - сдвигаем указатель на следующий символ
.L13:
	add	QWORD PTR -24[rbp], 1			#	++str (-24[rbp])

	#	условие while: *str
.L12:
	mov	rax, QWORD PTR -24[rbp]			#	rax = str (-24[rbp])
	movzx	eax, BYTE PTR [rax]			#	eax = *str
	test	al, al						
	jne	.L14							#	if (*str != 0) {goto .L14 - тело цикла while}

	#	return count;
	mov	eax, DWORD PTR -4[rbp]			#	eax = count (-4[rbp]) - возвращаемое значение
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
	
	#	сохраняем на стек переданные через регистры аргументы
	mov	QWORD PTR -24[rbp], rdi			#	сохраняет на стек (-24[rbp]) первый аргумент из rdi (char *str в Си)
	
	#	unsigned int count = 0;	
	mov	DWORD PTR -4[rbp], 0			#	count = 0 (-4[rbp]) - сохраняем счетчик на стеке

	#	цикл while - проход по строке
	jmp	.L17
	#	тело цикла while
.L19:
#	if ('a' <= *str && *str <= 'b')
	mov	rax, QWORD PTR -24[rbp]			#	rax = str (-24[rbp])
	movzx	eax, BYTE PTR [rax]			#	eax = *str
	cmp	al, 96							#	cmp *str, 64 =('a' - 1)
	jle	.L18							#	if (*str < 'a') {goto .L18}
	mov	rax, QWORD PTR -24[rbp]			#	rax = str (-24[rbp])
	movzx	eax, BYTE PTR [rax]			#	rax = *str
	cmp	al, 122							#	cmp *str, 122 =('z')
	jg	.L18							#	if (*str > 'z') then {goto .L18}

	add	DWORD PTR -4[rbp], 1			#	count += 1 (-4[rbp]) (если 'a' <= *str <= 'z')

	#	++str; - сдвигаем указатель на следующий символ
.L18:
	add	QWORD PTR -24[rbp], 1			#	++str (-24[rbp])

	#	условие while: *str
.L17:
	mov	rax, QWORD PTR -24[rbp]			#	rax = str (-24[rbp])
	movzx	eax, BYTE PTR [rax]			#	eax = *str
	test	al, al						
	jne	.L19							#	if (*str != 0) {goto .L14 - тело цикла while}

	#	return count;
	mov	eax, DWORD PTR -4[rbp]			#	eax = count (-4[rbp]) - возвращаемое значение
	pop	rbp								#	восстанавливаем rbp
	ret									#	выходим из функции и возвращаем eax = count
	.size	count_lowercase, .-count_lowercase



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
	sub	rsp, 32							#	конец фрейма rsp -= 32 (размер фрейма 40 байтов + 8 адрес возврата)
	
	# сохраняем на стек переданные через регистры аргументы
	mov	DWORD PTR -20[rbp], edi			#	сохраняет на стек (-20[rbp]) первый аргумент из edi (unsigned int uppercase в Си)
	mov	DWORD PTR -24[rbp], esi			#	сохраняет на стек (-24[rbp]) второй аргумент из esi (unsigned int lowercase в Си)
	mov	QWORD PTR -32[rbp], rdx			#	сохраняет на стек (-32[rbp]) третий аргумент из rdx (char *file_name в Си)
	
	#	FILE *ostream = fopen(file_name, "w");
	mov	rax, QWORD PTR -32[rbp]			#	rax = file_name (-32[rbp])
	lea	rsi, .LC1[rip]					#	rsi = "r" (pointer to the string) - второй аргумент
	mov	rdi, rax						#	rdi = file_name - первый аргумент
	call	fopen@PLT					#	rax = fopen(rdi = file_name, rsi = "r")
	mov	QWORD PTR -8[rbp], rax			#	-8[rbp] = ostream = fopen(file_name, "r") - сохраняем указатель на стеке

	#	fprintf(ostream, "Number of uppercase letters: %u\n", uppercase);
	mov	edx, DWORD PTR -20[rbp]			#	edx = uppercase (-20[rbp]) - третий аргумент
	mov	rax, QWORD PTR -8[rbp]			#	rax = ostream (-8[rbp])
	lea	rsi, .LC2[rip]					#	rsi = "Number of uppercase letters: %u\n" (pointer to string) - второй аргумент
	mov	rdi, rax						#	rdi = ostream - первый аргумент
	mov	eax, 0	
	call	fprintf@PLT					#	fprintf(rdi = ostream, rsi, edx=uppercase) - вывод результата
	
	#	fprintf(ostream, "Number of lowercase letters: %u\n", lowercase);
	mov	edx, DWORD PTR -24[rbp]			#	edx = lowercase (-24[rbp]) - третий аргумент
	mov	rax, QWORD PTR -8[rbp]			#	rax = ostream (-8[rbp])
	lea	rsi, .LC3[rip]					#	rsi = "Number of lowercase letters: %u\n" (pointer to string) - второй аргумент
	mov	rdi, rax						#	rdi = ostream - первый аргумент
	mov	eax, 0
	call	fprintf@PLT					#	fprintf(rdi = ostream, rsi, edx=lowercase) - вывод результата
	
	#	 fclose(ostream);
	mov	rax, QWORD PTR -8[rbp]			#	rax = ostream (-8[rbp])
	mov	rdi, rax						#	rdi = ostream - первый аргумент
	call	fclose@PLT					#	fclose(rdi = ostream) - закрытие файла
	nop
	leave
	ret									#	выход из функции
	.size	write_result, .-write_result


	#	функция void free_memory(char *str)
	.globl	free_memory
	.type	free_memory, @function
										#	точка входа в функцию free_array
free_memory:
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp
	sub	rsp, 16							#	конец фрейма rsp -= 16 (размер фрейма 24 байтов + 8 адрес возврата)
	
	# сохраняем на стек переданные через регистры аргументы
	mov	QWORD PTR -8[rbp], rdi			#	сохраняет на стек (-8[rbp]) первый аргумент из rdi (char *str в Си)
	
	#	free(str);
	mov	rax, QWORD PTR -8[rbp]			#	rax = str (-8[rbp])
	mov	rdi, rax						#	rdi = str - аргумент функции
	call	free@PLT					#	free(rdi = str)

	nop
	leave								#	восстанавливаем регистры состояния стека
	ret									#	return - выход из функции	
	.size	free_memory, .-free_memory

	#	функция main
	.section	.rodata
	#	строковые литералы (константы), которые используются в main
	.align 8
.LC4:
	.string	"2 argements excepted - input file and output file"
.LC5:
	.string	"--rand"
.LC6:
	.string	"--time"
.LC8:
	.string	"Process time:%f seconds\n"

	.text
	.globl	main
	.type	main, @function
main:
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp
	sub	rsp, 96							#	конец фрейма rsp -= 96 (размер фрейма 104 байта + 8 адрес возврата)
	
	#	два аргумента argc и argv передаются в main через rdi и rsi соответственно
	mov	DWORD PTR -84[rbp], edi			#	сохраняем int argc из edi на стек (-84[rbp])
	mov	QWORD PTR -96[rbp], rsi			#	сохраняем char **argv из esi на стек (-96[rbp])

	#	if (argc < 3) - проверяем, ввели ли файлы для ввода/вывода в качестве аргументов cmd
	cmp	DWORD PTR -84[rbp], 2			#	cmp argc, 2
	jg	.L24							#	if (argc > 3) then {goto .L24}

	#	incorrect input - 2 arguments excepted
	#	fprintf(stderr, "2 argements excepted - input file and output file");
	mov	rax, QWORD PTR stderr[rip]		#	rax = stderr
	mov	rcx, rax						# 	rcx = stderr - 4 аргумент
	mov	edx, 49							#	edx = 49 = len("2 argements excepted - input file and output file") - кол-во выводимых объектов - третий аргумент
	mov	esi, 1							#	esi = 1 = sizeof(char) - размер выводимых объектов - второй аргумент	
	lea	rdi, .LC4[rip]					#	rdi = "2 argements excepted - input file and output file" (pointer to the string) - первый агрумент
	call	fwrite@PLT					#	fwrite("2 argements excepted - input file and output file", 1, 49, stderr) - вывод ошибки
	
	#	exit(1);
	mov	edi, 1
	call	exit@PLT					#	exit(1) - аварийный выход

.L24:
	#	char *input = argv[1];
	mov	rax, QWORD PTR -96[rbp]			#	rax = argv (сохранен на стеке в -96[rbp])
	mov	rax, QWORD PTR 8[rax]			#	rax = argv[1]
	mov	QWORD PTR -40[rbp], rax			#	char *input = argv[1] - сохраняем локальную переменную на стек -40[rbp]
	
	#	char *output = argv[2];
	mov	rax, QWORD PTR -96[rbp]			#	rax = argv (сохранен на стеке в -96[rbp])
	mov	rax, QWORD PTR 16[rax]			#	rax = argv[2]
	mov	QWORD PTR -32[rbp], rax			#	char *output = argv[2] - сохраняем локальную переменную на стек -32[rbp]
	
	#	size_t random_size = 0;
	mov	QWORD PTR -64[rbp], 0			#	size_random = 0 - сохраняем локальную переменную на стек -64[rbp]
	
	#	начало цикла for: size_t i = 3;
	mov	QWORD PTR -56[rbp], 3			#	i = 3 - сохраняем локальный счетчик цикла for на цикл (-56[rbp])
	jmp	.L25

.L29:
	#	if (!strcmp(argv[i], "--rand"))
	mov	rax, QWORD PTR -56[rbp]			#	rax = i (-56[rbp])	
	lea	rdx, 0[0+rax*8]					#	rdx = 8 * i = i * sizeof(char *)
	mov	rax, QWORD PTR -96[rbp]			#	rax = argv (-96[rbp])
	add	rax, rdx						#	rax = argv + i * sizeof(char*) = &argv[i]
	mov	rax, QWORD PTR [rax]			#	rax = argv[i]

	lea	rsi, .LC5[rip]					#	rsi = "--rand" (pointer to the string) - второй аргумент (передаем через rsi)
	mov	rdi, rax						#	rdi = argv[i] - первый аргумент (передаем через rdi)
	call	strcmp@PLT					#	eax = strcmp(rdi = argv[i], rsi = "--rand)
	test	eax, eax
	jne	.L26							#	if (argv[i] != "--rand") {goto .L26}

	#	if (i + 1 < argc) 
	mov	rax, QWORD PTR -56[rbp]			#	rax = i (-56[rbp]
	lea	rdx, 1[rax]						#	rdx = i + 1
	mov	eax, DWORD PTR -84[rbp]			#	eax = argc (-86[rbp])	
	cdqe								#	eax -> rax (расширение значения argc из int в size_t)
	cmp	rdx, rax						#	cmp i + 1, argc
	jnb	.L27							#	if (!(i + 1 < argc)) {goto .L27}

	#	random_size = atoi(argv[i + 1]); - тело if (i + 1 < argc)
	mov	rax, QWORD PTR -56[rbp]			#	rax = i (-56[rbp])
	add	rax, 1							#	rax = i + 1
	lea	rdx, 0[0+rax*8]					#	rdx = sizeof(char*) * (i + 1)
	mov	rax, QWORD PTR -96[rbp]			#	rax = argv (-96[rbp])
	add	rax, rdx						#	rax = argv + sizeof(char*) * (i + 1) = &argv[i + 1]
	mov	rax, QWORD PTR [rax]			#	rax = argv[i + 1]
	mov	rdi, rax						#	rdi = argv[i + 1] - первый аргумент (передаем через rdi)
	call	atoi@PLT					#	atoi(rdi = argv[i + 1])
	cdqe								#	eax -> rax (расширение из int в long long) (rax = atoi (argv[i + 1]))
	mov	QWORD PTR -64[rbp], rax			#	size_random = rax = atoi (argv[i]) (сохранение значения в локальную переменную на стеке)

	#	if (!random_size)
.L27:
	cmp	QWORD PTR -64[rbp], 0			#	cmp size_random (-64[rbp]), 0
	jne	.L26							#	if (size_random != 0) {goto .L26}

	#	if (size_random == 0) - у опции --rand нет аргумента -> задаем дефолтное значение
	mov	QWORD PTR -64[rbp], 1000		#	size_random = 1000 

	#	 if (!strcmp(argv[i], "--time"))
.L26:
	mov	rax, QWORD PTR -56[rbp]			#	rax = i (-56[rbp])
	lea	rdx, 0[0+rax*8]					#	rdx = 8 * i = i * sizeof(char *)
	mov	rax, QWORD PTR -96[rbp]			#	rax = argv (-96[rbp])
	add	rax, rdx						#	rax = argv + i * sizeof(char*) = &argv[i]
	mov	rax, QWORD PTR [rax]			#	rax = argv[i]
	lea	rsi, .LC6[rip]					#	rsi = "--time" (pointer to the string) - второй аргумент (передаем через rsi)
	mov	rdi, rax						#	rdi = argv[i] - первый аргумент (передаем через rdi)
	call	strcmp@PLT					#	eax = strcmp(rdi = argv[i], rsi = "--time")
	test	eax, eax
	jne	.L28							#	if (argv[i] != "--rand")) {goto .L28}

	#	if (argv[i] == "--time") - устанавливаем флаг замера времени TIME_FLAG
	mov	BYTE PTR TIME_FLAG[rip], 1		#	TIME_FLAG = 1
.L28:
	add	QWORD PTR -56[rbp], 1

	#	условие цикла for: i < argc;
.L25:
	mov	eax, DWORD PTR -84[rbp]			#	eax = argc (-84[rbp])
	cdqe								#	eax -> rax (расширение значения argc из int в long long)
	cmp	QWORD PTR -56[rbp], rax			#	cmp i, argc
	jb	.L29							#	if (i < argc) {goto .L29 (тело цикла for)} 

	#	char *string = 0;
	mov	QWORD PTR -48[rbp], 0			#	string = 0 (инициализируем и сохраняем локальную переменную на стеке)
	
	#	if (random_size) - проверяем, была ли опция --rand И нужно ли генерировать массив
	cmp	QWORD PTR -64[rbp], 0			#	cmp random_size (-64[rbp]), 0		
	je	.L30							#	if (random_size == 0) {goto .L30}

	#	string = random_string(random_size);
	mov	rax, QWORD PTR -64[rbp]			#	rax = random_size (-64[rbp])
	mov	rdi, rax						#	rdi = random_size - первый аргумент
	call	random_string				#	rax = random_string(rdi = random_size) - генерируем рандомную строку
	mov	QWORD PTR -48[rbp], rax			#	str = random_string(random_size) - присваиваем локальному указателю (-48[rbp])
	
	#	 write_string(string, input); - записываем сгенерированную строку в input для помощи в тестировании
	mov	rdx, QWORD PTR -40[rbp]			#	rdx = input (-40[rbp])
	mov	rax, QWORD PTR -48[rbp]			#	rax = str (-48[rbp])
	mov	rsi, rdx						#	rsi = input - второй аргумент
	mov	rdi, rax						#	rdi = string - первый аргумент
	call	write_string				#	write_string(rdi = string, rsi = input) - вызов функции
	jmp	.L31

	#	string = read_string(input); - если не нужно рандомно генерировать строку
.L30:
	mov	rax, QWORD PTR -40[rbp]			#	rax = input (-40[rbp])
	mov	rdi, rax						#	rdi = input - первый аргумент
	call	read_string					#	rax = read_string(rdi = input) - вызов чтении функции
	mov	QWORD PTR -48[rbp], rax			#	str = read_string(input) (-48[rbp])

.L31:
	#	clock_t time_start = clock();
	call	clock@PLT					#	rax = clock()
	mov	QWORD PTR -24[rbp], rax			#	time_start = rax = clock (сохраняем на стеке -24[rbp])
	
	#	unsigned int uppercase = count_uppercase(string);
	mov	rax, QWORD PTR -48[rbp]			#	rax = string (-48[rbp])
	mov	rdi, rax						#	rdi = string - первый аргумент
	call	count_uppercase				#	eax = count_uppercase(rdi = string) - считаем прописные буквы
	mov	DWORD PTR -72[rbp], eax			#	uppercase = count_uppercase(string) (сохраняем на стек -72[rbp])
	
	#	unsigned int lowercase = count_lowercase(string);
	mov	rax, QWORD PTR -48[rbp]			#	rax = string (-48[rbp])
	mov	rdi, rax						#	rdi = string - первый аргумент
	call	count_lowercase				#	eax = count_lowercase(rdi = string) - считаем строчные буквы
	mov	DWORD PTR -68[rbp], eax			#	lowercase = count_lowercase(string) (сохраняем на стек -68[rbp])
	
	#	if (TIME_FLAG) - нужно ли замерять время
	movzx	eax, BYTE PTR TIME_FLAG[rip]	#	eax = TIME_FLAG (с беззнаковым расширением)
	test	al, al						
	je	.L32							#	if (TIME_FLAG == 0) {then goto .L32}
	
	#	начало цикла for: int i = 0;
	mov	DWORD PTR -76[rbp], 0			#	i = 0 (сохраняем счетчик на стеке _76[rbp])
	jmp	.L33

	#	тело цикла for
.L34:
	#	count_uppercase(string);
	mov	rax, QWORD PTR -48[rbp]			#	rax = string (-48[rbp])
	mov	rdi, rax						#	rdi = string - первый аргумент
	call	count_uppercase				#	eax = count_uppercase(rdi = string)

	#	count_lowercase(string);
	mov	rax, QWORD PTR -48[rbp]			#	rax = string (-48[rbp])
	mov	rdi, rax						#	rdi = string - первый аргумент
	call	count_lowercase				#	eax = count_lowercase(rdi = string)

	#	++i
	add	DWORD PTR -76[rbp], 1			# i += 1 (-76[rbp] - локальный счетчик)

	#	условие цикла for: i < 500;
.L33:
	cmp	DWORD PTR -76[rbp], 499			#	cmp i (-76[rbp]), 499
	jle	.L34							#	if (i <= 499) {then goto .L34}

.L32:
	#	clock_t time_end = clock()
	call	clock@PLT					#	rax = clock()
	mov	QWORD PTR -16[rbp], rax			#	time_end = clock() - сохраняем переменную на стеке -16[rbp]
	
	#	write_result(uppercase, lowercase, output); - записываем результат в выходной файл
	mov	rdx, QWORD PTR -32[rbp]			#	rdx = output (-32[rbp]) - третий аргумент
	mov	ecx, DWORD PTR -68[rbp]			#	ecx = lowercase (-68[rbp])
	mov	eax, DWORD PTR -72[rbp]			#	eax = uppercase (-72[rbp])
	mov	esi, ecx						#	esi = lowercase - второй аргумент
	mov	edi, eax						#	esi = uppercase - первый аргумент
	call	write_result				#	write_result(rdi = uppercase, rdi = lowercase, rdx = output)

	#	if (TIME_FLAG) - проверяем, нужно ли измерять время работы
	movzx	eax, BYTE PTR TIME_FLAG[rip]	#	eax = TIME_FLAG (с беззнаковым расширением)
	test	al, al
	je	.L35								#	if (TIME_FLAG == 0) {then goto .L35}

	#	double cpu_time_used = ((double)(time_end - time_start)) / CLOCKS_PER_SEC;
	mov	rax, QWORD PTR -16[rbp]			#	rax = time_end (-16[rbp])
	sub	rax, QWORD PTR -24[rbp]			#	rax = time_end - time_start (-24[rbp])

	#	работа с числами с плавающей точкой
	cvtsi2sd	xmm0, rax				#	xmm0 = (double) (time_end - time_start) - конвертация int в double
	movsd	xmm1, QWORD PTR .LC7[rip]	#	xmm1 = CLOCKS_PER_SEC 
	divsd	xmm0, xmm1					#	xmm0 /= xmm1 (xmm0 = (time_end - time_start) / CLOCKS_PER_SEC)
	movsd	QWORD PTR -8[rbp], xmm0		#	cpu_time_used = xmm0 (сохраняем локальную переменную на стеке по адресу -8[rbp])
	mov	rax, QWORD PTR -8[rbp]			#	rax = cpu_time_used (-8[rbp])

	#	printf("Process time:%f seconds\n", cpu_time_used);
	movq	xmm0, rax					#	xmm0 = cpu_time_used - второй аргумент
	lea	rdi, .LC8[rip]					#	rdi = "Process time:%f seconds\n" (pointer to str) - первый аргумент
	mov	eax, 1
	call	printf@PLT					#	вызов printf(rdi, xmm0) - вывод затраченного времени

	#	free_memory(string); - очистка динамической памяти
.L35:
	mov	rax, QWORD PTR -48[rbp]			#	rax = string (-48[rbp])
	mov	rdi, rax						#	rdi = string - первый аргумент
	call	free_memory					#	free_memory(rdi = string) - вызов функции
	
	mov	eax, 0	
	leave
	ret									#	return 0; - завершение программы
	.size	main, .-main
	.section	.rodata
	.align 8
.LC7:
	.long	0
	.long	1093567616
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",@progbits
