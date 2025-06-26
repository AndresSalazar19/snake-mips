# Author: Andrés Salazar y Yadira Suarez

###############################################################
### 		Configuración del juego		    	    ###	
###							    ###
###	Ancho del pixel: 8 			    	    ###
###	Alto del pixel: 1				    ###
###	Ancho total del juego: 512			    ###
###	Alto total del juego: 512 			    ###
###	base de posicion del juego 0x10010000 (static data) ###
###							    ###	
###############################################################

.data

frameBuffer: 	.space 	0x80000		#512 de ancho y 512 de alto y 16
xVel:		.word	0		
yVel:		.word	0		
xPos:		.word	50		
yPos:		.word	27		
appleX:		.word	32		# posicion x de la comida 
appleY:		.word	16		
snakeDown:	.word	0x10ff00	
snakeLeft:	.word	0x20ff00	
snakeRight:	.word	0x30ff00	
xConversion:	.word	64		
yConversion:	.word	4		

     
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
	li	$t1, 2000		#tail
	li 	$t2, 0x288a3a	

	add 	$t3, $t1, $t0
	sw	$t2, 0($t3)			
	addi	$t1, $t3, -128		# pintar el pixel  encima
	sw	$t2, 0($t1)		
	
	### draw initial apple
		