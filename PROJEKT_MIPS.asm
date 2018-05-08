.eqv IN_BUF_LEN 4
.eqv OUT_BUF_LEN 4

.globl main
.data
intro:		.ascii	"The Huffman Coding - MIPS \"Big Project\"\n"
		.asciiz "Copyright: Politechnika Warszawska, Author: Michal Parafiniuk (285634)\n"
prompt1:	.asciiz	"Input file (path): "
prompt2:	.asciiz "Output file (path): "
prompt3:	.asciiz	"Do you want to encode? (leave empty if yes, write anything if you want to decode)"
file_error:	.asciiz "Error	opening file! "
colon:		.asciiz	": "
breakline:	.asciiz	"\n"

input_path:	.space 256
input_desc:	.byte 0	
input_buffer:	.space IN_BUF_LEN 
output_path:	.space 256
output_desc:	.byte 0
		.align 2
output_buffer:	.space OUT_BUF_LEN
		.align	2
ascii_stats:	.space 1024
ascii_table:	.space 5120	# 256 * 20 - na każdy znak ascii 1 słowo na długość kodu i 16 bajtów na sam kod
bit_head:	.word 0
bit_counter:	.byte 0

.text
main:		la	$t0, output_buffer
		sw	$t0, bit_head		# ustaw głowicę piszącą na początek output_buffer

		li	$v0, 4
		la	$a0, intro
		syscall #wypisz intro

getInput:	li	$v0, 4
		la	$a0, prompt1
		syscall #wypisz prompt1

		li	$v0, 8
		la	$a0, input_path
		li	$a1, 100
		syscall #weź ścieżkę inputu

		la	$a0, input_path
		jal	pathSanitization #obetnij \n

		li	$v0, 13
		la	$a0, input_path
		li	$a1, 0
		li	$a2, 0
		syscall #otwórz plik
		sb	$v0, input_desc		# zapisz deskryptor otwartego pliku

		#kontrola	błędu
		bgt	$v0, $0, getOutput

		li	$v0, 4
		la	$a0, file_error
		syscall #wypluj	error
		j	getInput


getOutput:	li	$v0, 4
		la	$a0, prompt2
		syscall #wypisz prompt2

		li	$v0, 8
		la	$a0, output_path
		li	$a1, 100
		syscall #weź ścieżkę outputu

		la	$a0, output_path
		jal	pathSanitization #obetnij \n

		li	$v0, 13
		la	$a0, output_path
		li	$a1, 1
		li	$a2, 0
		syscall #otwórz plik
		sb	$v0, output_desc		# zapisz deskryptor otwartego pliku w output_desc

		#kontrola	błędu
		bgt	$v0, $0, getMode

		li	$v0, 4
		la	$a0, file_error
		syscall #wypluj	error
		j	getOutput

getMode:	li	$v0, 4
		la	$a0, prompt3
		syscall # wypisz prompt3

		li	$v0, 8
		addiu	$a0, $sp, -1
		li	$a1, 3
		syscall # weź max 2 znaki

		lb	$t0, 1($a0)			# załaduj drugi z nich
		bnez	$t0, DECODE			# jeżeli nie jest \0, czyli cokolwiek zostało wpisane, DECODE

ENCODE:
		#STATYSTYKA ZNAKÓW TEKSTU
		la	$s7, ascii_stats		# $s7 = adres początku ascii_stats
		jal	Load				# załaduj dane z pliku wejściowego
		beqz	$v0, end			# jeżeli plik jest pusty, zakończ program
		add	$t8, $0, $v0			# przygotowanie licznika znaków w buforze (zapezpieczenie przed wyjęciem poza bufor lub załadowane znaki)
		la	$t9, input_buffer		# przygotowanie adresu początku pobranej	porcji wejściowego pliku
stat_loop:	lb	$t0, ($t9)			# weź do $t0 bieżący znak
		andi	$t0, $t0, 0x000000ff 		# ogranicz dane tylko do tego bajtu 
		mul	$t1, $t0, 4			# załaduj to $t1 wartość wziętego znaku ASCII liczoną w słowach
		addu	$t1, $s7, $t1			# stwórz adres do ascii_stats z przesunięciem równym wartości 4*ASCII
		lw	$t2, ($t1)			# weź do $t2 obecną wartość zliczonych znaków tego rodzaju
		addi	$t2, $t2, 1			# zwiększ o jeden
		sw	$t2, ($t1)			# odstaw na miejsce
		addiu	$t9, $t9, 1			# przesuń się o znak do przodu
		addi	$t8, $t8, -1			# zmniejsz licznik
		bnez	$t8, stat_loop			# jeżeli nie wyszedłeś poza zakres, powtórz
		jal	Load
		add	$t8, $0, $v0			# przygotowanie licznika znaków w buforze (zapezpieczenie przed wyjściem poza bufor lub załadowane znaki)
		la	$t9, input_buffer		# przygotowanie adresu początku pobranej	porcji wejściowego pliku
		bnez	$v0, stat_loop			# jeżeli coś wczytano, powtarzaj dalej

		# wypisywanie statystyki znaków
		la	$t0, ascii_stats		# załaduj do $t0 adres ascii_stats
		li	$t9, 0				# załaduj licznik
		li	$t8, 256			# górna granica licznika

stat_print:	lb	$t5, ($t0)			# załaduj liczbę wystąpień obecnego znaku, żeby sprawdzić czy w ogóle występuje
		beqz	$t5, s_p_next			#jeżeli nie występuje, przejdź dalej

		li	$v0, 11				# print char
		add	$a0, $t9, $0			# załaduj tego chara
		syscall		# do it
		li	$v0, 4				# print string
		la	$a0, colon			# dwukropek i spacja
		syscall		# do it
		li	$v0, 1				# print int
		lw	$a0, ($t0)			# załaduj liczbę wystąpień znaku
		syscall		# do it
		li	$v0, 4				# print string
		la	$a0, breakline			# nowa linia
		syscall		# do it
		
s_p_next:	addiu	$t0, $t0, 4			# przejdź do następnego znaku
		addi	$t9, $t9, 1			# zinkrementuj	licznik
		bne	$t9, $t8, stat_print		# loop

# utworzenie "drzewa" Huffmanowskiego

		li	$s5, 0xffffffff			# przygotuj null marker
		move	$s7, $sp			# zapisz obecny $sp do póniejszego zwolnienia pamięci
tree_loop:	move	$t0, $s5			# $t0 - akumulator	min1
		move	$t1, $s5			# $t1 - adres min1
		la	$t9, ascii_table		# przestaw głowicę czytającą na ascii_table, gdzie tymczasowo przechowywane są adresy luźnych węzłów
f_m1_n_loop:	lw	$t8, ($t9)			# wczytaj do $t8 adres węzła
		beq	$t8, $s5, f_m1_n_next		# jeżeli null, przejdź do następnego węzła
		beqz	$t8, f_m1_ascii			# jeśli	0 (nie ma węzła, czyli koniec), przejdź do znajdowania min1 spośród znaków ascii
		lw	$t8, ($t8)			# wczytaj do $t8 wartość węzła
		bgeu	$t8, $t0, f_m1_n_next		# jeżeli wartość większa równa min1, pomiń
		move	$t0, $t8			# zaktualizuj min1
		lw	$t1, ($t9)			# zaktualizuj adres min1
		move	$t2, $t9			# w miejsce wartości ASCII zapisz adres komórki w buforze z adresem węzła
f_m1_n_next:	addiu	$t9, $t9, 4			# przesuń głowicę czytającą do przodu
		j	f_m1_n_loop			# powtórz dla	następnego węzła

f_m1_ascii:	la	$t9, ascii_stats		# $t9 - głowica czytająca
		li	$t7, 256			# $t7 - licznik do końca ascii_stats

f_m1_a_loop:	lw	$t8, ($t9)			# wczytaj wartość z głowicy czytającej
		beqz	$t8, f_m1_a_next		# jeżeli wartość = 0, pomiń
		bgeu	$t8, $t0, f_m1_a_next		# jeżeli wartość większa równa min1, pomiń
		move	$t0, $t8			# zaktualizuj min1
		move	$t1, $t9			# zaktualizuj adres min1
		la	$t2, ascii_stats		# załaduj adres ascii_stats do $t2
		sub	$t2, $t9, $t2			# zapisz wartość 4*ASCII w $t2
		sra	$t2, $t2, 2			# $t2 = ASCII
f_m1_a_next:	addiu	$t9, $t9, 4			# przesuń głowicę czytającą na następne słowo
		addi	$t7, $t7, -1			# zdekrementuj licznik
		bnez	$t7, f_m1_a_loop		# jeżeli licznik się skończył (rozpatrzono wszystkie ascii), przejdź do szukania min2

f_m2_nodes:	move	$t3, $s5			# $t3 - akumulator	min2
		move	$t4, $s5			# $t4 - adres min2
		la	$t9, ascii_table		# przestaw głowicę czytającą na ascii_table, gdzie tymczasowo przechowywane są adresy luźnych węzłów
f_m2_n_loop:	lw	$t8, ($t9)			# wczytaj do $t8 adres węzła
		beq	$t8, $s5, f_m2_n_next		# jeżeli null, przejdź do następnego węzła
		beqz	$t8, f_min2_ascii		# jeśli	0 (nie ma węzła, czyli koniec), szukaj	w ascii
		lw	$t8, ($t8)			# wczytaj do $t8 wartość węzła
		bgeu	$t8, $t3, f_m2_n_next		# jeżeli wartość większa równa min2, pomiń
		lw	$t4, ($t9)			# zaktualizuj adres min2
		beq	$t4, $t1, f_m2_n_next		# jeżeli to ten sam element co w min1, pomiń
		move	$t3, $t8			# zaktualizuj min2
		move	$t5, $t9			# w miejsce wartości ASCII zapisz adres komórki w buforze z adresem węzła
f_m2_n_next:	addiu	$t9, $t9, 4			# przesuń głowicę czytającą do przodu
		j	f_m2_n_loop			# powtórz dla	następnego węzła

f_min2_ascii:	la	$t9, ascii_stats		# $t9 - głowica czytająca
		li	$t7, 256			# $t7 - licznik do końca ascii_stats

f_m2_a_loop:	lw	$t8, ($t9)			# wczytaj wartość z głowicy czytającej
		beqz	$t8, f_m2_a_next		# jeżeli wartość = 0, pomiń
		bgeu	$t8, $t3, f_m2_a_next		# jeżeli wartość większa równa min2, pomiń
		move	$a0, $t9			# wczytaj adres min2
		beq	$a0, $t1, f_m2_a_next		# jeżeli to ten sam element co w min1, pomiń
		move	$t3, $t8			# zaktualizuj min2
		move	$t4, $a0			# zaktualizuj adres min2
		la	$t5, ascii_stats		# załaduj adres ascii_stats do $t5
		sub	$t5, $t9, $t5			# zapisz wartość 4*ASCII w $t5
		sra	$t5, $t5, 2			# $t5 = ASCII
f_m2_a_next:	addiu	$t9, $t9, 4			# przesuń głowicę czytającą na następne słowo
		addi	$t7, $t7, -1			# zdekrementuj licznik
		bnez	$t7, f_m2_a_loop		# jeżeli licznik się skończył (rozpatrzono wszystkie ascii), przejdź do tworzenia węzła z min1 i min2

create_node:	beq	$t1, $s5, end			# $t1 = null => plik wejściowy pusty => zakończ program
		andi	$t6, $t2, 0x11111100		# zapisz do $t6 starsze 3 bajty z $t2
		bnez	$t6, m1_is_node			# wykryj czy min1 jest węzłem (jeżeli jest węzłem, wszystkie 3 starsze bajty nie będą zerowe)
		sw	$0, ($t1)			# wyzeruj w ascii_stats
		sw	$t0, ($sp)			# STWÓRZ WĘZEŁ: zapisz min1
		sw	$t2, -4($sp)			# zapisz ASCII
		sw	$s5, -8($sp)			# ustaw adres lewego potomka na null
		sw	$s5, -12($sp)			# ustaw adres prawego potomka na null
		move	$t1, $sp			# zapisz w adresie min1 adres stworzonego węzła
		addiu	$sp, $sp, -16			# przesuń $sp
		j	m2				# przejdź do min2
m1_is_node:	sw	$s5, ($t2)			# zapisz wartość null w miejsce adresu w ascii_table

m2:		beq	$s5, $t3, tree_save		# jeżeli min2 = null, to znaczy że jest tylko jeden węzeł, czyli root => zakończono tworzenie drzewa -> przejdź do zapisu drzewa w output_buffer
		andi	$t6, $t5, 0x11111100		# zapisz do $t6 starsze 3 bajty z $t5
		bnez	$t6, m2_is_node			# wykryj czy min2 jest węzłem (jeżeli jest węzłem, wszystkie 3 starsze bajty nie będą zerowe)
		sw	$0, ($t4)			# wyzeruj w ascii_stats
		sw	$t3, ($sp)			# STWÓRZ WĘZEŁ: zapisz min1
		sw	$t5, -4($sp)			# zapisz ASCII
		sw	$s5, -8($sp)			# ustaw adres lewego potomka na null
		sw	$s5, -12($sp)			# ustaw aders prawego potomka na null
		move	$t4, $sp			# zapisz w adresie min2 adres stworzonego węzła
		addiu	$sp, $sp, -16			# przesuń $sp
		j	c_n_wrap			# przejdź do tworzenia węzła łączącego min1 i min2
m2_is_node:	sw	$s5, ($t5)			# zapisz wartość null w miejsce adresu w ascii_table
		
c_n_wrap:	add	$t0, $t0, $t3			# wylicz sumę poddrzew
		sw	$t0, ($sp)			# zapisz wartość w nowym węźle
		sw	$s5, -4($sp)			# zapisz null w wartości ASCII
		sw	$t1, -8($sp)			# zapisz adres min1 jako adres lewego potomka
		sw	$t4, -12($sp)			# zapisz adres min2 jako adres prawego potomka
		la	$t9, ascii_table		# ustaw głowicę czytającą na ascii_table

		addiu	$t9, $t9, -4			# przygotuj do nadchodzącej	pętli
cnw_loop:	addiu	$t9, $t9, 4			# przesuń głowicę do przodu
		lw	$t8, ($t9)			# załaduj wartość
		bnez	$t8, cnw_loop			# znajdź pierwszą wolna komórkę

		sw	$sp, ($t9)			# zapisz adres nowo stworzonego węzła w ascii_table
		addiu	$sp, $sp, -16			# przesuń $sp
		j	tree_loop			# powtórz operację aż się skończą węzły

tree_save:
		# wyczyść ascii_table
		la	$t6, ascii_table		# załaduj adres ascii_table do $t6
clean:		sw	$0, ($t6)			# wyzeruj słowo
		addiu	$t6, $t6, 4			# przesuń głowicę
		lw	$t7, ($t6)			# wczytaj następne słowo
		bnez	$t7, clean			# powtórz aż nie wyczyścisz wszystkiego co było zapisane

		li	$s6, 1				# przygotuj rejestr $s6, który od teraz będzie licznikiem "brudnych" bajtów (takich, które były zapisywane)

		la	$s4, ($t1)			# $s4 = root drzewa
		move	$t9, $s4			# ustaw głowicę czytającą na root drzewa
		move	$fp, $sp			# ustaw $fp na początek komórki buforowej (czyli komórki przechowującej	tymczasowy kod i jego długość)
		addiu	$fp, $fp, -12			# ustaw $fp na początek bufora kodu (wtedy pod -4($fp), a właściwie -1($fp) znajduje się licznik długości kodu)
		addiu	$sp, $sp, -20			# stwórz bufor kodu
		sw	$s5, ($sp)			# zapisz null marker na stosie (znacznik końca algorytmu)
		addiu	$sp, $sp, -24			# przesuń $sp o komórkę

tree_save_loop:	lw	$t8, -4($t9)			# wczytaj do $t8 wartość ASCII
		bltz	$t8, ts_node			# sprawdź czy to node

ts_ascii:
		# jeżeli to ASCII, to 1. dopisz do kodu drzewa w output_buffer "1" i kod ASCII 2. zapisz kod znaku w ascii_table, 3. przejdź do prawego potomka ostatniego węzła na stosie (dodając 1 do kodu)

		# Dopisz "1" do schematu drzewa w output_buffer
		li	$a0, 1				# $a0 = 1 (dopisywany bit)
		lw	$a1, bit_head			# wczytaj adres pisanego bajtu do $a1
		lb	$a2, bit_counter		# wczytaj liczbę bitów zapisanych w tym bajcie
		jal	BitAppend_s			# dopisz
		sb	$v0, bit_counter		# zaktualizuj bit_counter
		sw	$v1, bit_head			# zaktualizuj bit_head

		# Dopisz kod znaku ASCII do schematu drzewa w output_buffer
		move	$a0, $t8			# dane = kod ASCII
		lw	$a1, bit_head			# adres = bit_head
		li	$a2, 8				# n = 8 (liczba bitów do zapisania)
		jal	ByteWrite			# zapisz

		li	$t0, 20				# $t0 = wielkość jednej	komórki ascii_table
		mul	$t6, $t8, $t0			# $t6 = przesunięcie względem początku ascii_table
		la	$t0, ascii_table		# $t0 = ascii_table
		addu	$t6, $t6, $t0			# $t6 = finalny adres odpowiedniego znaku ascii
		lw	$t0, -4($fp)			# załaduj długość kodu do $t0
		sw	$t0, 16($t6)			# zapisz długość kodu w ascii_table
		lw	$t0, ($fp)			# przepisz kod z ($fp) do ascii_table
		sw	$t0, ($t6)			# ...
		lw	$t0, 4($fp)			# ...
		sw	$t0, 4($t6)			# ...
		lw	$t0, 8($fp)			# ...
		sw	$t0, 8($t6)			# ...
		lw	$t0, 12($fp)			# ...
		sw	$t0, 12($t6)			# przepisz kod z ($fp) do ascii_table
		
		addiu	$sp, $sp, 24			# zwiń stos o jeden node
		lw	$t9, ($sp)			# przesuń głowicę na prawe dziecko
		lw	$t0, -4($sp)			# przepisz zawartość zwijanego node'a do bufora
		sw	$t0, -4($fp)			# ...
		lw	$t0, -8($sp)			# ...
		sw	$t0, ($fp)			# ...
		lw	$t0, -12($sp)			# ...
		sw	$t0, 4($fp)			# ...
		lw	$t0, -16($sp)			# ...
		sw	$t0, 8($fp)			# ...
		lw	$t0, -20($sp)			# ...
		sw	$t0, 12($fp)			# przepisz zawartość zwijanego node'a do bufora
		sw	$0, -20($sp)			# usuń zwijany node
		sw	$0, -16($sp)			# ...
		sw	$0, -12($sp)			# ...
		sw	$0, -8($sp)			# ...
		sw	$0, -4($sp)			# ...
		sw	$0, ($sp)			# usuń zwijany node
		bltz	$t9, tree_save_wrap		# jeżeli prawe dziecko to null marker, zakończ algorytm

		# Dopisz "1" do kodu tymczasowego:
		li	$a0, 1				# bit do dopisania = 1 (bo w prawo w dół po drzewie)
		lw	$a2, -4($fp)			# wczytaj długość kodu do $a2
		li	$t0, 8				# $t0 = 8
		div	$a2, $t0			# podziel długość kodu przez 8 => LO = liczba zajętych bajtów, HI = liczba zajętych bitów w ostatnim bajcie
		mfhi	$a2				# $a2 = licznik bitów
		mflo	$t0				# wczytaj do $t0 liczbę w pełni zajętych bajtów
		add	$a1, $t0, $fp			# $a1 = $t0($fp) -> adres bajtu, który będziesz modyfikować
		jal	BitAppend			# dopisz ten bit w odpowiednie miejsce
		lw	$t0, -4($fp)			# wczytaj długość kodu do $t0
		addi	$t0, $t0, 1			# zwiększ o 1
		sw	$t0, -4($fp)			# odstaw na miejsce
		
		j	tree_save_loop			# powtórz dla	poddrzewa
		
ts_node:
		# jeżeli to node, to dodaj "0" do kodu drzewa w output_buffer, zapisz się na stosie i przejdź do lewego potomka, dodając "1" do kodu znaku

		# Dopisz "0" do schematu drzewa w output_buffer
		li	$a0, 0				# $a0 = 0 (dopisywany bit)
		lw	$a1, bit_head			# wczytaj adres pisanego bajtu do $a1
		lb	$a2, bit_counter		# wczytaj liczbę bitów zapisanych w tym bajcie
		jal	BitAppend_s			# dopisz
		sb	$v0, bit_counter		# zaktualizuj bit_counter
		sw	$v1, bit_head			# zaktualizuj bit_head
		
		lw	$t7, -12($t9)			# zapisz w $t7 adres prawego potomka
		sw	$t7, ($sp)			# zapisz na stosie adres prawego potomka
		lw	$t9, -8($t9)			# przejdź do lewego potomka
		
		lw	$t0, -4($fp)			# wczytaj długość kodu do $t0
		sw	$t0, -4($sp)			# zapisz długość kodu do schematu na stosie
		lw	$t0, ($fp)			# zapisz kod tymczasowy z bufora do schematu na stosie
		sw	$t0, -8($sp)			# ...
		lw	$t0, 4($fp)			# ...
		sw	$t0, -12($sp)			# ...
		lw	$t0, 8($fp)			# ...
		sw	$t0, -16($sp)			# ...
		lw	$t0, 12($fp)			# ...
		sw	$t0, -20($sp)			# zapisz kod tymczasowy z bufora do schematu na stosie
		addiu	$sp, $sp, -24			# przesuń $sp

		# Przygotuj	argumenty BitAppend:
		li	$a0, 0				# bit do dopisania = 0 (bo w lewo w dół po drzewie)
		lw	$a2, -4($fp)			# wczytaj długość kodu do $a2
		li	$t0, 8				# $t0 = 8
		div	$a2, $t0			# podziel długość kodu przez 8 => LO = liczba zajętych bajtów, HI = liczba zajętych bitów w ostatnim bajcie
		mfhi	$a2				# $a2 = licznik bitów
		mflo	$t0				# wczytaj do $t0 liczbę w pełni zajętych bajtów
		add	$a1, $t0, $fp			# $a1 = $t0($fp) -> adres bajtu, który będziesz modyfikować
		jal	BitAppend			# dopisz ten bit w odpowiednie miejsce
		lw	$t0, -4($fp)			# wczytaj długość kodu do $t0
		addi	$t0, $t0, 1			# zwiększ o 1
		sw	$t0, -4($fp)			# odstaw na miejsce

		j	tree_save_loop			# powtórz dla	poddrzewa

tree_save_wrap:
		# znajdź ascii o kodzie składającym się z samych zer i dodaj	do kodu "1" na końcu, aby zapobiec anomaliom przy czytaniu pliku
		la	$t9, ascii_table		# ustaw głowicę czytającą na ascii_table
		addiu	$t9, $t9, -20			# przygotuj pod algorytm
marker_loop:	addiu	$t9, $t9, 20			# przesuń głowicę dalej
		lb	$t8, 16($t9)			# wczytaj długość kodu
		beqz	$t8, marker_loop		# pomiń, jeżeli długość kodu = 0
		lw	$t0, ($t9)			# zsumuj	cały kod w $t0
		lw	$t1, 4($t9)			# ...
		add	$t0, $t0, $t1			# ...
		lw	$t1, 8($t9)			# ...
		add	$t0, $t0, $t1			# ...
		lw	$t1, 12($t9)			# ...
		add	$t0, $t0, $t1			# zsumuj	cały kod w $t0
		bnez	$t0, marker_loop		# jeżeli suma całego kodu != 0 => cały kod nie jest złożony z samych zer => szukaj	dalej
		div	$t8, $t8, 8			# $t8 = liczba całkowicie zapisanych bajtów
		add	$t9, $t9, $t8			# $t9 = adres bajtu z końcówką kodu
		li	$a0, 1				# $a0 - bit do dopisania (na najmniej	znaczącym miejscu)
		move	$a1, $t9			# $a1 - adres docelowy
		mfhi	$a2				# $a2 - licznik już zajętych bitów (od 1 do 8)
		jal	BitAppend			# dopisz
		sw	$a2, 16($t9)			# uaktualnij długość kodu

		move	$sp, $s7			# zwiń stos


		# KODOWANIE
		li	$v0, 16
		lb	$a0, input_desc
		syscall # zamknij	plik wejściowy

		li	$v0, 13
		la	$a0, input_path
		li	$a1, 0
		li	$a2, 0
		syscall #otwórz plik wejściowy raz jeszcze
		sb	$v0, input_desc			# zapisz deskryptor otwartego pliku

		jal	Load				# wczytaj porcję danych
		move	$s7, $v0			# zapisz liczbę wczytanych bajtów do $s7
		la	$t9, input_buffer		# ustaw głowicę czytającą znaki na początek input_buffer
encode_loop:	lb	$t8, ($t9)			# załaduj znak do $t8
		andi	$t8, $t8, 0x000000ff		# ogranicz dane tylko do tego bajtu
		la	$t7, ascii_table		# załaduj do $t7 adres ascii_table
		li	$t0, 20				# $t0 = wielkość komórki
		mul	$t8, $t8, $t0			# $t8 = ASCII*wielkość komórki = względny adres komórki w ascii_table
		addu	$t7, $t7, $t8			# $t7 = bezwzględny adres odpowiedniej	komórki w ascii_table	(głowica czytająca kod)
		lw	$t6, 16($t7)			# $t6 = długość kodu
		div	$t5, $t6, 8			# $t5 = liczba w pełni zapisanych bajtów (licznik)
		mfhi	$t4				# $t4 = liczba bitów w ostatnim bajcie
		beqz	$t5, enc_mini_wrap		# jeżeli liczba w pełni zapisanych bajtów = 0, zapisz ostatni bajt
enc_mini_loop:	# zapisz wszystkie "pełne" bajty
		lb	$a0, ($t7)			# a0 = dane
		lw	$a1, bit_head			# a1 = adres
		li	$a2, 8				# a2 = liczba bitów do wpisania
		move	$a3, $s6			# a3 = licznik bajtów
		jal	ByteWrite			# dopisz kolejny bajt
		move	$s6, $a3			# zaktualizuj liczniik bajtów
		addiu	$t7, $t7, 1			# przesuń głowicę czytającą kod na kolejny bajt
		addi	$t5, $t5, -1			# zmniejsz licznik w pełni zapisanych bajtów
		bnez	$t5, enc_mini_loop		# powtarzaj aż do wyzerowania licznika (zapisania wszystkich "pełnych" bajtów)
enc_mini_wrap:	# zapisz ostatni, "niepełny" bajt
		lb	$a0, ($t7)			# $a0 = dane
		lw	$a1, bit_head			# $a1 = adres
		move	$a2, $t4			# $a2 = liczba bitów do wpisania
		move	$a3, $s6			# $a3 = licznik bajtów
		jal	ByteWrite			# dopisz ostatni bajt
		move	$s6, $a3			# zaktualizuj liczniik bajtów
		addiu	$t9, $t9, 1			# przesuń głowicę czytającą do przodu
		addi	$s7, $s7, -1			# zmniejsz licznik o 1
		bnez	$s7, encode_loop		# jeżeli jeszcze jest co kodować, powtórz
		jal	Load				# wczytaj więcej
		move	$s7, $v0			# zapisz liczbę wczytanych bajtów do $s7
		la	$t9, input_buffer		# ustaw głowicę czytającą znaki na początek input_buffer
		bnez	$s7, encode_loop		# jeżeli wczytano cokolwiek, powtórz

encode_wrap:	lw	$t0, bit_head			# załaduj adres głowicy piszącej	do $t0
		lb	$t1, ($t0)			# załaduj ostatni bajt (prawdopodobnie niepełny) do $t1
		lb	$t2, bit_counter		# załaduj bit_counter do $t2 (n)
		sub	$t2, $0, $t2			# $t2 = -$t2 (-n)
		addi	$t2, $t2, 8			# $t2 = 8 - n
		sllv	$t1, $t1, $t2			# dosuń ostatni bajt do lewej
		sb	$t1, ($t0)			# zapisz na miejscu

		lb	$t0, bit_counter		# załaduj bit_counter do $t0
		addi	$t0, $t0, -1			# odejmij 1 => bit_counter < 0 wtedy i tylko wtedy, gdy było = 0
		bgezal	$t0, Encode_Save		# jeżeli bit_counter != 0, zapisz output_buffer (bit_counter = 0 wtedy i tylko wtedy, gdy dokonano przed chwilą zapisu i output_buffer jest pusty)
		j	end				# zakończ program


DECODE:		jal	Load				# wczytaj dane do bufora
		beqz	$v0, end			# jeżeli nic nie wczytano, to znaczy że plik jest pusty => zakończ program
		move	$s7, $v0			# zapisz liczbę wczytanych bajtów do $s7
		la	$t0, input_buffer		# $t0 = adres input_buffer
		sw	$t0, bit_head			# ustaw głowicę czytającą na początek input_buffer
		li	$s5, 0xffffffff			# wczytaj null marker do $t0
		move	$s3, $0				# wczytaj 0 do $s3
		addiu	$s4, $sp, -4			# wczytaj neutralny adres do $s4 (zabezpieczenie przed błędem)

read_tree:	move	$a3, $s7			# $a3 = licznik wczytanych bajtów
		jal	ReadBit				# wczytaj bit
		move	$s7, $a3			# zaktualizuj licznik
		bnez	$a0, read_tree_ascii		# sprawdź czy to node, czy liść

read_tree_node:	sw	$s3, ($sp)			# STWÓRZ NOWY NODE: zapisz adres rodzica
		sw	$sp, ($s4)			# zapisz adres dziecka w parent node
		sw	$s5, -4($sp)			# zapisz null marker w miejscu ASCII
		sw	$0, -8($sp)			# zapisz 0 w miejscu adresu lewego potomka
		sw	$0, -12($sp)			# zapisz 0 w miejscu adresu prawego potomka
		move	$s3, $sp			# przesuń $s3 na nowy node
		addiu	$s4, $s3, -8			# ustaw $s4 na adres lewego potomka
		addiu	$sp, $sp, -16			# przesuń $sp na wolne miejsce
		j	read_tree			# wczytuj dalej

read_tree_ascii:sw	$s3, ($sp)			# STWÓRZ NOWY LIŚĆ: zapisz adres rodzica
		sw	$sp, ($s4)			# zapisz adres potomka pod $s4
		addiu	$sp, $sp, -16			# przesuń $sp na następne wolne miejsce
		move	$a3, $s7			# $a3 = licznik wczytanych bajtów
		jal	ReadByte			# wczytaj następny bajt danych (kod ASCII)
		move	$s7, $a3			# zaktualizuj licznik
		sw	$v0, 12($sp)			# zapisz kod ASCII
		
		subu	$t0, $s3, $s4			# $t0 = położenie $s4 względem $s3
		beq	$t0, 12, tree_right		# jeżeli właśnie stworzyłeś prawego potomka, przejdź w inne miejsce; jeżeli lewego:
		addiu	$s4, $s4, -4			# przesuń $s4 z adresu lewego potomka na prawy
		j	read_tree			# wczytuj dalej
tree_right:	lw	$s3, ($s3)			# przejdź do parenta
		beqz	$s3, decode			# jeżeli wyszedłeś z roota, zakończ algorytm
		addiu	$s4, $s3, -12			# ustaw $s4 na adres prawego dziecka
		lw	$t0, ($s4)			# wczytaj adres prawego dziecka
		bnez	$t0, tree_right			# przejdź wyżej, jeżeli już jest
		j	read_tree			# wczytuj dalej

decode:		addiu	$s3, $s4, 12			# ustaw $s3 na root drzewa
		move	$s4, $s3			# $s4 też
		move	$s0, $0				# przygotuj zero_flag (znacznik odpowiadający za to, czy czytany kod składa się z samych zer)
		move	$s1, $0				# przygotuj licznik zapisanych bajtów (znaków)
		la	$s2, output_buffer		# ustaw głowicę piszącą na początek output_buffer
decode_loop:	move	$a3, $s7			# $a3 = licznik wczytanych bajtów
		jal	ReadBit				# wczytaj bit
		move	$s7, $a3			# zaktualizuj licznik
		beqz	$a0, go_left			# jeżeli to "0", idź w lewo po drzewie, jeżeli nie, idź w prawo
go_right:	lw	$s3, -12($s3)			# przejdź głowicę do prawego dziecka
		li	$s0, 1				# ustaw zero_flag na wartość niezerową
		j	check				# sprawdź czy to liść
go_left:	lw	$s3, -8($s3)			# przejdź głowicę do lewego dziecka
check:		lw	$t8, -4($s3)			# wczytaj ASCII
		beq	$t8, -1, decode_loop		# jeżeli to node, wczytuj dalej; jezeli	nie:
		bnez	$s0, write			# jeżeli zero_flag != 0, zapisz ascii
		jal	ReadBit				# wczytaj następny bit
		move	$s7, $a3			# zaktualizuj licznik
		beqz	$a0, decode_end			# jeżeli następny bit to też 0 => wczytujesz same zera => EOF => koniec dekodowania

write:		sb	$t8, ($s2)			# zapisz ASCII pod adresem wskazywanym przez głowicę piszącą
		addiu	$s2, $s2, 1			# przesuń głowicę piszącą
		addi	$s1, $s1, 1			# zinkrementuj	licznik zapisanych bajtów
		li	$t0, OUT_BUF_LEN		# wczytaj wielkość bufora
		addi	$t0, $t0, -1			# odejmij 1
		sub	$t1, $t0, $s1			# $t1 = wielkość bufora - liczba zapisanych bajtów - 1 => przyjmuje wartość ujemną wtw, gdy $s1 = wielkość bufora
		bltzal	$t1, Decode_Save		# jeżeli $s1 = wielkość bufora, zapisz
		move	$s3, $s4			# wróć głowicę chodzącą po drzewie do roota
		move	$s0, $0				# wyzeruj zero_flag
		j	decode_loop			# dekoduj	dalej

decode_end:	addi	$t0, $s1, -1			# odejmij 1 od licznika zapisanych bajtów
		bgezal	$t0, Decode_Save		# jeżeli $s0 >= 0, znaczy że było >= 1, czyli trzeba coś zapisać

end:		li	$v0, 4
		la	$a0, input_buffer
		syscall 				# wypisz input_buffer

		li	$v0, 4
		la	$a0, breakline
		syscall 				# wypisz \n

		li	$v0, 4
		la	$a0, output_buffer
		syscall 				# wypisz output_buffer

		li	$v0, 10
		syscall 				# zabij	się (i wszystkie swoje otwarte pliki)

# INNE FUNKCJE ------------------------------------

Load:		# wczytanie pliku do bufora (a przynajmniej pierwsze lub kolejne N bajtów)
		li	$v0, 14			# komenda "wczytaj"
		lb	$a0, input_desc		# $a0 = deskryptor pliku
		la	$a1, input_buffer	# $a1 = adres docelowy (input_buffer)
		li	$a2, IN_BUF_LEN 	# $a2 = liczba bajtów do wczytania
		syscall	# zrób to
		jr	$ra			# wróć skąd przybyłeś

BitAppend_s:		# bezpieczna wersja Bit_Append, służąca do pisania do output_buffer, uwzględniająca przepełnienie bufora

		sw	$ra, ($sp)		# zapisz adres powrotu na stosie
		addiu	$sp, $sp, -4		# przesuń stos
		
		bne	$a2, 8, append		# jeżeli bit_counter != 8, spokojnie przejdź do BitAppend
		bne	$s6, OUT_BUF_LEN, append	# jeżeli bufor się nie przepełnia, przejdź do BitAppend
		# jeżeli oba warunki są spełnione (czyli bufor właśnie się przepełnia):
		sw	$a0, ($sp)		# zapisz na stosie wartość $a0
		sw	$a1, -4($sp)		# zapisz na stosie wartość $a1
		sw	$a2, -8($sp)		# zapisz na stosie wartość $a2
		addiu	$sp, $sp, -12		# przesuń stos
		jal	Encode_Save		# zrzuć output_buffer do pliku
		addiu	$sp, $sp, 12		# wróć stos
		sw	$a0, ($sp)		# wczytaj wartość $a0
		sw	$a1, -4($sp)		# wczytaj wartość $a1
		sw	$a2, -8($sp)		# wczytaj wartość $a2

append:		move	$a3, $s6		# wczytaj licznik bajtów
		jal	BitAppend		# przejdź do BitAppend
		move	$s6, $a3		# uaktualnij licznik bajtów
		addiu	$sp, $sp, 4		# cofnij stos
		lw	$ra, ($sp)		# wczytaj adres powrotu
		jr	$ra			# wróć skąd przybyłeś

Encode_Save:	sw	$ra, ($sp)		# zapisz adres powrotu
		addiu	$sp, $sp, -4		# przesuń stos
		move	$a2, $s6		# $a2 = liczba bajtów do zapisania
		jal	Save	# zapisz
		li	$s6, 1			# ustaw licznik zapisanych bajtów na 1
		sw	$a1, bit_head		# ustaw głowicę piszącą na początek bufora
		sb	$0, bit_counter		# wyzeruj bit_counter
		addiu	$sp, $sp, 4		# wróć stos
		lw	$ra, ($sp)		# przywróć adres powrotu
		jr	$ra 			# wróć skąd przybyłeś

Decode_Save:	sw	$ra, ($sp)		# zapisz adres powrotu
		addiu	$sp, $sp, -4		# przesuń stos
		move	$a2, $s1		# $a2 = liczba bajtów do zapisania
		jal	Save	# zapisz
		move	$s1, $0			# wyzeruj licznik bajtów
		la	$s2, output_buffer	# ustaw głowicę piszącą na początek bufora
		addiu	$sp, $sp, 4		# wróć stos
		lw	$ra, ($sp)		# przywróć adres powrotu
		jr	$ra			# wróć skąd przybyłeś

Save:		# zrzucenie danych z output_buffer do pliku. Przyjmuje liczbę bajtów do zapisania w $a2
		li	$v0, 15			# komenda "zapisz"
		lb	$a0, output_desc	# $a0 = deskryptor pliku
		la	$a1, output_buffer	# $a1 = adres bufora
		syscall		# zrób to
		jr	$ra			# wróć skąd przybyłeś

pathSanitization: # usunięcie \n z końca ścieżki
		li	$t8, '\n'
		addiu	$a0, $a0, -1
		PS_loop:
		addiu	$a0, $a0, 1
		lb	$t1, ($a0)
		bne	$t1, $t8, PS_loop
		sb	$0, ($a0)
		jr	$ra

ByteWrite:
		# Dopisz 0-8 bitów danych (n), zaczynając od wskazanego miejsca (adr)
		# $a0 - dane
		# $a1 - adr
		# $a2 - n
		# Zwraca licznik w $v0 i (nowy) adres w $v1 i $a1. Korzysta z i aktualizuje bit_counter i bit_head
		sw	$ra, ($sp)		# zapisz na stosie adres powrotu
		sw	$s0, -4($sp)
		sw	$s2, -8($sp)
		addiu	$sp, $sp, -12		# zapisz na stosie wartości używanych zmiennych sprzed wywołania
		
		move	$s2, $a2		# zapisz licznik w $s2
		beqz	$s2, WW_end		# jeżeli licznik = 0, zakończ procedurę
		li	$s0, 32			# $s0 = 32
		sub	$s0, $s0, $s2		# $s0 = 32 - n
		sllv	$s0, $a0, $s0		# $s0 = dane z $a0 dosunięte do lewej	(przesunięte w lewo o 32-n )

WW_loop:	lb	$a2, bit_counter	# wczytaj bit_counter do $a2
		rol	$a0, $s0, 1		# zapisz w $a0 dane (gdzie na najmniej	znaczącym miejscu znajduje się bit do dopisania)
		jal	BitAppend		# wywołaj funkcję BitAppend
		sb	$v0, bit_counter	# zaktualizuj bit_counter
		move	$s6, $a3		# zaktualizuj licznik bajtów
		subi	$v0, $v0, 8		# odejmij 8 od $v0
		bnez	$v0, WW_next		# sprawdź czy licznik bitów = 8, jeżeli tak:
		li	$t0, OUT_BUF_LEN	#   załaduj wielkość bufora
		bne	$s6, $t0, WW_next	#   sprawdź, czy przepełnia się bufor
		jal	Encode_Save		#   jeżeli tak, zrzuć bufor do pliku
WW_next:	sll	$s0, $s0, 1		# przesuń dane o 1 w lewo
		addi	$s2, $s2, -1		# zdekrementuj licznik
		bnez	$s2, WW_loop		# powtórz, jeżeli licznik != 0

WW_end:		sw	$a1, bit_head		# uaktualnij bit_head
		addiu	$sp, $sp, 12		# cofnij stos
		lw	$s2, -8($sp)		
		lw	$s0, -4($sp)		# wczytaj wartości sprzed wywołania funkcji
		lw	$ra, ($sp)		# wczytaj adres powrotu ze stosu
		jr	$ra			# wróć skąd przybyłeś

BitAppend:	# Dopisz pojedynczy bit. Argumenty:
		# $a0 - bit do dopisania (na najmniej	znaczącym miejscu)
		# $a1 - adres docelowy
		# $a2 - licznik już zajętych bitów (od 1 do 8)
		# $a3 - licznik zapisanych bajtów (inkrementowany przy przejściu do następnego bajtu)
		# Zwraca licznik w $v0 i (nowy) adres w $v1 i $a1
		sw	$s0, ($sp)		# odstaw $s0 na stos
		addiu	$sp, $sp, 4		# przesuń stos

		li	$v1, 8
		bne	$a2, $v1, append_bit 	# jeżeli licznik = 8:
		addu	$a1, $a1, 1		#   przejdź o bajt dalej
		add	$a3, $a3, 1		#   zwiększ licznik zapisanych bajtów o 1
		move	$a2, $0			#   licznik bitów = 0
append_bit:	lb	$s0, ($a1)		# weź bajt spod podanego adresu
		sll	$s0, $s0, 1 		# przesuń o 1 w lewo
		andi	$a0, $a0, 1		# upewnij się że podany bit to tylko 1 bit
		or	$s0, $s0, $a0		# wpisz bit na koniec
		sb	$s0, ($a1)		# odstaw nowy bajt
		addi	$a2, $a2, 1		# zwiększ licznik

		addiu	$sp, $sp, -4		# zwiń stos
		lw	$s0, ($sp)		# przywróć wartość $s0

		move	$v0, $a2		# zwróć licznik
		move	$v1, $a1		# zwróć adres
		jr	$ra			# wróć skąd przybyłeś
		
ReadBit:	# Przeczytaj	pojedynczy bit. Argumenty bierze z bit_head i bit_counter oraz $a3 (licznik wczytanych bajtów)
		# Zwraca wczytany bit w $a0, (nowy) adres w $a1 i nowe wartości liczników w $a2 i $a3. Korzysta z i uaktualnia bit_head i bit_counter
		sw	$ra, ($sp)		# zapisz na stosie adres powrotu
		sw	$s0, -4($sp)		# zapisz na stosie wartość $s0
		addiu	$sp, $sp, -8		# przesuń $sp
		
		lw	$a1, bit_head		# wczytaj adres
		lb	$a2, bit_counter	# wczytaj licznik przeczytanych bitów
		li	$s0, 7			# $s0 = 7
		ble	$a2, $s0, read		# sprawdź czy przeczytano już wszystkie bity z tego bajtu, jeśli tak:
		addiu	$a1, $a1, 1		#	przesuń głowicę o 1
		sw	$a1, bit_head		#	uaktualnij bit_head
		li	$a2, 0			#	wyzeruj licznik
		addi	$a3, $a3, -1		#	zdekrementuj licznik wczytanych bajtów
		bnez	$a3, read		# 	sprawdź, czy przeczytano już wszystkie wczytane bajty, jeśli tak:
		jal	Load			#		wczytaj więcej
		move	$a0, $0			# 		wyzeruj dane (na wypadek gdyby to był EOF)
		move	$a3, $v0		# 		zaktualizuj licznik wczytanych bajtów
		beqz	$a3, read_end		#		zakończ, jeżeli wczytano EOF
		li	$a2, 0			#		wyzeruj licznik
		la	$a1, input_buffer	# 		wczytaj adres input_buffer
		sw	$a1, bit_head 		#		ustaw głowicę piszącą na początek input_buffer

read:		lb	$a0, ($a1)		# wczytaj bajt do $a0
		sub	$s0, $s0, $a2		# $a3 = przesunięcie w prawo wymagane, by żądany bit znalazł się na najmniej	znaczącym miejscu
		srlv	$a0, $a0, $s0		# przesuń w lewo o przesunięcie wyliczone powyżej
		andi	$a0, $a0, 0x00000001 	# zredukuj dane wynikowe tylko do tego jednego bitu
		addi	$a2, $a2, 1		# zwiększ licznik przeczytanych bitów
		sb	$a2, bit_counter	# uaktualnij bit_counter

read_end:	addiu	$sp, $sp, 8		# wróć stos
		lw	$s0, -4($sp)		# przywróć wartość $s0
		lw	$ra, ($sp)		# przywróć adres powrotu
		jr	$ra			# wróć skąd przybyłeś

ReadByte:	# Przeczytaj	następne 8 bitów. Korzysta z ReadBit, a więc też posługuje się bit_head i bit_counter.
		# Zwraca wczytany bajt w $v0 i całą resztę jak ReadBit.
		sw	$s0, ($sp)		# zapisz wartość $s0 na stosie
		sw	$s1, -4($sp)		# zapisz wartość $s1 na stosie
		sw	$ra, -8($sp)		# zapisz adres powrotu na stosie
		addiu	$sp, $sp, -12		# przesuń stos

		move	$s1, $0			# wyzeruj akumulator danych
		li	$s0, 8			# przygotuj licznik
RB_loop:	jal	ReadBit			# wczytaj bit
		sll	$s1, $s1, 1		# przesuń w lewo wynikowy bajt
		or	$s1, $s1, $a0		# dodaj	na koniec wczytany bit
		addi	$s0, $s0, -1		# zdekrementuj licznik
		bnez	$s0, RB_loop		# powtarzaj aż do wyzerowania licznika
		move	$v0, $s1		# zwróć wynik

		addiu	$sp, $sp, 12		# wróć stos
		lw	$ra, -8($sp)		# przywróć adres powrotu
		lw	$s1, -4($sp)		# przywróć wartość $s1
		lw	$s0, ($sp)		# przywróć wartość $s0
		jr	$ra			# wróć skąd przybyłeś
