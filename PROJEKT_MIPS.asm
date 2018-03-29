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
ascii_stats:	.space 1024

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
#przygotowanie tablicy ascii_stats (tablica dwubajtowych elementów, gdzie drugi bajt to znak ASCII, a pierwszy to liczba jego wyst¹pieñ)
la $s7, ascii_stats	# za³aduj adres
li $t9, 127		# za³aduj licznik maksymalnym kodem ASCII
preparation_loop:
mul $t8, $t9, 8		# za³aduj do $t8 podwojon¹ wartoœæ obecnie rozpatrywanego znaku ASCII liczon¹ w s³owach
addu $t8, $s7, $t8	# za³aduj do $t8 adres ascii_table przesuniêty o to co wy¿ej
addiu $t8, $t8, 4	# przesuñ jeszcze o jedno s³owo dalej
sw $t9, ($t8)		# zapisz znak ASCII na swoim miejscu
addi $t9, $t9, -1		# przejdŸ do kolejnego znaku ASCII
bge $t9, $0, preparation_loop	# je¿eli nie przeszed³eœ na ujemne liczby, powtórz dla kolejnego znaku ASCII

Load:
li $v0, 14
add $a0, $0, $s0
la $a1, input_buffer
li $a2, 1000
syscall #wczytaj plik do bufora (a przynajmniej pierwsze lub kolejne 1000 bajtów)


#STATYSTYKA ZNAKÓW TEKSTU
beqz $v0, stat_end
add $t8, $0, $v0	# przygotowanie licznika znaków w buforze (zapezpieczenie przed wyjœciem poza bufor lub za³adowane znaki)
la $t9, input_buffer	# przygotowanie adresu pocz¹tku pobranej porcji wejœciowego pliku

stat_loop:
lb $t0, ($t9)		# weŸ do $t0 bie¿¹cy znak
beq $t0, $0, stat_end	# je¿eli to \0, zakoñcz procedurê
mul $t1, $t0, 8		# za³aduj to $t1 podwojon¹ wartoœæ wziêtego znaku ASCII liczon¹ w s³owach
addu $t1, $s7, $t1	# stwórz adres do ascii_stats z przesuniêciem równym wartoœci 8*ASCII
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
addiu $t0, $t0, 4	# w t0 mamy adres pierwszego znaku
li $t9, 0		# za³adowanie licznika
li $t8, 128		# górna granica licznika

stat_print_loop:
li $v0, 11		# print char
lb $a0, ($t0)		# za³aduj tego chara
syscall		# do it
li $v0, 4		# print string
la $a0, colon		# dwukropek i spacja
syscall		# do it
li $v0, 1		# print int
lw $a0, -4($t0)		# za³aduj liczbê wyst¹pieñ znaku
syscall		# do it
li $v0, 4		# print string
la $a0, breakline	# nowa linia
syscall		# do it

addiu $t0, $t0, 8	# przejdŸ do nastêpnego znaku
addi $t9, $t9, 1	# zinkrementuj licznik
bne $t9, $t8, stat_print_loop	# loop


li $v0, 4
la $a0, input_buffer
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
