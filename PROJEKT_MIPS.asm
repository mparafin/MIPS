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
ascii_table:	.space 5120	# 256 * 20 - na ka¿dy znak ascii 1 s³owo na d³ugoœæ kodu i 16 bajtów na sam kod
bit_head:	.word 0
bit_counter:	.byte 0

.text
main:
la $t0, output_buffer
sw $t0, bit_head		# ustaw g³owicê pisz¹c¹ na pocz¹tek output_buffer

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
syscall #weŸ œcie¿kê inputu

la $a0, input_path
jal pathSanitization #obetnij \n

li $v0, 13
la $a0, input_path
li $a1, 0
li $a2, 0
syscall #otwórz plik
sb $v0, input_desc		# zapisz deskryptor otwartego pliku

#kontrola b³êdu
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
syscall #weŸ œcie¿kê outputu

la $a0, output_path
jal pathSanitization #obetnij \n

li $v0, 13
la $a0, output_path
li $a1, 1
li $a2, 0
syscall #otwórz plik
sb $v0, output_desc		# zapisz deskryptor otwartego pliku w output_desc

#kontrola b³êdu
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
syscall # weŸ max 2 znaki

lb $t0, 1($a0)	# za³aduj drugi z nich
bnez $t0, DECODE	# je¿eli nie jest \0, czyli cokolwiek zosta³o wpisane, DECODE

ENCODE:
#STATYSTYKA ZNAKÓW TEKSTU
la $s7, ascii_stats	# $s7 = adres pocz¹tku ascii_stats
jal Load		# za³aduj dane z pliku wejœciowego
beqz $v0, end		# je¿eli plik jest pusty, zakoñcz program
add $t8, $0, $v0	# przygotowanie licznika znaków w buforze (zapezpieczenie przed wyjœciem poza bufor lub za³adowane znaki)
la $t9, input_buffer	# przygotowanie adresu pocz¹tku pobranej porcji wejœciowego pliku
stat_loop:
lb $t0, ($t9)		# weŸ do $t0 bie¿¹cy znak
andi $t0, $t0, 0x000000ff # ogranicz dane tylko do tego bajtu 
mul $t1, $t0, 4		# za³aduj to $t1 wartoœæ wziêtego znaku ASCII liczon¹ w s³owach
addu $t1, $s7, $t1	# stwórz adres do ascii_stats z przesuniêciem równym wartoœci 4*ASCII
lw $t2, ($t1)		# weŸ do $t2 obecn¹ wartoœæ zliczonych znaków tego rodzaju
addi $t2, $t2, 1	# zwiêksz o jeden
sw $t2, ($t1)		# odstaw na miejsce
addiu $t9, $t9, 1	# przesuñ siê o znak do przodu
addi $t8, $t8, -1	# zmniejsz licznik
bnez $t8, stat_loop	# je¿eli nie wyszed³eœ poza zakres, powtórz
jal Load
add $t8, $0, $v0	# przygotowanie licznika znaków w buforze (zapezpieczenie przed wyjœciem poza bufor lub za³adowane znaki)
la $t9, input_buffer	# przygotowanie adresu pocz¹tku pobranej porcji wejœciowego pliku
bnez $v0, stat_loop	# je¿eli coœ wczytano, powtarzaj dalej

# wypisywanie statystyki znaków
la $t0, ascii_stats	# za³aduj do $t0 adres ascii_stats
li $t9, 0		# za³aduj licznik
li $t8, 256		# górna granica licznika

stat_print_loop:
lb $t5, ($t0)		# za³aduj liczbê wyst¹pieñ obecnego znaku, ¿eby sprawdziæ czy w ogóle wystêpuje
beqz $t5, stat_print_next	#je¿eli nie wystêpuje, przejdŸ dalej

li $v0, 11		# print char
add $a0, $t9, $0		# za³aduj tego chara
syscall		# do it
li $v0, 4		# print string
la $a0, colon		# dwukropek i spacja
syscall		# do it
li $v0, 1		# print int
lw $a0, ($t0)		# za³aduj liczbê wyst¹pieñ znaku
syscall		# do it
li $v0, 4		# print string
la $a0, breakline	# nowa linia
syscall		# do it

stat_print_next:
addiu $t0, $t0, 4	# przejdŸ do nastêpnego znaku
addi $t9, $t9, 1	# zinkrementuj licznik
bne $t9, $t8, stat_print_loop	# loop

# utworzenie "drzewa" Huffmanowskiego

li $s5, 0xffffffff		# przygotuj null marker
move $s7, $sp			# zapisz obecny $sp do póŸniejszego zwolnienia pamiêci
tree_loop:

find_min1_nodes:
move $t0, $s5			# $t0 - akumulator min1
move $t1, $s5			# $t1 - adres min1
la $t9, ascii_table		# przestaw g³owicê czytaj¹c¹ na ascii_table, gdzie tymczasowo przechowywane s¹ adresy luŸnych wêz³ów
f_m1_n_loop:
lw $t8, ($t9)			# wczytaj do $t8 adres wêz³a
beq $t8, $s5, f_m1_n_next	# je¿eli null, przejdŸ do nastêpnego wêz³a
beqz $t8, find_min1_ascii	# jeœli 0 (nie ma wêz³a, czyli koniec), przejdŸ do znajdowania min1 spoœród znaków ascii
lw $t8, ($t8)			# wczytaj do $t8 wartoœæ wêz³a
bgeu $t8, $t0, f_m1_n_next	# je¿eli wartoœæ wiêksza równa min1, pomiñ
move $t0, $t8			# zaktualizuj min1
lw $t1, ($t9)			# zaktualizuj adres min1
move $t2, $t9			# w miejsce wartoœci ASCII zapisz adres komórki w buforze z adresem wêz³a
f_m1_n_next:
addiu $t9, $t9, 4		# przesuñ g³owicê czytaj¹c¹ do przodu
j f_m1_n_loop			# powtórz dla nastêpnego wêz³a

find_min1_ascii:
la $t9, ascii_stats		# $t9 - g³owica czytaj¹ca
li $t7, 256			# $t7 - licznik do koñca ascii_stats

f_m1_a_loop:
lw $t8, ($t9)			# wczytaj wartoœæ z g³owicy czytaj¹cej
beqz $t8, f_m1_a_next	# je¿eli wartoœæ = 0, pomiñ
bgeu $t8, $t0, f_m1_a_next	# je¿eli wartoœæ wiêksza równa min1, pomiñ
move $t0, $t8			# zaktualizuj min1
move $t1, $t9			# zaktualizuj adres min1
la $t2, ascii_stats		# za³aduj adres ascii_stats do $t2
sub $t2, $t9, $t2		# zapisz wartoœæ 4*ASCII w $t2
sra $t2, $t2, 2			# $t2 = ASCII
f_m1_a_next:
addiu $t9, $t9, 4		# przesuñ g³owicê czytaj¹c¹ na nastêpne s³owo
addi $t7, $t7, -1		# zdekrementuj licznik
bnez $t7, f_m1_a_loop	# je¿eli licznik siê skoñczy³ (rozpatrzono wszystkie ascii), przejdŸ do szukania min2

find_min2_nodes:
move $t3, $s5			# $t3 - akumulator min2
move $t4, $s5			# $t4 - adres min2
la $t9, ascii_table		# przestaw g³owicê czytaj¹c¹ na ascii_table, gdzie tymczasowo przechowywane s¹ adresy luŸnych wêz³ów
f_m2_n_loop:
lw $t8, ($t9)			# wczytaj do $t8 adres wêz³a
beq $t8, $s5, f_m2_n_next	# je¿eli null, przejdŸ do nastêpnego wêz³a
beqz $t8, find_min2_ascii	# jeœli 0 (nie ma wêz³a, czyli koniec), szukaj w ascii
lw $t8, ($t8)			# wczytaj do $t8 wartoœæ wêz³a
bgeu $t8, $t3, f_m2_n_next	# je¿eli wartoœæ wiêksza równa min2, pomiñ
lw $t4, ($t9)			# zaktualizuj adres min2
beq $t4, $t1, f_m2_n_next	# je¿eli to ten sam element co w min1, pomiñ
move $t3, $t8			# zaktualizuj min2
move $t5, $t9			# w miejsce wartoœci ASCII zapisz adres komórki w buforze z adresem wêz³a
f_m2_n_next:
addiu $t9, $t9, 4		# przesuñ g³owicê czytaj¹c¹ do przodu
j f_m2_n_loop			# powtórz dla nastêpnego wêz³a

find_min2_ascii:
la $t9, ascii_stats		# $t9 - g³owica czytaj¹ca
li $t7, 256			# $t7 - licznik do koñca ascii_stats

f_m2_a_loop:
lw $t8, ($t9)			# wczytaj wartoœæ z g³owicy czytaj¹cej
beqz $t8, f_m2_a_next	# je¿eli wartoœæ = 0, pomiñ
bgeu $t8, $t3, f_m2_a_next	# je¿eli wartoœæ wiêksza równa min2, pomiñ
move $a0, $t9			# wczytaj adres min2
beq $a0, $t1, f_m2_a_next	# je¿eli to ten sam element co w min1, pomiñ
move $t3, $t8			# zaktualizuj min2
move $t4, $a0			# zaktualizuj adres min2
la $t5, ascii_stats		# za³aduj adres ascii_stats do $t5
sub $t5, $t9, $t5		# zapisz wartoœæ 4*ASCII w $t5
sra $t5, $t5, 2			# $t5 = ASCII
f_m2_a_next:
addiu $t9, $t9, 4		# przesuñ g³owicê czytaj¹c¹ na nastêpne s³owo
addi $t7, $t7, -1		# zdekrementuj licznik
bnez $t7, f_m2_a_loop		# je¿eli licznik siê skoñczy³ (rozpatrzono wszystkie ascii), przejdŸ do tworzenia wêz³a z min1 i min2

create_node:

beq $t1, $s5, end		# $t1 = null => plik wejœciowy pusty => zakoñcz program
andi $t6, $t2, 0x11111100	# zapisz do $t6 starsze 3 bajty z $t2
bnez $t6, m1_is_node		# wykryj czy min1 jest wêz³em (je¿eli jest wêz³em, wszystkie 3 starsze bajty nie bêd¹ zerowe)
sw $0, ($t1)			# wyzeruj w ascii_stats
sw $t0, ($sp)			# STWÓRZ WÊZE£: zapisz min1
sw $t2, -4($sp)			# zapisz ASCII
sw $s5, -8($sp)			# ustaw adres lewego potomka na null
sw $s5, -12($sp)		# ustaw adres prawego potomka na null
move $t1, $sp			# zapisz w adresie min1 adres stworzonego wêz³a
addiu $sp, $sp, -16		# przesuñ $sp
j m2				# przejdŸ do min2
m1_is_node:
sw $s5, ($t2)			# zapisz wartoœæ null w miejsce adresu w ascii_table

m2:
beq $s5, $t3, tree_save		# je¿eli min2 = null, to znaczy ¿e jest tylko jeden wêze³, czyli root => zakoñczono tworzenie drzewa -> przejdŸ do zapisu drzewa w output_buffer
andi $t6, $t5, 0x11111100	# zapisz do $t6 starsze 3 bajty z $t5
bnez $t6, m2_is_node		# wykryj czy min2 jest wêz³em (je¿eli jest wêz³em, wszystkie 3 starsze bajty nie bêd¹ zerowe)
sw $0, ($t4)			# wyzeruj w ascii_stats
sw $t3, ($sp)			# STWÓRZ WÊZE£: zapisz min1
sw $t5, -4($sp)			# zapisz ASCII
sw $s5, -8($sp)			# ustaw adres lewego potomka na null
sw $s5, -12($sp)		# ustaw aders prawego potomka na null
move $t4, $sp			# zapisz w adresie min2 adres stworzonego wêz³a
addiu $sp, $sp, -16		# przesuñ $sp
j create_node_wrap		# przejdŸ do tworzenia wêz³a ³¹cz¹cego min1 i min2
m2_is_node:
sw $s5, ($t5)			# zapisz wartoœæ null w miejsce adresu w ascii_table

create_node_wrap:
add $t0, $t0, $t3		# wylicz sumê poddrzew
sw $t0, ($sp)			# zapisz wartoœæ w nowym wêŸle
sw $s5, -4($sp)			# zapisz null w wartoœci ASCII
sw $t1, -8($sp)			# zapisz adres min1 jako adres lewego potomka
sw $t4, -12($sp)		# zapisz adres min2 jako adres prawego potomka
la $t9, ascii_table		# ustaw g³owicê czytaj¹c¹ na ascii_table

addiu $t9, $t9, -4		# przygotuj do nadchodz¹cej pêtli
cnw_loop:
addiu $t9, $t9, 4		# przesuñ g³owicê do przodu
lw $t8, ($t9)			# za³aduj wartoœæ
bnez $t8, cnw_loop		# znajdŸ pierwsz¹ wolna komórkê

sw $sp, ($t9)			# zapisz adres nowo stworzonego wêz³a w ascii_table
addiu $sp, $sp, -16		# przesuñ $sp
j tree_loop			# powtórz operacjê a¿ siê skoñcz¹ wêz³y

tree_save:

# wyczyœæ ascii_table
la $t6, ascii_table		# za³aduj adres ascii_table do $t6
ascii_table_clear:
sw $0, ($t6)			# wyzeruj s³owo
addiu $t6, $t6, 4		# przesuñ g³owicê
lw $t7, ($t6)			# wczytaj nastêpne s³owo
bnez $t7, ascii_table_clear	# powtórz a¿ nie wyczyœcisz wszystkiego co by³o zapisane

li $s6, 1			# przygotuj rejestr $s6, który od teraz bêdzie licznikiem "brudnych" bajtów (takich, które by³y zapisywane)

la $s4, ($t1)			# $s4 = root drzewa
move $t9, $s4			# ustaw g³owicê czytaj¹c¹ na root drzewa
move $fp, $sp			# ustaw $fp na pocz¹tek komórki buforowej (czyli komórki przechowuj¹cej tymczasowy kod i jego d³ugoœæ)
addiu $fp, $fp, -12		# ustaw $fp na pocz¹tek bufora kodu (wtedy pod -4($fp), a w³aœciwie -1($fp) znajduje siê licznik d³ugoœci kodu)
addiu $sp, $sp, -20		# stwórz bufor kodu
sw $s5, ($sp)			# zapisz null marker na stosie (znacznik koñca algorytmu)
addiu $sp, $sp, -24		# przesuñ $sp o komórkê

tree_save_loop:
lw $t8, -4($t9)			# wczytaj do $t8 wartoœæ ASCII
bltz $t8, ts_node		# sprawdŸ czy to node

ts_ascii:		# je¿eli to ASCII, to 1. dopisz do kodu drzewa w output_buffer "1" i kod ASCII 2. zapisz kod znaku w ascii_table, 3. przejdŸ do prawego potomka ostatniego wêz³a na stosie (dodaj¹c 1 do kodu)

# Dopisz "1" do schematu drzewa w output_buffer
li $a0, 1			# $a0 = 1 (dopisywany bit)
lw $a1, bit_head		# wczytaj adres pisanego bajtu do $a1
lb $a2, bit_counter		# wczytaj liczbê bitów zapisanych w tym bajcie
jal BitAppend_s		# dopisz
sb $v0, bit_counter		# zaktualizuj bit_counter
sw $v1, bit_head		# zaktualizuj bit_head

# Dopisz kod znaku ASCII do schematu drzewa w output_buffer
move $a0, $t8			# dane = kod ASCII
lw $a1, bit_head		# adres = bit_head
li $a2, 8			# n = 8 (liczba bitów do zapisania)
jal ByteWrite		# zapisz

li $t0, 20			# $t0 = wielkoœæ jednej komórki ascii_table
mul $t6, $t8, $t0		# $t6 = przesuniêcie wzglêdem pocz¹tku ascii_table
la $t0, ascii_table		# $t0 = ascii_table
addu $t6, $t6, $t0		# $t6 = finalny adres odpowiedniego znaku ascii
lw $t0, -4($fp)			# za³aduj d³ugoœæ kodu do $t0
sw $t0, 16($t6)			# zapisz d³ugoœæ kodu w ascii_table
lw $t0, ($fp)			# przepisz kod z ($fp) do ascii_table
sw $t0, ($t6)			# ...
lw $t0, 4($fp)			# ...
sw $t0, 4($t6)			# ...
lw $t0, 8($fp)			# ...
sw $t0, 8($t6)			# ...
lw $t0, 12($fp)			# ...
sw $t0, 12($t6)			# przepisz kod z ($fp) do ascii_table

addiu $sp, $sp, 24		# zwiñ stos o jeden node
lw $t9, ($sp)			# przesuñ g³owicê na prawe dziecko
lw $t0, -4($sp)			# przepisz zawartoœæ zwijanego node'a do bufora
sw $t0, -4($fp)			# ...
lw $t0, -8($sp)			# ...
sw $t0, ($fp)			# ...
lw $t0, -12($sp)		# ...
sw $t0, 4($fp)			# ...
lw $t0, -16($sp)		# ...
sw $t0, 8($fp)			# ...
lw $t0, -20($sp)		# ...
sw $t0, 12($fp)			# przepisz zawartoœæ zwijanego node'a do bufora
sw $0, -20($sp)			# usuñ zwijany node
sw $0, -16($sp)			# ...
sw $0, -12($sp)			# ...
sw $0, -8($sp)			# ...
sw $0, -4($sp)			# ...
sw $0, ($sp)			# usuñ zwijany node
bltz $t9, tree_save_wrap	# je¿eli prawe dziecko to null marker, zakoñcz algorytm

# Dopisz "1" do kodu tymczasowego:
li $a0, 1			# bit do dopisania = 1 (bo w prawo w dó³ po drzewie)
lw $a2, -4($fp)			# wczytaj d³ugoœæ kodu do $a2
li $t0, 8			# $t0 = 8
div $a2, $t0			# podziel d³ugoœæ kodu przez 8 => LO = liczba zajêtych bajtów, HI = liczba zajêtych bitów w ostatnim bajcie
mfhi $a2			# $a2 = licznik bitów
mflo $t0			# wczytaj do $t0 liczbê w pe³ni zajêtych bajtów
add $a1, $t0, $fp		# $a1 = $t0($fp) -> adres bajtu, który bêdziesz modyfikowaæ
jal BitAppend		# dopisz ten bit w odpowiednie miejsce
lw $t0, -4($fp)			# wczytaj d³ugoœæ kodu do $t0
addi $t0, $t0, 1		# zwiêksz o 1
sw $t0, -4($fp)			# odstaw na miejsce

j tree_save_loop		# powtórz dla poddrzewa

ts_node:		# je¿eli to node, to dodaj "0" do kodu drzewa w output_buffer, zapisz siê na stosie i przejdŸ do lewego potomka, dodaj¹c "1" do kodu znaku

# Dopisz "0" do schematu drzewa w output_buffer
li $a0, 0			# $a0 = 0 (dopisywany bit)
lw $a1, bit_head		# wczytaj adres pisanego bajtu do $a1
lb $a2, bit_counter		# wczytaj liczbê bitów zapisanych w tym bajcie
jal BitAppend_s		# dopisz
sb $v0, bit_counter		# zaktualizuj bit_counter
sw $v1, bit_head		# zaktualizuj bit_head

lw $t7, -12($t9)		# zapisz w $t7 adres prawego potomka
sw $t7, ($sp)			# zapisz na stosie adres prawego potomka
lw $t9, -8($t9)			# przejdŸ do lewego potomka

lw $t0, -4($fp)		# wczytaj d³ugoœæ kodu do $t0
sw $t0, -4($sp)			# zapisz d³ugoœæ kodu do schematu na stosie
lw $t0, ($fp)			# zapisz kod tymczasowy z bufora do schematu na stosie
sw $t0, -8($sp)			# ...
lw $t0, 4($fp)			# ...
sw $t0, -12($sp)		# ...
lw $t0, 8($fp)			# ...
sw $t0, -16($sp)		# ...
lw $t0, 12($fp)			# ...
sw $t0, -20($sp)		# zapisz kod tymczasowy z bufora do schematu na stosie
addiu $sp, $sp, -24		# przesuñ $sp

# Przygotuj argumenty BitAppend:
li $a0, 0			# bit do dopisania = 0 (bo w lewo w dó³ po drzewie)
lw $a2, -4($fp)			# wczytaj d³ugoœæ kodu do $a2
li $t0, 8			# $t0 = 8
div $a2, $t0			# podziel d³ugoœæ kodu przez 8 => LO = liczba zajêtych bajtów, HI = liczba zajêtych bitów w ostatnim bajcie
mfhi $a2			# $a2 = licznik bitów
mflo $t0			# wczytaj do $t0 liczbê w pe³ni zajêtych bajtów
add $a1, $t0, $fp		# $a1 = $t0($fp) -> adres bajtu, który bêdziesz modyfikowaæ
jal BitAppend			# dopisz ten bit w odpowiednie miejsce
lw $t0, -4($fp)			# wczytaj d³ugoœæ kodu do $t0
addi $t0, $t0, 1		# zwiêksz o 1
sw $t0, -4($fp)		# odstaw na miejsce

j tree_save_loop		# powtórz dla poddrzewa

tree_save_wrap:
# znajdŸ ascii o kodzie sk³adaj¹cym siê z samych zer i dodaj do kodu "1" na koñcu, aby zapobiec anomaliom przy czytaniu pliku
la $t9, ascii_table		# ustaw g³owicê czytaj¹c¹ na ascii_table
addiu $t9, $t9, -20		# przygotuj pod algorytm
marker_loop:
addiu $t9, $t9, 20		# przesuñ g³owicê dalej
lb $t8, 16($t9)			# wczytaj d³ugoœæ kodu
beqz $t8, marker_loop		# pomiñ, je¿eli d³ugoœæ kodu = 0
lw $t0, ($t9)			# zsumuj ca³y kod w $t0
lw $t1, 4($t9)			# ...
add $t0, $t0, $t1		# ...
lw $t1, 8($t9)			# ...
add $t0, $t0, $t1		# ...
lw $t1, 12($t9)			# ...
add $t0, $t0, $t1		# zsumuj ca³y kod w $t0
bnez $t0, marker_loop		# je¿eli suma ca³ego kodu != 0 => ca³y kod nie jest z³o¿ony z samych zer => szukaj dalej
div $t8, $t8, 8			# $t8 = liczba ca³kowicie zapisanych bajtów
add $t9, $t9, $t8		# $t9 = adres bajtu z koñcówk¹ kodu
li $a0, 1			# $a0 - bit do dopisania (na najmniej znacz¹cym miejscu)
move $a1, $t9			# $a1 - adres docelowy
mfhi $a2			# $a2 - licznik ju¿ zajêtych bitów (od 1 do 8)
jal BitAppend		# dopisz
sw $a2, 16($t9)			# uaktualnij d³ugoœæ kodu

move $sp, $s7			# zwiñ stos


# KODOWANIE
li $v0, 16
lb $a0, input_desc
syscall # zamknij plik wejœciowy

li $v0, 13
la $a0, input_path
li $a1, 0
li $a2, 0
syscall #otwórz plik wejœciowy raz jeszcze
sb $v0, input_desc		# zapisz deskryptor otwartego pliku

jal Load			# wczytaj porcjê danych
move $s7, $v0			# zapisz liczbê wczytanych bajtów do $s7
la $t9, input_buffer		# ustaw g³owicê czytaj¹c¹ znaki na pocz¹tek input_buffer
encode_loop:
lb $t8, ($t9)			# za³aduj znak do $t8
andi $t8, $t8, 0x000000ff	# ogranicz dane tylko do tego bajtu
la $t7, ascii_table		# za³aduj do $t7 adres ascii_table
li $t0, 20			# $t0 = wielkoœæ komórki
mul $t8, $t8, $t0		# $t8 = ASCII*wielkoœæ komórki = wzglêdny adres komórki w ascii_table
addu $t7, $t7, $t8		# $t7 = bezwzglêdny adres odpowiedniej komórki w ascii_table (g³owica czytaj¹ca kod)
lw $t6, 16($t7)			# $t6 = d³ugoœæ kodu
div $t5, $t6, 8			# $t5 = liczba w pe³ni zapisanych bajtów (licznik)
mfhi $t4			# $t4 = liczba bitów w ostatnim bajcie
beqz $t5, enc_mini_wrap		# je¿eli liczba w pe³ni zapisanych bajtów = 0, zapisz ostatni bajt
enc_mini_loop:	# zapisz wszystkie "pe³ne" bajty
lb $a0, ($t7)			# a0 = dane
lw $a1, bit_head		# a1 = adres
li $a2, 8			# a2 = liczba bitów do wpisania
move $a3, $s6			# a3 = licznik bajtów
jal ByteWrite		# dopisz kolejny bajt
move $s6, $a3			# zaktualizuj liczniik bajtów
addiu $t7, $t7, 1		# przesuñ g³owicê czytaj¹c¹ kod na kolejny bajt
addi $t5, $t5, -1		# zmniejsz licznik w pe³ni zapisanych bajtów
bnez $t5, enc_mini_loop		# powtarzaj a¿ do wyzerowania licznika (zapisania wszystkich "pe³nych" bajtów)
enc_mini_wrap:	# zapisz ostatni, "niepe³ny" bajt
lb $a0, ($t7)			# $a0 = dane
lw $a1, bit_head		# $a1 = adres
move $a2, $t4			# $a2 = liczba bitów do wpisania
move $a3, $s6			# $a3 = licznik bajtów
jal ByteWrite		# dopisz ostatni bajt
move $s6, $a3			# zaktualizuj liczniik bajtów
addiu $t9, $t9, 1		# przesuñ g³owicê czytaj¹c¹ do przodu
addi $s7, $s7, -1		# zmniejsz licznik o 1
bnez $s7, encode_loop		# je¿eli jeszcze jest co kodowaæ, powtórz
jal Load			# wczytaj wiêcej
move $s7, $v0			# zapisz liczbê wczytanych bajtów do $s7
la $t9, input_buffer		# ustaw g³owicê czytaj¹c¹ znaki na pocz¹tek input_buffer
bnez $s7, encode_loop		# jezeli wczytano cokolwiek, powtórz

encode_wrap:
lw $t0, bit_head		# za³aduj adres g³owicy pisz¹cej do $t0
lb $t1, ($t0)			# za³aduj ostatni bajt (prawdopodobnie niepe³ny) do $t1
lb $t2, bit_counter		# za³aduj bit_counter do $t2 (n)
sub $t2, $0, $t2		# $t2 = -$t2 (-n)
addi $t2, $t2, 8		# $t2 = 8 - n
sllv $t1, $t1, $t2		# dosuñ ostatni bajt do lewej
sb $t1, ($t0)			# zapisz na miejscu

lb $t0, bit_counter		# za³aduj bit_counter do $t0
addi $t0, $t0, -1		# odejmij 1 => bit_counter < 0 wtedy i tylko wtedy, gry by³o = 0
bgezal $t0, Encode_Save		# je¿eli bit_counter != 0, zapisz output_buffer (bit_counter = 0 wtedy i tylko wtedy, gdy dokonano przed chwil¹ zapisu i output_buffer jest pusty)
j end				# zakoñcz program


DECODE:

jal Load			# wczytaj dane do bufora
beqz $v0, end			# je¿eli nic nie wczytano, to znaczy ¿e plik jest pusty => zakoñcz program
move $s7, $v0			# zapisz liczbê wczytanych bajtów do $s7
la $t0, input_buffer		# $t0 = adres input_buffer
sw $t0, bit_head		# ustaw g³owicê czytaj¹c¹ na pocz¹tek input_buffer
li $s5, 0xffffffff		# wczytaj null marker do $t0
move $s3, $0			# wczytaj 0 do $s3
addiu $s4, $sp, -4		# wczytaj neutralny adres do $s4 (zabezpieczenie przed b³êdem)

read_tree:
move $a3, $s7			# $a3 = licznik wczytanych bajtów
jal ReadBit			# wczytaj bit
move $s7, $a3			# zaktualizuj licznik
bnez $a0, read_tree_ascii	# sprawdŸ czy to node, czy liœæ

read_tree_node:
sw $s3, ($sp)			# STWÓRZ NOWY NODE: zapisz adres rodzica
sw $sp, ($s4)			# zapisz adres dziecka w parent node
sw $s5, -4($sp)			# zapisz null marker w miejscu ASCII
sw $0, -8($sp)			# zapisz 0 w miejscu adresu lewego potomka
sw $0, -12($sp)			# zapisz 0 w miejscu adresu prawego potomka
move $s3, $sp			# przesuñ $s3 na nowy node
addiu $s4, $s3, -8		# ustaw $s4 na adres lewego potomka
addiu $sp, $sp, -16		# przesuñ $sp na wolne miejsce
j read_tree			# wczytuj dalej

read_tree_ascii:
sw $s3, ($sp)			# STWÓRZ NOWY LIŒÆ: zapisz adres rodzica
sw $sp, ($s4)			# zapisz adres potomka pod $s4
addiu $sp, $sp, -16		# przesuñ $sp na nastêpne wolne miejsce
move $a3, $s7			# $a3 = licznik wczytanych bajtów
jal ReadByte			# wczytaj nastêpny bajt danych (kod ASCII)
move $s7, $a3			# zaktualizuj licznik
sw $v0, 12($sp)			# zapisz kod ASCII

subu $t0, $s3, $s4		# $t0 = po³o¿enie $s4 wzglêdem $s3
beq $t0, 12, tree_right		# je¿eli w³aœnie stworzy³eœ prawego potomka, przejdŸ w inne miejsce; je¿eli lewego:
addiu $s4, $s4, -4		# przesuñ $s4 z adresu lewego potomka na prawy
j read_tree			# wczytuj dalej
tree_right:
lw $s3, ($s3)			# przejdŸ do parenta
beqz $s3, decode		# je¿eli wyszed³eœ z roota, zakoñcz algorytm
addiu $s4, $s3, -12		# ustaw $s4 na adres prawego dziecka
lw $t0, ($s4)			# wczytaj adres prawego dziecka
bnez $t0, tree_right		# przejdŸ wy¿ej, je¿eli ju¿ jest
j read_tree			# wczytuj dalej

decode:
addiu $s3, $s4, 12		# ustaw $s3 na root drzewa
move $s4, $s3			# $s4 te¿
move $s0, $0			# przygotuj zero_flag (znacznik odpowiadaj¹cy za to, czy czytany kod sk³ada siê z samych zer)
move $s1, $0			# przygotuj licznik zapisanych bajtów (znaków)
la $s2, output_buffer		# ustaw g³owicê pisz¹c¹ na pocz¹tek output_buffer
decode_loop:
move $a3, $s7			# $a3 = licznik wczytanych bajtów
jal ReadBit			# wczytaj bit
move $s7, $a3			# zaktualizuj licznik
beqz $a0, go_left		# je¿eli to "0", idŸ w lewo po drzewie, je¿eli nie, idŸ w prawo
go_right:
lw $s3, -12($s3)		# przejdŸ g³owic¹ do prawego dziecka
li $s0, 1			# ustaw zero_flag na wartoœæ niezerow¹
j check				# sprawdŸ czy to liœæ
go_left:
lw $s3, -8($s3)			# przejdŸ g³owic¹ do lewego dziecka
check:
lw $t8, -4($s3)			# wczytaj ASCII
beq $t8, -1, decode_loop	# je¿eli to node, wczytuj dalej; jezeli nie:
bnez $s0, write			# je¿eli zero_flag != 0, zapisz ascii
jal ReadBit			# wczytaj nastêpny bit
move $s7, $a3			# zaktualizuj licznik
beqz $a0, decode_end		# je¿eli nastêpny bit to te¿ 0 => wczytujesz same zera => EOF => koniec dekodowania

write:
sb $t8, ($s2)			# zapisz ASCII pod adresem wskazywanym przez g³owicê pisz¹c¹
addiu $s2, $s2, 1		# przesuñ g³owicê pisz¹c¹
addi $s1, $s1, 1		# zinkrementuj licznik zapisanych bajtów
li $t0, OUT_BUF_LEN		# wczytaj wielkoœæ bufora
addi $t0, $t0, -1		# odejmij 1
sub $t1, $t0, $s1		# $t1 = wielkoœæ bufora - liczba zapisanych bajtów - 1 => przyjmuje wartoœæ ujemn¹ wtw, gdy $s1 = wielkoœæ bufora
bltzal $t1, Decode_Save		# je¿eli $s1 = wielkoœæ bufora, zapisz
move $s3, $s4			# wróæ g³owic¹ chodz¹c¹ po drzewie do roota
move $s0, $0			# wyzeruj zero_flag
j decode_loop			# dekoduj dalej

decode_end:
addi $t0, $s1, -1		# odejmij 1 od licznika zapisanych bajtów
bgezal $t0, Decode_Save		# je¿eli $s0 >= 0, znaczy ¿e by³o >= 1, czyli trzeba coœ zapisaæ

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
syscall #zabij siê (i wszystkie swoje otwarte pliki)

# INNE FUNKCJE ------------------------------------

Load: # wczytanie pliku do bufora (a przynajmniej pierwsze lub kolejne N bajtów)
li $v0, 14		# komenda "wczytaj"
lb $a0, input_desc	# $a0 = deskryptor pliku
la $a1, input_buffer	# $a1 = adres docelowy (input_buffer)
li $a2, IN_BUF_LEN 		# $a2 = liczba bajtów do wczytania
syscall	# zrób to
jr $ra			# wróæ sk¹d przyby³eœ

BitAppend_s:		# bezpieczna wersja Bit_Append, s³u¿¹ca do pisania do output_buffer, uwzglêdniaj¹ca przepe³nienie bufora
sw $ra, ($sp)		# zapisz adres powrotu na stosie
addiu $sp, $sp, -4	# przesuñ stos

bne $a2, 8, append	# je¿eli bit_counter != 8, spokojnie przejdŸ do BitAppend
bne $s6, OUT_BUF_LEN, append	# je¿eli bufor siê nie przepe³nia, przejdŸ do BitAppend
# je¿eli oba warunki s¹ spe³nione (czyli bufor w³aœnie siê przepe³nia):
sw $a0, ($sp)		# zapisz na stosie wartoœæ $a0
sw $a1, -4($sp)		# zapisz na stosie wartoœæ $a1
sw $a2, -8($sp)		# zapisz na stosie wartoœæ $a2
addiu $sp, $sp, -12	# przesuñ stos
jal Encode_Save		# zrzuæ output_buffer do pliku
addiu $sp, $sp, 12	# wróæ stos
sw $a0, ($sp)		# wczytaj wartoœæ $a0
sw $a1, -4($sp)		# wczytaj wartoœæ $a1
sw $a2, -8($sp)		# wczytaj wartoœæ $a2

append:
move $a3, $s6		# wczytaj licznik bajtów
jal BitAppend		# przejdŸ do BitAppend
move $s6, $a3		# uaktualnij licznik bajtów
addiu $sp, $sp, 4	# cofnij stos
lw $ra, ($sp)		# wczytaj adres powrotu
jr $ra			# wróæ sk¹d przyby³eœ

Encode_Save:
sw $ra, ($sp)		# zapisz adres powrotu
addiu $sp, $sp, -4	# przesuñ stos
move $a2, $s6		# $a2 = liczba bajtów do zapisania
jal Save	# zapisz
li $s6, 1		# ustaw licznik zapisanych bajtów na 1
sw $a1, bit_head	# ustaw g³owicê pisz¹c¹ na pocz¹tek bufora
sb $0, bit_counter	# wyzeruj bit_counter
addiu $sp, $sp, 4	# wróæ stos
lw $ra, ($sp)		# przywróæ adres powrotu
jr $ra 			# wróæ sk¹d przyby³eœ

Decode_Save:
sw $ra, ($sp)		# zapisz adres powrotu
addiu $sp, $sp, -4	# przesuñ stos
move $a2, $s1		# $a2 = liczba bajtów do zapisania
jal Save	# zapisz
move $s1, $0		# wyzeruj licznik bajtów
la $s2, output_buffer	# ustaw g³owicê pisz¹c¹ na pocz¹tek bufora
addiu $sp, $sp, 4	# wróæ stos
lw $ra, ($sp)		# przywróæ adres powrotu
jr $ra			# wróæ sk¹d przyby³eœ

Save: # zrzucenie danych z output_buffer do pliku. Przyjmuje liczbê bajtów do zapisania w $a2
li $v0, 15		# komenda "zapisz"
lb $a0, output_desc	# $a0 = deskryptor pliku
la $a1, output_buffer	# $a1 = adres bufora
syscall		# zrób to
jr $ra			# wróæ sk¹d przyby³eœ

pathSanitization: # usuniêcie \n z koñca œcie¿ki
li $t8, '\n'
addiu $a0, $a0, -1
PS_loop:
addiu $a0, $a0, 1
lb $t1, ($a0)
bne $t1, $t8, PS_loop
sb $0, ($a0)
jr $ra

ByteWrite:
# Dopisz 0-8 bitów danych (n), zaczynaj¹c od wskazanego miejsca (adr)
# $a0 - dane
# $a1 - adr
# $a2 - n
# Zwraca licznik w $v0 i (nowy) adres w $v1 i $a1. Korzysta z i aktualizuje bit_counter i bit_head
sw $ra, ($sp)		# zapisz na stosie adres powrotu
sw $s0, -4($sp)
sw $s2, -8($sp)
addiu $sp, $sp, -12	# zapisz na stosie wartoœci u¿ywanych zmiennych sprzed wywo³ania

move $s2, $a2		# zapisz licznik w $s2
beqz $s2, WW_end	# je¿eli licznik = 0, zakoñcz procedurê
li $s0, 32		# $s0 = 32
sub $s0, $s0, $s2	# $s0 = 32 - n
sllv $s0, $a0, $s0	# $s0 = dane z $a0 dosuniête do lewej (przesuniête w lewo o 32-n )

WW_loop:
lb $a2, bit_counter	# wczytaj bit_counter do $a2
rol $a0, $s0, 1		# zapisz w $a0 dane (gdzie na najmniej znacz¹cym miejscu znajduje siê bit do dopisania)
jal BitAppend		# wywo³aj funkcjê BitAppend
sb $v0, bit_counter	# zaktualizuj bit_counter
move $s6, $a3		# zaktualizuj licznik bajtów
subi $v0, $v0, 8	# odejmij 8 od $v0
bnez $v0, WW_next	# sprawdŸ czy licznik bitów = 8, je¿eli tak:
li $t0, OUT_BUF_LEN	#   za³aduj wielkoœæ bufora
bne $s6, $t0, WW_next	#   sprawdŸ, czy przepe³nia siê bufor
jal Encode_Save		#   je¿eli tak, zrzuæ bufor do pliku
WW_next:
sll $s0, $s0, 1		# przesuñ dane o 1 w lewo
addi $s2, $s2, -1	# zdekrementuj licznik
bnez $s2, WW_loop	# powtórz, je¿eli licznik != 0

WW_end:
sw $a1, bit_head	# uaktualnij bit_head
addiu $sp, $sp, 12	# cofnij stos
lw $s2, -8($sp)		
lw $s0, -4($sp)		# wczytaj wartoœci sprzed wywo³ania funkcji
lw $ra, ($sp)		# wczytaj adres powrotu ze stosu
jr $ra			# wróæ sk¹d przyby³eœ

BitAppend:
# Dopisz pojedynczy bit. Argumenty:
# $a0 - bit do dopisania (na najmniej znacz¹cym miejscu)
# $a1 - adres docelowy
# $a2 - licznik ju¿ zajêtych bitów (od 1 do 8)
# $a3 - licznik zapisanych bajtów (inkrementowany przy przejœciu do nastêpnego bajtu)
# Zwraca licznik w $v0 i (nowy) adres w $v1 i $a1
sw $s0, ($sp)		# odstaw $s0 na stos
addiu $sp, $sp, 4	# przesuñ stos

li $v1, 8
bne $a2, $v1, append_bit # je¿eli licznik = 8:
addu $a1, $a1, 1	#   przejdŸ o bajt dalej
add $a3, $a3, 1		#   zwiêksz licznik zapisanych bajtów o 1
move $a2, $0		#   licznik bitów = 0
append_bit:
lb $s0, ($a1)		# weŸ bajt spod podanego adresu
sll $s0, $s0, 1 	# przesuñ o 1 w lewo
andi $a0, $a0, 1	# upewnij siê ¿e podany bit to tylko 1 bit
or $s0, $s0, $a0	# wpisz bit na koniec
sb $s0, ($a1)		# odstaw nowy bajt
addi $a2, $a2, 1	# zwiêksz licznik

addiu $sp, $sp, -4	# zwiñ stos
lw $s0, ($sp)		# przywróæ wartoœæ $s0

move $v0, $a2		# zwróæ licznik
move $v1, $a1		# zwróc adres
jr $ra			# wróæ sk¹d przyby³eœ

ReadBit:
# Przeczytaj pojedynczy bit. Argumenty bierze z bit_head i bit_counter oraz $a3 (licznik wczytanych bajtów)
# Zwraca wczytany bit w $a0, (nowy) adres w $a1 i nowe wartoœci liczników w $a2 i $a3. Korzysta z i uaktualnia bit_head i bit_counter
sw $ra, ($sp)		# zapisz na stosie adres powrotu
sw $s0, -4($sp)		# zapisz na stosie wartoœæ $s0
addiu $sp, $sp, -8	# przesuñ $sp

lw $a1, bit_head	# wczytaj adres
lb $a2, bit_counter	# wczytaj licznik przeczytanych bitów
li $s0, 7		# $s0 = 7
ble $a2, $s0, read	# sprawdŸ czy przeczytano ju¿ wszystkie bity z tego bajtu, jeœli tak:
addiu $a1, $a1, 1	#	przesuñ g³owicê o 1
sw $a1, bit_head	#	uaktualnij bit_head
li $a2, 0		#	wyzeruj licznik
addi $a3, $a3, -1	#	zdekrementuj licznik wczytanych bajtów
bnez $a3, read		# 	sprawdŸ, czy przeczytano ju¿ wszystkie wczytane bajty, jeœli tak:
jal Load		#		wczytaj wiêcej
move $a0, $0		# 		wyzeruj dane (na wypadek gdyby to by³ EOF)
move $a3, $v0		# 		zaktualizuj licznik wczytanych bajtów
beqz $a3, read_end	#		zakoñcz, je¿eli wczytano EOF
li $a2, 0		#		wyzeruj licznik
la $a1, input_buffer	# 		wczytaj adres input_buffer
sw $a1, bit_head 	#		ustaw g³owicê pisz¹c¹ na pocz¹tek input_buffer

read:
lb $a0, ($a1)		# wczytaj bajt do $a0
sub $s0, $s0, $a2	# $a3 = przesuniêcie w prawo wymagane, by ¿¹dany bit znalaz³ siê na najmniej znacz¹cym miejscu
srlv $a0, $a0, $s0	# przesuñ w lewo o przesuniêcie wyliczone powy¿ej
andi $a0, $a0, 0x00000001 # zredukuj dane wynikowe tylko do tego jednego bitu
addi $a2, $a2, 1	# zwiêksz licznik przeczytanych bitów
sb $a2, bit_counter	# uaktualnij bit_counter

read_end:
addiu $sp, $sp, 8	# wróæ stos
lw $s0, -4($sp)		# przywróæ wartoœæ $s0
lw $ra, ($sp)		# przywróæ adres powrotu
jr $ra		# wróæ sk¹d przyby³eœ

ReadByte:
# Przeczytaj nastêpne 8 bitów. Korzysta z ReadBit, a wiêc te¿ pos³uguje siê bit_head i bit_counter.
# Zwraca wczytany bajt w $v0 i ca³¹ resztê jak ReadBit.
sw $s0, ($sp)		# zapisz wartoœæ $s0 na stosie
sw $s1, -4($sp)		# zapisz wartoœæ $s1 na stosie
sw $ra, -8($sp)		# zapisz adres powrotu na stosie
addiu $sp, $sp, -12	# przesuñ stos

move $s1, $0		# wyzeruj akumulator danych
li $s0, 8		# przygotuj licznik
RB_loop:
jal ReadBit		# wczytaj bit
sll $s1, $s1, 1		# przesuñ w lewo wynikowy bajt
or $s1, $s1, $a0	# dodaj na koniec wczytany bit
addi $s0, $s0, -1	# zdekrementuj licznik
bnez $s0, RB_loop	# powtarzaj a¿ do wyzerowania licznika
move $v0, $s1		# zwróæ wynik

addiu $sp, $sp, 12	# wróæ stos
lw $ra, -8($sp)		# przywróæ adres powrotu
lw $s1, -4($sp)		# przywróæ wartoœæ $s1
lw $s0, ($sp)		# przywróæ wartoœæ $s0
jr $ra			# wróæ sk¹d przyby³eœ
