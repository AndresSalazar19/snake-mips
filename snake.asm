# Author: Andrés Salazar y Yadira Suarez

###############################################################
### 		Configuración del juego		    	    ###	
###							    ###
###	Ancho del pixel: 16 			    	    ###
###	Alto del pixel: 16				    ###
###	Ancho total del juego: 512			    ###
###	Alto total del juego: 512 			    ###
###	base de posicion del juego 0x10010000 (static data) ###
###							    ###	
###############################################################

.data

frameBuffer: 	.space 	0x00100000		#512 de ancho y 512 de alto y 4 bytes por pixel (512x512x4)/16 
xVel:		.word	0		
yVel:		.word	0		
xPos:		.word	20		
yPos:		.word	13		
tail:		.word	2000		# location of rail on bit map display
appleX:		.word	4		# posicion x de la comida 
appleY:		.word	10	
snakeUp:	.word	0x00288a3a	# green pixel for when snaking moving up	
snakeDown:	.word	0x00288a3b	
snakeLeft:	.word	0x00288a3d	
snakeRight:	.word	0x00288a3f	
xConversion:	.word	4		
yConversion:	.word	128		

     
.text
main:

### Sección del fondo del juego

	la 	$t0, frameBuffer	# cargar la dirección frameBuffer
	li 	$t1, 262144		# guarda 512*512 pixels, el número de cuadrados que se pintará
	li 	$t2, 0xcc9b9b		# color de la pantalla
l1:
	sw   	$t2, 0($t0)
	addi 	$t0, $t0, 4 		# avanza al siguiente pixel a pintar
	addi 	$t1, $t1, -1		# decrementa el número de pixeles
	bne 	$t1, $zero, l1		# se repite mientras el número de pixeles faltantes sea diferente de 0
			
### Borde
	
	# Borde Top y bottom
	la	$t0, frameBuffer
	addi	$t1, $zero, 32		# 512/16 32 columnas a pintar
	li 	$t2, 0x00000000		# borde color negro
drawBorderTop:
	sh	$t2, 0($t0)		# pinta 
	addi	$t0, $t0, 4		# avanza al siguiente pixel a pintar
	addi	$t1, $t1, -1		# resta 1 a las columnas por pintar
	bne 	$t1, $zero, drawBorderTop	# repite hast haya completado todas las columnas
	
	addi	$t0, $t0, 3840		# manda a la última fila 31x32x4
	addi	$t1, $zero, 32		# pintará 32 filas (512/16)

drawBorderBot:
	sh	$t2, 0($t0)		
	addi	$t0, $t0, 4		
	addi	$t1, $t1, -1		
	bne 	$t1, $zero, drawBorderBot	
	
	# Borde left y right
	la	$t0, frameBuffer	
	addi	$t1, $zero, 32		# 32 filas a pintar (512/16)

drawBorderColumn:
	sh	$t2, 0($t0)		# pinta el borde left
	sh 	$t2, 124($t0)		# pinta el borde right
	addi	$t0, $t0, 128		# va al siguiente fila 32x4
	addi	$t1, $t1, -1		# festa 1 al numero de filas por pintar
	bne	$t1, $zero, drawBorderColumn	
	
	### dibujo de serpiente
	la 	$t0, frameBuffer	
	lw	$t1, tail		#tail
	lw 	$t2, snakeUp	

	add 	$t3, $t1, $t0
	sw	$t2, 0($t3)			
	addi	$t1, $t3, -128		# pintar el pixel  encima
	sw	$t2, 0($t1)		
	
	### draw initial apple
	jal 	drawApple

# This is the update function for game
# psudeocode
# input = get user input
# if input == w { moveUp();}
# if input == s { moveDown();}	
# if input == a { moveLeft();}	
# if input == d { moveRigth();}	
### each move method has similar code
# moveDirection () {
#	dir = direction of snake
#	updateSnake(dir)
#	updateSnakeHeadPosition()
#	go back to beginning of update fucntion
# } 	
# Registers:
# t3 = key press input
# s3 = direction of the snake
gameUpdateLoop:

	lw	$t3, 0xffff0004		# get keypress from keyboard input
	
	### Sleep for 66 ms so frame rate is about 15
	addi	$v0, $zero, 32	# syscall sleep
	addi	$a0, $zero, 100	# 100 ms	
	
	syscall
	beq	$t3, 100, moveRight	# if key press = 'd' branch to moveright
	beq	$t3, 97, moveLeft	# else if key press = 'a' branch to moveLeft
	beq	$t3, 119, moveUp	# if key press = 'w' branch to moveUp
	beq	$t3, 115, moveDown	# else if key press = 's' branch to moveDown
	beq	$t3, 0, moveUp		# start game moving up

moveUp:
	lw	$s3, snakeUp	# s3 = direction of snake
	add	$a0, $s3, $zero	# a0 = direction of snake
	addi	$t5, $zero, 0		# set x velocity to zero
	addi	$t6, $zero, -1	 	# set y velocity to -1
	sw	$t5, xVel		# update xVel in memory
	sw	$t6, yVel		# update yVel in memory
	jal	updateSnake
	jal 	updateSnakeHeadPosition
	
	j	exitMoving 	

moveDown:
	lw	$s3, snakeDown	# s3 = direction of snake
	add	$a0, $s3, $zero	# a0 = direction of snake
	addi	$t5, $zero, 0		# set x velocity to zero
	addi	$t6, $zero, 1 		# set y velocity to 1
	sw	$t5, xVel		# update xVel in memory
	sw	$t6, yVel		# update yVel in memory
	jal	updateSnake
	jal 	updateSnakeHeadPosition
	
	j	exitMoving 
	
moveRight:
	lw	$s3, snakeRight	# s3 = direction of snake
	add	$a0, $s3, $zero	# a0 = direction of snake
	addi	$t5, $zero, 1		# set x velocity to 1
	addi	$t6, $zero, 0 		# set y velocity to zero
	sw	$t5, xVel		# update xVel in memory
	sw	$t6, yVel		# update yVel in memory
	jal	updateSnake
	jal 	updateSnakeHeadPosition
	
	j	exitMoving 

moveLeft:
	lw	$s3, snakeLeft	# s3 = direction of snake
	add	$a0, $s3, $zero	# a0 = direction of snake
	addi	$t5, $zero, -1		# set x velocity to -1
	addi	$t6, $zero, 0 		# set y velocity to zero
	sw	$t5, xVel		# update xVel in memory
	sw	$t6, yVel		# update yVel in memory
	jal	updateSnake
	jal 	updateSnakeHeadPosition
	j	exitMoving 
	
	
# this function update the snake on the bitmap display and changes its velocity
# Param 1 is the direction
# code logic steps
# updateSnake(colorDir) {
#	getBitMapLocation;
#	store color dir in bitMapLoction
#	getDirection of snake
# 	update velocity based on snake
#	check if head == apple
#		get random new apple coordinates
#		draw apple on bitmap display
#		exit updateSnake function
#	check head != background color
#		game over
#	Remove tail from bit map display
#	update new tail base upon tail direction
#	exit updateSnake function
# }	
updateSnake:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateSnake frame pointer
	
	### DRAW HEAD
	lw	$t0, xPos		# t0 = xPos of snake
	lw	$t1, yPos		# t1 = yPos of snake
	lw	$t2, xConversion	# t2 = 4
	lw	$t3, yConversion
	mult	$t1, $t3		
	mflo	$t3			# yPos * 128
	mult	$t0, $t2
	mflo	$t2			# xPos *4
	add	$t0, $t3, $t2		# t0 = yPos * 128 + xPos * 4
	la 	$t1, frameBuffer	# load frame buffer address
	add	$t0, $t1, $t0		# t0 = (yPos * 64 + xPos) * 4 + frame address
	lw	$t4, 0($t0)		# save original val of pixel in t4
	sw	$a0, 0($t0)		# store direction plus color on the bitmap display
	
	### Head location checks
	li 	$t2, 0x00ff0000		# load red color
	bne	$t2, $t4, headNotApple	# if head location is not the apple branch away
	
	jal 	newAppleLocation
	jal	drawApple
	j exitUpdateSnake

	
headNotApple:

	li	$t2, 0xcc9b9b			# load light gray color
	beq	$t2, $t4, validHeadSquare	# if head location is background branch away
	
	addi 	$v0, $zero, 10	# exit the program
	syscall
	
validHeadSquare:

	### Remove Tail
	lw	$t0, tail		# t0 = tail
	la 	$t1, frameBuffer	# load frame buffer address
	add	$t2, $t0, $t1		# t2 = tail location on the bitmap display
	li 	$t3, 0xcc9b9b		# load light gray color
	lw	$t4, 0($t2)		# t4 = tail direction and color
	sw	$t3, 0($t2)		# replace tail with background color
	
	### update new Tail
	lw	$t5, snakeUp			# load word snake up = 0x0000ff00
	beq	$t5, $t4, setNextTailUp		# if tail direction and color == snake up branch to setNextTailUp
	
	lw	$t5, snakeDown			# load word snake up = 0x0100ff00
	beq	$t5, $t4, setNextTailDown	# if tail direction and color == snake down branch to setNextTailDown
	
	lw	$t5, snakeLeft			# load word snake up = 0x0200ff00
	beq	$t5, $t4, setNextTailLeft	# if tail direction and color == snake left branch to setNextTailLeft
	
	lw	$t5, snakeRight			# load word snake up = 0x0300ff00
	beq	$t5, $t4, setNextTailRight	# if tail direction and color == snake right branch to setNextTailRight
	
setNextTailUp:
	addi	$t0, $t0, -128		# tail = tail - 256
	sw	$t0, tail		# store  tail in memory
	j exitUpdateSnake
	
setNextTailDown:
	addi	$t0, $t0, 128		# tail = tail + 256
	sw	$t0, tail		# store  tail in memory
	j exitUpdateSnake
	
setNextTailLeft:
	addi	$t0, $t0, -4		# tail = tail - 4
	sw	$t0, tail		# store  tail in memory
	j exitUpdateSnake
	
setNextTailRight:
	addi	$t0, $t0, 4		# tail = tail + 4
	sw	$t0, tail		# store  tail in memory
	j exitUpdateSnake
	

exitUpdateSnake:
	
	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code
	
	
updateSnakeHeadPosition:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateSnake frame pointer	
	
	lw	$t3, xVel	# load xVel from memory
	lw	$t4, yVel	# load yVel from memory
	lw	$t5, xPos	# load xPos from memory
	lw	$t6, yPos	# load yPos from memory
	add	$t5, $t5, $t3	# update x pos
	add	$t6, $t6, $t4	# update y pos
	sw	$t5, xPos	# store updated xpos back to memory
	sw	$t6, yPos	# store updated ypos back to memory
	
	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code
	
exitMoving:
	j 	gameUpdateLoop		# loop back to beginning

# this function draws the apple base upon x and y coordintes
# code logic
# drawApple() {
#	convert (x, y) to bitmap display
#	store red color into bitmap display
#	exit drawApple
# }
drawApple:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateSnake frame pointer
	
	lw	$t0, appleX		# t0 = xPos of apple
	lw	$t1, appleY		# t1 = yPos of apple
	lw	$t2, yConversion	
	lw	$t3, xConversion	
	mult	$t1, $t2		# appleY * 128
	mflo	$t4			# t4 = appleY * 128
	mult	$t0, $t3			
	mflo	$t5 			# t5 = appleX * 4
	add	$t0, $t4, $t5		
		
	la 	$t1, frameBuffer	# load frame buffer address
	add	$t0, $t1, $t0		
	li	$t4, 0x00ff0000
	sw	$t4, 0($t0)		# store direction plus color on the bitmap display
	
	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code	

# This function finds a new spot for an apple after its been eaten
# does so randomly using syscall 42 which is a random number generator
# code logic:
# newAppleLocation() {
#	get random X from 0 - 63
# 	get random Y from 0 - 31
#	convert (x, y) to bit map display value
# 	if (bit map display value != gray background)
#		redo the randomize
#	once good apple spot found store x, y in memory
#	exit newAppleLocation
# }
newAppleLocation:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateSnake frame pointer

redoRandom:		
	addi	$v0, $zero, 42	# random int 
	addi	$a1, $zero, 31	# upper bound
	syscall
	add	$t1, $zero, $a0	# random appleX
	
	addi	$v0, $zero, 42	# random int 
	addi	$a1, $zero, 31	# upper bound
	syscall
	add	$t2, $zero, $a0	# random appleY
	
	lw	$t3, yConversion	
	mult	$t2, $t3		
	mflo	$t4			# t4 = random appleY * 128
	lw 	$t3, xConversion
	mult	$t3, $t1
	mflo	$t5			# t5 = random appleX * 4
	add	$t4, $t4, $t5		# t4 = random appleY * 64 + random appleX *4
	
	la 	$t0, frameBuffer	# load frame buffer address
	add	$t0, $t4, $t0		
	lw	$t5, 0($t0)		# t5 = value of pixel at t0
	
	li	$t6, 0xcc9b9b		# load light gray color
	beq	$t5, $t6, goodApple	# if loction is a good sqaure branch to goodApple
	j redoRandom

goodApple:
	sw	$t1, appleX
	sw	$t2, appleY	

	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code
