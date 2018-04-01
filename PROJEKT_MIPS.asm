.globl main
.data
intro:	.ascii	"The Huffman Coding - MIPS \"Big Project\"\n"
	.asciiz "Copyright: Politechnika Warszawska, Author: Michal Parafiniuk (285634)\n"
prompt1:	.asciiz	"Input file (path): "
prompt2:	.asciiz "Output file (path): "
prompt3:	.asciiz	"Do you want to encode? (leave empty if yes, write anything if you want to decode)"
file_error:	.asciiz "Error opening file! "
colon:	.asciiz	": "
breakline:	.asciiz	"\n"

input_path:	.space 100	# "E:\Coding\MIPS\input.txt"
input_buffer:	.space 1000
output_path:	.space 100	# "E:\Coding\MIPS\output.txt"
output_buffer:	.space 1000
		.align	2
ascii_stats:	.space 512

.text
main:
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
add $s0, $0, $v0 # zapisz identyfikator otwartego pliku w $s0

#kontrola b³êdu
bgt $s0, $0, getOutput

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
add $s1, $0, $v0 # zapisz identyfikator otwartego pliku w $s1

#kontrola b³êdu
bgt $s1, $0, getMode

li $v0, 4
la $a0, file_error
syscall #wypluj error
j getOutput

getMode:	# getMode

li $v0, 4
la $a0, prompt3
syscall # wypisz prompt3

li $v0, 8
la $a0, input_buffer
li $a1, 3
syscall # weŸ max 2 znaki

lb $t0, 1($a0)	# za³aduj drugi z nich
bnez $t0, DECODE	# je¿eli nie jest \0, decode

ENCODE:
#przygotowanie tablicy ascii_stats (tablica liczników wyst¹pieñ znaków)
#la $s7, ascii_stats	# za³aduj adres
#li $t9, 127		# za³aduj licznik maksymalnym kodem ASCII
#preparation_loop:
#mul $t8, $t9, 8		# za³aduj do $t8 podwojon¹ wartoœæ obecnie rozpatrywanego znaku ASCII liczon¹ w s³owach
#addu $t8, $s7, $t8	# za³aduj do $t8 adres ascii_table przesuniêty o to co wy¿ej
#addiu $t8, $t8, 4	# przesuñ jeszcze o jedno s³owo dalej
#sw $t9, ($t8)		# zapisz znak ASCII na swoim miejscu
#addi $t9, $t9, -1		# przejdŸ do kolejnego znaku ASCII
#bge $t9, $0, preparation_loop	# je¿eli nie przeszed³eœ na ujemne liczby, powtórz dla kolejnego znaku ASCII

Load:
li $v0, 14
add $a0, $0, $s0
la $a1, input_buffer
li $a2, 1000
syscall #wczytaj plik do bufora (a przynajmniej pierwsze lub kolejne 1000 bajtów)


#STATYSTYKA ZNAKÓW TEKSTU
beqz $v0, stat_end
la $s7, ascii_stats
add $t8, $0, $v0	# przygotowanie licznika znaków w buforze (zapezpieczenie przed wyjœciem poza bufor lub za³adowane znaki)
la $t9, input_buffer	# przygotowanie adresu pocz¹tku pobranej porcji wejœciowego pliku

stat_loop:
lb $t0, ($t9)		# weŸ do $t0 bie¿¹cy znak
beq $t0, $0, stat_end	# je¿eli to \0, zakoñcz procedurê
mul $t1, $t0, 4		# za³aduj to $t1 wartoœæ wziêtego znaku ASCII liczon¹ w s³owach
addu $t1, $s7, $t1	# stwórz adres do ascii_stats z przesuniêciem równym wartoœci 4*ASCII
lw $t2, ($t1)		# weŸ do $t2 obecn¹ wartoœæ zliczonych znaków tego rodzaju
addi $t2, $t2, 1	# zwiêksz o jeden
sw $t2, ($t1)		# odstaw na miejsce
addiu $t9, $t9, 1	# przesuñ siê o znak do przodu
addi $t8, $t8, -1	# zmniejsz licznik
bnez $t8, stat_loop	# je¿eli nie wyszed³eœ poza zakres, powtórz
beqz $t8, Load		# je¿eli skoñczy³ siê bufor, za³aduj nowy fragment pliku

stat_end:

# wypisywanie statystyki znaków
addu $t0, $0, $s7	# w t0 mamy adres ascii_stats
li $t9, 0		# za³adowanie licznika
li $t8, 128		# górna granica licznika

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
la $t1, output_buffer	# w $t1 mamy adres output buffer, gdzie bêdziemy ju¿ pisaæ
tree_big_loop:		# (szukamy maksymalnej wartoœci tyle razy, ile znaków wystêpuje chocia¿ raz w tekœcie i wstawiamy je kolejno na pocz¹tku szyfrogramu, tworz¹c "drzewo")
addu $t0, $0, $s7	# za³aduj do $t0 adres ascii_stats
li $t9, 128		# przygotuj licznik
li $t3, 0		# przygotuj rejestr na max
li $t4, 0		# przygotuj rejestr na znak

tree_small_loop:	# (szukamy maksymalnej wartoœci ¿eby j¹ zapisaæ jako kolejn¹ w "drzewie")
lw $t2, ($t0)		# za³aduj liczbê wyst¹pieñ znaku
beqz $t2, tree_small_next	# przejdŸ dalej, je¿eli znak nie wystêpuje
ble $t2, $t3, tree_small_next	# przejdŸ do nastêpnego znaku, jeœli liczba jest mniejsza ni¿ max; else:
add $t3, $t2, $0	# max = liczba wyst¹pieñ obecnego znaku
sub $t4, $t0, $s7		# znak = 4*obecny znak
div $t4, $t4, 4			# znak = obecny znak
tree_small_next:		# nastêpny znak acsii
addiu $t0, $t0, 4	# przesuñ "g³owicê czytaj¹c¹" na liczbê wyst¹pieñ nastêpnego znaku ASCII
addi $t9, $t9, -1	# zdekrementuj licznik
beqz $t9, tree_big_next	# zakoñcz szukanie maksymalnego elementu po przejœciu przez wszystkie znaki ASCII
j tree_small_loop	# powtórz dla nastêpnego znaku ASCII

tree_big_next:
beqz $t3, bit_pack	# je¿eli max = 0 => wszystkie pozosta³e znaki nie wystêpuj¹ w tekœcie -> zakoñcz procedurê
sb $t4, ($t1)		# wyœlij do output_buffer kolejny najczêsciej wystepuj¹cy znak
mul $t4, $t4, 4		# przygotuj przesuniêcie (przelicz ASCII na s³owa)
addu $t0, $t4, $s7	# za³aduj do $t0 adres ascii_stats przesuniêty o (int)znak
sb $0, ($t0)		# wyzeruj liczbê wyst¹pieñ tego znaku
addiu $t1, $t1, 1	# przesuñ "g³owicê pisz¹c¹" na nastêpny znak output_buffer
j tree_big_loop		# powtórz dla kolejnego obecnie najczêœciej wystepuj¹cego znaku

bit_pack:

li $v0, 4
la $a0, input_buffer
syscall #wypisz plik

li $v0, 4
la $a0, breakline
syscall #wypisz plik

li $v0, 4
la $a0, output_buffer
syscall #wypisz plik

DECODE:
li $v0, 10
syscall #zabij siê


pathSanitization: #usuniêcie \n z koñca œcie¿ki
li $t8, '\n'
PS_loop:
lb $t1, ($a0)
beq $t1, $t8, destroy
addiu $a0, $a0, 1
j PS_loop
destroy:
sb $0, ($a0)
jr $ra
