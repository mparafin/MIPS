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
syscall #we� �cie�k� inputu

la $a0, input_path
jal pathSanitization #obetnij \n

li $v0, 13
la $a0, input_path
li $a1, 0
li $a2, 0
syscall #otw�rz plik
add $s0, $0, $v0 # zapisz identyfikator otwartego pliku w $s0

#kontrola b��du
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
syscall #we� �cie�k� outputu

la $a0, output_path
jal pathSanitization #obetnij \n

li $v0, 13
la $a0, output_path
li $a1, 1
li $a2, 0
syscall #otw�rz plik
add $s1, $0, $v0 # zapisz identyfikator otwartego pliku w $s1

#kontrola b��du
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
syscall # we� max 2 znaki

lb $t0, 1($a0)	# za�aduj drugi z nich
bnez $t0, DECODE	# je�eli nie jest \0, decode

ENCODE:
#przygotowanie tablicy ascii_stats (tablica licznik�w wyst�pie� znak�w)
#la $s7, ascii_stats	# za�aduj adres
#li $t9, 127		# za�aduj licznik maksymalnym kodem ASCII
#preparation_loop:
#mul $t8, $t9, 8		# za�aduj do $t8 podwojon� warto�� obecnie rozpatrywanego znaku ASCII liczon� w s�owach
#addu $t8, $s7, $t8	# za�aduj do $t8 adres ascii_table przesuni�ty o to co wy�ej
#addiu $t8, $t8, 4	# przesu� jeszcze o jedno s�owo dalej
#sw $t9, ($t8)		# zapisz znak ASCII na swoim miejscu
#addi $t9, $t9, -1		# przejd� do kolejnego znaku ASCII
#bge $t9, $0, preparation_loop	# je�eli nie przeszed�e� na ujemne liczby, powt�rz dla kolejnego znaku ASCII

Load:
li $v0, 14
add $a0, $0, $s0
la $a1, input_buffer
li $a2, 1000
syscall #wczytaj plik do bufora (a przynajmniej pierwsze lub kolejne 1000 bajt�w)


#STATYSTYKA ZNAK�W TEKSTU
beqz $v0, stat_end
la $s7, ascii_stats
add $t8, $0, $v0	# przygotowanie licznika znak�w w buforze (zapezpieczenie przed wyj�ciem poza bufor lub za�adowane znaki)
la $t9, input_buffer	# przygotowanie adresu pocz�tku pobranej porcji wej�ciowego pliku

stat_loop:
lb $t0, ($t9)		# we� do $t0 bie��cy znak
beq $t0, $0, stat_end	# je�eli to \0, zako�cz procedur�
mul $t1, $t0, 4		# za�aduj to $t1 warto�� wzi�tego znaku ASCII liczon� w s�owach
addu $t1, $s7, $t1	# stw�rz adres do ascii_stats z przesuni�ciem r�wnym warto�ci 4*ASCII
lw $t2, ($t1)		# we� do $t2 obecn� warto�� zliczonych znak�w tego rodzaju
addi $t2, $t2, 1	# zwi�ksz o jeden
sw $t2, ($t1)		# odstaw na miejsce
addiu $t9, $t9, 1	# przesu� si� o znak do przodu
addi $t8, $t8, -1	# zmniejsz licznik
bnez $t8, stat_loop	# je�eli nie wyszed�e� poza zakres, powt�rz
beqz $t8, Load		# je�eli sko�czy� si� bufor, za�aduj nowy fragment pliku

stat_end:

# wypisywanie statystyki znak�w
addu $t0, $0, $s7	# w t0 mamy adres ascii_stats
li $t9, 0		# za�adowanie licznika
li $t8, 128		# g�rna granica licznika

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
la $t1, output_buffer	# w $t1 mamy adres output buffer, gdzie b�dziemy ju� pisa�
tree_big_loop:		# (szukamy maksymalnej warto�ci tyle razy, ile znak�w wyst�puje chocia� raz w tek�cie i wstawiamy je kolejno na pocz�tku szyfrogramu, tworz�c "drzewo")
addu $t0, $0, $s7	# za�aduj do $t0 adres ascii_stats
li $t9, 128		# przygotuj licznik
li $t3, 0		# przygotuj rejestr na max
li $t4, 0		# przygotuj rejestr na znak

tree_small_loop:	# (szukamy maksymalnej warto�ci �eby j� zapisa� jako kolejn� w "drzewie")
lw $t2, ($t0)		# za�aduj liczb� wyst�pie� znaku
beqz $t2, tree_small_next	# przejd� dalej, je�eli znak nie wyst�puje
ble $t2, $t3, tree_small_next	# przejd� do nast�pnego znaku, je�li liczba jest mniejsza ni� max; else:
add $t3, $t2, $0	# max = liczba wyst�pie� obecnego znaku
sub $t4, $t0, $s7		# znak = 4*obecny znak
div $t4, $t4, 4			# znak = obecny znak
tree_small_next:		# nast�pny znak acsii
addiu $t0, $t0, 4	# przesu� "g�owic� czytaj�c�" na liczb� wyst�pie� nast�pnego znaku ASCII
addi $t9, $t9, -1	# zdekrementuj licznik
beqz $t9, tree_big_next	# zako�cz szukanie maksymalnego elementu po przej�ciu przez wszystkie znaki ASCII
j tree_small_loop	# powt�rz dla nast�pnego znaku ASCII

tree_big_next:
beqz $t3, bit_pack	# je�eli max = 0 => wszystkie pozosta�e znaki nie wyst�puj� w tek�cie -> zako�cz procedur�
sb $t4, ($t1)		# wy�lij do output_buffer kolejny najcz�sciej wystepuj�cy znak
mul $t4, $t4, 4		# przygotuj przesuni�cie (przelicz ASCII na s�owa)
addu $t0, $t4, $s7	# za�aduj do $t0 adres ascii_stats przesuni�ty o (int)znak
sb $0, ($t0)		# wyzeruj liczb� wyst�pie� tego znaku
addiu $t1, $t1, 1	# przesu� "g�owic� pisz�c�" na nast�pny znak output_buffer
j tree_big_loop		# powt�rz dla kolejnego obecnie najcz�ciej wystepuj�cego znaku

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
