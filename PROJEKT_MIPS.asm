.globl main
.data
intro:	.ascii	"The Huffman Coding - MIPS \"Big Project\"\n"
	.asciiz "Copyright: Politechnika Warszawska, Author: Michal Parafiniuk (285634)\n"
prompt1:	.asciiz	"Input file (path): "
prompt2:	.asciiz "Output file (path): "
prompt3:	.asciiz	"Do you want to decode? (leave empty if not)"

input_filename:	.space 100 #"E:\Coding\MIPS\input.txt"
input_buffer:	.space 1000
output_filename:	.space 100
output_buffer:	.space 1000

.text
main:
li $v0, 4
la $a0, intro
syscall #wypisz intro

li $v0, 4
la $a0, prompt1
syscall #wypisz prompt1

getInput:
li $v0, 8
la $a0, input_filename
li $a1, 100
syscall #weŸ œcie¿kê inputu

la $a0, input_filename
jal pathSanitization #obetnij \n
addiu $sp, $sp, -4
sw $0, ($sp) #posprz¹taj

li $v0, 13
la $a0, input_filename
li $a1, 0
li $a2, 0
syscall #otwórz plik

#TODO: kontrola b³êdu

add $t0, $0, $v0
li $v0, 14
add $a0, $0, $t0
la $a1, input_buffer
li $a2, 1000
syscall #wczytaj plik do bufora (a przynajmniej pierwsze 1000 bajtów)

li $v0, 4
la $a0, input_buffer
syscall #wypisz plik

li $v0, 10
syscall #zabij siê


pathSanitization: #usuniêcie \n z koñca œcie¿ki
sw $31, ($sp)
addiu $sp, $sp, 4
li $s0, '\n'
IS_loop:
lb $t1, ($a0)
beq $t1, $s0, destroy
addiu $a0, $a0, 1
j IS_loop
destroy:
sb $0, ($a0)
jr $ra
