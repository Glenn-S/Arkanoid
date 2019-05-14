.sect	.data

/******************************************************
 * Purpose: To clear the paddle image by replacing it 
 * with the background image colour.
 * Post: The background will be overwritten with the 
 * new colour.
 * Param: None
 * Return: None
 *
 ******************************************************/
.global	clearPaddle
clearPaddle:
	push	{r4-r10, lr}
	
	sAddr	.req	r10
	colour	.req	r9
	x	.req	r5
	y	.req	r6
	outCnt	.req	r7
	inCnt	.req	r8
	temp	.req	r3
	offset	.req	r4

	ldr	sAddr, =paddleImage		@ get the paddle address
	mov	r3, sAddr			@ move the address into r3 for function call

	bl	getPaddleCoord			@ get the coordinates of where to draw the ball relative to the board
	@ return is in r0 - x, r1 - y	

	@ get paddle coordinate realtive to the screen
	add	colour, sAddr, #20 		@ address of first ascii
	mov	x, r0	@ store x		@ save the value of x returned from getCoord
	mov	y, r1	@ store y		@ save the value of y returned from getCoord

	mov	outCnt, #0 			@ height counter
clearPaddleOuterLoop:
	ldr	temp, [sAddr, #12]		@ get the height of the paddle
	cmp	outCnt, temp			@ compare counter with heigth
	bge	clearPaddlePrintDone		@ if the counter reaches the height, terminate

	mov	inCnt, #0 			@ counter
	mov	offset, #0			@ offset of x
clearPaddlePrintLoop:
	ldr	temp, [sAddr, #8]		@ get the width of the paddle
	cmp	inCnt, temp			@ compare counter with width
	bge	clearPaddleFinishRow		@ if the counter reaches the width, terminate
	
	@ call pixel draw
	add	r0, x, offset			@ x + offset
	mov	r1, y				@ get the y value
	ldr	r2, =0x3B0275			@ get value of ascii in colour
	bl	DrawPixel			@ draw the pixel in the (x,y) location	

	add	inCnt, #1			@ increment the loop counter by 1
	add 	offset, #1			@ increment offset by 1
	add	colour, #4			@ move to next pixel colour (each is a word)
	b	clearPaddlePrintLoop

clearPaddleFinishRow:
	add	outCnt, #1			@ increment counter
	ldr	temp, =frameBufferInfo		@ get address of frame buffer to get the width value
	ldr	temp, [temp, #4]		@ go to the byte containing the width
	add	x, temp				@ add width of screen 
	b	clearPaddleOuterLoop
	
clearPaddlePrintDone:	
	.unreq	sAddr
	.unreq	colour
	.unreq	x
	.unreq	y
	.unreq	outCnt
	.unreq	inCnt
	.unreq	temp
	.unreq	offset
	pop	{r4-r10, lr}
	bx	lr

/******************************************************
 * Purpose: To clear the ball image by replacing it 
 * with the background image colour.
 * Post: The background will be overwritten with the 
 * new colour.
 * Param: None
 * Return: None
 *
 ******************************************************/
.global	clearBall
clearBall:
	push	{r4-r10, lr}
	
	sAddr	.req	r10
	colour	.req	r9
	x	.req	r5
	y	.req	r6
	outCnt	.req	r7
	inCnt	.req	r8
	temp	.req	r3
	offset	.req	r4

	ldr	sAddr, =ballImage		@ get the ball address
	mov	r3, sAddr			@ move the address into r3 for function call

	bl	getBallCoord			@ get the coordinates of where to draw the ball relative to the board
	@ return is in r0 - x, r1 - y	

	@ get ball coordinate relative to the screen
	add	colour, sAddr, #20 		@ address of first ascii
	mov	x, r0	@ store x		@ save the value of x returned from getCoord
	mov	y, r1	@ store y		@ save the value of y returned from getCoord

	mov	outCnt, #0 			@ height counter

cb_OuterLoop:
	ldr	temp, [sAddr, #8]		@ get the diameter of the ball
	cmp	outCnt, temp			@ compare counter with height
	bge	cb_PrintDone			@ if the counter reaches the height, terminate

	mov	inCnt, #0 			@ counter
	mov	offset, #0			@ offset of x

cb_PrintLoop:
	ldr	temp, [sAddr, #8]		@ get the diameter of the ball
	cmp	inCnt, temp			@ compare counter with diameter
	bge	cb_FinishRow			@ if the counter reaches the width, terminate
	
	@ call pixel draw
	add	r0, x, offset			@ x + offset
	mov	r1, y				@ get the y value
	ldr	r2, =0x3B0275			@ get value of ascii in colour
	bl	DrawPixel

	add	inCnt, #1			@ increment the loop counter by 1
	add 	offset, #1			@ increment offset by 1
	add	colour, #4			@ move to next pixel colour (each is a word)
	b	cb_PrintLoop

cb_FinishRow:
	add	outCnt, #1			@ increment counter
	ldr	temp, =frameBufferInfo		@ get address of frame buffer to get the width value
	ldr	temp, [temp, #4]		@ go to the byte containing the width
	add	x, temp				@ add width of screen 
	b	cb_OuterLoop
	
cb_PrintDone:	
	.unreq	sAddr
	.unreq	colour
	.unreq	x
	.unreq	y
	.unreq	outCnt
	.unreq	inCnt
	.unreq	temp
	.unreq	offset
	pop	{r4-r10, lr}
	bx	lr

/*****************************************************
 * Purpose: To clear the score on the screen.
 * Post: The score will be overwritten
 * Param: None
 * Return: None
 *
 *****************************************************/

.global	clearScore
clearScore:
	push	{lr}

	mov	r0, #112			@ x and y set manually
	rsb	r0, r0, #0			@ x is negative
	mov	r1, #448
	rsb	r1, r1, #0			@ y is negative
	bl	clearSprite

	mov	r0, #80				@ x and y set manually
	rsb	r0, r0, #0			@ x is negative
	mov	r1, #448
	rsb	r1, r1, #0			@ y is negative
	bl	clearSprite

	mov	r0, #48				@ x and y set manually
	rsb	r0, r0, #0			@ x is negative
	mov	r1, #448
	rsb	r1, r1, #0			@ y is negative
	bl	clearSprite
	
	mov	r0, #16				@ x and y set manually
	rsb	r0, r0, #0			@ x is negative
	mov	r1, #448
	rsb	r1, r1, #0			@ y is negative
	bl	clearSprite

	pop	{lr}
	bx	lr

/*****************************************************
 * Purpose: To clear the lives on the screen
 * Post: The lives will be overwritten on the screen
 * Param: None
 * Return: None
 *
 *****************************************************/

.global	clearLives
clearLives:
	push {lr}

	mov	r0, #304			@ load x value for printing the sprite
	mov	r1, #448			@ load y value for printing the sprite
	rsb	r1, r1, #0			@ get the negative index for the x value
	bl	clearSprite			@ clear the lives

	pop	{lr}
	bx	lr

/****************************************************
 * Purpose: To clear a sprite
 * Pre: The game is in play
 * Post: The sprite will be overwritten on the screen
 * Param: r0 - x
 * r1 - y
 * r2 - sprite address
 * Return: None
 *
**************************************************/
.global clearSprite
clearSprite:
	push	{r4-r10, lr}
	
	sAddr	.req	r10
	colour	.req	r9
	x	.req	r5
	y	.req	r6
	outCnt	.req	r7
	inCnt	.req	r8
	temp	.req	r3
	offset	.req	r4

	ldr	sAddr, =sprite_refs
	ldr	sAddr, [sAddr]

	mov	r3, sAddr			@ move the image address into r3 to get coordinates
	bl	getSpriteCoord			@ get the coordinates of the image for printing
	@ return is in r0 - x, r1 - y

	mov	x, r0	@ store x		@ copy the x value into x
	mov	y, r1	@ store y		@ copy the y value into y to save

	mov	outCnt, #0 			@ height counter
cs_outerLoop:
	ldr	temp, [sAddr, #4]		@ store the screen height in temp
	cmp	outCnt, temp			@ compare counter with heigth
	bge	cs_done				@ if the pixels for height are done, exit

	mov	inCnt, #0 			@ counter
	mov	offset, #0			@ offset of x
cs_printLoop:
	ldr	temp, [sAddr]			@ store the screen width in temp
	cmp	inCnt, temp			@ compare counter with width
	bge	cs_finishRow			@ move to next row if current one is done printing
	
	@ call pixel draw
	add	r0, x, offset			@ x + offset for function call
	mov	r1, y				@ move the y value into r1 to pass to function
	ldr	r2, =0x3B0275			@ get value of ascii in colour
	bl	DrawPixel

	add	inCnt, #1			@ increment the loop counter by 1
	add 	offset, #1			@ increment offset by 1
	add	colour, #4			@ move to next pixel colour (each is a word)
	b	cs_printLoop

cs_finishRow:
	add	outCnt, #1			@ increment counter
	ldr	temp, =frameBufferInfo		@ get address of frame buffer to get the width value
	ldr	temp, [temp, #4]		@ go to the byte containing the width
	add	x, temp				@ add width of screen 
	b	cs_outerLoop
	
cs_done:	
	.unreq	sAddr
	.unreq	colour
	.unreq	x
	.unreq	y
	.unreq	outCnt
	.unreq	inCnt
	.unreq	temp
	.unreq	offset
	pop	{r4-r10, lr}
	bx	lr

/****************************************************
 * Purpose: To clear an image of the back ground
 * Pre: The user has selected to exit the game
 * Post: The screen is turned black to signify it is 
 * off.
 * Param: r0 - x
 * r1 - y
 * r2 - the address to read in
 * Return: None
 *
 ****************************************************/
.global clearBacking
clearBacking:
	push	{r4-r10, lr}
	
	sAddr	.req	r10
	colour	.req	r9
	x	.req	r5
	y	.req	r6
	outCnt	.req	r7
	inCnt	.req	r8
	temp	.req	r3
	offset	.req	r4

	mov	sAddr, r2			@ r2 has the address of the image to print, save in sAddr

	mov	r3, r2				@ move the image address into r3 to get coordinates
	bl	getCoord			@ get the coordinates of the image for printing
	@ return is in r0 - x, r1 - y	
	
	add	colour, sAddr, #8 		@ address of ascii value
	mov	x, r0	@ store x		@ copy the x value into x
	mov	y, r1	@ store y		@ copy the y value into y to save

	mov	outCnt, #0 			@ height counter
clearBackOuterLoop:
	ldr	temp, [sAddr, #4]		@ store the screen height in temp
	cmp	outCnt, temp			@ compare counter with heigth
	bge	clearBackDone			@ if the pixels for height are done, exit

	mov	inCnt, #0 			@ counter
	mov	offset, #0			@ offset of x
clearBackPrintLoop:
	ldr	temp, [sAddr]			@ store the screen width in temp
	cmp	inCnt, temp			@ compare counter with width
	bge	clearBackFinishRow		@ move to next row if current one is done printing
	
	@ call pixel draw
	add	r0, x, offset			@ x + offset for function call
	mov	r1, y				@ move the y value into r1 to pass to function
	ldr	r2, [colour]			@ get value of ascii at address r9		
	bl	DrawPixel			@ print the pixel		
	add	inCnt, #1			@ increment the inner loop counter
	add 	offset, #1			@ increment offset by 1
	
	b	clearBackPrintLoop		@ go back to print the next pixel in the row

clearBackFinishRow:
	add	outCnt, #1			@ increment outer loop counter
	ldr	temp, =frameBufferInfo		@ get the frame buffers address and store in temp
	ldr	temp, [temp, #4]		@ get the width of the screen to add to x for next row
	add	x, temp				@ add width of screen 
	b	clearBackOuterLoop		@ continue back to print the next row of pixels
	
clearBackDone:	
	.unreq	sAddr
	.unreq	colour
	.unreq	x
	.unreq	y
	.unreq	outCnt
	.unreq	inCnt
	.unreq	temp
	.unreq	offset
	pop	{r4-r10, lr}
	bx	lr


