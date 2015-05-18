#Anthony J. Martinez
#CS2430
#2048 Project Phase 3
#Parts of the following program contains code segments
#that belong to Dr. Roger Doering. A large part
#of the main program, the entirety of the findnextblank function,
#and part of the placerandom function are either directly taken
#from Dr. Doering's code, or have been derived from his pseudocode.
#begin class Box
	.data	#begin data segment
Box:	.struct
tl:	.byte	0
top:	.byte	0
tr:	.byte	0
left:	.byte	0
middle:	.byte	0	
right:	.byte	0
bl:	.byte	0
bot:	.byte	0
br:	.byte	0
	.data
	# box instances
single:	.ascii 	"ÚÄ¿"
	.ascii 	"³ ³"
	.ascii 	"ÀÄÙ"
double:	.ascii 	"ÉÍ»"
	.ascii	"º º"
	.ascii	"ÈÍ¼"	#end data segment
	.code 	#begin void Box::Draw(x,y,w,h)
Box.Draw:	
# arguments		begin doc
#	a0 x co-ordinate of upper left-hand corner
#	a1 y co-ordinate of upper left-hand corner
#	a2 width:16; height:16 of box guts in characters
#	a3 "this" pointer for box;
#{	begin pseudo code
#	gotoxy(x,y);
#	cout << tl;
#	for (int t2=w; t2>0; t2--) cout << top;
#	cout << tr;
#	for (int t3=h; t3>0; t3--)
#	{
#		gotoxy(x,++y);
#		cout << left;
#		for (int t2=w; t2>0; t2--) cout << middle; 
#		cout << right;
#	}
#	gotoxy(x,++y);
#	cout << bl;
#	for (int t2=w; t2>0; t2--) cout << bot;
#	cout << br;
#} end pseudo code end doc
	srl	$t6,$a2,16		# unpack w
	andi	$t7,$a2,0xffff		# unpack h
	mov	$t8,$a0		#	gotoxy(x,y);
	mov	$t9,$a1
	syscall	$xy
	lb	$a0,Box.tl($a3)	#	cout << tl;
	syscall	$print_char
	mov	$t2,$t6		#	for (int t2=w; t2>0; t2--) 
	lb	$a0,Box.top($a3)	
	b	2f
1:	syscall	$print_char		#		cout << top;
	addi	$t2,$t2,-1
2:	bgtz	$t2,1b
	lb	$a0,Box.tr($a3)	#	cout << tr;
	syscall	$print_char					
	b	6f				#	for (; h>0; h--)
3:					#	{
	mov	$a0,$t8		#	    gotoxy(x,++y);
	addi	$t9,$t9,1
	mov	$a1,$t9
	syscall	$xy
	lb	$a0,Box.left($a3)	#	    cout << left;
	syscall	$print_char
	mov	$t2,$t6		#	    for (int t2=w; t2>0; t2--) 
	lb	$a0,Box.middle($a3)
	b	5f
4:	syscall	$print_char		#		cout << middle; 
	addi	$t2,$t2,-1
5:	bgtz	$t2,4b
	lb	$a0,Box.right($a3)	#	    cout << right;
	syscall	$print_char
	addi	$t7,$t7,-1		#	}
6:	bgtz	$t7,3b
	mov	$a0,$t8		#	gotoxy(x,++y);
	addi	$a1,$t9,1
	syscall	$xy
	lb	$a0,Box.bl($a3)	#	cout << bl;
	syscall	$print_char
	mov	$t2,$t6		#	for (int t2=w; t2>0; t2--) 
	lb	$a0,Box.bot($a3)	
	b	2f
1:	syscall	$print_char		#		cout << bot;
	addi	$t2,$t2,-1
2:	bgtz	$t2,1b
	lb	$a0,Box.br($a3)	#	cout << br;
	syscall	$print_char		
	jr	$ra			# end Box.Draw
#end Box class
#begin keyboard stuff
LEFT_ARROW = 37
UP_ARROW = 38
RIGHT_ARROW = 39
DOWN_ARROW = 40
keyboard:	.struct 0xa0000000	#start from hardware base address
flags:		.byte 0
mask:		.byte 0
		.half 0
keypress: 	.byte 0,0,0
presscon: 	.byte 0
keydown:	.half 0
shiftdown:	.byte 0
downcon:	.byte 0
keyup:		.half 0
upshift:	.byte 0
upcon:		.byte 0
		.data
keyPressFlag	=	0b00000001 	# these may be ORed if needed
keyDownFlag	=	0b00000010
keyUpFlag	=	0b00000100
keyShift	=	0b00000001 	# Shift flag values
keyAlt		=	0b00000010
keyCtrl		=	0b00000100
#end keyboard stuff
#begin Swipe class
swipe:	.struct
move:	.byte	0
start:	.byte	0
next:	.byte	0
	.data
	
# swipe arr[4];
arr:
west:	.byte	2,0,8
north:	.byte	8,0,2
east:	.byte	-2,3,8
south:	.byte	-8,12,2
	la	$t0,arr
	li	$t1,swipe
	mul	$t1,$t1,$a1   # a1 is index
	add	$t0,$t0,$t1
#end Swipe class
#begin main
	.data
board:	.half	2,4,8,16
	.half	32,64,128,256
	.half	512,8,4,2048
	.half	2,8192,16384,32768
	
continuegame:	.asciiz	"\n\n\n\nWelcome to 2048. Press enter to quit, otherwise make a move.\n 8 = UP, 6 = RIGHT, 2 = DOWN, 4 = LEFT"
	.code
	.globl	main
main:		
	
	mov	$a0,$0
	mov	$a1,$0
	li	$a2,4*7<<16+20
	la	$a3,double
	jal	Box.Draw
	la	$s7,board
	mov	$s6,$0			#box index
	addi	$s3,$0,1		#starting x co-ordinate
	addi	$s4,$0,1		#starting y co-ordinate
1:	sll	$t0,$s6,1		#index to offset
	add	$t0,$t0,$s7		
	lhu	$s5,($t0)
	beqz	$s5,skip
	la	$a3,single		#Box instance
	mov	$a0,$s3
	mov	$a1,$s4
	li	$a2,0x50003
	jal	Box.Draw
	addi	$t2,$0,3
	mov	$t1,$s5
	addi	$t3,$0,100
2:	div	$t1,$t1,$t3
	beqz	$t1,3f
	addi	$t2,$t2,-1
	b	2b
3:	add	$a0,$t2,$s3
	addi	$a1,$s4,2
	syscall	$xy
	mov	$a0,$s5
	syscall	$print_int
skip:	addi	$s6,$s6,1
	andi	$t0,$s6,0xf		#check for finished
	beqz	$t0,CkReady
	addi	$s3,$s3,7
	andi	$t0,$s6,3
	bnez	$t0,1b
	addi	$s3,$s3,-28
	addi	$s4,$s4,5
	b	1b
rand:
	la		$a0,board
	addi	$a0,$a0,-2
	li		$s0,0
	jal		board.numblanks2
	move	$s0,$v0
	beqz	$s0,check
	la		$a0,board
	li		$s0,0
	addi	$a0,$a0,-2
	li		$a1,32
	#addi	$t1,$0,'\r
	jal		board.numblanks2
	move	$s0,$v0
	#syscall	$read_char
	#beq		$v0,$t1,quit
	jal		placerandom
	b		main
	
CkReady
	#testing swipes####
	move	$t9,$a0
	move	$t8,$a1
	la	$a0,keyboard.flags
	li	$a1,1
	li	$t3,56 # 8 or up arrow
	li	$t4,52 #4 or left arrow
	li	$t5,50 #2 or down arrow
	li	$t6,54	#6 or right arrow
	li	$t7,13 #enter to quit
CkReady2:	
	syscall	$IO_read
	andi	$t1,$v0,1
	beqz	$t1,CkReady2
	addi	$a0,$a0,4
	syscall	$IO_read
	move	$t0,$v0
	move	$a0,$t9
	move	$a1,$t8
	beq		$t0,$t3,upswipe
	beq		$t0,$t4,leftswipe
	beq		$t0,$t5,downswipe
	beq		$t0,$t6,rightswipe
	beq		$t0,$t7,quit
	b		rand
rightswipe:
	move	$t9,$a0
	la		$a0,board
	jal		scrunchright
	move	$a0,$t9
	move	$t9,$a0
	la		$a0,board 
	addi	$a0,$a0,6	#start will be the last entry since we're going backwards
	jal		swiperight2
	move	$a0,$t9
	move	$t9,$a0
	la		$a0,board
	jal		scrunchright
	move	$a0,$t9
	b		rand
leftswipe:
	move	$t9,$a0
	la		$a0,board
	addi	$a0,$a0,6
	jal		scrunchleft
	move	$a0,$t9
	move	$t9,$a0
	la		$a0,board 
	jal		swipeleft
	move	$a0,$t9
	move	$t9,$a0
	la		$a0,board
	addi	$a0,$a0,6
	jal		scrunchleft
	move	$a0,$t9
	b		rand
downswipe:
	move	$t9,$a0
	la		$a0,board
	jal		scrunchdown
	move	$a0,$t9
	move	$t9,$a0
	la		$a0,board
	addi	$a0,$a0,24
	jal		swipedown
	move	$a0,$t9
	move	$t9,$a0
	la		$a0,board
	jal		scrunchdown
	move	$a0,$t9
	b		rand
upswipe:
	move	$t9,$a0
	la		$a0,board
	addi	$a0,$a0,24
	jal		scrunchup
	move	$a0,$t9
	move	$t9,$a0
	la		$a0,board
	jal		swipeup
	move	$a0,$t9
	move	$t9,$a0
	la		$a0,board
	addi	$a0,$a0,24
	jal		scrunchup
	move	$a0,$t9
	b		rand
check:
	addi	$t1,$0,'\r
	addi	$t2,$0,'n
	la		$a0,continuegame
	syscall	$print_string
	syscall	$read_char
	beq		$v0,$t1,quit
	jal		newgame
	b		main
quit:
	syscall	$exit	
#end main
#begin Rand Num Placement
placerandom:
	addi	$sp,$sp,-4 
	sw		$ra,($sp)
	li		$v1,100 
	li		$t1,50
	syscall	$random
	divu	$v0,$s0
	mfhi	$t4
	divu	$v0,$v1
	mfhi	$t0
	blt		$t0,$t1,next
	addi	$t2,$0,2
	b		next2
next:
	addi	$t2,$0,4
next2:
	la		$a0,board
	addi	$a0,$a0,-2
	jal		board.findnextblank
	beqz	$t4,3f
2:	jal		board.findnextblank
	addi	$t4,$t4,-1
	bnez	$t4,2b
3:	sh		$t2,($a0)
	lw		$ra,($sp)
	addi	$sp,$sp,4
	jr		$ra#end Rand Num Placement
#begin Find Next Blank
board.findnextblank:
		addi 	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,board.findnextblank
		jr		$ra
#end Find Next Blank
# begin swiperight2
swiperight2:
10:		lhu		$t0,($a0)
		lhu		$t1,-2($a0)
		bne		$t0,$t1,11f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,-2($a0)
11:		lhu		$t0,-2($a0)
		lhu		$t1,-4($a0)
		bne		$t0,$t1,12f
		add		$t0,$t0,$t1
		sh		$t0,-2($a0)
		sh		$0,-4($a0)
12:		lhu		$t0,-4($a0)
		lhu		$t1,-6($a0)
		bne		$t0,$t1,20f
		add		$t0,$t0,$t1
		sh		$t0,-4($a0)
		sh		$0,-6($a0)
20:		addi	$a0,$a0,8
		lhu		$t0,($a0)
		lhu		$t1,-2($a0)
		bne		$t0,$t1,21f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,-2($a0)
21:		lhu		$t0,-2($a0)
		lhu		$t1,-4($a0)
		bne		$t0,$t1,22f
		add		$t0,$t0,$t1
		sh		$t0,-2($a0)
		sh		$0,-4($a0)
22:		lhu		$t0,-4($a0)
		lhu		$t1,-6($a0)
		bne		$t0,$t1,30f
		add		$t0,$t0,$t1
		sh		$t0,-4($a0)
		sh		$0,-6($a0)
30:		addi	$a0,$a0,8
		lhu		$t0,($a0)
		lhu		$t1,-2($a0)
		bne		$t0,$t1,31f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,-2($a0)
31:		lhu		$t0,-2($a0)
		lhu		$t1,-4($a0)
		bne		$t0,$t1,32f
		add		$t0,$t0,$t1
		sh		$t0,-2($a0)
		sh		$0,-4($a0)
32:		lhu		$t0,-4($a0)
		lhu		$t1,-6($a0)
		bne		$t0,$t1,40f
		add		$t0,$t0,$t1
		sh		$t0,-4($a0)
		sh		$0,-6($a0)
40:		addi	$a0,$a0,8
		lhu		$t0,($a0)
		lhu		$t1,-2($a0)
		bne		$t0,$t1,41f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,-2($a0)
41:		lhu		$t0,-2($a0)
		lhu		$t1,-4($a0)
		bne		$t0,$t1,42f
		add		$t0,$t0,$t1
		sh		$t0,-2($a0)
		sh		$0,-4($a0)
42:		lhu		$t0,-4($a0)
		lhu		$t1,-6($a0)
		bne		$t0,$t1,endswipe
		add		$t0,$t0,$t1
		sh		$t0,-4($a0)
		sh		$0,-6($a0)
endswipe:
		jr		$ra
#end swiperight2
#begin swipeleft
swipeleft:
10:		lhu		$t0,($a0)
		lhu		$t1,2($a0)
		bne		$t0,$t1,11f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,2($a0)
11:		lhu		$t0,2($a0)
		lhu		$t1,4($a0)
		bne		$t0,$t1,12f
		add		$t0,$t0,$t1
		sh		$t0,2($a0)
		sh		$0,4($a0)
12:		lhu		$t0,4($a0)
		lhu		$t1,6($a0)
		bne		$t0,$t1,20f
		add		$t0,$t0,$t1
		sh		$t0,4($a0)
		sh		$0,6($a0)
20:		addi	$a0,$a0,8
		lhu		$t0,($a0)
		lhu		$t1,2($a0)
		bne		$t0,$t1,21f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,2($a0)
21:		lhu		$t0,2($a0)
		lhu		$t1,4($a0)
		bne		$t0,$t1,22f
		add		$t0,$t0,$t1
		sh		$t0,2($a0)
		sh		$0,4($a0)
22:		lhu		$t0,4($a0)
		lhu		$t1,6($a0)
		bne		$t0,$t1,30f
		add		$t0,$t0,$t1
		sh		$t0,4($a0)
		sh		$0,6($a0)
30:		addi	$a0,$a0,8
		lhu		$t0,($a0)
		lhu		$t1,2($a0)
		bne		$t0,$t1,31f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,2($a0)
31:		lhu		$t0,2($a0)
		lhu		$t1,4($a0)
		bne		$t0,$t1,32f
		add		$t0,$t0,$t1
		sh		$t0,2($a0)
		sh		$0,4($a0)
32:		lhu		$t0,4($a0)
		lhu		$t1,6($a0)
		bne		$t0,$t1,40f
		add		$t0,$t0,$t1
		sh		$t0,4($a0)
		sh		$0,6($a0)
40:		addi	$a0,$a0,8
		lhu		$t0,($a0)
		lhu		$t1,2($a0)
		bne		$t0,$t1,41f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,2($a0)
41:		lhu		$t0,2($a0)
		lhu		$t1,4($a0)
		bne		$t0,$t1,42f
		add		$t0,$t0,$t1
		sh		$t0,2($a0)
		sh		$0,4($a0)
42:		lhu		$t0,4($a0)
		lhu		$t1,6($a0)
		bne		$t0,$t1,endswipeleft
		add		$t0,$t0,$t1
		sh		$t0,4($a0)
		sh		$0,6($a0)
endswipeleft:
		jr		$ra
#end swipeleft
# begin swipedown
swipedown:
10:		lhu		$t0,($a0)
		lhu		$t1,-8($a0)
		bne		$t0,$t1,11f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,-8($a0)
11:		lhu		$t0,-8($a0)
		lhu		$t1,-16($a0)
		bne		$t0,$t1,12f
		add		$t0,$t0,$t1
		sh		$t0,-8($a0)
		sh		$0,-16($a0)
12:		lhu		$t0,-16($a0)
		lhu		$t1,-24($a0)
		bne		$t0,$t1,20f
		add		$t0,$t0,$t1
		sh		$t0,-16($a0)
		sh		$0,-24($a0)
20:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		lhu		$t1,-8($a0)
		bne		$t0,$t1,21f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,-8($a0)
21:		lhu		$t0,-8($a0)
		lhu		$t1,-16($a0)
		bne		$t0,$t1,22f
		add		$t0,$t0,$t1
		sh		$t0,-8($a0)
		sh		$0,-16($a0)
22:		lhu		$t0,-16($a0)
		lhu		$t1,-24($a0)
		bne		$t0,$t1,30f
		add		$t0,$t0,$t1
		sh		$t0,-16($a0)
		sh		$0,-24($a0)
30:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		lhu		$t1,-8($a0)
		bne		$t0,$t1,31f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,-8($a0)
31:		lhu		$t0,-8($a0)
		lhu		$t1,-16($a0)
		bne		$t0,$t1,32f
		add		$t0,$t0,$t1
		sh		$t0,-8($a0)
		sh		$0,-16($a0)
32:		lhu		$t0,-16($a0)
		lhu		$t1,-24($a0)
		bne		$t0,$t1,40f
		add		$t0,$t0,$t1
		sh		$t0,-16($a0)
		sh		$0,-24($a0)
40:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		lhu		$t1,-8($a0)
		bne		$t0,$t1,41f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,-8($a0)
41:		lhu		$t0,-8($a0)
		lhu		$t1,-16($a0)
		bne		$t0,$t1,42f
		add		$t0,$t0,$t1
		sh		$t0,-8($a0)
		sh		$0,-16($a0)
42:		lhu		$t0,-16($a0)
		lhu		$t1,-24($a0)
		bne		$t0,$t1,endswipedown
		add		$t0,$t0,$t1
		sh		$t0,-16($a0)
		sh		$0,-24($a0)
endswipedown:
		jr		$ra
# end swipedown
# begin swipeup
swipeup:
10:		lhu		$t0,($a0)
		lhu		$t1,8($a0)
		bne		$t0,$t1,11f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,8($a0)
11:		lhu		$t0,8($a0)
		lhu		$t1,16($a0)
		bne		$t0,$t1,12f
		add		$t0,$t0,$t1
		sh		$t0,8($a0)
		sh		$0,16($a0)
12:		lhu		$t0,16($a0)
		lhu		$t1,24($a0)
		bne		$t0,$t1,20f
		add		$t0,$t0,$t1
		sh		$t0,16($a0)
		sh		$0,24($a0)
20:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		lhu		$t1,8($a0)
		bne		$t0,$t1,21f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,8($a0)
21:		lhu		$t0,8($a0)
		lhu		$t1,16($a0)
		bne		$t0,$t1,22f
		add		$t0,$t0,$t1
		sh		$t0,8($a0)
		sh		$0,16($a0)
22:		lhu		$t0,16($a0)
		lhu		$t1,24($a0)
		bne		$t0,$t1,30f
		add		$t0,$t0,$t1
		sh		$t0,16($a0)
		sh		$0,24($a0)
30:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		lhu		$t1,8($a0)
		bne		$t0,$t1,31f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,8($a0)
31:		lhu		$t0,8($a0)
		lhu		$t1,16($a0)
		bne		$t0,$t1,32f
		add		$t0,$t0,$t1
		sh		$t0,8($a0)
		sh		$0,16($a0)
32:		lhu		$t0,16($a0)
		lhu		$t1,24($a0)
		bne		$t0,$t1,40f
		add		$t0,$t0,$t1
		sh		$t0,16($a0)
		sh		$0,24($a0)
40:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		lhu		$t1,8($a0)
		bne		$t0,$t1,41f
		add		$t0,$t0,$t1
		sh		$t0,($a0)
		sh		$0,8($a0)
41:		lhu		$t0,8($a0)
		lhu		$t1,16($a0)
		bne		$t0,$t1,42f
		add		$t0,$t0,$t1
		sh		$t0,8($a0)
		sh		$0,16($a0)
42:		lhu		$t0,16($a0)
		lhu		$t1,24($a0)
		bne		$t0,$t1,endswipeup
		add		$t0,$t0,$t1
		sh		$t0,16($a0)
		sh		$0,24($a0)
endswipeup:
		jr		$ra
# end swipeup
# begin scrunchdown
scrunchdown:#function to right justify numbers
11:		move		$t6,$a0
		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		bnez		$t1,12f
		sh			$0,($a0)
		sh			$t0,8($a0)
12:		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		lhu			$t2,16($a0)
		bnez		$t2,13f
		sh			$0,($a0)
		sh			$t0,8($a0)
		sh			$t1,16($a0)
13:		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		lhu			$t2,16($a0)
		lhu			$t3,24($a0)
		bnez		$t3,21f
		sh			$0,($a0)
		sh			$t0,8($a0)
		sh			$t1,16($a0)
		sh			$t2,24($a0)
21:		addi		$a0,$t6,2
		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		bnez		$t1,22f
		sh			$0,($a0)
		sh			$t0,8($a0)
22:		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		lhu			$t2,16($a0)
		bnez		$t2,23f
		sh			$0,($a0)
		sh			$t0,8($a0)
		sh			$t1,16($a0)
23:		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		lhu			$t2,16($a0)
		lhu			$t3,24($a0)
		bnez		$t3,31f
		sh			$0,($a0)
		sh			$t0,8($a0)
		sh			$t1,16($a0)
		sh			$t2,24($a0)
31:		addi		$a0,$t6,4
		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		bnez		$t1,32f
		sh			$0,($a0)
		sh			$t0,8($a0)
32:		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		lhu			$t2,16($a0)
		bnez		$t2,33f
		sh			$0,($a0)
		sh			$t0,8($a0)
		sh			$t1,16($a0)
33:		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		lhu			$t2,16($a0)
		lhu			$t3,24($a0)
		bnez		$t3,41f
		sh			$0,($a0)
		sh			$t0,8($a0)
		sh			$t1,16($a0)
		sh			$t2,24($a0)
41:		addi		$a0,$t6,6
		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		bnez		$t1,42f
		sh			$0,($a0)
		sh			$t0,8($a0)
42:		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		lhu			$t2,16($a0)
		bnez		$t2,43f
		sh			$0,($a0)
		sh			$t0,8($a0)
		sh			$t1,16($a0)
43:		lhu			$t0,($a0)
		lhu			$t1,8($a0)
		lhu			$t2,16($a0)
		lhu			$t3,24($a0)
		bnez		$t3,51f
		sh			$0,($a0)
		sh			$t0,8($a0)
		sh			$t1,16($a0)
		sh			$t2,24($a0)
51:
		jr			$ra
# end scrunchdown
# begin scrunchup
scrunchup:
11:		move		$t6,$a0
		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		bnez		$t1,12f
		sh			$0,($a0)
		sh			$t0,-8($a0)
12:		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		lhu			$t2,-16($a0)
		bnez		$t2,13f
		sh			$0,($a0)
		sh			$t0,-8($a0)
		sh			$t1,-16($a0)
13:		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		lhu			$t2,-16($a0)
		lhu			$t3,-24($a0)
		bnez		$t3,21f
		sh			$0,($a0)
		sh			$t0,-8($a0)
		sh			$t1,-16($a0)
		sh			$t2,-24($a0)
21:		addi		$a0,$t6,2
		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		bnez		$t1,22f
		sh			$0,($a0)
		sh			$t0,-8($a0)
22:		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		lhu			$t2,-16($a0)
		bnez		$t2,23f
		sh			$0,($a0)
		sh			$t0,-8($a0)
		sh			$t1,-16($a0)
23:		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		lhu			$t2,-16($a0)
		lhu			$t3,-24($a0)
		bnez		$t3,31f
		sh			$0,($a0)
		sh			$t0,-8($a0)
		sh			$t1,-16($a0)
		sh			$t2,-24($a0)
31:		addi		$a0,$t6,4
		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		bnez		$t1,32f
		sh			$0,($a0)
		sh			$t0,-8($a0)
32:		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		lhu			$t2,-16($a0)
		bnez		$t2,33f
		sh			$0,($a0)
		sh			$t0,-8($a0)
		sh			$t1,-16($a0)
33:		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		lhu			$t2,-16($a0)
		lhu			$t3,-24($a0)
		bnez		$t3,41f
		sh			$0,($a0)
		sh			$t0,-8($a0)
		sh			$t1,-16($a0)
		sh			$t2,-24($a0)
41:		addi		$a0,$t6,6
		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		bnez		$t1,42f
		sh			$0,($a0)
		sh			$t0,-8($a0)
42:		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		lhu			$t2,-16($a0)
		bnez		$t2,43f
		sh			$0,($a0)
		sh			$t0,-8($a0)
		sh			$t1,-16($a0)
43:		lhu			$t0,($a0)
		lhu			$t1,-8($a0)
		lhu			$t2,-16($a0)
		lhu			$t3,-24($a0)
		bnez		$t3,51f
		sh			$0,($a0)
		sh			$t0,-8($a0)
		sh			$t1,-16($a0)
		sh			$t2,-24($a0)
51:
		jr			$ra
#end scrunchup
# begin scrunchright
scrunchright:
11:		move		$t6,$a0
		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		bnez		$t1,12f
		sh			$0,($a0)
		sh			$t0,2($a0)
12:		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		lhu			$t2,4($a0)
		bnez		$t2,13f
		sh			$0,($a0)
		sh			$t0,2($a0)
		sh			$t1,4($a0)
13:		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		lhu			$t2,4($a0)
		lhu			$t3,6($a0)
		bnez		$t3,21f
		sh			$0,($a0)
		sh			$t0,2($a0)
		sh			$t1,4($a0)
		sh			$t2,6($a0)
21:		addi		$a0,$t6,8
		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		bnez		$t1,22f
		sh			$0,($a0)
		sh			$t0,2($a0)
22:		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		lhu			$t2,4($a0)
		bnez		$t2,23f
		sh			$0,($a0)
		sh			$t0,2($a0)
		sh			$t1,4($a0)
23:		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		lhu			$t2,4($a0)
		lhu			$t3,6($a0)
		bnez		$t3,31f
		sh			$0,($a0)
		sh			$t0,2($a0)
		sh			$t1,4($a0)
		sh			$t2,6($a0)
31:		addi		$a0,$t6,16
		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		bnez		$t1,32f
		sh			$0,($a0)
		sh			$t0,2($a0)
32:		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		lhu			$t2,4($a0)
		bnez		$t2,33f
		sh			$0,($a0)
		sh			$t0,2($a0)
		sh			$t1,4($a0)
33:		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		lhu			$t2,4($a0)
		lhu			$t3,6($a0)
		bnez		$t3,41f
		sh			$0,($a0)
		sh			$t0,2($a0)
		sh			$t1,4($a0)
		sh			$t2,6($a0)
41:		addi		$a0,$t6,24
		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		bnez		$t1,42f
		sh			$0,($a0)
		sh			$t0,2($a0)
42:		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		lhu			$t2,4($a0)
		bnez		$t2,43f
		sh			$0,($a0)
		sh			$t0,2($a0)
		sh			$t1,4($a0)
43:		lhu			$t0,($a0)
		lhu			$t1,2($a0)
		lhu			$t2,4($a0)
		lhu			$t3,6($a0)
		bnez		$t3,51f
		sh			$0,($a0)
		sh			$t0,2($a0)
		sh			$t1,4($a0)
		sh			$t2,6($a0)
51:
		jr			$ra
# end scrunchright
# begin scrunchleft
scrunchleft:
11:		move		$t6,$a0
		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		bnez		$t1,12f
		sh			$0,($a0)
		sh			$t0,-2($a0)
12:		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		lhu			$t2,-4($a0)
		bnez		$t2,13f
		sh			$0,($a0)
		sh			$t0,-2($a0)
		sh			$t1,-4($a0)
13:		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		lhu			$t2,-4($a0)
		lhu			$t3,-6($a0)
		bnez		$t3,21f
		sh			$0,($a0)
		sh			$t0,-2($a0)
		sh			$t1,-4($a0)
		sh			$t2,-6($a0)
21:		addi		$a0,$t6,8
		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		bnez		$t1,22f
		sh			$0,($a0)
		sh			$t0,-2($a0)
22:		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		lhu			$t2,-4($a0)
		bnez		$t2,23f
		sh			$0,($a0)
		sh			$t0,-2($a0)
		sh			$t1,-4($a0)
23:		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		lhu			$t2,-4($a0)
		lhu			$t3,-6($a0)
		bnez		$t3,31f
		sh			$0,($a0)
		sh			$t0,-2($a0)
		sh			$t1,-4($a0)
		sh			$t2,-6($a0)
31:		addi		$a0,$t6,16
		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		bnez		$t1,32f
		sh			$0,($a0)
		sh			$t0,-2($a0)
32:		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		lhu			$t2,-4($a0)
		bnez		$t2,33f
		sh			$0,($a0)
		sh			$t0,-2($a0)
		sh			$t1,-4($a0)
33:		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		lhu			$t2,-4($a0)
		lhu			$t3,-6($a0)
		bnez		$t3,41f
		sh			$0,($a0)
		sh			$t0,-2($a0)
		sh			$t1,-4($a0)
		sh			$t2,-6($a0)
41:		addi		$a0,$t6,24
		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		bnez		$t1,42f
		sh			$0,($a0)
		sh			$t0,-2($a0)
42:		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		lhu			$t2,-4($a0)
		bnez		$t2,43f
		sh			$0,($a0)
		sh			$t0,-2($a0)
		sh			$t1,-4($a0)
43:		lhu			$t0,($a0)
		lhu			$t1,-2($a0)
		lhu			$t2,-4($a0)
		lhu			$t3,-6($a0)
		bnez		$t3,51f
		sh			$0,($a0)
		sh			$t0,-2($a0)
		sh			$t1,-4($a0)
		sh			$t2,-6($a0)
51:
		jr			$ra
# end scrunchleft
# begin numblanks2		
board.numblanks2:
			li		$v0,0
1:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,2f
		addi	$v0,$v0,1
2:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,3f
		addi	$v0,$v0,1
3:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,4f
		addi	$v0,$v0,1
4:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,5f
		addi	$v0,$v0,1
5:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,6f
		addi	$v0,$v0,1
6:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,7f
		addi	$v0,$v0,1
7:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,8f
		addi	$v0,$v0,1
8:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,9f
		addi	$v0,$v0,1
9:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,10f
		addi	$v0,$v0,1
10:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,11f
		addi	$v0,$v0,1
11:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,12f
		addi	$v0,$v0,1
12:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,13f
		addi	$v0,$v0,1
13:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,14f
		addi	$v0,$v0,1
14:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,15f
		addi	$v0,$v0,1
15:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,16f
		addi	$v0,$v0,1
16:		addi	$a0,$a0,2
		lhu		$t0,($a0)
		bnez	$t0,17f
		addi	$v0,$v0,1
17:		jr		$ra
# end numblanks2
# begin newgame
newgame:
		la		$a0,board
		sh		$0,($a0)
		sh		$0,2($a0)
		sh		$0,4($a0)
		sh		$0,6($a0)
		sh		$0,8($a0)
		sh		$0,10($a0)
		sh		$0,12($a0)
		sh		$0,14($a0)
		sh		$0,16($a0)
		sh		$0,18($a0)
		sh		$0,20($a0)
		sh		$0,22($a0)
		sh		$0,24($a0)
		sh		$0,26($a0)
		sh		$0,28($a0)
		sh		$0,30($a0)
		jr		$ra
# end newgame
