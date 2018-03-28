.globl main
.data
intro:	.ascii	"The Huffman Coding - MIPS \"Big Project\"\n"
	.asciiz "Copyright: Politechnika Warszawska, Author: Michal Parafiniuk (285634)\n"
prompt1:	.asciiz	"Input file (path): "
prompt2:	.asciiz "Output file (path): "
prompt3:	.asciiz	"Do you want to decode? (leave empty if you want to encode)"
file_error:	.asciiz "Error opening file! "

input_path:	.space 100 #"E:\Coding\MIPS\input.txt"
input_buffer:	.space 1000
output_path:	.space 100
output_buffer:	.space 1000

ascii_stats:	.space 128

.text
main:
li $v0, 4
la $a0, intro
syscall #wypisz intro

getInput:
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

#kontrola b��du
bgt $v0, $0, preLoad

li $v0, 4
la $a0, file_error
syscall #wypluj error
j getInput

preLoad:
add $s7, $0, $v0 # zapisz identyfikator otwartego pliku w $s0
Load:
li $v0, 14
add $a0, $0, $s7
la $a1, input_buffer
li $a2, 1000
syscall #wczytaj plik do bufora (a przynajmniej pierwsze lub kolejne 1000 bajt�w)


#STATYSTYKA ZNAK�W TEKSTU
beqz $v0, stat_end
add $t8, $0, $v0	# przygotowanie licznika znak�w w buforze (zapezpieczenie przed wyj�ciem poza bufor lub za�adowane znaki)
la $t9, input_buffer	# przygotowanie adresu pocz�tku pobranej porcji wej�ciowego pliku
la $s0, ascii_stats	# przygotowanie adresu tablicy zliczaj�cej wyst�pienia znak�w

stat_loop:
lb $t0, ($t9)		# w $t0 mamy bie��cy znak
beq $t0, $0, stat_end	# je�eli napotkamy \0, ko�czymy procedur�
addu $t1, $s0, $t0	# tworzymy adres do ascii_stats z przesuni�ciem r�wnym warto�ci ascii
lb $t2, ($t1)		# �adujemy do $t2 obecn� warto�� zliczonych znak�w tego rodzaju
addi $t2, $t2, 1	# inkrementujemy
sb $t2, ($t1)		# odstawiamy na miejsce
addiu $t9, $t9, 1	# przesuwamy si� o znak do przodu
addi $t8, $t8, -1	# zmniejszamy licznik
bnez $t8, stat_loop	# je�eli nie wyszli�my poza zakres, powtarzamy
beqz $t8, Load		# je�eli sko�czy� si� bufor, za�aduj nowy fragment pliku

stat_end:

li $v0, 4
la $a0, input_buffer
syscall #wypisz plik

li $v0, 10
syscall #zabij si�


pathSanitization: #usuni�cie \n z ko�ca �cie�ki
li $t8, '\n'
PS_loop:
lb $t1, ($a0)
beq $t1, $t8, destroy
addiu $a0, $a0, 1
j PS_loop
destroy:
sb $0, ($a0)
jr $ra
