
.sect	.text

/******************************************************
 * Purpose: To update the paddle coordinates based on
 * user input
 * Pre: The user has provided some or no input.
 * Post: The paddle coordinates are change in the label
 * Param: r0 - buttons pressed
 * Return: None
 *
 *****************************************************/
.global updatePaddle	
updatePaddle:
	push	{r4-r6, lr}

	ldr	r4, =paddleImage		@ get the address of the paddle image
	ldr	r6, [r4]	
	ldr	r5, [r4, #16]			@ obtain the value for the velocity
	mvn	r0, r0				@ get the compliment of r0
	mov	r1, #0x40			@ for seeing if left was pressed
	mov	r2, #0x80			@ for seeing if right was pressed
	and	r1, r1, r0			@ extract the bit for left
	and	r2, r2, r0			@ extract the bit for right
	lsr	r1, #6				@ shift the bit for testing if on for left
	lsr	r2, #7				@ shift the bit for testing if on for right
	teq	r1, #1				@ see if bit is turned on
	beq	leftPressed			@ if left was pressed proceed
	teq	r2, #1				@ see if bit was turned on
	beq	rightPressed			@ if right was pressed proceed
	b	endUpdate			@ if neither were pressed, exit

leftPressed:
	mov	r1, #0x100			@ create mask for seeing if A was pressed
	and	r1, r1, r0			@ extract the bit
	lsr	r1, #8				@ shift A button bit over
	teq	r1, #1				@ check to see if A was pressed
	lsleq	r5, #1				@ multiply the velocity by 2 if A was pressed			
	sub	r6, r5				@ add the velocity value to the displacement
	b	testPaddleCollisions
	
rightPressed:
	mov	r1, #0x100			@ create mask for seeing if A was pressed
	and	r1, r1, r0			@ extract the bit
	lsr	r1, #8				@ shift A button bit over
	teq	r1, #1				@ check to see if A was pressed
	lsleq	r5, #1				@ multiply the velocity by 2 if A was pressed	
	add	r6, r5				@ add the velocity value to the displacement
	b	testPaddleCollisions		@ go to the end if done
	
	@ test collisions
testPaddleCollisions:
	@ r4 has paddle image, r6 has the new offset
	@ get screen dimensions
	ldr	r5, =gameBackground		@ get the address of the game background
	ldr	r5, [r5]			@ get the width of the board
	lsr	r5, #1				@ divide the board to get half the width
	rsb	r1, r5, #0			@ get the negative value of the board
	add	r1, #32				@ left boarder threshold 
	add	r5, #-32			@ right boarder threshold
	add	r2, r6, #-48			@ get the left side of the paddle (from current position)
	add	r3, r6, #48			@ get the right side of the paddle (from current position)
	
	@ test thresholds
	cmp	r2, r1				@ see if the paddle is touching the left boarder
	ble	endUpdate			@ if there is a collision, exit instead of updating	
	cmp	r3, r5				@ see if the paddle is touching the right boarder
	bge	endUpdate			@ if there is a collision, exit with no update
 	@ if their are no collisions, update the displacement
	str	r6, [r4]			@ load the new displacement back into the paddle image

endUpdate:
	
	pop	{r4-r6, lr}
	bx	lr
	
/*****************************************************
 * Purpose: to update x and y coordinates of ball 
 * based on current direction
 * Pre: The game is in action
 * Post: The ball coordinates are update in the label
 * Param: None
 * Return: None
 *
 *****************************************************/
.global	updateBall
updateBall:
	push	{r4-r6, lr}

	ldr 	r0, =ballImage			@ load address of ball image

	ldr 	r2, [r0]			@ get x of ball
	ldr 	r3, [r0, #4]			@ get y of ball
	ldr 	r4, [r0, #12]			@ get velocity
	ldr 	r5, [r0, #16]			@ get direction

	@ test bit 0 of direction
	mov 	r6, #1				@ bitmask for bit 0
	tst	r5, r6				@ compare bits
	subeq 	r0, r2, r4			@ bit 0 = 0: left (subtract velocity from x)
	addne	r0, r2, r4			@ bit 0 = 1: right (add velocity to x)

	@ test bit 1 of direction
	lsl	r6, #1				@ move bitmask over to bit 1
	tst	r5, r6				@ compare bits
	subeq	r1, r3, r4			@ bit 1 = 0: up (subtract velocity from y)
	addne 	r1, r3, r4			@ bit 1 = 1: down (add velocity to y)
	
	bl	testBallCollisions		@ check if this update will cause a collision

	ldr	r3, =ballImage			@ load address of ball image
	str 	r0, [r3]			@ set adjusted x value in ball
	str 	r1, [r3, #4]			@ set adjusted y value in ball
	str	r2, [r3, #16]			@ set adjusted direction in ball

	cmp	r1, #408			@ check if ball y is past lower y bound of paddle
	blt	ub_done

ub_outofBounds:
	ldr	r3, =oobFlag			@ if it is, load address of out of bounds flag
	mov	r0, #1				@ set it to 1
	str	r0, [r3]			@ and store updated value of flag

	ldr	r3, =lives			@ load address of lives number
	ldr	r0, [r3]			@ load number of lives

	cmp	r0, #0				@ check if player is out of lives
	ldreq	r2, =lossFlag			@ if player's lives are 0, load address of game loss flag
	moveq	r1, #1				@ set it to 1
	streq	r1, [r2]			@ and store updated value of flag
	beq	ub_done				@ then continue
	
	sub	r0, #1				@ otherwise subtract one from number of lives
	str	r0, [r3]			@ and store updated number of lives

	bl	clearLives

ub_done:
	pop	{r4-r6, lr}
	bx	lr

/**********************************************************
 * Purpose: to check if the ball's potential 
 * x and y values will cause collisions with 
 * other game objects
 * Pre: The game is in action
 * Post: The ball is determined to have collided with an 
 * object or not
 * Param: r0 - x
 * r1 - y
 * Return: r0 = x, r1 = y, r2 = updated direction
 *
 **********************************************************/
testBallCollisions:
	push	{r4-r10, lr}

	x	.req	r4
	y	.req	r5
	dia	.req	r6
	vel	.req	r7
	dir	.req	r8
	temp	.req	r9
	edge	.req	r10

	mov	x, r0				@ store potential x value
	mov	y, r1				@ store potential y value
	
	ldr	r0, =ballImage			@ load address of ball image
	ldr	dia, [r0, #8]			@ get diameter
	ldr	vel, [r0, #12]			@ get velocity
	ldr	dir, [r0, #16]			@ get direction

	ldr	r0, =gameBackground		@ load address of game background
	ldr	temp, [r0]			@ get background width
	lsr	temp, #1			@ cut in half
	rsb	r2, temp, #0			@ get the negative value of the board
	add	r2, #40				@ left border threshold 
	add	r1, temp, #-40			@ right border threshold

	cmp	x, r1				@ test x against right border
	movgt	x, r1				@ if x is past right border push it back
	bicgt	dir, dir, #1			@ and start moving left

	cmp	x, r2				@ test x against left border
	movlt	x, r2				@ if x is past left border push it back
	orrlt	dir, dir, #1			@ and start moving right

	ldr	temp, [r0, #4]			@ get background height
	lsr	temp, #1			@ cut in half
	rsb	r1, temp, #0			@ get the negative value of the board
	add	r1, #88				@ find top border threshold	

	cmp	y, r1				@ test y against top border
	movlt	y, r1				@ if y is past top border push it back
	orrlt	dir, dir, #2			@ and start moving down

	mov	r1, #-136			@ boundary of green brick row
	tst	dir, #2				@ check if ball is hitting bricks from top/bottom
	subne	r1, #16				@ subtract ball diameter if hitting from top
	cmp	y, r1				@ test y against green row boundary
	blt	tbc_checkGreenBricks		@ if y is past green row boundary check brick presence

	ldr	r0, =paddleImage		@ load address of paddle image
	ldr	temp, [r0]			@ get x of paddle
	sub	r1, temp, #48			@ find left edge of paddle
	add	r2, temp, #48			@ find right edge of paddle

	cmp	x, r1				@ test lower bound of ball x value
	moveq	edge, r1			@ if ball is touching left edge store its x

	bgt	tbc_checkRange			@ if ball is past left edge check x range
	beq	tbc_checkEdge			@ if ball is on left edge check y range
	blt	tbc_done			@ if ball is behind left edge continue

tbc_checkRange:
	cmp	x, r2				@ test upper bound of ball x value
	moveq	edge, r2			@ if ball is touching right edge store its x

	blt	tbc_inRange			@ if ball is behind right edge check y range
	beq	tbc_checkEdge			@ if ball is on right edge check y range
	bgt	tbc_done			@ if ball is past right edge continue

tbc_inRange:
	mov	r1, #360

	cmp	y, r1				@ compare y to paddle height
	movgt	y, r1				@ if y is past top of paddle push it back
	bicgt	dir, dir, #2			@ and start moving back up

	b	tbc_done			@ continue

tbc_checkEdge:
	mov	r1, #368			@ load test value for y for lower bound
	mov	r2, #400			@ load test value for y for upper bound

	cmp	y, r1				@ test lower bound of ball y value
	bge	tbc_checkEdgeRange		@ if y is past lower bound check y range
	blt	tbc_done			@ if ball is behind lower bound continue

tbc_checkEdgeRange:
	cmp	y, r2				@ test upper bound of ball y value
	ble	tbc_onEdge			@ if y is behind upper bound change direction
	bgt	tbc_done			@ ***if y is past lower bound you've lost***

tbc_onEdge:
	mov	x, edge				@ move the value stored in edge into x
	eor	dir, dir, #1			@ switch horizontal direction
	bic	dir, dir, #2			@ start moving back up

	b	tbc_done			@ continue

tbc_checkGreenBricks:
	mov	r1, #-168			@ boundary of yellow brick row
	tst	dir, #2				@ check if ball is hitting bricks from top/bottom
	subne	r1, #16				@ subtract ball diameter if hitting from top
	cmp	y, r1				@ test y against row boundary
	blt	tbc_checkYellowBricks		@ if y is past yellow row boundary check brick presence

	add	temp, x, #408			@ normalize x of ball
	lsr	temp, #6			@ divide by 64 to get specific brick in row
	add	temp, #21			@ add 21 to get offset in bricksList
	ldr	r0, =bricksList			@ load address of bricksList
	ldr	r1, [r0, temp, LSL #2]		@ load status of concerned brick

	cmp	r1, #0				@ check if brick exists
	bgt	tbc_onBrick			@ if brick exists update it
	beq	tbc_done			@ otherwise continue

tbc_checkYellowBricks:
	mov	r1, #-200			@ boundary of red brick row
	tst	dir, #2				@ check if ball is hitting bricks from top/bottom
	subne	r1, #16				@ subtract ball diameter if hitting from top
	cmp	y, r1				@ test y against row boundary
	ble	tbc_checkRedBricks		@ if y is past red row boundary check brick presence

	add	temp, x, #408			@ normalize x of ball
	lsr	temp, #6			@ divide by 64 to get specific brick in row
	add	temp, #10			@ add 10 to get offset in bricksList
	ldr	r0, =bricksList			@ load address of bricksList
	ldr	r1, [r0, temp, LSL #2]		@ load status of concerned brick

	cmp	r1, #0				@ check if brick exists
	bgt	tbc_onBrick			@ if brick exists update it
	beq	tbc_done			@ otherwise continue

tbc_checkRedBricks:
	mov	r1, #-232			@ boundary past bricks
	tst	dir, #2				@ check if ball is hitting bricks from top/bottom
	subne	r1, #16				@ subtract ball diameter if hitting from top
	cmp	y, r1				@ test y against boundary
	blt	tbc_done			@ if y is past brick boundary continue

	add	temp, x, #408			@ normalize x of ball
	lsr	temp, #6			@ divide by 64 to get specific brick in row
	sub	temp, #1			@ subtract 1 to get offset in bricksList
	ldr	r0, =bricksList			@ load address of bricksList
	ldr	r1, [r0, temp, LSL #2]		@ load status of concerned brick

	cmp	r1, #0				@ check if brick exists
	beq	tbc_done			@ if not continue

tbc_onBrick:
	sub	r1, #1				@ subtract 1 from brick status
	str	r1, [r0, temp, LSL #2]		@ store updated brick status

	tst	dir, #2				@ check if ball hit bricks from top or bottom
	subne	y, vel				@ if ball hit from top subtract velocity from x
	addeq	y, vel				@ if ball hit from bottom add velocity to x
	eor	dir, dir, #2			@ swap vertical direction
	
	ldr	r0, =score			@ load address of score
	ldr	r2, [r0]			@ load score
	mov	r3, #50				@ r3 = 50
	add	r2, r3, LSL r1			@ add 50 * 2^(updated brick status) to score
	str	r2, [r0]			@ store updated score

	bl	clearScore			@ clear the score board
	bl	printScore			@ print the new score
	bl	printBricks			@ reprint the bricks

	bl	checkRemainingBricks		@ check if any bricks still remain
	cmp	r0, #0				@ compare result to 0
	bgt	tbc_done			@ if result > 0, continue
	ldr	r0, =winFlag			@ load address of win flag
	mov	r1, #1				@ set win flag to 1
	str	r1, [r0]			@ store updated value of win flag

tbc_done:	
	mov	r0, x				@ copy x value in r0 for return value
	mov 	r1, y				@ copy y value in r1 for return value
	mov	r2, dir				@ copy the ball's updated direction in r2 for return value

	.unreq	x
	.unreq	y
	.unreq	dia
	.unreq	vel
	.unreq	dir
	.unreq	temp
	.unreq	edge
	pop	{r4-r10, lr}
	bx	lr

/******************************************************
 * Purpose: to check if there are any bricks left on 
 * the screen
 * Pre: The game is in action
 * Post: A value is returned to indicate yes or no
 * Param: None
 * Return: r0 = flag (0: none left, 1: some left)
 *
 ******************************************************/
checkRemainingBricks:
	push	{lr}

	mov	r0, #0				@ assume there are no bricks remaining
	ldr	r1, =bricksList			@ load address of brick list
	mov	r2, #0				@ start at brick 0

cbr_loop:
	cmp	r2, #33				@ compare brick index to 33
	bge	cbr_done			@ if brick index >= 33, break

	ldr	r3, [r1, r2, LSL #2]		@ load current brick
	cmp	r3, #1				@ check if current brick exists
	bge	cbr_someleft			@ if current brick exists, set flag

	add	r2, #1				@ increment index
	b	cbr_loop			@ continue loop 

cbr_someleft:
	mov	r0, #1				@ set flag to 1

cbr_done:
	pop	{lr}
	bx	lr

/***************************** END OF FILE ***************************/

