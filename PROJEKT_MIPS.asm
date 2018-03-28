.globl main
.data
intro:	.ascii	"The Huffman Coding - MIPS \"Big Project\"\n"
	.asciiz "Copyright: Politechnika Warszawska, Author: Michal Parafiniuk (285634)\n"
prompt1:	.asciiz	"Input file (path): "
prompt2:	.asciiz "Output file (path): "
prompt3:	.asciiz	"Do you want to encode? (leave empty if yes, write anything if you want to decode)"
file_error:	.asciiz "Error opening file! "

input_path:	.space 100	# "E:\Coding\MIPS\input.txt"
input_buffer:	.space 1000
output_path:	.space 100	# "E:\Coding\MIPS\output.txt"
output_buffer:	.space 1000

ascii_stats:	.space 256

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
la $s7, ascii_stats	# za³adowanie adresu
li $t9, 127		# za³adowanie licznika maksymalnym kodem ASCII
preparation_loop:
addu $t8, $s7, $t9	# za³aduj do $t8 adres przesuniêty o...
addu $t8, $t8, $t9	# ...dwukrotnoœæ obecnie rozpatrywanego znaku ASCII
addiu $t8, $t8, 1	# przesuñ jeszcze o jeden bajt dalej
sb $t9, ($t8)		# zapisz znak ASCII na swoim miejscu
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
lb $t0, ($t9)		# w $t0 mamy bie¿¹cy znak
beq $t0, $0, stat_end	# je¿eli napotkamy \0, koñczymy procedurê
addu $t1, $s7, $t0	# tworzymy adres do ascii_stats z przesuniêciem równym wartoœci ASCII
addu $t1, $t1, $t0	# podwajamy przesuniêcie
lb $t2, ($t1)		# ³adujemy do $t2 obecn¹ wartoœæ zliczonych znaków tego rodzaju
addi $t2, $t2, 1	# inkrementujemy
sb $t2, ($t1)		# odstawiamy na miejsce
addiu $t9, $t9, 1	# przesuwamy siê o znak do przodu
addi $t8, $t8, -1	# zmniejszamy licznik
bnez $t8, stat_loop	# je¿eli nie wyszliœmy poza zakres, powtarzamy
beqz $t8, Load		# je¿eli skoñczy³ siê bufor, za³aduj nowy fragment pliku

stat_end:




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
