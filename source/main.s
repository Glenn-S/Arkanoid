/*****************************************************
 * CPSC 359 Assignment 2, Arkanoid
 * Creators:
 * Dominic Demierre, Maha Asim, 
 * Jessica Pelley, Glenn Skelton
 *
 * Due June 14, 2018
 *
 *****************************************************/

.sect	.data

.align
.globl	frameBufferInfo
frameBufferInfo:
	.int	0				@ frame buffer pointer
	.int	0				@ screen width
	.int	0				@ screen hight

.global	GpioPtr
GpioPtr:
	.int	0				@ pointer to the address of the GPIO base register

.global winFlag
winFlag:
	.int	0				@ flag for checking if the game has been won

.global lossFlag
lossFlag:
	.int	0				@ flag for checking if the game has been lost

.global	oobFlag
oobFlag:
	.int	0				@flag for checking if ball is out of bounds

.global score
score:	.int 0					@ total score for the game play

.global lives
lives:	.int 0					@ total number of lives for the game

.global bricksList
bricksList:					@ brick difficulty and existance array for printing (or not printing) a brick 
	.int	3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

.global brickStart
brickStart:
	.int	33				@ x location from the left side of the board
	.int	224				@ y location from the right side of the board

.global purple
purple:
	.int	0x3B0275			@ colour value for the background

.global clear
clear:
	.int	768				@ width of the screen to print
	.int	896				@ height of the screen to print
	.int	0				@ load the background to be black 


/*------------------------- CODE ------------------------*/
.sect	.text
.global	main

/**********************************************************
 * Purpose: To run the main game loop of the game Arkanoid.
 * To win the game, all of the bricks must be broken. If 
 * the player loses all of their lives, they lose the game.
 * Param: None
 * Return: None
 *
 **********************************************************/

main:
	bl	setup				@ set up all buffers for the game proccesses

	mov	r1, #0				@ load test value for win flag 
	ldr	r0, =winFlag			@ load the address of the win flag to store
	str	r1, [r0]			@ reset win flag
	ldr	r0, =lossFlag			@ load the address for the loss flag
	str	r1, [r0]			@ reset loss flag

	mov	r1, #3				@ load the value in for the lives to start
	ldr	r0, =lives			@ load the address for lives
	str	r1, [r0]			@ reset number of lives

	@ get user input to determine mode
	bl 	mainMenu			@ get user input for starting or quiting the game
	@ will only go on if select is pressed else it will terminate, r0 will have 0 or 1 

	cmp	r0, #0				@ if the function mainMenu returned 0, terminate the program
	beq	end				@ exit the program, will need to write a blank screen
	bne	startGame			@ if function returned 1, go on to the game loop
	
startGame:
	ldr	r5, =gameBackground
	mov	r2, r5				@ prepare the background image for function call
	bl	printBacking			@ print the background image
	bl	printLives			@ print the total number of lives to start
	bl	printScore			@ print the total score to start (should be 0000)
	bl	drawPaddle			@ draw the paddle on the scren
	bl	drawBall			@ draw the ball on the screen
	bl	printBricks			@ print the brick array
	
wait:
	bl	Read_SNES			@ get the input from the SNES paddle
	ldr	r1, =0xFFFE			@ load the test value for testing the button register for B being pressed
	teq	r0, r1				@ test to see if the B button has been pressed to start
	beq	gameLoop			@ if the B button was pressed, start the game
	bne	wait				@ while the input is not B, keep waiting

gameLoop:
	bl	Read_SNES			@ get the input from the SNES paddle	
	mov	r4, r0				@ save the button register values in r4 for later use

	@ start button
	mvn	r1, r0				@ get the compliment of r0
	mov	r2, #0x8			@ for seeing if start was pressed
	and	r2, r2, r1			@ extract the bit for start
	lsr	r2, #3				@ shift the bit for testing if on for start
	teq	r2, #1				@ see if bit is turned on
	bne	start_cont			@ if start is not pressed, continue
	bl	resetGame			@ if start was pressed, reset the game parameters
	bl	startGame			@ go back to the start of the game

start_cont:
	@select button
	mvn	r1, r0				@ get the compliment of r0
	mov	r2, #0x4			@ for seeing if select was pressed
	and	r2, r2, r1			@ extract the bit for select
	lsr	r2, #2				@ shift the bit for testing if on for select
	teq	r2, #1				@ see if bit is turned on
	bne	sel_cont			@ if select is not pressed, continue
	bl	resetGame			@ if start was pressed, reset the game parameters
	b	main				@ if select was pressed, go back to the main menu

sel_cont:
	@ clear, update the images
	@ldr	r0, =paddleImage		@ load the paddle image for printing the clear paddle
	bl	clearPaddle			@ clear the paddle image
	@ldr	r0, =ballImage			@ load the address for the ball image
	bl	clearBall			@ clear the ball image 
	mov	r0, r4				@ move the button register values into r0 for function call
	bl	updatePaddle			@ update the paddles x coordinates based on the paddle register
	bl	updateBall			@ update the ball coordinates based on its interactions

	@ check the state of the game for wins and losses
	ldr	r1, =winFlag			@ load address of win flag
	ldr	r1, [r1]			@ get the win flag for checking
	cmp	r1, #1				@ see if the win flag was set
	bleq	gameOver			@ if so go to game over

	ldr	r1, =lossFlag			@ load address of loss flag
	ldr	r1, [r1]			@ get the loss flag for checking
	cmp	r1, #1				@ check to see if the flag was set
	bleq	gameOver			@ if so go to game over

	cmp	r0, #1				@ check to make sure gameOver was valid
	bne	go_cont				@ if not valid, continue on through the regular game loop
	bl	resetGame			@ if game is over, reset the game parameters (paddle, ball, bricks)
	b	main				@ if so go back to the main screen

go_cont:
	ldr	r0, =oobFlag			@ load address of out of bounds flag
	ldr	r0, [r0]			@ load out of bounds flag
	cmp	r0, #1				@ check if player went out of bounds
	bne	oob_cont			@ if player is not out of bounds, continue
	bl	refreshGame			@ if player went out of bounds then reset game state
	bl	startGame			@ and reset gameplay

oob_cont:	
	@ redraw the paddle and ball
	mov	r2, r5				@ move the game background address into r2 
	bl	drawPaddle			@ draw the paddle
	bl	drawBall			@ draw the ball

	@ delay frames
	mov	r0, #5000			@ delay for 5 miliseconds		
	lsl 	r0, #1				@ multiply by two to get it to 10 milisecond delay
	bl	delayMicroseconds		@ frame rate delay
		
	b	gameLoop			@ continue back through the game loop for regular game play

end:
	ldr	r2, =clear			@ call the label with the clear screen parameters
	bl	clearBacking			@ print the background image
	bl	exit				@ terminate the program

/*---------------------- FUNCTIONS --------------------*/

/******************************************************
 * Purpose: Setup GPIO register, pins and framebuffer
 * Pre: There is a label storing the frameBuffer .
 * Post: The address for the frame buffer is loaded.
 * Param: None
 * Return: None
 *
 ******************************************************/
setup:
	push	{lr}

	ldr	r0, =frameBufferInfo		@ load the frame buffer address for initializing
	bl	initFbInfo			@ initialize the frame buffer

	ldr	r0, =GpioPtr			@ get address of pointer to initialize
	bl	initGpioPtr			@ set up base address

	mov	r0, #1				@ set for output in r1
	mov	r1, #9				@ pin 9 in r1 (Latch)
	bl	init_GPIO			@ set pin 9 to output

	mov	r0, #1				@ set for output in r1
	mov	r1, #11				@ pin 11 in r1 (Clock)
	bl	init_GPIO			@ set pin 11 to output

	mov	r0, #0				@ set for input in r1
	mov	r1, #10				@ pin 10 in r1 (Data)
	bl	init_GPIO			@ set pin 10 to input

	pop	{lr}
	bx	lr

/********************************************************
 * Purpose: To run the main menu loop for starting or
 * quiting the game
 * Pre: The game has been instansiated
 * Post: The game will either start or quit depending on
 * the user input
 * Param: None
 * Return: 0 if the user selects quit or 1 if they select
 * start.
 ********************************************************/
mainMenu:	
	push	{r4-r6, lr}
	
	mov	r5, #0				@ defualt 0 for start screen and 1 for quit selection
	mov	r6, #0				@ assume player not already holding a button

	@ start with the start button selected
	ldr	r2, =splashStart		@ load the splash start screen
	bl	printBacking			@ print the screen image

	mov	r1, #0xFFFF			@ mask to check if player is already holding a button
	teq	r0, r1				@ test to see if player is already holding a button
	movne	r6, #1				@ set flag to indicate button still being held

readInLoop:
	bl	Read_SNES			@ get the input from the SNES paddle
	mov	r1, #0xFFFF			@ mask to check if a button was pushed or not
	teq	r0, r1				@ test to see if a button was pushed
	moveq	r6, #0				@ if no button being pushed reset flag
	beq	readInLoop			@ then go back and wait until it one is pushed

	teq	r6, #1				@ check if player is already holding a button
	beq	readInLoop			@ if player is already holding a button ignore input
	
btnPressed:
	@ r0 contains the buttons pressed
	mov	r4, r0				@ store the button values in r4	for any function calls

	mvn	r0, r0				@ get the compliment of r0
	mov	r1, #0x10			@ for seeing if up was pressed
	mov	r2, #0x20			@ for seeing if down was pressed
	mov	r3, #0x100			@ value to see if A was pressed
	and	r1, r1, r0			@ extract the bit for up
	and	r2, r2, r0			@ extract the bit for down
	and	r3, r3, r0			@ extract the bit for down
	lsr	r1, #4				@ shift the bit for testing if on for up
	lsr	r2, #5				@ shift the bit for testing if on for down
	lsr	r3, #8				@ shift the bit for testing if on for A
	
	@ test if A was pressed first to see if it should go on
	teq	r3, #1				@ see if bit is turned on
	beq	aPressed			@ got to A pressed label if true to determine what mode to execute 
	teq	r2, #1				@ see if bit is turned on for DOWN
	beq	checkScreenFlag			@ if so determine which screen to change
 	teq	r1, #1				@ see if bit is turned on for UP
	beq	checkScreenFlag			@ if so determine which screen to change
	b	readOutLoop			@ if nothing valid was pressed, continue to read

checkScreenFlag:
	cmp	r5, #0				@ test to see what the flag bit is set to 
	beq	quitScreen			@ if flag is set to 0, got to quitScreen to change to quit screen image
	bne	startScreen			@ if flag is set to 1, got to startScreen to change to start screen image
	b	readOutLoop			@ error so exit

startScreen:
	teq	r2, #1				@ make sure that up wasn't pressed
	beq	readOutLoop			@ if so, continue back to reading input
	ldr	r2, =splashStart		@ get the start screen address
	bl	printBacking			@ print the start screen
	mov	r5, #0				@ change flag to 0 to signify that start screen is now enabled
	b	readOutLoop

quitScreen:
	teq	r1, #1				@ make sure that down wasn't pressed
	beq	readOutLoop			@ if so, continue back to reading input
	ldr	r2, =splashQuit			@ get the exit screen address
	bl	printBacking			@ print the exit screen
	mov	r5, #1				@ change flag to 1 to signify that quit screen is now enabled
	b	readOutLoop

aPressed:
	cmp	r5, #0				@ see which screen we are currently on
	moveq	r0, #1				@ if start was selected, return value of 1 to start game
	movne	r0, #0				@ if quit was selected, return 0 to terminate the game
	b	endMainLoop			@ terminate main menu loop	

readOutLoop:
	@ delay to eliminate any accidental multiple prints from odd elecetrical connection
	mov	r0, #5000			@ value to delay, multiplied by 2
	lsl 	r0, #1				@ delay is 10 miliseconds
	bl	delayMicroseconds		@ delay for 10 miliseconds

	bl	Read_SNES			@ get the input from the SNES paddle
	mov	r1, #0xFFFF			@ mask to check if a button was released
	cmp	r0, r1				@ test to see if a button was pushed	
	bne	readOutLoop			@ if not go back and wait until it one is pushed
	b	readInLoop			@ loop back to get input
	
endMainLoop:
	pop	{r4-r6, lr}
	bx	lr

/******************************************************
 * Purpose: To reset the ball and paddle and brick
 * positions.
 * Pre: The game has been started
 * Post: The ball variables will be reset in the label
 * Param: None
 * Return: None
 *
 ******************************************************/
resetGame:
	push	{lr}
	
	@ reset the paddle:
	ldr	r0, =paddleImage		@ load the paddle image address to edit values
	mov	r1, #0				@ move 0 into r1 for reseting the x coordinates
	str	r1, [r0]			@ save 0 into the x value
	mov	r1, #368			@ move 368 into r1 for reseting the y coordinates
	str	r1, [r0, #4]			@ save 368 into the y value
	
	@ reset the ball:
	ldr	r0, =ballImage			@ load the ball image address to edit values
	mov	r1, #0				@ move 0 into r1 for reseting the x coordinate
	str	r1, [r0]			@ save 0 into the x value
	mov	r1, #364			@ move 364 into r1 for reseting the y coordinate 
	str	r1, [r0, #4]			@ save 364 into the y value
	mov	r1, #16				@ move 16 into r1 for reseting the diameter
	str	r1, [r0, #8]			@ save 16 into the diameter
	mov	r1, #4				@ move 8 into r1 for reseting the velocity
	str	r1, [r0, #12]			@ save 8 into the velocity
	mov	r1, #0				@ move 0 into r1 for reseting the direction
	str	r1, [r0, #16]			@ save 0 into the direction

	ldr	r0, =score			@ load score address
	mov	r1, #0				@ reset score to 0
	str	r1, [r0]			@ store back into score

	ldr	r0, =lives			@ load lives address
	mov	r1, #3				@ reset the lives back to 3
	str	r1, [r0]			@ store back into lives

	ldr	r0, =oobFlag			@ load out of bounds flag address
	mov	r1, #0				@ reset flag to 0
	str	r1, [r0]			@ store back into flag

	bl	resetBricks			@ reset all bricks
	
	pop	{lr}
	bx	lr

/******************************************************
 * Purpose: To reset the ball and paddle positions
 * Pre: The game has been started
 * Post: Only the paddle and ball will be reset so that
 * the user can continue game play
 * Param: None
 * Return: None
 *
 ******************************************************/
refreshGame:
	push	{lr}
	
	@ reset the paddle:
	ldr	r0, =paddleImage		@ load the paddle image address to edit values
	mov	r1, #0				@ move 0 into r1 for reseting the x coordinates
	str	r1, [r0]			@ save 0 into the x value
	mov	r1, #368			@ move 368 into r1 for reseting the y coordinates
	str	r1, [r0, #4]			@ save 368 into the y value
	
	@ reset the ball:
	ldr	r0, =ballImage			@ load the ball image address to edit values
	mov	r1, #0				@ move 0 into r1 for reseting the x coordinate
	str	r1, [r0]			@ save 0 into the x value
	mov	r1, #364			@ move 364 into r1 for reseting the y coordinate 
	str	r1, [r0, #4]			@ save 364 into the y value
	mov	r1, #16				@ move 16 into r1 for reseting the diameter
	str	r1, [r0, #8]			@ save 16 into the diameter
	mov	r1, #4				@ move 8 into r1 for reseting the velocity
	str	r1, [r0, #12]			@ save 8 into the velocity
	mov	r1, #0				@ move 0 into r1 for reseting the direction
	str	r1, [r0, #16]			@ save 0 into the direction

	ldr	r0, =oobFlag			@ load out of bounds flag address
	mov	r1, #0				@ reset flag to 0
	str	r1, [r0]			@ store back into flag

	pop	{lr}
	bx	lr



/*********************************************************
 * Purpose: To reset every individual brick
 * Pre: The bricks varaible exists
 * Post: The values in the brick variable will be returned
 * back to their starting state.
 * Param: None
 * Return: None
 *
 *********************************************************/
resetBricks:
	push	{lr}

	ldr	r0, =bricksList			@ load address of brick list

	mov	r1, #3				@ set row number to 0
	mov	r2, #0				@ set brick number to 0
	mov	r3, #0				@ set i to 0
	
rb_outerLoop:
	mov	r3, #0				@ reset i
	cmp	r1, #1				@ compare row number to 1
	blt	rb_done				@ if row number is less than 1, break

rb_innerLoop:
	str	r1, [r0, r2, LSL #2]		@ set current brick to row number
	add	r2, #1				@ increment brick number
	add	r3, #1				@ increment i
	
	cmp	r3, #11				@ compare i to 11
	blt	rb_innerLoop			@ if i < 11, continue inner loop

rb_outerBody:
	sub	r1, #1				@ decrement row number
	b	rb_outerLoop			@ continue outer loop

rb_done:
	pop	{lr}
	bx	lr

/******************************************************
 * Purpose: To end the game
 * Pre: A win or loss flag is set
 * Post: The user must select any button and will be 
 * brought back to the main menu.
 * Param: None
 * Return: 1 if the game is indeed over
 *
 ******************************************************/
gameOver:
	push	{lr}

	ldr	r0, =winFlag			@ get the game ending flag
	ldr	r0, [r0]
	cmp	r0, #1				@ see if game won is action
	bleq	drawWinLoss			@ call winLoss function with r0 = 1 for win game

	ldr	r0, =lossFlag			@ if win wasnt called, check and make sure loss was
	ldr	r0, [r0]
	cmp	r0, #1				@ check to validate that this is true
	moveq	r0, #0				@ if true, load the value for printing the loss game message
	bleq	drawWinLoss			@ call winLoss function with r0 = 0 for loss game

getInput:
	bl	Read_SNES			@ get the input from the SNES paddle
	ldr	r1, =0xFFFF	
	cmp	r0, r1				@ test to see if any button was pressed
	bne	endGameOverInput		@ exit function if a button was pressed
	beq	getInput			@ loop back if no input yet
	
endGameOverInput:
	mov	r0, #1				@ load 1 in r0 to signify the game is indeed over

	pop	{lr}
	bx	lr				

/************************* END OF FILE *****************************/

.end
