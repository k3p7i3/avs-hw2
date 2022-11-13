	.file	"main.s"
	.intel_syntax noprefix
	.text

	.globl	TIME_FLAG
	.bss	#	секция с глобальными переменными
	.type	TIME_FLAG, @object
	.size	TIME_FLAG, 1
TIME_FLAG:
	.zero	1

    #   объявляем внешние функции из других файлов
    .extern read_string
	.extern write_string
    .extern write_result
    .extern count_lowercase
    .extern count_uppercase

    .text
	#	функция char *random_string(size_t size)
	.globl	random_string
	.type	random_string, @function
										#	точка входа в функцию random_string
random_string:
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp
	push 	rbx							#	сохраняем регистр rbx на стеке (будем его изменять)
	push	r12							#	сохраняем регистр r12 на стеке (будем его изменять)
	push	r13							#	сохраняем регистр r13 на стеке (будем его изменять)
	sub	rsp, 8							#	конец фрейма rsp -= 8 (размер фрейма 40 байтов + 8 адрес возврата)

	# сохраняем в регистры переданные аргументы
	mov	rbx, rdi						#	сохраняет в регистр rbx первый аргумент из rdi (size_t size в Си)

	#	char *str = malloc(size + 1);
	add rdi, 1							#	rdi = size + 1 (size уже хранился в rdi с начала работы функции)
	call	malloc@PLT					#	rax = malloc(rdi = size + 1) (т.к. sizeof(char) = 1)
	mov	r12, rax						#	str = malloc(size + 1) (сохраняем указатель в регистр r12)

	#	srand(time(NULL)); задаем "начало" для рандома на основе системного времени для уникальности
	xor edi, edi						#	edi = 0 - первый аргумент
	call	time@PLT					#	eax = time(edi = 0) - получаем системное время
	mov	edi, eax						#	edi = time(NULL) - первый аргумент
	call	srand@PLT					#	srand(edi = time(NULL)) - вызываем функцию

	#	начало цикла for: size_t i = 0;
	xor r13, r13						#	i = 0 (сохраняем счетчик в регистр r13)
	jmp	.L7

	#	тело цикла for
.L9:
	#	edx = rand() % (127 - 32) + 32; - символы из этого диапазона корректно отображаются в формате txt
	call	rand@PLT					#	randval = eax = rand() - вызываем рандомный генератор
	xor rdx, rdx						#	мы будем делить на число типа int -> делимое хранится в edx:eax, поэтому зануляем edx
	mov ecx, 95							#	ecx = 95 = 127 - 32 - число, по которому надо взять остаток от rand()
	div ecx								#	целочисленное деление на ecx=95, eax = rand()//95(частное), edx=rand()%95(остаток)
	add edx, 32							#	edx = rand() % (127 - 32) + 32

	#	str[i] = rand() % (127 - 32) + 32;
	mov BYTE PTR [r12 + r13], dl		#	r12 + r13 = str + i = &str[i]

.L8:   	#	++i - "обновление" цикла for
	add	r13, 1							#	i += 1 (r13)

	#	условие цикла for: i < size;
.L7:
	cmp	r13, rbx						#	cmp i(r13), size(rbx)
	jb	.L9								#	if (i < size) {goto .L9 - тело цикла}

	#	str[size] = 0;
	mov	BYTE PTR [r12 + rbx], 0			#	str[size] = '\0' - конец строки (r12 + rbx = &str[size])

	#	return str;
	mov	rax, r12						#	rax = str (r12) - возвращаемое значение
	#	восстанавливаем регистры, которые изначально сохранили на стеке
	add rsp, 8
	pop 	r13
	pop		r12
	pop		rbx
	pop 	rbp
	ret									#	return str
	.size	random_string, .-random_string


	#	функция void free_memory(char *str)
	.globl	free_memory
	.type	free_memory, @function
										#	точка входа в функцию free_array
free_memory:
	push	rbp
	mov	rbp, rsp						#	начало фрейма rbp = rsp
	
	#	free(str);
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
	push 	rbx							#	сохраняем регистр rbx на стеке (будем его изменять)
	push	r12							#	сохраняем регистр r12 на стеке (будем его изменять)
	push	r13							#	сохраняем регистр r13 на стеке (будем его изменять)
	push	r14							#	сохраняем регистр r14 на стеке (будем его изменять)

	sub	rsp, 16							#	конец фрейма rsp -= 16 (размер фрейма 56 байтов + 8 адрес возврата)
	
	#	два аргумента argc и argv передаются в main через rdi и rsi соответственно
	mov	ebx, edi						#	сохраняем int argc из edi в регистр rbx
	mov	r12, rsi						#	сохраняем char **argv из esi в регистр r12

	#	if (argc < 3) - проверяем, ввели ли файлы для ввода/вывода в качестве аргументов cmd
	cmp ebx, 2							#	cmp argc, 2
	jg	.L24							#	if (argc > 3) then {goto .L24}

	#	incorrect input - 2 arguments excepted
	#	fprintf(stderr, "2 argements excepted - input file and output file");
	mov	rcx, QWORD PTR stderr[rip]		# 	rcx = stderr - 4 аргумент
	mov	edx, 49							#	edx = 49 = len("2 argements excepted - input file and output file") - кол-во выводимых объектов - третий аргумент
	mov	esi, 1							#	esi = 1 = sizeof(char) - размер выводимых объектов - второй аргумент	
	lea	rdi, .LC4[rip]					#	rdi = "2 argements excepted - input file and output file" (pointer to the string) - первый агрумент
	call	fwrite@PLT					#	fwrite("2 argements excepted - input file and output file", 1, 49, stderr) - вывод ошибки
	
	#	exit(1);
	mov	edi, 1
	call	exit@PLT					#	exit(1) - аварийный выход

.L24:	
	#	size_t random_size = 0;
	mov	r13, 0							#	size_random = 0 - сохраняем локальную переменную в регистр r13
	
	#	начало цикла for: size_t i = 3;
	mov	r14, 3							#	i = 3 - сохраняем локальный счетчик цикла for в регистр r14
	jmp	.L25

.L29:
	#	if (!strcmp(argv[i], "--rand"))

	lea	rsi, .LC5[rip]					#	rsi = "--rand" (pointer to the string) - второй аргумент (передаем через rsi)
	mov	rdi, QWORD PTR [r12 + 8*r14]	#	rdi = argv[i] (r12 + 8*r14 = &argv[i], т.к sizeof(char*)=8) - первый аргумент					#	rdi = argv[i] - первый аргумент (передаем через rdi)
	call	strcmp@PLT					#	eax = strcmp(rdi = argv[i], rsi = "--rand)
	test	eax, eax
	jne	.L26							#	if (argv[i] != "--rand") {goto .L26}

	#	if (i + 1 < argc) 
	lea	rdx, 1[r14]						#	rdx = i + 1 (r14 = i)
	mov	eax, ebx						#	eax = argc (ebx)	
	cdqe								#	eax -> rax (расширение значения argc из int в size_t)
	cmp	rdx, rax						#	cmp i + 1, argc
	jnb	.L27							#	if (!(i + 1 < argc)) {goto .L27}

	#	random_size = atoi(argv[i + 1]); - тело if (i + 1 < argc)
	mov rdi, QWORD PTR 8[r12 + 8*r14]	#	rdi = argv[i + 1] (arg + 8*i + 8 = &argv[i+1]) - первый аргумент
	call	atoi@PLT					#	eax = atoi(rdi = argv[i + 1])
	cdqe								#	eax -> rax (расширение из int в long long) (rax = atoi (argv[i + 1]))
	mov	r13, rax						#	r13 = size_random = atoi (argv[i + 1]) (сохранение значения в регистр r13)

	#	if (!random_size)
.L27:
	cmp	r13, 0							#	cmp size_random (r13), 0
	jne	.L26							#	if (size_random != 0) {goto .L26}

	#	if (size_random == 0) - у опции --rand нет аргумента -> задаем дефолтное значение
	mov	r13, 1000						#	size_random = 1000 

	#	 if (!strcmp(argv[i], "--time"))
.L26:
	lea	rsi, .LC6[rip]					#	rsi = "--time" (pointer to the string) - второй аргумент (передаем через rsi)
	mov	rdi, QWORD PTR [r12 + 8*r14]	#	rdi = argv[i] (argv + 8*i = &argv[i]) - первый аргумент
	call	strcmp@PLT					#	eax = strcmp(rdi = argv[i], rsi = "--time")
	test	eax, eax
	jne	.L28							#	if (argv[i] != "--rand")) {goto .L28}

	#	if (argv[i] == "--time") - устанавливаем флаг замера времени TIME_FLAG
	mov	BYTE PTR TIME_FLAG[rip], 1		#	TIME_FLAG = 1

.L28:	#	обновление счетчика i
	add	r14, 1							#	++i (r14)

	#	условие цикла for: i < argc;
.L25:
	mov	eax, ebx						#	eax = argc (ebx)
	cdqe								#	eax -> rax (расширение значения argc из int в long long)
	cmp	r14, rax						#	cmp i, argc
	jb	.L29							#	if (i < argc) {goto .L29 (тело цикла for)} 

	#	char *string = 0;
	mov	rbx, 0							#	string = 0 (инициализируем и сохраняем в rbx, argc нам больше не нужен, rbx можно освободить для char *string)
	
	#	if (random_size) - проверяем, была ли опция --rand и нужно ли генерировать массив
	cmp	r13, 0							#	cmp random_size (r13), 0		
	je	.L30							#	if (random_size == 0) {goto .L30}

	#	string = random_string(random_size);
	mov	rdi, r13						#	rdi = random_size (r13) - первый аргумент
	call	random_string				#	rax = random_string(rdi = random_size) - генерируем рандомную строку
	mov	rbx, rax						#	str = random_string(random_size) - присваиваем указателю в rbx
	
	#	 write_string(string, input); - записываем сгенерированную строку в input для помощи в тестировании
	mov	rsi, QWORD PTR 8[r12]			#	rsi = input = argv[1] - второй аргумент
	mov	rdi, rbx						#	rdi = string - первый аргумент
	call	write_string				#	write_string(rdi = string, rsi = input = argv[1]) - вызов функции
	jmp	.L31

	#	string = read_string(input); - если не нужно рандомно генерировать строку
.L30:
	mov	rdi, QWORD PTR 8[r12]			#	rdi = input = argv[1] - первый аргумент
	call	read_string					#	rax = read_string(rdi = input) - вызов чтении функции
	mov	rbx, rax						#	str = read_string(input) - присваиваем указателю в rbx

.L31:
	#	clock_t time_start = clock();
	call	clock@PLT					#	rax = clock()
	mov	r13, rax						#	time_start = clock (сохраняем в регистре r13)
	
	#	unsigned int uppercase = count_uppercase(string);
	mov	rdi, rbx						#	rdi = string (rbx) - первый аргумент
	call	count_uppercase				#	eax = count_uppercase(rdi = string) - считаем прописные буквы
	mov	DWORD PTR -40[rbp], eax			#	uppercase = count_uppercase(string) - (сохраняем на стек -40[rbp])
	
	#	unsigned int lowercase = count_lowercase(string);
	mov	rdi, rbx						#	rdi = string - первый аргумент
	call	count_lowercase				#	eax = count_lowercase(rdi = string) - считаем строчные буквы
	mov	DWORD PTR -44[rbp], eax			#	lowercase = count_lowercase(string) (сохраняем на стек -44[rbp])
	
	#	if (TIME_FLAG) - нужно ли замерять время
	movzx	eax, BYTE PTR TIME_FLAG[rip]	#	eax = TIME_FLAG (с беззнаковым расширением)
	test	al, al						
	je	.L32							#	if (TIME_FLAG == 0) {then goto .L32}
	
	#	начало цикла for: int i = 0;
	mov	r14, 0							#	i = 0 (сохраняем счетчик в регистре r14)
	jmp	.L33

	#	тело цикла for
.L34:
	#	count_uppercase(string);
	mov	rdi, rbx						#	rdi = string (rbx) - первый аргумент
	call	count_uppercase				#	eax = count_uppercase(rdi = string)

	#	count_lowercase(string);
	mov	rdi, rbx						#	rdi = string (rbx) - первый аргумент
	call	count_lowercase				#	eax = count_lowercase(rdi = string)

	#	++i
	add	r14, 1							# i += 1 (r14 - локальный счетчик)

	#	условие цикла for: i < 500;
.L33:
	cmp	r14, 499						#	cmp i (-76[rbp]), 499
	jle	.L34							#	if (i <= 499) {then goto .L34}

.L32:
	#	clock_t time_end = clock()
	call	clock@PLT					#	rax = clock()

	neg r13								#	r13 = -time_start (сделали отрицательным)
	add	r13, rax						#	r13 = time_end - time_start - будем хранить разницу, так как две переменные нам все равно ни к чему
	
	#	write_result(uppercase, lowercase, output); - записываем результат в выходной файл
	mov	rdx, QWORD PTR 16[r12]			#	rdx = output = argv[2] (argv + 16 = &argv[2]) - третий аргумент
	mov	esi, DWORD PTR -44[rbp]			#	esi = lowercase (-44[rbp]) - второй аргумент
	mov	edi, DWORD PTR -40[rbp]			#	esi = uppercase (-40[rbp]) - первый аргумент
	call	write_result				#	write_result(rdi = uppercase, rdi = lowercase, rdx = output)

	#	if (TIME_FLAG) - проверяем, нужно ли измерять время работы
	movzx	eax, BYTE PTR TIME_FLAG[rip]	#	eax = TIME_FLAG (с беззнаковым расширением)
	test	al, al
	je	.L35								#	if (TIME_FLAG == 0) {then goto .L35}

	#	double cpu_time_used = ((double)(time_end - time_start)) / CLOCKS_PER_SEC;
	#	r13 = time_end - time_start
	#	работа с числами с плавающей точкой
	cvtsi2sd	xmm0, r13				#	xmm0 = (double) (time_end - time_start) - конвертация int в double
	movsd	xmm1, QWORD PTR .LC7[rip]	#	xmm1 = CLOCKS_PER_SEC 
	divsd	xmm0, xmm1					#	xmm0 /= xmm1 (xmm0 = (time_end - time_start) / CLOCKS_PER_SEC)

	#	printf("Process time:%f seconds\n", cpu_time_used);
	#	второй аргумент cpu_time_used передается через xmm0
	lea	rdi, .LC8[rip]					#	rdi = "Process time:%f seconds\n" (pointer to str) - первый аргумент
	mov	eax, 1
	call	printf@PLT					#	вызов printf(rdi, xmm0) - вывод затраченного времени

	#	free_memory(string); - очистка динамической памяти
.L35:
	mov	rdi, rbx						#	rdi = string (rbx) - первый аргумент
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
