.sect	.data

/***************************************************
 * Purpose: to get the x/y value of a background
 * image.
 * Pre: The image exists
 * Post: The coordinates to print will be calculated
 * based on the size of the screen.
 * Param: r3 - the address of the image
 * Return: r0 - x, r1 - y
 *
 ***************************************************/
.global getCoord
getCoord:
	push	{r4, r5, lr}

	ldr	r0, =frameBufferInfo
	ldr	r1, [r0, #4]			@ width
	ldr	r2, [r0, #8]			@ height
	@ load picture dimensions
	@ r3 has the image address
	ldr	r4, [r3]			@ picture width
	ldr	r5, [r3, #4]
	
	lsr	r1, #1				@ divide size in half
	sub	r1, r4, lsr #1			@ subtract the image divided in half
	lsr	r2, #1				@ divide height in half
	sub	r2, r5, lsr #1			@ subtract image height divided in half

	mov	r0, r1				@ move the image x value into r0 to return
	mov	r1, r2				@ move the image y value into r1 to return

	pop	{r4, r5, lr}
	bx	lr

/***********************************************
 * Purpose: to get the x/y value of the paddle.
 * Pre: The paddle image exists
 * Post: The paddle image location to print will
 * be calculated.
 * Param: r3 - the address of the image
 * Return: r0 - x, r1 - y
 *
 ************************************************/
.global getPaddleCoord
getPaddleCoord:
	push	{r4, r5, r6, r7, lr}

	ldr	r0, =frameBufferInfo
	ldr	r1, [r0, #4]			@ width
	ldr	r2, [r0, #8]			@ height
	@ load image dimensions
	@ r3 has the image address, maybe change to LDMIA
	ldmia	r3, {r4-r7}			@ r4 - x displacement, r5 - y disp, r6 - paddle width, r7 - paddle height
	
	lsr	r1, #1				@ divide width of screen in half
	sub	r1, r6, lsr #1			@ subtract half the image width
	add	r1, r4				@ add the x displacement to the location
	lsr	r2, #1				@ divide height in half
	add	r2, r7, lsr #1			@ add the image height//2 to the screen height//2
	add	r2, r5				@ add the displacement to the coordinate in r2 (y)
	mov	r0, r1				@ prepare for returning 
	mov	r1, r2				@ prepare for returning

	pop	{r4, r5, r6, r7, lr}
	bx	lr

/***********************************************
 * Purpose: To get the x/y value of the ball
 * Pre: The ball image exists
 * Post: The ball image location to print will
 * be calculated.
 * Param: r3 - the address of the image
 * return: r0 - x, r1 - y
 *
 ************************************************/
.global	getBallCoord
getBallCoord:
	push	{r4, r5, r6, r7, lr}

	ldr	r0, =frameBufferInfo
	ldr	r1, [r0, #4]			@ width
	ldr	r2, [r0, #8]			@ height
	@ load image dimensions
	@ r3 has the image address, maybe change to LDMIA
	ldmia	r3, {r4-r6}			@ r4 - x displacement, r5 - y disp, r6 - ball diameter
	
	lsr	r1, #1				@ divide width of screen in half
	sub	r1, r6, lsr #1			@ subtract half the image width
	add	r1, r4				@ add the x displacement to the location
	lsr	r2, #1				@ divide height in half
	add	r2, r6, lsr #1			@ add the image height//2 to the screen height//2
	add	r2, r5				@ add the displacement to the coordinate in r2 (y)
	mov	r0, r1				@ prepare for returning 
	mov	r1, r2				@ prepare for returning

	pop	{r4, r5, r6, r7, lr}
	bx	lr

/*************************************************
 * Purpose: To get the offset for a counter sprite
 * Pre: The counter sprite exists
 * Post: The sprite image location to print will
 * be calculated.
 * Param: r3 - sprite address
 * Return: r0 - x, r1 - y
 *
 **************************************************/

.global getSpriteCoord
getSpriteCoord:
	push	{r4, r5, r6, r7, lr}

	mov	r4, r0
	mov	r5, r1

	ldr	r0, =frameBufferInfo
	ldr	r1, [r0, #4]			@ width
	ldr	r2, [r0, #8]			@ height
	@ load image dimensions
	@ r3 has the image address, maybe change to LDMIA
	ldmia	r3, {r6, r7}			@ r4 - x displacement, r5 - y disp, r6 - sprite width, r7 - sprite height
	
	lsr	r1, #1				@ divide width of screen in half
	sub	r1, r6, lsr #1			@ subtract half the image width
	add	r1, r4				@ add the x displacement to the location
	lsr	r2, #1				@ divide height in half
	add	r2, r7, lsr #1			@ add the image height//2 to the screen height//2
	add	r2, r5				@ add the displacement to the coordinate in r2 (y)
	mov	r0, r1				@ prepare for returning 
	mov	r1, r2				@ prepare for returning

	pop	{r4, r5, r6, r7, lr}
	bx	lr

/************************************************
 * Purpose: To get the offset for a brick tile.
 * Pre: The brick tile exists
 * Post: The brick image location to print will
 * be calculated.
 * Param: r3 - brick address
 * Return: r0 - x, r1 - y
 *
 *************************************************/
.global getBrickCoord
getBrickCoord:
	push	{r4-r5, lr}

	mov	r4, r0
	mov	r5, r1

	ldr	r0, =frameBufferInfo
	ldr	r1, [r0, #4]			@ width
	ldr	r2, [r0, #8]			@ height
	@ load image dimensions
	
	lsr	r1, #1				@ divide width of screen in half
	sub	r1, #384			@ get the edge of the background
	add	r1, r4				@ add the x displacement to the location
	lsr	r2, #1				@ divide height in half
	sub	r2, #448			@ get the top of the background
	add	r2, r5				@ add the displacement to the coordinate in r2 (y)
	mov	r0, r1				@ prepare for returning 
	mov	r1, r2				@ prepare for returning

	pop	{r4-r5, lr}
	bx	lr

.end
