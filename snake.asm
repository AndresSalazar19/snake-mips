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
plasticX:        .word    4               # Posición X del plastico
plasticY:        .word    10              # Posición Y del plastico
sharkUp:     	 .word 0xFFAAAAAA   	# Gris claro, dirección 00
sharkDown:       .word 0xFFAAAAAB   	# Gris claro, dirección 01
sharkLeft:       .word 0xFFAAAAAC   	# Gris claro, dirección 10
sharkRight:      .word 0xFFAAAAAD   	# Gris claro, dirección 11

xConversion:     .word    4               # Conversión de coordenadas X a dirección de memoria
yConversion:     .word    128             # Conversión de coordenadas Y a dirección de memoria
score:           .word   0      # Puntos acumulados por comer plasticos
msgScore:        .asciiz "SCORE: "

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
    li     $t1, 32                 # 32 filas (512/16)

drawBorderColumn:
    sh     $t2, 0($t0)             # Pintar borde izquierdo
    sh     $t2, 124($t0)           # Pintar borde derecho
    addi   $t0, $t0, 128           # Avanzar a la siguiente fila
    addi   $t1, $t1, -1
    bne    $t1, $zero, drawBorderColumn

    # Dibujo inicial del Shark
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

    # Dibujo inicial del plastico
    jal    drawPlastic

# Bucle de actualización del juego

# Lógica: espera entrada del teclado y llama a la función de movimiento
# con base en la tecla presionada. Si no hay tecla, sigue moviendo hacia arriba (como inicio del juego)

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
	lw	$s3, sharkUp		# s3 = color del shark cuando sube
	add	$a0, $s3, $zero		# a0 = copia el valor de s3
	li	$t5, 0			#
	li	$t6, -1	 		# 
	sw	$t5, xVel		# actualiza xVel=0 en memoria
	sw	$t6, yVel		# actualiza yVel=-1 en memoria
	jal	updateShark
	jal 	updateSharkHeadPosition
	
	j	exitMoving 	

moveDown:
	lw	$s3, sharkDown		# s3 = color del shark cuando baja
	add	$a0, $s3, $zero		
	li	$t5, 0			
	li	$t6, 1 		
	sw	$t5, xVel		# actualiza xVel=0 en memoria
	sw	$t6, yVel		# actualiza yVel=1 en memoria
	jal	updateShark
	jal 	updateSharkHeadPosition
	
	j	exitMoving 
	
moveRight:
	lw	$s3, sharkRight		# s3 = color del shark cuando va a la derecha
	add	$a0, $s3, $zero		
	li	$t5, 1			
	li	$t6, 0 		
	sw	$t5, xVel		# actualiza xVel=1 en memoria
	sw	$t6, yVel		# actualiza yVel=0 en memoria
	jal	updateShark
	jal 	updateSharkHeadPosition
	
	j	exitMoving 

moveLeft:
	lw	$s3, sharkLeft		# s3 = color del shark cuando va a la izquierda
	add	$a0, $s3, $zero		
	li	$t5, -1			
	li	$t6, 0 			
	sw	$t5, xVel		# actualiza xVel=-1 en memoria
	sw	$t6, yVel		# actualiza yVel=0 en memoria
	jal	updateShark
	jal 	updateSharkHeadPosition
	j	exitMoving 
	
	
# Esta función pinta el head del Shark, con el color que se envió como argumento.
# Primero verifica si la nueva posición no coincide con la posición del plastico. 
# Si es positivo pinta en un nueva dirección el plastico, actualiza el score y regresa al lazo de repetición.
# Caso contrario, verifica que la posición que acaba de pintar no pertenece a la dirección del borde o del propio cuerpo del Sharck.
# Si lo anterior se cumple, se acaba el juego.
# Si no, se procede a eliminar la cola (pinta de nuevo la interfaz de color azul), actualiza la nueva posición de la cola y regresa al lazo de repetición.

	
updateShark:
	addiu 	$sp, $sp, -24		# Reserva 24 bytes en la pila
	sw 	$fp, 0($sp)		# guarda el frame pointer
	sw 	$ra, 4($sp)		# guarda la dirección de return
	addiu 	$fp, $sp, 20		# se configura el puntero del marco updateShark	
	
	### Pintar el head
	lw	$t0, xPos		# t0 = Posición de la columna del Shark
	lw	$t1, yPos		# t1 = Posición de la fila del shark
	lw	$t2, xConversion	# t2 = 4
	lw	$t3, yConversion	# t3 = 128
	mult	$t1, $t3		
	mflo	$t3			# Como en cada fila hay 128 bytes, t3 = yPos*128
	mult	$t0, $t2
	mflo	$t2			# En cada columna hay 4 bytes, t2 = xPos*4
	add	$t0, $t3, $t2		
	la 	$t1, frameBuffer	
	add	$t0, $t1, $t0		# Obtiene la dirección correcta del Shark (t0 =  frameBuffer + (yPos * 128 + xPos * 4))
	lw	$t4, 0($t0)		# t4 = valor del color inicial que tenía antes de pintarlo
	sw	$a0, 0($t0)		# Pinta la dirección con el argumento pasado
	
	### Chequea si comió plastico
	li 	$t2, 0x00ff0000		# Carga color rojo
	bne	$t2, $t4, headNotPlastic	# Si no comió plastico, salta a verificar si sigue en una posición correcta
	
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

	li	$t2, 0xFF003366			# Carga el color de la interfaz azul
	beq	$t2, $t4, validHeadSquare	# Si el color antes de pintar era azul, salta a actualizar el tail
	
	addi 	$v0, $zero, 10			# Detiene el programa
	syscall
	
validHeadSquare:

	### Eliminamos el valor actual de la cola
	lw	$t0, tail			# t0 = cola
	la 	$t1, frameBuffer		
	add	$t2, $t0, $t1			# t2 = dirección de la cola en el bitMap
	li 	$t3, 0xFF003366			# Color azul
	lw	$t4, 0($t2)			# Guarda el color que tuvo antes de pintar de azul
	sw	$t3, 0($t2)			# Pinta de azul
	
	### Actualizacion de la cola
	lw	$t5, sharkUp			# Carga el color de shark cuando sube
	beq	$t5, $t4, setNextTailUp		# Si el shark subió, salta para actualizar la cola hacia arriba
	
	lw	$t5, sharkDown			# Carga el color de shark cuando baja
	beq	$t5, $t4, setNextTailDown	# Si el shark bajó, salta para actualizar la cola hacia abajo
	
	lw	$t5, sharkLeft			# Carga el color de shark cuando va a la izquierda
	beq	$t5, $t4, setNextTailLeft	# Si el shark fue a la izquiera, salta para actualizar la cola hacia la izquierda
	
	lw	$t5, sharkRight			# Carga el color de shark cuando va a la derecha
	beq	$t5, $t4, setNextTailRight	# Si el shark fue a la derecha, salta para actualizar la cola hacia la derecha
	

setNextTailUp:
	addi	$t0, $t0, -128			# Como la cola sube, debe retroceder 128 bytes
	sw	$t0, tail			# actualiza la cola en memoria
	j exitUpdateShark
	
setNextTailDown:
	addi	$t0, $t0, 128			# Como la cola baja, debe aumentar 128 bytes
	sw	$t0, tail			
	j exitUpdateShark
	
setNextTailLeft:
	addi	$t0, $t0, -4			# Como la cola va a la izquierda, se retrocede solo 4 bytes
	sw	$t0, tail		
	j exitUpdateShark
	
setNextTailRight:
	addi	$t0, $t0, 4			# Como la cola va a la derecha, se aumenta 4 bytes
	sw	$t0, tail		
	j exitUpdateShark
	

exitUpdateShark:
	
	lw 	$ra, 4($sp)	# carga la dirección de return
	lw 	$fp, 0($sp)	# carga el frame pointer
	addiu 	$sp, $sp, 24	# restaura la pila
	jr 	$ra		
	
	
updateSharkHeadPosition:
	addiu 	$sp, $sp, -24	# reserva 24 bytes en la pila
	sw 	$fp, 0($sp)	# guarda el frame pointer
	sw 	$ra, 4($sp)	# guarda la dirección de return
	addiu 	$fp, $sp, 20	# se configura el puntero del marco updateShark	
	
	lw	$t3, xVel	# carga xVel de memoria
	lw	$t4, yVel	# carga yVel de memoria
	lw	$t5, xPos	# carga xPos de memoria
	lw	$t6, yPos	# carga yPos de memoria
	add	$t5, $t5, $t3	# actualiza la posición de x en base al valor de xVel
	add	$t6, $t6, $t4	# actualiza la posición de y en base al valor de yVel
	sw	$t5, xPos	# guarda el nuevo valor xpos a memoria
	sw	$t6, yPos	# guarda el nuevo valor ypos a memoria
	
	lw 	$ra, 4($sp)	# carga la dirección de return
	lw 	$fp, 0($sp)	# carga el frame pointer
	addiu 	$sp, $sp, 24	# restaura la pila
	jr 	$ra		
	
exitMoving:
	j 	gameUpdateLoop		# loop back to beginning

# Esta función pinta el plastico en la dirección

drawPlastic:
	addiu 	$sp, $sp, -24	
	sw 	$fp, 0($sp)	
	sw 	$ra, 4($sp)	
	addiu 	$fp, $sp, 20	
	
	lw	$t0, plasticX		# t0 = xPos del plastico
	lw	$t1, plasticY		# t1 = yPos del plastico
	lw	$t2, yConversion	
	lw	$t3, xConversion	
	mult	$t1, $t2		
	mflo	$t4			# t4 = plasticY * 128
	mult	$t0, $t3			
	mflo	$t5 			# t5 = plasticX * 4
	add	$t0, $t4, $t5		
		
	la 	$t1, frameBuffer	
	add	$t0, $t1, $t0		
	li	$t4, 0x00ff0000
	sw	$t4, 0($t0)		# pinta del color del plastico en el bitMap
	
	lw 	$ra, 4($sp)	
	lw 	$fp, 0($sp)	
	addiu 	$sp, $sp, 24	
	jr 	$ra		

# Esta función nos permite obtener una nueva posición del plastico utilizando numeros aleatorios

newPlasticLocation:
	addiu 	$sp, $sp, -24	
	sw 	$fp, 0($sp)	
	sw 	$ra, 4($sp)	
	addiu 	$fp, $sp, 20	

redoRandom:		
	addi	$v0, $zero, 42	# syscall 42: número entero aleatorio
	addi	$a1, $zero, 31	# límite superior (inclusive) (son 32 columnas)
	syscall
	add	$t1, $zero, $a0	# PlasticX aleatorio
	
	addi	$v0, $zero, 42	
	addi	$a1, $zero, 31	# límite superior (inclusive) (son 32 filas)
	syscall
	add	$t2, $zero, $a0	# PlasticY aleatorio
	
	lw	$t3, yConversion	
	mult	$t2, $t3		
	mflo	$t4			# t4 = PlasticY * 128
	lw 	$t3, xConversion
	mult	$t3, $t1
	mflo	$t5			# t5 = PlasticX * 4
	add	$t4, $t4, $t5		# t4 =PlasticY * 64 + PlasticX *4
	
	la 	$t0, frameBuffer	
	add	$t0, $t4, $t0		
	lw	$t5, 0($t0)		# guarda el color anterior antes de pintar
	
	li	$t6, 0xFF003366		# interfaz de color azul
	beq	$t5, $t6, goodPlastic	# si la nueva direccion del plastico coincide con el color azul, salta para actualizar la nueva posición
	j redoRandom			# Si no, vuelve a generar un nueva dirección

goodPlastic:
	sw	$t1, plasticX
	sw	$t2, plasticY	

	lw 	$ra, 4($sp)	
	lw 	$fp, 0($sp)	
	addiu 	$sp, $sp, 24	
	jr 	$ra		
