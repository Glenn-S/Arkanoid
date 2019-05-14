
.sect	.text

/*--------------------- FUNCTIONS ----------------------*/

/********************************************************
 * Purpose: To set a pins function either input or 	
 * output.						
 * Pre: The GPIO address is valid.			
 * Post: The pins function bits will be set according 	
 * to the value passed in.				
 * Param: r0 - the function value to set (output/input)	
 * r1 - the pin number to be set			
 * Return: None						
 * Inspiration borrowed from tutorial notes		
 ********************************************************/
.global init_GPIO
init_GPIO:
	push	{r4-r7, lr}

	func	.req	r0
	pin	.req	r1
	gPtr	.req	r2
	addr	.req	r3
	mask	.req	r4
	temp	.req	r5
	cnt	.req	r7	

	@ move these functions over
	ldr	gPtr, =GpioPtr			@ get the base address
	ldr	addr, [gPtr]			@ read the value of the base address

	mov	cnt, #0				@ initialize counter to 0 for loop
setFuncLoop:
	cmp	pin, #9				@ check to see if pin <= 9
	subhi	pin, #10			@ subtract 10 if not <= 9
	addhi	addr, #4			@ increment GPIO base address
	bhi	setFuncLoop			@ if pin value not <= 9 branch

	add	pin, pin, lsl #1		@ multiply pin value by 3
	lsl	func, pin			@ move the function value over to the pin bits
	mov	mask, #7			@ store mask
	lsl	mask, pin			@ move the mask #7 to the pin bits			

	ldr	temp, [addr]			@ store the effective address in temp	
	bic	temp, mask	 		@ clear the pin function
	orr	temp, func			@ set the pin function
	str	temp, [addr]			@ store the value of function back into GPIO

	.unreq	func
	.unreq	pin
	.unreq	gPtr
	.unreq	addr
	.unreq	mask
	.unreq	temp
	.unreq	cnt

	pop	{r4-r7, lr}
	bx	lr				@ return to calling function

/********************************************************
 * Purpose: To read in the state of the controller for	 
 * one register cycle (16 clock cycles) and return the	
 * corresponding bit pattern transfered from the 	
 * controller.						
 * Pre: The pins functions are set.			
 * Post: The bit pattern for which buttons are pressed	
 * is recorded in a register and returned.		
 * Param: None						
 * Return: a register containing all 16 bits passed from
 * the controller to the core in the proper ordering.	
 ********************************************************/
.global Read_SNES
Read_SNES:
	push	{r4, r5, lr}

	param	.req	r0
	cnt	.req	r4
	btns	.req	r5

	mov	btns, #0			@ register to store button samples
	
	mov	param, #1			@ store 1 for function call to set clock
	bl	Write_Clock			@ set clock line
	mov	param, #1			@ store 1 for function call to set latch
	bl	Write_Latch			@ set latch line
	
	mov	param, #12			@ store value of 12 microseconds for delay
	bl	delayMicroseconds		@ delay 12 microseconds
	mov	param, #0			@ store 0 for clearing latch line
	bl	Write_Latch			@ clear latch line
	
	mov	cnt, #0				@ loop counter set to 0
readLoop: 
	mov	param, #6			@ store value of 6 microseconds for delay
	bl	delayMicroseconds		@ delay 6 microseconds
	
	mov	param, #0			@ store 0 for function call to clear clock
	bl	Write_Clock			@ clear clock line

	mov	param, #6			@ store value of 6 microseconds for delay
	bl	delayMicroseconds		@ delay 6 microseconds

	bl	Read_Data			@ read the input from the serial data
	orr	btns, param			@ store the bit read in in r7
	ror	btns, #1			@ rotate one bit right to be ready to store next
	
	mov	param, #1			@ store 1 for function call to set clock
	bl	Write_Clock			@ set clock line
	
	add	cnt, #1				@ increment the loop counter
	cmp	cnt, #16			@ check to see if r1 is 16 yet
	bne	readLoop			@ if loop counter is not 16, branch through loop again

readEnd:	
	mov	param, btns			@ move the word containing the input into r0 for return
	lsr	param, #16			@ move all bits over into the lower half of the word
	
	.unreq	param
	.unreq	btns
	.unreq	cnt	

	pop	{r4, r5, lr}	
	bx	lr				@ return to calling function

/********************************************************
 * Purpose: To turn the latch line on or off.		
 * Pre: The latches function is set to output.		
 * Post: The latches voltage is changed accordingly.	
 * Param: r0 - the value to write to the line		
 * Return: None						
 * inspiration for latch algorithm borrowed from lecture
 * notes						
 ********************************************************/
Write_Latch:
	push	{lr}			

	val	.req	r0
	gPtr	.req	r1
	mask	.req	r2

	ldr	gPtr, =GpioPtr			@ get the base address
	ldr	gPtr, [gPtr]			@ get the value of the base address
					
	mov	mask, #1			@ set the mask and store in mask
	lsl	mask, #9			@ pin number to change
	
	teq	val, #0				@ test to see whether to clear or store
	streq	mask, [gPtr, #0x28]		@ if val is 0, clear
	strne	mask, [gPtr, #0x1C]		@ if val is 1, set

	.unreq	val
	.unreq	gPtr
	.unreq	mask

	pop	{lr}		
	bx	lr				@ return to calling function


/********************************************************
 * Purpose: To turn the clock line on or off.		
 * Pre: The clocks function is set to output.		
 * Post: The clocks voltage is changed accordingly.
 * Param: r0 - the value to write to the line		
 * Return: None						
 * inspiration for clock algorithm borrowed from lecture
 * notes						
 ********************************************************/
Write_Clock:
	push	{lr}		
	
	val	.req	r0
	gPtr	.req	r1
	mask	.req	r2

	ldr	gPtr, =GpioPtr			@ get the base address
	ldr	gPtr, [gPtr]			@ get the value of the base address
					
	mov	mask, #1			@ set the mask and store in mask
	lsl	mask, #11			@ pin number to change
	
	teq	val, #0				@ test to see whether to clear or store
	streq	mask, [gPtr, #0x28]		@ if val is 0, clear
	strne	mask, [gPtr, #0x1C]		@ if val is 1, set

	.unreq	val
	.unreq	gPtr
	.unreq	mask

	pop	{lr}		
	bx	lr				@ return to calling function

/********************************************************
 * Purpose: To read the input from the snes controller.	
 * Pre: The data lines function is set to input.	
 * Post: The value is recorded from the line.		
 * Param: None						
 * Return: The bit value read in from the data line.	
 * inspiration for read algorithm borrowed from lecture 
 * notes						
 ********************************************************/
Read_Data:
	push	{lr}		

	val	.req	r0
	addr	.req	r1
	gPtr	.req	r2
	mask	.req	r3
	
	mov	val, #10			@ pin number 10 for reading Data			
	ldr	gPtr, =GpioPtr			@ get the base address for GPIO
	ldr	gPtr, [gPtr]			@ get the value of the base pointer and store
	ldr	addr, [gPtr, #52]		@ get the effective address for reading
	
	mov	mask, #1			@ set bit mask				
	lsl	mask, val			@ move the value into the pin bit
	and	addr, mask			@ test to get the value of the bit in r1
	teq	addr, #0			@ test to see if it is 0 or 1
	
	moveq	val, #0				@ return 0 if 0
	movne	val, #1				@ return 1 if 1

	.unreq	val
	.unreq	addr
	.unreq	gPtr
	.unreq	mask

	pop	{lr}				
	bx	lr				@ return to calling function



