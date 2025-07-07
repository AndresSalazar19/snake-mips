# Author: Andrés Salazar y Yadira Suarez

# === Configuración del Juego ===
# Resolución de pantalla:      512 x 512 píxeles
# Tamaño de cada píxel:        16 x 16
# Dirección base de memoria:   0x10010000 (área de datos estática)
# Cada píxel usa 4 bytes (ARGB)

.data

frameBuffer:     .space     0x00100000    # Espacio para la pantalla (512x512x4 bytes)
xVel:            .word    0               # Velocidad en X
yVel:            .word    0               # Velocidad en Y
xPos:            .word    20              # Posición X de la cabeza de la serpiente
yPos:            .word    13              # Posición Y de la cabeza de la serpiente
tail:            .word    2000            # Posición de la cola en el bitmap
plasticX:          .word    4               # Posición X de la manzana
plasticY:          .word    10              # Posición Y de la manzana
sharkUp:     .word 0xFFAAAAAA   # Gris claro, dirección 00
sharkDown:   .word 0xFFAAAAAB   # Gris claro, dirección 01
sharkLeft:   .word 0xFFAAAAAC   # Gris claro, dirección 10
sharkRight:  .word 0xFFAAAAAD   # Gris claro, dirección 11

xConversion:     .word    4               # Conversión de coordenadas X a dirección de memoria
yConversion:     .word    128             # Conversión de coordenadas Y a dirección de memoria
score:      .word   0      # Puntos acumulados por comer manzanas
msgScore:   .asciiz "SCORE: "

.text
main:

# Dibujo del fondo del juego

    la     $t0, frameBuffer        # Cargar la dirección del buffer de pantalla
    li     $t1, 262144             # Cantidad de pixeles: 512 * 512
    li     $t2, 0xFF003366           # Color de fondo gris claro
l1:
    sw     $t2, 0($t0)             # Pintar pixel actual
    addi   $t0, $t0, 4             # Avanzar al siguiente pixel
    addi   $t1, $t1, -1            # Decrementar contador
    bne    $t1, $zero, l1          # Repetir hasta pintar todo

# Dibujo de los bordes del juego

    # Bordes superior e inferior
    la     $t0, frameBuffer
    li     $t1, 32                 # 512/16 = 32 columnas
    li     $t2, 0x00000000         # Color negro para el borde

drawBorderTop:
    sh     $t2, 0($t0)             # Pintar borde superior
    addi   $t0, $t0, 4             # Siguiente pixel
    addi   $t1, $t1, -1
    bne    $t1, $zero, drawBorderTop

    addi   $t0, $t0, 3840          # Ir al inicio de la última fila
    li     $t1, 32                 # Pintar 32 columnas

drawBorderBot:
    sh     $t2, 0($t0)             # Pintar borde inferior
    addi   $t0, $t0, 4
    addi   $t1, $t1, -1
    bne    $t1, $zero, drawBorderBot

    # Bordes izquierdo y derecho
    la     $t0, frameBuffer
    li     $t1, 32                 # 32 filas

drawBorderColumn:
    sh     $t2, 0($t0)             # Pintar borde izquierdo
    sh     $t2, 124($t0)           # Pintar borde derecho
    addi   $t0, $t0, 128           # Avanzar a la siguiente fila
    addi   $t1, $t1, -1
    bne    $t1, $zero, drawBorderColumn

    # Dibujo inicial de la serpiente
    la     $t0, frameBuffer
    lw     $t1, tail
    lw     $t2, sharkUp
    add    $t3, $t1, $t0
    sw     $t2, 0($t3)             # Pintar cabeza
    addi   $t1, $t3, -128          # Pintar pixel encima
    sw     $t2, 0($t1)

# Mostrar el texto inicial "SCORE: 0"
    li   $v0, 4          # syscall para imprimir string
    la   $a0, msgScore
    syscall

    lw   $a0, score      # score está en 0 al inicio
    li   $v0, 1          # syscall para imprimir entero
    syscall

    # Salto de línea opcional
    li   $v0, 11
    li   $a0, 10         # ASCII de '\n'
    syscall

    # Dibujo inicial de la manzana
    jal    drawPlastic

# Bucle de actualización del juego

# Lógica: espera entrada del teclado y llama a la función de movimiento
# con base en la tecla presionada. Si no hay tecla, sigue moviendo hacia arriba

gameUpdateLoop:

    lw     $t3, 0xffff0004         # Leer entrada de teclado

    addi   $v0, $zero, 32          # Pausa de 100 ms (para ~15 FPS)
    addi   $a0, $zero, 100
    syscall

    beq    $t3, 100, moveRight     # 'd'
    beq    $t3, 97, moveLeft       # 'a'
    beq    $t3, 119, moveUp        # 'w'
    beq    $t3, 115, moveDown      # 's'
    beq    $t3, 0, moveUp          # Si no hay entrada, ir hacia arriba

moveUp:
	lw	$s3, sharkUp	# s3 = direction of Shark
	add	$a0, $s3, $zero	# a0 = direction of Shark
	addi	$t5, $zero, 0		# set x velocity to zero
	addi	$t6, $zero, -1	 	# set y velocity to -1
	sw	$t5, xVel		# update xVel in memory
	sw	$t6, yVel		# update yVel in memory
	jal	updateShark
	jal 	updateSharkHeadPosition
	
	j	exitMoving 	

moveDown:
	lw	$s3, sharkDown	# s3 = direction of Shark
	add	$a0, $s3, $zero	# a0 = direction of Shark
	addi	$t5, $zero, 0		# set x velocity to zero
	addi	$t6, $zero, 1 		# set y velocity to 1
	sw	$t5, xVel		# update xVel in memory
	sw	$t6, yVel		# update yVel in memory
	jal	updateShark
	jal 	updateSharkHeadPosition
	
	j	exitMoving 
	
moveRight:
	lw	$s3, sharkRight	# s3 = direction of Shark
	add	$a0, $s3, $zero	# a0 = direction of Shark
	addi	$t5, $zero, 1		# set x velocity to 1
	addi	$t6, $zero, 0 		# set y velocity to zero
	sw	$t5, xVel		# update xVel in memory
	sw	$t6, yVel		# update yVel in memory
	jal	updateShark
	jal 	updateSharkHeadPosition
	
	j	exitMoving 

moveLeft:
	lw	$s3, sharkLeft	# s3 = direction of Shark
	add	$a0, $s3, $zero	# a0 = direction of Shark
	addi	$t5, $zero, -1		# set x velocity to -1
	addi	$t6, $zero, 0 		# set y velocity to zero
	sw	$t5, xVel		# update xVel in memory
	sw	$t6, yVel		# update yVel in memory
	jal	updateShark
	jal 	updateSharkHeadPosition
	j	exitMoving 
	
	
# this function update the Shark on the bitmap display and changes its velocity
# Param 1 is the direction
# code logic steps
# updateShark(colorDir) {
#	getBitMapLocation;
#	store color dir in bitMapLoction
#	getDirection of Shark
# 	update velocity based on Shark
#	check if head == Plastic
#		get random new Plastic coordinates
#		draw Plastic on bitmap display
#		exit updateShark function
#	check head != background color
#		game over
#	Remove tail from bit map display
#	update new tail base upon tail direction
#	exit updateShark function
# }	
updateShark:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateShark frame pointer
	
	### DRAW HEAD
	lw	$t0, xPos		# t0 = xPos of Shark
	lw	$t1, yPos		# t1 = yPos of Shark
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
	bne	$t2, $t4, headNotPlastic	# if head location is not the Plastic branch away
	
	jal 	newPlasticLocation
	jal	drawPlastic
	# Incrementar el score
    lw   $t7, score       # Cargar el score actual
    addi $t7, $t7, 1      # Incrementar en 1
    sw   $t7, score       # Guardar de nuevo
    # Mostrar "SCORE: "
    li   $v0, 4          # syscall para imprimir string
    la   $a0, msgScore   # dirección del mensaje
    syscall

    # Mostrar el número del score
    lw   $a0, score      # cargar el valor actual
    li   $v0, 1          # syscall para imprimir entero
    syscall

    # Salto de línea
    li   $v0, 11         # syscall para imprimir carácter
    li   $a0, 10         # código ASCII para newline '\n'
    syscall


	j exitUpdateShark

	
headNotPlastic:

	li	$t2, 0xFF003366			# load light gray color
	beq	$t2, $t4, validHeadSquare	# if head location is background branch away
	
	addi 	$v0, $zero, 10	# exit the program
	syscall
	
validHeadSquare:

	### Remove Tail
	lw	$t0, tail		# t0 = tail
	la 	$t1, frameBuffer	# load frame buffer address
	add	$t2, $t0, $t1		# t2 = tail location on the bitmap display
	li 	$t3, 0xFF003366		# load light gray color
	lw	$t4, 0($t2)		# t4 = tail direction and color
	sw	$t3, 0($t2)		# replace tail with background color
	
	### update new Tail
	lw	$t5, sharkUp			# load word Shark up = 0x0000ff00
	beq	$t5, $t4, setNextTailUp		# if tail direction and color == Shark up branch to setNextTailUp
	
	lw	$t5, sharkDown			# load word Shark up = 0x0100ff00
	beq	$t5, $t4, setNextTailDown	# if tail direction and color == Shark down branch to setNextTailDown
	
	lw	$t5, sharkLeft			# load word Shark up = 0x0200ff00
	beq	$t5, $t4, setNextTailLeft	# if tail direction and color == Shark left branch to setNextTailLeft
	
	lw	$t5, sharkRight			# load word Shark up = 0x0300ff00
	beq	$t5, $t4, setNextTailRight	# if tail direction and color == Shark right branch to setNextTailRight
	
setNextTailUp:
	addi	$t0, $t0, -128		# tail = tail - 256
	sw	$t0, tail		# store  tail in memory
	j exitUpdateShark
	
setNextTailDown:
	addi	$t0, $t0, 128		# tail = tail + 256
	sw	$t0, tail		# store  tail in memory
	j exitUpdateShark
	
setNextTailLeft:
	addi	$t0, $t0, -4		# tail = tail - 4
	sw	$t0, tail		# store  tail in memory
	j exitUpdateShark
	
setNextTailRight:
	addi	$t0, $t0, 4		# tail = tail + 4
	sw	$t0, tail		# store  tail in memory
	j exitUpdateShark
	

exitUpdateShark:
	
	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code
	
	
updateSharkHeadPosition:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateShark frame pointer	
	
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

# this function draws the Plastic base upon x and y coordintes
# code logic
# drawPlastic() {
#	convert (x, y) to bitmap display
#	store red color into bitmap display
#	exit drawPlastic
# }
drawPlastic:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateShark frame pointer
	
	lw	$t0, plasticX		# t0 = xPos of plastic
	lw	$t1, plasticY		# t1 = yPos of plastic
	lw	$t2, yConversion	
	lw	$t3, xConversion	
	mult	$t1, $t2		# plasticY * 128
	mflo	$t4			# t4 = plasticY * 128
	mult	$t0, $t3			
	mflo	$t5 			# t5 = plasticX * 4
	add	$t0, $t4, $t5		
		
	la 	$t1, frameBuffer	# load frame buffer address
	add	$t0, $t1, $t0		
	li	$t4, 0x00ff0000
	sw	$t4, 0($t0)		# store direction plus color on the bitmap display
	
	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code	

# This function finds a new spot for an plastic after its been eaten
# does so randomly using syscall 42 which is a random number generator
# code logic:
# newplasticLocation() {
#	get random X from 0 - 63
# 	get random Y from 0 - 31
#	convert (x, y) to bit map display value
# 	if (bit map display value != gray background)
#		redo the randomize
#	once good plastic spot found store x, y in memory
#	exit newplasticLocation
# }
newPlasticLocation:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateShark frame pointer

redoRandom:		
	addi	$v0, $zero, 42	# random int 
	addi	$a1, $zero, 31	# upper bound
	syscall
	add	$t1, $zero, $a0	# random PlasticX
	
	addi	$v0, $zero, 42	# random int 
	addi	$a1, $zero, 31	# upper bound
	syscall
	add	$t2, $zero, $a0	# random PlasticY
	
	lw	$t3, yConversion	
	mult	$t2, $t3		
	mflo	$t4			# t4 = random PlasticY * 128
	lw 	$t3, xConversion
	mult	$t3, $t1
	mflo	$t5			# t5 = random PlasticX * 4
	add	$t4, $t4, $t5		# t4 = random PlasticY * 64 + random PlasticX *4
	
	la 	$t0, frameBuffer	# load frame buffer address
	add	$t0, $t4, $t0		
	lw	$t5, 0($t0)		# t5 = value of pixel at t0
	
	li	$t6, 0xFF003366		# load light gray color
	beq	$t5, $t6, goodPlastic	# if loction is a good sqaure branch to goodPlastic
	j redoRandom

goodPlastic:
	sw	$t1, plasticX
	sw	$t2, plasticY	

	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code
