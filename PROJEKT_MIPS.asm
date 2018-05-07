.eqv IN_BUF_LEN 4
.eqv OUT_BUF_LEN 4

.globl main
.data
intro:	.ascii	"The Huffman Coding - MIPS \"Big Project\"\n"
	.asciiz "Copyright: Politechnika Warszawska, Author: Michal Parafiniuk (285634)\n"
prompt1:	.asciiz	"Input file (path): "
prompt2:	.asciiz "Output file (path): "
prompt3:	.asciiz	"Do you want to encode? (leave empty if yes, write anything if you want to decode)"
file_error:	.asciiz "Error opening file! "
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
ascii_table:	.space 5120	# 256 * 20 - na ka�dy znak ascii 1 s�owo na d�ugo�� kodu i 16 bajt�w na sam kod
bit_head:	.word 0
bit_counter:	.byte 0

.text
main:
la $t0, output_buffer
sw $t0, bit_head		# ustaw g�owic� pisz�c� na pocz�tek output_buffer

li $v0, 4
la $a0, intro
syscall #wypisz intro

getInput:	# getInput
li $v0, 4
la $a0, prompt1
syscall #wypisz prompt1

li $v0, 8
la $a0, input_path
li $a1, 100
syscall #we� �cie�k� inputu

la $a0, input_path
jal pathSanitization #obetnij \n

li $v0, 13
la $a0, input_path
li $a1, 0
li $a2, 0
syscall #otw�rz plik
sb $v0, input_desc		# zapisz deskryptor otwartego pliku

#kontrola b��du
bgt $v0, $0, getOutput

li $v0, 4
la $a0, file_error
syscall #wypluj error
j getInput


getOutput:	# getOutput
li $v0, 4
la $a0, prompt2
syscall #wypisz prompt2

li $v0, 8
la $a0, output_path
li $a1, 100
syscall #we� �cie�k� outputu

la $a0, output_path
jal pathSanitization #obetnij \n

li $v0, 13
la $a0, output_path
li $a1, 1
li $a2, 0
syscall #otw�rz plik
sb $v0, output_desc		# zapisz deskryptor otwartego pliku w output_desc

#kontrola b��du
bgt $v0, $0, getMode

li $v0, 4
la $a0, file_error
syscall #wypluj error
j getOutput

getMode:	# getMode

li $v0, 4
la $a0, prompt3
syscall # wypisz prompt3

li $v0, 8
addiu $a0, $sp, -1
li $a1, 3
syscall # we� max 2 znaki

lb $t0, 1($a0)	# za�aduj drugi z nich
bnez $t0, DECODE	# je�eli nie jest \0, czyli cokolwiek zosta�o wpisane, DECODE

ENCODE:
#STATYSTYKA ZNAK�W TEKSTU
la $s7, ascii_stats	# $s7 = adres pocz�tku ascii_stats
jal Load		# za�aduj dane z pliku wej�ciowego
beqz $v0, end		# je�eli plik jest pusty, zako�cz program
add $t8, $0, $v0	# przygotowanie licznika znak�w w buforze (zapezpieczenie przed wyj�ciem poza bufor lub za�adowane znaki)
la $t9, input_buffer	# przygotowanie adresu pocz�tku pobranej porcji wej�ciowego pliku
stat_loop:
lb $t0, ($t9)		# we� do $t0 bie��cy znak
andi $t0, $t0, 0x000000ff # ogranicz dane tylko do tego bajtu 
mul $t1, $t0, 4		# za�aduj to $t1 warto�� wzi�tego znaku ASCII liczon� w s�owach
addu $t1, $s7, $t1	# stw�rz adres do ascii_stats z przesuni�ciem r�wnym warto�ci 4*ASCII
lw $t2, ($t1)		# we� do $t2 obecn� warto�� zliczonych znak�w tego rodzaju
addi $t2, $t2, 1	# zwi�ksz o jeden
sw $t2, ($t1)		# odstaw na miejsce
addiu $t9, $t9, 1	# przesu� si� o znak do przodu
addi $t8, $t8, -1	# zmniejsz licznik
bnez $t8, stat_loop	# je�eli nie wyszed�e� poza zakres, powt�rz
jal Load
add $t8, $0, $v0	# przygotowanie licznika znak�w w buforze (zapezpieczenie przed wyj�ciem poza bufor lub za�adowane znaki)
la $t9, input_buffer	# przygotowanie adresu pocz�tku pobranej porcji wej�ciowego pliku
bnez $v0, stat_loop	# je�eli co� wczytano, powtarzaj dalej

# wypisywanie statystyki znak�w
la $t0, ascii_stats	# za�aduj do $t0 adres ascii_stats
li $t9, 0		# za�aduj licznik
li $t8, 256		# g�rna granica licznika

stat_print_loop:
lb $t5, ($t0)		# za�aduj liczb� wyst�pie� obecnego znaku, �eby sprawdzi� czy w og�le wyst�puje
beqz $t5, stat_print_next	#je�eli nie wyst�puje, przejd� dalej

li $v0, 11		# print char
add $a0, $t9, $0		# za�aduj tego chara
syscall		# do it
li $v0, 4		# print string
la $a0, colon		# dwukropek i spacja
syscall		# do it
li $v0, 1		# print int
lw $a0, ($t0)		# za�aduj liczb� wyst�pie� znaku
syscall		# do it
li $v0, 4		# print string
la $a0, breakline	# nowa linia
syscall		# do it

stat_print_next:
addiu $t0, $t0, 4	# przejd� do nast�pnego znaku
addi $t9, $t9, 1	# zinkrementuj licznik
bne $t9, $t8, stat_print_loop	# loop

# utworzenie "drzewa" Huffmanowskiego

li $s5, 0xffffffff		# przygotuj null marker
move $s7, $sp			# zapisz obecny $sp do p�niejszego zwolnienia pami�ci
tree_loop:

find_min1_nodes:
move $t0, $s5			# $t0 - akumulator min1
move $t1, $s5			# $t1 - adres min1
la $t9, ascii_table		# przestaw g�owic� czytaj�c� na ascii_table, gdzie tymczasowo przechowywane s� adresy lu�nych w�z��w
f_m1_n_loop:
lw $t8, ($t9)			# wczytaj do $t8 adres w�z�a
beq $t8, $s5, f_m1_n_next	# je�eli null, przejd� do nast�pnego w�z�a
beqz $t8, find_min1_ascii	# je�li 0 (nie ma w�z�a, czyli koniec), przejd� do znajdowania min1 spo�r�d znak�w ascii
lw $t8, ($t8)			# wczytaj do $t8 warto�� w�z�a
bgeu $t8, $t0, f_m1_n_next	# je�eli warto�� wi�ksza r�wna min1, pomi�
move $t0, $t8			# zaktualizuj min1
lw $t1, ($t9)			# zaktualizuj adres min1
move $t2, $t9			# w miejsce warto�ci ASCII zapisz adres kom�rki w buforze z adresem w�z�a
f_m1_n_next:
addiu $t9, $t9, 4		# przesu� g�owic� czytaj�c� do przodu
j f_m1_n_loop			# powt�rz dla nast�pnego w�z�a

find_min1_ascii:
la $t9, ascii_stats		# $t9 - g�owica czytaj�ca
li $t7, 256			# $t7 - licznik do ko�ca ascii_stats

f_m1_a_loop:
lw $t8, ($t9)			# wczytaj warto�� z g�owicy czytaj�cej
beqz $t8, f_m1_a_next	# je�eli warto�� = 0, pomi�
bgeu $t8, $t0, f_m1_a_next	# je�eli warto�� wi�ksza r�wna min1, pomi�
move $t0, $t8			# zaktualizuj min1
move $t1, $t9			# zaktualizuj adres min1
la $t2, ascii_stats		# za�aduj adres ascii_stats do $t2
sub $t2, $t9, $t2		# zapisz warto�� 4*ASCII w $t2
sra $t2, $t2, 2			# $t2 = ASCII
f_m1_a_next:
addiu $t9, $t9, 4		# przesu� g�owic� czytaj�c� na nast�pne s�owo
addi $t7, $t7, -1		# zdekrementuj licznik
bnez $t7, f_m1_a_loop	# je�eli licznik si� sko�czy� (rozpatrzono wszystkie ascii), przejd� do szukania min2

find_min2_nodes:
move $t3, $s5			# $t3 - akumulator min2
move $t4, $s5			# $t4 - adres min2
la $t9, ascii_table		# przestaw g�owic� czytaj�c� na ascii_table, gdzie tymczasowo przechowywane s� adresy lu�nych w�z��w
f_m2_n_loop:
lw $t8, ($t9)			# wczytaj do $t8 adres w�z�a
beq $t8, $s5, f_m2_n_next	# je�eli null, przejd� do nast�pnego w�z�a
beqz $t8, find_min2_ascii	# je�li 0 (nie ma w�z�a, czyli koniec), szukaj w ascii
lw $t8, ($t8)			# wczytaj do $t8 warto�� w�z�a
bgeu $t8, $t3, f_m2_n_next	# je�eli warto�� wi�ksza r�wna min2, pomi�
lw $t4, ($t9)			# zaktualizuj adres min2
beq $t4, $t1, f_m2_n_next	# je�eli to ten sam element co w min1, pomi�
move $t3, $t8			# zaktualizuj min2
move $t5, $t9			# w miejsce warto�ci ASCII zapisz adres kom�rki w buforze z adresem w�z�a
f_m2_n_next:
addiu $t9, $t9, 4		# przesu� g�owic� czytaj�c� do przodu
j f_m2_n_loop			# powt�rz dla nast�pnego w�z�a

find_min2_ascii:
la $t9, ascii_stats		# $t9 - g�owica czytaj�ca
li $t7, 256			# $t7 - licznik do ko�ca ascii_stats

f_m2_a_loop:
lw $t8, ($t9)			# wczytaj warto�� z g�owicy czytaj�cej
beqz $t8, f_m2_a_next	# je�eli warto�� = 0, pomi�
bgeu $t8, $t3, f_m2_a_next	# je�eli warto�� wi�ksza r�wna min2, pomi�
move $a0, $t9			# wczytaj adres min2
beq $a0, $t1, f_m2_a_next	# je�eli to ten sam element co w min1, pomi�
move $t3, $t8			# zaktualizuj min2
move $t4, $a0			# zaktualizuj adres min2
la $t5, ascii_stats		# za�aduj adres ascii_stats do $t5
sub $t5, $t9, $t5		# zapisz warto�� 4*ASCII w $t5
sra $t5, $t5, 2			# $t5 = ASCII
f_m2_a_next:
addiu $t9, $t9, 4		# przesu� g�owic� czytaj�c� na nast�pne s�owo
addi $t7, $t7, -1		# zdekrementuj licznik
bnez $t7, f_m2_a_loop		# je�eli licznik si� sko�czy� (rozpatrzono wszystkie ascii), przejd� do tworzenia w�z�a z min1 i min2

create_node:

beq $t1, $s5, end		# $t1 = null => plik wej�ciowy pusty => zako�cz program
andi $t6, $t2, 0x11111100	# zapisz do $t6 starsze 3 bajty z $t2
bnez $t6, m1_is_node		# wykryj czy min1 jest w�z�em (je�eli jest w�z�em, wszystkie 3 starsze bajty nie b�d� zerowe)
sw $0, ($t1)			# wyzeruj w ascii_stats
sw $t0, ($sp)			# STW�RZ W�ZE�: zapisz min1
sw $t2, -4($sp)			# zapisz ASCII
sw $s5, -8($sp)			# ustaw adres lewego potomka na null
sw $s5, -12($sp)		# ustaw adres prawego potomka na null
move $t1, $sp			# zapisz w adresie min1 adres stworzonego w�z�a
addiu $sp, $sp, -16		# przesu� $sp
j m2				# przejd� do min2
m1_is_node:
sw $s5, ($t2)			# zapisz warto�� null w miejsce adresu w ascii_table

m2:
beq $s5, $t3, tree_save		# je�eli min2 = null, to znaczy �e jest tylko jeden w�ze�, czyli root => zako�czono tworzenie drzewa -> przejd� do zapisu drzewa w output_buffer
andi $t6, $t5, 0x11111100	# zapisz do $t6 starsze 3 bajty z $t5
bnez $t6, m2_is_node		# wykryj czy min2 jest w�z�em (je�eli jest w�z�em, wszystkie 3 starsze bajty nie b�d� zerowe)
sw $0, ($t4)			# wyzeruj w ascii_stats
sw $t3, ($sp)			# STW�RZ W�ZE�: zapisz min1
sw $t5, -4($sp)			# zapisz ASCII
sw $s5, -8($sp)			# ustaw adres lewego potomka na null
sw $s5, -12($sp)		# ustaw aders prawego potomka na null
move $t4, $sp			# zapisz w adresie min2 adres stworzonego w�z�a
addiu $sp, $sp, -16		# przesu� $sp
j create_node_wrap		# przejd� do tworzenia w�z�a ��cz�cego min1 i min2
m2_is_node:
sw $s5, ($t5)			# zapisz warto�� null w miejsce adresu w ascii_table

create_node_wrap:
add $t0, $t0, $t3		# wylicz sum� poddrzew
sw $t0, ($sp)			# zapisz warto�� w nowym w�le
sw $s5, -4($sp)			# zapisz null w warto�ci ASCII
sw $t1, -8($sp)			# zapisz adres min1 jako adres lewego potomka
sw $t4, -12($sp)		# zapisz adres min2 jako adres prawego potomka
la $t9, ascii_table		# ustaw g�owic� czytaj�c� na ascii_table

addiu $t9, $t9, -4		# przygotuj do nadchodz�cej p�tli
cnw_loop:
addiu $t9, $t9, 4		# przesu� g�owic� do przodu
lw $t8, ($t9)			# za�aduj warto��
bnez $t8, cnw_loop		# znajd� pierwsz� wolna kom�rk�

sw $sp, ($t9)			# zapisz adres nowo stworzonego w�z�a w ascii_table
addiu $sp, $sp, -16		# przesu� $sp
j tree_loop			# powt�rz operacj� a� si� sko�cz� w�z�y

tree_save:

# wyczy�� ascii_table
la $t6, ascii_table		# za�aduj adres ascii_table do $t6
ascii_table_clear:
sw $0, ($t6)			# wyzeruj s�owo
addiu $t6, $t6, 4		# przesu� g�owic�
lw $t7, ($t6)			# wczytaj nast�pne s�owo
bnez $t7, ascii_table_clear	# powt�rz a� nie wyczy�cisz wszystkiego co by�o zapisane

li $s6, 1			# przygotuj rejestr $s6, kt�ry od teraz b�dzie licznikiem "brudnych" bajt�w (takich, kt�re by�y zapisywane)

la $s4, ($t1)			# $s4 = root drzewa
move $t9, $s4			# ustaw g�owic� czytaj�c� na root drzewa
move $fp, $sp			# ustaw $fp na pocz�tek kom�rki buforowej (czyli kom�rki przechowuj�cej tymczasowy kod i jego d�ugo��)
addiu $fp, $fp, -12		# ustaw $fp na pocz�tek bufora kodu (wtedy pod -4($fp), a w�a�ciwie -1($fp) znajduje si� licznik d�ugo�ci kodu)
addiu $sp, $sp, -20		# stw�rz bufor kodu
sw $s5, ($sp)			# zapisz null marker na stosie (znacznik ko�ca algorytmu)
addiu $sp, $sp, -24		# przesu� $sp o kom�rk�

tree_save_loop:
lw $t8, -4($t9)			# wczytaj do $t8 warto�� ASCII
bltz $t8, ts_node		# sprawd� czy to node

ts_ascii:		# je�eli to ASCII, to 1. dopisz do kodu drzewa w output_buffer "1" i kod ASCII 2. zapisz kod znaku w ascii_table, 3. przejd� do prawego potomka ostatniego w�z�a na stosie (dodaj�c 1 do kodu)

# Dopisz "1" do schematu drzewa w output_buffer
li $a0, 1			# $a0 = 1 (dopisywany bit)
lw $a1, bit_head		# wczytaj adres pisanego bajtu do $a1
lb $a2, bit_counter		# wczytaj liczb� bit�w zapisanych w tym bajcie
jal BitAppend_s		# dopisz
sb $v0, bit_counter		# zaktualizuj bit_counter
sw $v1, bit_head		# zaktualizuj bit_head

# Dopisz kod znaku ASCII do schematu drzewa w output_buffer
move $a0, $t8			# dane = kod ASCII
lw $a1, bit_head		# adres = bit_head
li $a2, 8			# n = 8 (liczba bit�w do zapisania)
jal ByteWrite		# zapisz

li $t0, 20			# $t0 = wielko�� jednej kom�rki ascii_table
mul $t6, $t8, $t0		# $t6 = przesuni�cie wzgl�dem pocz�tku ascii_table
la $t0, ascii_table		# $t0 = ascii_table
addu $t6, $t6, $t0		# $t6 = finalny adres odpowiedniego znaku ascii
lw $t0, -4($fp)			# za�aduj d�ugo�� kodu do $t0
sw $t0, 16($t6)			# zapisz d�ugo�� kodu w ascii_table
lw $t0, ($fp)			# przepisz kod z ($fp) do ascii_table
sw $t0, ($t6)			# ...
lw $t0, 4($fp)			# ...
sw $t0, 4($t6)			# ...
lw $t0, 8($fp)			# ...
sw $t0, 8($t6)			# ...
lw $t0, 12($fp)			# ...
sw $t0, 12($t6)			# przepisz kod z ($fp) do ascii_table

addiu $sp, $sp, 24		# zwi� stos o jeden node
lw $t9, ($sp)			# przesu� g�owic� na prawe dziecko
lw $t0, -4($sp)			# przepisz zawarto�� zwijanego node'a do bufora
sw $t0, -4($fp)			# ...
lw $t0, -8($sp)			# ...
sw $t0, ($fp)			# ...
lw $t0, -12($sp)		# ...
sw $t0, 4($fp)			# ...
lw $t0, -16($sp)		# ...
sw $t0, 8($fp)			# ...
lw $t0, -20($sp)		# ...
sw $t0, 12($fp)			# przepisz zawarto�� zwijanego node'a do bufora
sw $0, -20($sp)			# usu� zwijany node
sw $0, -16($sp)			# ...
sw $0, -12($sp)			# ...
sw $0, -8($sp)			# ...
sw $0, -4($sp)			# ...
sw $0, ($sp)			# usu� zwijany node
bltz $t9, tree_save_wrap	# je�eli prawe dziecko to null marker, zako�cz algorytm

# Dopisz "1" do kodu tymczasowego:
li $a0, 1			# bit do dopisania = 1 (bo w prawo w d� po drzewie)
lw $a2, -4($fp)			# wczytaj d�ugo�� kodu do $a2
li $t0, 8			# $t0 = 8
div $a2, $t0			# podziel d�ugo�� kodu przez 8 => LO = liczba zaj�tych bajt�w, HI = liczba zaj�tych bit�w w ostatnim bajcie
mfhi $a2			# $a2 = licznik bit�w
mflo $t0			# wczytaj do $t0 liczb� w pe�ni zaj�tych bajt�w
add $a1, $t0, $fp		# $a1 = $t0($fp) -> adres bajtu, kt�ry b�dziesz modyfikowa�
jal BitAppend		# dopisz ten bit w odpowiednie miejsce
lw $t0, -4($fp)			# wczytaj d�ugo�� kodu do $t0
addi $t0, $t0, 1		# zwi�ksz o 1
sw $t0, -4($fp)			# odstaw na miejsce

j tree_save_loop		# powt�rz dla poddrzewa

ts_node:		# je�eli to node, to dodaj "0" do kodu drzewa w output_buffer, zapisz si� na stosie i przejd� do lewego potomka, dodaj�c "1" do kodu znaku

# Dopisz "0" do schematu drzewa w output_buffer
li $a0, 0			# $a0 = 0 (dopisywany bit)
lw $a1, bit_head		# wczytaj adres pisanego bajtu do $a1
lb $a2, bit_counter		# wczytaj liczb� bit�w zapisanych w tym bajcie
jal BitAppend_s		# dopisz
sb $v0, bit_counter		# zaktualizuj bit_counter
sw $v1, bit_head		# zaktualizuj bit_head

lw $t7, -12($t9)		# zapisz w $t7 adres prawego potomka
sw $t7, ($sp)			# zapisz na stosie adres prawego potomka
lw $t9, -8($t9)			# przejd� do lewego potomka

lw $t0, -4($fp)		# wczytaj d�ugo�� kodu do $t0
sw $t0, -4($sp)			# zapisz d�ugo�� kodu do schematu na stosie
lw $t0, ($fp)			# zapisz kod tymczasowy z bufora do schematu na stosie
sw $t0, -8($sp)			# ...
lw $t0, 4($fp)			# ...
sw $t0, -12($sp)		# ...
lw $t0, 8($fp)			# ...
sw $t0, -16($sp)		# ...
lw $t0, 12($fp)			# ...
sw $t0, -20($sp)		# zapisz kod tymczasowy z bufora do schematu na stosie
addiu $sp, $sp, -24		# przesu� $sp

# Przygotuj argumenty BitAppend:
li $a0, 0			# bit do dopisania = 0 (bo w lewo w d� po drzewie)
lw $a2, -4($fp)			# wczytaj d�ugo�� kodu do $a2
li $t0, 8			# $t0 = 8
div $a2, $t0			# podziel d�ugo�� kodu przez 8 => LO = liczba zaj�tych bajt�w, HI = liczba zaj�tych bit�w w ostatnim bajcie
mfhi $a2			# $a2 = licznik bit�w
mflo $t0			# wczytaj do $t0 liczb� w pe�ni zaj�tych bajt�w
add $a1, $t0, $fp		# $a1 = $t0($fp) -> adres bajtu, kt�ry b�dziesz modyfikowa�
jal BitAppend			# dopisz ten bit w odpowiednie miejsce
lw $t0, -4($fp)			# wczytaj d�ugo�� kodu do $t0
addi $t0, $t0, 1		# zwi�ksz o 1
sw $t0, -4($fp)		# odstaw na miejsce

j tree_save_loop		# powt�rz dla poddrzewa

tree_save_wrap:
# znajd� ascii o kodzie sk�adaj�cym si� z samych zer i dodaj do kodu "1" na ko�cu, aby zapobiec anomaliom przy czytaniu pliku
la $t9, ascii_table		# ustaw g�owic� czytaj�c� na ascii_table
addiu $t9, $t9, -20		# przygotuj pod algorytm
marker_loop:
addiu $t9, $t9, 20		# przesu� g�owic� dalej
lb $t8, 16($t9)			# wczytaj d�ugo�� kodu
beqz $t8, marker_loop		# pomi�, je�eli d�ugo�� kodu = 0
lw $t0, ($t9)			# zsumuj ca�y kod w $t0
lw $t1, 4($t9)			# ...
add $t0, $t0, $t1		# ...
lw $t1, 8($t9)			# ...
add $t0, $t0, $t1		# ...
lw $t1, 12($t9)			# ...
add $t0, $t0, $t1		# zsumuj ca�y kod w $t0
bnez $t0, marker_loop		# je�eli suma ca�ego kodu != 0 => ca�y kod nie jest z�o�ony z samych zer => szukaj dalej
div $t8, $t8, 8			# $t8 = liczba ca�kowicie zapisanych bajt�w
add $t9, $t9, $t8		# $t9 = adres bajtu z ko�c�wk� kodu
li $a0, 1			# $a0 - bit do dopisania (na najmniej znacz�cym miejscu)
move $a1, $t9			# $a1 - adres docelowy
mfhi $a2			# $a2 - licznik ju� zaj�tych bit�w (od 1 do 8)
jal BitAppend		# dopisz
sw $a2, 16($t9)			# uaktualnij d�ugo�� kodu

move $sp, $s7			# zwi� stos


# KODOWANIE
li $v0, 16
lb $a0, input_desc
syscall # zamknij plik wej�ciowy

li $v0, 13
la $a0, input_path
li $a1, 0
li $a2, 0
syscall #otw�rz plik wej�ciowy raz jeszcze
sb $v0, input_desc		# zapisz deskryptor otwartego pliku

jal Load			# wczytaj porcj� danych
move $s7, $v0			# zapisz liczb� wczytanych bajt�w do $s7
la $t9, input_buffer		# ustaw g�owic� czytaj�c� znaki na pocz�tek input_buffer
encode_loop:
lb $t8, ($t9)			# za�aduj znak do $t8
andi $t8, $t8, 0x000000ff	# ogranicz dane tylko do tego bajtu
la $t7, ascii_table		# za�aduj do $t7 adres ascii_table
li $t0, 20			# $t0 = wielko�� kom�rki
mul $t8, $t8, $t0		# $t8 = ASCII*wielko�� kom�rki = wzgl�dny adres kom�rki w ascii_table
addu $t7, $t7, $t8		# $t7 = bezwzgl�dny adres odpowiedniej kom�rki w ascii_table (g�owica czytaj�ca kod)
lw $t6, 16($t7)			# $t6 = d�ugo�� kodu
div $t5, $t6, 8			# $t5 = liczba w pe�ni zapisanych bajt�w (licznik)
mfhi $t4			# $t4 = liczba bit�w w ostatnim bajcie
beqz $t5, enc_mini_wrap		# je�eli liczba w pe�ni zapisanych bajt�w = 0, zapisz ostatni bajt
enc_mini_loop:	# zapisz wszystkie "pe�ne" bajty
lb $a0, ($t7)			# a0 = dane
lw $a1, bit_head		# a1 = adres
li $a2, 8			# a2 = liczba bit�w do wpisania
move $a3, $s6			# a3 = licznik bajt�w
jal ByteWrite		# dopisz kolejny bajt
move $s6, $a3			# zaktualizuj liczniik bajt�w
addiu $t7, $t7, 1		# przesu� g�owic� czytaj�c� kod na kolejny bajt
addi $t5, $t5, -1		# zmniejsz licznik w pe�ni zapisanych bajt�w
bnez $t5, enc_mini_loop		# powtarzaj a� do wyzerowania licznika (zapisania wszystkich "pe�nych" bajt�w)
enc_mini_wrap:	# zapisz ostatni, "niepe�ny" bajt
lb $a0, ($t7)			# $a0 = dane
lw $a1, bit_head		# $a1 = adres
move $a2, $t4			# $a2 = liczba bit�w do wpisania
move $a3, $s6			# $a3 = licznik bajt�w
jal ByteWrite		# dopisz ostatni bajt
move $s6, $a3			# zaktualizuj liczniik bajt�w
addiu $t9, $t9, 1		# przesu� g�owic� czytaj�c� do przodu
addi $s7, $s7, -1		# zmniejsz licznik o 1
bnez $s7, encode_loop		# je�eli jeszcze jest co kodowa�, powt�rz
jal Load			# wczytaj wi�cej
move $s7, $v0			# zapisz liczb� wczytanych bajt�w do $s7
la $t9, input_buffer		# ustaw g�owic� czytaj�c� znaki na pocz�tek input_buffer
bnez $s7, encode_loop		# jezeli wczytano cokolwiek, powt�rz

encode_wrap:
lw $t0, bit_head		# za�aduj adres g�owicy pisz�cej do $t0
lb $t1, ($t0)			# za�aduj ostatni bajt (prawdopodobnie niepe�ny) do $t1
lb $t2, bit_counter		# za�aduj bit_counter do $t2 (n)
sub $t2, $0, $t2		# $t2 = -$t2 (-n)
addi $t2, $t2, 8		# $t2 = 8 - n
sllv $t1, $t1, $t2		# dosu� ostatni bajt do lewej
sb $t1, ($t0)			# zapisz na miejscu

lb $t0, bit_counter		# za�aduj bit_counter do $t0
addi $t0, $t0, -1		# odejmij 1 => bit_counter < 0 wtedy i tylko wtedy, gry by�o = 0
bgezal $t0, Encode_Save		# je�eli bit_counter != 0, zapisz output_buffer (bit_counter = 0 wtedy i tylko wtedy, gdy dokonano przed chwil� zapisu i output_buffer jest pusty)
j end				# zako�cz program


DECODE:

jal Load			# wczytaj dane do bufora
beqz $v0, end			# je�eli nic nie wczytano, to znaczy �e plik jest pusty => zako�cz program
move $s7, $v0			# zapisz liczb� wczytanych bajt�w do $s7
la $t0, input_buffer		# $t0 = adres input_buffer
sw $t0, bit_head		# ustaw g�owic� czytaj�c� na pocz�tek input_buffer
li $s5, 0xffffffff		# wczytaj null marker do $t0
move $s3, $0			# wczytaj 0 do $s3
addiu $s4, $sp, -4		# wczytaj neutralny adres do $s4 (zabezpieczenie przed b��dem)

read_tree:
move $a3, $s7			# $a3 = licznik wczytanych bajt�w
jal ReadBit			# wczytaj bit
move $s7, $a3			# zaktualizuj licznik
bnez $a0, read_tree_ascii	# sprawd� czy to node, czy li��

read_tree_node:
sw $s3, ($sp)			# STW�RZ NOWY NODE: zapisz adres rodzica
sw $sp, ($s4)			# zapisz adres dziecka w parent node
sw $s5, -4($sp)			# zapisz null marker w miejscu ASCII
sw $0, -8($sp)			# zapisz 0 w miejscu adresu lewego potomka
sw $0, -12($sp)			# zapisz 0 w miejscu adresu prawego potomka
move $s3, $sp			# przesu� $s3 na nowy node
addiu $s4, $s3, -8		# ustaw $s4 na adres lewego potomka
addiu $sp, $sp, -16		# przesu� $sp na wolne miejsce
j read_tree			# wczytuj dalej

read_tree_ascii:
sw $s3, ($sp)			# STW�RZ NOWY LI��: zapisz adres rodzica
sw $sp, ($s4)			# zapisz adres potomka pod $s4
addiu $sp, $sp, -16		# przesu� $sp na nast�pne wolne miejsce
move $a3, $s7			# $a3 = licznik wczytanych bajt�w
jal ReadByte			# wczytaj nast�pny bajt danych (kod ASCII)
move $s7, $a3			# zaktualizuj licznik
sw $v0, 12($sp)			# zapisz kod ASCII

subu $t0, $s3, $s4		# $t0 = po�o�enie $s4 wzgl�dem $s3
beq $t0, 12, tree_right		# je�eli w�a�nie stworzy�e� prawego potomka, przejd� w inne miejsce; je�eli lewego:
addiu $s4, $s4, -4		# przesu� $s4 z adresu lewego potomka na prawy
j read_tree			# wczytuj dalej
tree_right:
lw $s3, ($s3)			# przejd� do parenta
beqz $s3, decode		# je�eli wyszed�e� z roota, zako�cz algorytm
addiu $s4, $s3, -12		# ustaw $s4 na adres prawego dziecka
lw $t0, ($s4)			# wczytaj adres prawego dziecka
bnez $t0, tree_right		# przejd� wy�ej, je�eli ju� jest
j read_tree			# wczytuj dalej

decode:
addiu $s3, $s4, 12		# ustaw $s3 na root drzewa
move $s4, $s3			# $s4 te�
move $s0, $0			# przygotuj zero_flag (znacznik odpowiadaj�cy za to, czy czytany kod sk�ada si� z samych zer)
move $s1, $0			# przygotuj licznik zapisanych bajt�w (znak�w)
la $s2, output_buffer		# ustaw g�owic� pisz�c� na pocz�tek output_buffer
decode_loop:
move $a3, $s7			# $a3 = licznik wczytanych bajt�w
jal ReadBit			# wczytaj bit
move $s7, $a3			# zaktualizuj licznik
beqz $a0, go_left		# je�eli to "0", id� w lewo po drzewie, je�eli nie, id� w prawo
go_right:
lw $s3, -12($s3)		# przejd� g�owic� do prawego dziecka
li $s0, 1			# ustaw zero_flag na warto�� niezerow�
j check				# sprawd� czy to li��
go_left:
lw $s3, -8($s3)			# przejd� g�owic� do lewego dziecka
check:
lw $t8, -4($s3)			# wczytaj ASCII
beq $t8, -1, decode_loop	# je�eli to node, wczytuj dalej; jezeli nie:
bnez $s0, write			# je�eli zero_flag != 0, zapisz ascii
jal ReadBit			# wczytaj nast�pny bit
move $s7, $a3			# zaktualizuj licznik
beqz $a0, decode_end		# je�eli nast�pny bit to te� 0 => wczytujesz same zera => EOF => koniec dekodowania

write:
sb $t8, ($s2)			# zapisz ASCII pod adresem wskazywanym przez g�owic� pisz�c�
addiu $s2, $s2, 1		# przesu� g�owic� pisz�c�
addi $s1, $s1, 1		# zinkrementuj licznik zapisanych bajt�w
li $t0, OUT_BUF_LEN		# wczytaj wielko�� bufora
addi $t0, $t0, -1		# odejmij 1
sub $t1, $t0, $s1		# $t1 = wielko�� bufora - liczba zapisanych bajt�w - 1 => przyjmuje warto�� ujemn� wtw, gdy $s1 = wielko�� bufora
bltzal $t1, Decode_Save		# je�eli $s1 = wielko�� bufora, zapisz
move $s3, $s4			# wr�� g�owic� chodz�c� po drzewie do roota
move $s0, $0			# wyzeruj zero_flag
j decode_loop			# dekoduj dalej

decode_end:
addi $t0, $s1, -1		# odejmij 1 od licznika zapisanych bajt�w
bgezal $t0, Decode_Save		# je�eli $s0 >= 0, znaczy �e by�o >= 1, czyli trzeba co� zapisa�

end:
li $v0, 4
la $a0, input_buffer
syscall #wypisz input_buffer

li $v0, 4
la $a0, breakline
syscall #wypisz \n

li $v0, 4
la $a0, output_buffer
syscall #wypisz output_buffer

li $v0, 10
syscall #zabij si� (i wszystkie swoje otwarte pliki)

# INNE FUNKCJE ------------------------------------

Load: # wczytanie pliku do bufora (a przynajmniej pierwsze lub kolejne N bajt�w)
li $v0, 14		# komenda "wczytaj"
lb $a0, input_desc	# $a0 = deskryptor pliku
la $a1, input_buffer	# $a1 = adres docelowy (input_buffer)
li $a2, IN_BUF_LEN 		# $a2 = liczba bajt�w do wczytania
syscall	# zr�b to
jr $ra			# wr�� sk�d przyby�e�

BitAppend_s:		# bezpieczna wersja Bit_Append, s�u��ca do pisania do output_buffer, uwzgl�dniaj�ca przepe�nienie bufora
sw $ra, ($sp)		# zapisz adres powrotu na stosie
addiu $sp, $sp, -4	# przesu� stos

bne $a2, 8, append	# je�eli bit_counter != 8, spokojnie przejd� do BitAppend
bne $s6, OUT_BUF_LEN, append	# je�eli bufor si� nie przepe�nia, przejd� do BitAppend
# je�eli oba warunki s� spe�nione (czyli bufor w�a�nie si� przepe�nia):
sw $a0, ($sp)		# zapisz na stosie warto�� $a0
sw $a1, -4($sp)		# zapisz na stosie warto�� $a1
sw $a2, -8($sp)		# zapisz na stosie warto�� $a2
addiu $sp, $sp, -12	# przesu� stos
jal Encode_Save		# zrzu� output_buffer do pliku
addiu $sp, $sp, 12	# wr�� stos
sw $a0, ($sp)		# wczytaj warto�� $a0
sw $a1, -4($sp)		# wczytaj warto�� $a1
sw $a2, -8($sp)		# wczytaj warto�� $a2

append:
move $a3, $s6		# wczytaj licznik bajt�w
jal BitAppend		# przejd� do BitAppend
move $s6, $a3		# uaktualnij licznik bajt�w
addiu $sp, $sp, 4	# cofnij stos
lw $ra, ($sp)		# wczytaj adres powrotu
jr $ra			# wr�� sk�d przyby�e�

Encode_Save:
sw $ra, ($sp)		# zapisz adres powrotu
addiu $sp, $sp, -4	# przesu� stos
move $a2, $s6		# $a2 = liczba bajt�w do zapisania
jal Save	# zapisz
li $s6, 1		# ustaw licznik zapisanych bajt�w na 1
sw $a1, bit_head	# ustaw g�owic� pisz�c� na pocz�tek bufora
sb $0, bit_counter	# wyzeruj bit_counter
addiu $sp, $sp, 4	# wr�� stos
lw $ra, ($sp)		# przywr�� adres powrotu
jr $ra 			# wr�� sk�d przyby�e�

Decode_Save:
sw $ra, ($sp)		# zapisz adres powrotu
addiu $sp, $sp, -4	# przesu� stos
move $a2, $s1		# $a2 = liczba bajt�w do zapisania
jal Save	# zapisz
move $s1, $0		# wyzeruj licznik bajt�w
la $s2, output_buffer	# ustaw g�owic� pisz�c� na pocz�tek bufora
addiu $sp, $sp, 4	# wr�� stos
lw $ra, ($sp)		# przywr�� adres powrotu
jr $ra			# wr�� sk�d przyby�e�

Save: # zrzucenie danych z output_buffer do pliku. Przyjmuje liczb� bajt�w do zapisania w $a2
li $v0, 15		# komenda "zapisz"
lb $a0, output_desc	# $a0 = deskryptor pliku
la $a1, output_buffer	# $a1 = adres bufora
syscall		# zr�b to
jr $ra			# wr�� sk�d przyby�e�

pathSanitization: # usuni�cie \n z ko�ca �cie�ki
li $t8, '\n'
addiu $a0, $a0, -1
PS_loop:
addiu $a0, $a0, 1
lb $t1, ($a0)
bne $t1, $t8, PS_loop
sb $0, ($a0)
jr $ra

ByteWrite:
# Dopisz 0-8 bit�w danych (n), zaczynaj�c od wskazanego miejsca (adr)
# $a0 - dane
# $a1 - adr
# $a2 - n
# Zwraca licznik w $v0 i (nowy) adres w $v1 i $a1. Korzysta z i aktualizuje bit_counter i bit_head
sw $ra, ($sp)		# zapisz na stosie adres powrotu
sw $s0, -4($sp)
sw $s2, -8($sp)
addiu $sp, $sp, -12	# zapisz na stosie warto�ci u�ywanych zmiennych sprzed wywo�ania

move $s2, $a2		# zapisz licznik w $s2
beqz $s2, WW_end	# je�eli licznik = 0, zako�cz procedur�
li $s0, 32		# $s0 = 32
sub $s0, $s0, $s2	# $s0 = 32 - n
sllv $s0, $a0, $s0	# $s0 = dane z $a0 dosuni�te do lewej (przesuni�te w lewo o 32-n )

WW_loop:
lb $a2, bit_counter	# wczytaj bit_counter do $a2
rol $a0, $s0, 1		# zapisz w $a0 dane (gdzie na najmniej znacz�cym miejscu znajduje si� bit do dopisania)
jal BitAppend		# wywo�aj funkcj� BitAppend
sb $v0, bit_counter	# zaktualizuj bit_counter
move $s6, $a3		# zaktualizuj licznik bajt�w
subi $v0, $v0, 8	# odejmij 8 od $v0
bnez $v0, WW_next	# sprawd� czy licznik bit�w = 8, je�eli tak:
li $t0, OUT_BUF_LEN	#   za�aduj wielko�� bufora
bne $s6, $t0, WW_next	#   sprawd�, czy przepe�nia si� bufor
jal Encode_Save		#   je�eli tak, zrzu� bufor do pliku
WW_next:
sll $s0, $s0, 1		# przesu� dane o 1 w lewo
addi $s2, $s2, -1	# zdekrementuj licznik
bnez $s2, WW_loop	# powt�rz, je�eli licznik != 0

WW_end:
sw $a1, bit_head	# uaktualnij bit_head
addiu $sp, $sp, 12	# cofnij stos
lw $s2, -8($sp)		
lw $s0, -4($sp)		# wczytaj warto�ci sprzed wywo�ania funkcji
lw $ra, ($sp)		# wczytaj adres powrotu ze stosu
jr $ra			# wr�� sk�d przyby�e�

BitAppend:
# Dopisz pojedynczy bit. Argumenty:
# $a0 - bit do dopisania (na najmniej znacz�cym miejscu)
# $a1 - adres docelowy
# $a2 - licznik ju� zaj�tych bit�w (od 1 do 8)
# $a3 - licznik zapisanych bajt�w (inkrementowany przy przej�ciu do nast�pnego bajtu)
# Zwraca licznik w $v0 i (nowy) adres w $v1 i $a1
sw $s0, ($sp)		# odstaw $s0 na stos
addiu $sp, $sp, 4	# przesu� stos

li $v1, 8
bne $a2, $v1, append_bit # je�eli licznik = 8:
addu $a1, $a1, 1	#   przejd� o bajt dalej
add $a3, $a3, 1		#   zwi�ksz licznik zapisanych bajt�w o 1
move $a2, $0		#   licznik bit�w = 0
append_bit:
lb $s0, ($a1)		# we� bajt spod podanego adresu
sll $s0, $s0, 1 	# przesu� o 1 w lewo
andi $a0, $a0, 1	# upewnij si� �e podany bit to tylko 1 bit
or $s0, $s0, $a0	# wpisz bit na koniec
sb $s0, ($a1)		# odstaw nowy bajt
addi $a2, $a2, 1	# zwi�ksz licznik

addiu $sp, $sp, -4	# zwi� stos
lw $s0, ($sp)		# przywr�� warto�� $s0

move $v0, $a2		# zwr�� licznik
move $v1, $a1		# zwr�c adres
jr $ra			# wr�� sk�d przyby�e�

ReadBit:
# Przeczytaj pojedynczy bit. Argumenty bierze z bit_head i bit_counter oraz $a3 (licznik wczytanych bajt�w)
# Zwraca wczytany bit w $a0, (nowy) adres w $a1 i nowe warto�ci licznik�w w $a2 i $a3. Korzysta z i uaktualnia bit_head i bit_counter
sw $ra, ($sp)		# zapisz na stosie adres powrotu
sw $s0, -4($sp)		# zapisz na stosie warto�� $s0
addiu $sp, $sp, -8	# przesu� $sp

lw $a1, bit_head	# wczytaj adres
lb $a2, bit_counter	# wczytaj licznik przeczytanych bit�w
li $s0, 7		# $s0 = 7
ble $a2, $s0, read	# sprawd� czy przeczytano ju� wszystkie bity z tego bajtu, je�li tak:
addiu $a1, $a1, 1	#	przesu� g�owic� o 1
sw $a1, bit_head	#	uaktualnij bit_head
li $a2, 0		#	wyzeruj licznik
addi $a3, $a3, -1	#	zdekrementuj licznik wczytanych bajt�w
bnez $a3, read		# 	sprawd�, czy przeczytano ju� wszystkie wczytane bajty, je�li tak:
jal Load		#		wczytaj wi�cej
move $a0, $0		# 		wyzeruj dane (na wypadek gdyby to by� EOF)
move $a3, $v0		# 		zaktualizuj licznik wczytanych bajt�w
beqz $a3, read_end	#		zako�cz, je�eli wczytano EOF
li $a2, 0		#		wyzeruj licznik
la $a1, input_buffer	# 		wczytaj adres input_buffer
sw $a1, bit_head 	#		ustaw g�owic� pisz�c� na pocz�tek input_buffer

read:
lb $a0, ($a1)		# wczytaj bajt do $a0
sub $s0, $s0, $a2	# $a3 = przesuni�cie w prawo wymagane, by ��dany bit znalaz� si� na najmniej znacz�cym miejscu
srlv $a0, $a0, $s0	# przesu� w lewo o przesuni�cie wyliczone powy�ej
andi $a0, $a0, 0x00000001 # zredukuj dane wynikowe tylko do tego jednego bitu
addi $a2, $a2, 1	# zwi�ksz licznik przeczytanych bit�w
sb $a2, bit_counter	# uaktualnij bit_counter

read_end:
addiu $sp, $sp, 8	# wr�� stos
lw $s0, -4($sp)		# przywr�� warto�� $s0
lw $ra, ($sp)		# przywr�� adres powrotu
jr $ra		# wr�� sk�d przyby�e�

ReadByte:
# Przeczytaj nast�pne 8 bit�w. Korzysta z ReadBit, a wi�c te� pos�uguje si� bit_head i bit_counter.
# Zwraca wczytany bajt w $v0 i ca�� reszt� jak ReadBit.
sw $s0, ($sp)		# zapisz warto�� $s0 na stosie
sw $s1, -4($sp)		# zapisz warto�� $s1 na stosie
sw $ra, -8($sp)		# zapisz adres powrotu na stosie
addiu $sp, $sp, -12	# przesu� stos

move $s1, $0		# wyzeruj akumulator danych
li $s0, 8		# przygotuj licznik
RB_loop:
jal ReadBit		# wczytaj bit
sll $s1, $s1, 1		# przesu� w lewo wynikowy bajt
or $s1, $s1, $a0	# dodaj na koniec wczytany bit
addi $s0, $s0, -1	# zdekrementuj licznik
bnez $s0, RB_loop	# powtarzaj a� do wyzerowania licznika
move $v0, $s1		# zwr�� wynik

addiu $sp, $sp, 12	# wr�� stos
lw $ra, -8($sp)		# przywr�� adres powrotu
lw $s1, -4($sp)		# przywr�� warto�� $s1
lw $s0, ($sp)		# przywr�� warto�� $s0
jr $ra			# wr�� sk�d przyby�e�
