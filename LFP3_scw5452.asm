#####################################################################
#Start Notes/Comments Section
#There are a few bugs that I have not had time to work out around the ship weapons fire. Sometimes the
#bullets will wrap around to another spot on the display briefly. Not sure why this is happening.
#I somewhat got the mob weapons fire to work, but it isn't updating properly, and so they kind of get 
#drawn to the screen, but don't seem to be updating. Again, ran out of time to troubleshoot this issue.
#ship weapons fire collision detection works (but not perfectly), but ran out of time around mob weapons
#fire collision detection. Was going to work on this once I got the mob fire to update properly.
#There is a missing function called WhichMobFired that was going to use a random number generator
#to determine which mobs would be firing randomly. As I did not get the mob fire working properly,
#I did not make it to this step in the coding processes. Due to the lack of other routines working 
#properly, and the lack of mob fire collision detection, I did not get to the point of updating
#the number of lives in the bottom left corner. 
#
###MARS Setup to run the game#####
#Unit width = 1
#Unit Height = 1
#Display Width = 512
#Display Height = 512
#Base Address for Display = heap
#
#Requies athe Keyboard and Display MIMO Simulator for user input
###Contorls###
#Move left = a
#Move Right = d
#Ship Weapons fire = space bar
#Quit game = q
#
#End Notes/Comments Section
#####################################################################

#####################################################################
#Kernal Data Section
########################################################################
	#   Description:
	#       Example SPIM exception handler
	#       Derived from the default exception handler in the SPIM S20
	#       distribution.
	#
	#   History:
	#       Dec 2009    J Bacon
	
	########################################################################
	# Exception handling code.  This must go first!
	
	.kdata
	__start_msg_:   .asciiz "  Exception "
	__end_msg_:     .asciiz " occurred and ignored\n"
	
	# Messages for each of the 5-bit exception codes
	__exc0_msg:     .asciiz "  [Interrupt] "
	__exc1_msg:     .asciiz "  [TLB]"
	__exc2_msg:     .asciiz "  [TLB]"
	__exc3_msg:     .asciiz "  [TLB]"
	__exc4_msg:     .asciiz "  [Address error in inst/data fetch] "
	__exc5_msg:     .asciiz "  [Address error in store] "
	__exc6_msg:     .asciiz "  [Bad instruction address] "
	__exc7_msg:     .asciiz "  [Bad data address] "
	__exc8_msg:     .asciiz "  [Error in syscall] "
	__exc9_msg:     .asciiz "  [Breakpoint] "
	__exc10_msg:    .asciiz "  [Reserved instruction] "
	__exc11_msg:    .asciiz ""
	__exc12_msg:    .asciiz "  [Arithmetic overflow] "
	__exc13_msg:    .asciiz "  [Trap] "
	__exc14_msg:    .asciiz ""
	__exc15_msg:    .asciiz "  [Floating point] "
	__exc16_msg:    .asciiz ""
	__exc17_msg:    .asciiz ""
	__exc18_msg:    .asciiz "  [Coproc 2]"
	__exc19_msg:    .asciiz ""
	__exc20_msg:    .asciiz ""
	__exc21_msg:    .asciiz ""
	__exc22_msg:    .asciiz "  [MDMX]"
	__exc23_msg:    .asciiz "  [Watch]"
	__exc24_msg:    .asciiz "  [Machine check]"
	__exc25_msg:    .asciiz ""
	__exc26_msg:    .asciiz ""
	__exc27_msg:    .asciiz ""
	__exc28_msg:    .asciiz ""
	__exc29_msg:    .asciiz ""
	__exc30_msg:    .asciiz "  [Cache]"
	__exc31_msg:    .asciiz ""
	
	__level_msg:    .asciiz "Interrupt mask: "
	
	
	#########################################################################
	# Lookup table of exception messages
	__exc_msg_table:
		.word   __exc0_msg, __exc1_msg, __exc2_msg, __exc3_msg, __exc4_msg
		.word   __exc5_msg, __exc6_msg, __exc7_msg, __exc8_msg, __exc9_msg
		.word   __exc10_msg, __exc11_msg, __exc12_msg, __exc13_msg, __exc14_msg
		.word   __exc15_msg, __exc16_msg, __exc17_msg, __exc18_msg, __exc19_msg
		.word   __exc20_msg, __exc21_msg, __exc22_msg, __exc23_msg, __exc24_msg
		.word   __exc25_msg, __exc26_msg, __exc27_msg, __exc28_msg, __exc29_msg
		.word   __exc30_msg, __exc31_msg
	
	# Variables for save/restore of registers used in the handler
	save_v0:    .word   0
	save_a0:    .word   0
	save_a1:    .word   0
	save_at:    .word   0
	save_t0:		.word	0
	save_t1:		.word	0
	save_t2:		.word	0
	save_t3:		.word	0
	save_t4:		.word	0
	save_t5:		.word	0
	save_t6:		.word	0
	save_t7:		.word	0
	save_t8:		.word	0
	save_t9:		.word	0
	
	
	#########################################################################
	# This is the exception handler code that the processor runs when
	# an exception occurs. It only prints some information about the
	# exception, but can serve as a model of how to write a handler.
	#
	# Because this code is part of the kernel, it can use $k0 and $k1 without
	# saving and restoring their values.  By convention, they are treated
	# as temporary registers for kernel use.
	#
	# On the MIPS-1 (R2000), the exception handler must be at 0x80000080
	# This address is loaded into the program counter whenever an exception
	# occurs.  For the MIPS32, the address is 0x80000180.
	# Select the appropriate one for the mode in which SPIM is compiled.
	
	.ktext  0x80000180
	
		# Save ALL registers modified in this handler, except $k0 and $k1
		# This includes $t* since the user code does not explicitly
		# call this handler.  $sp cannot be trusted, so saving them to
		# the stack is not an option.  This routine is not reentrant (can't
		# be called again while it is running), so we can save registers
		# to static variables.
		sw      $v0, save_v0
		sw      $a0, save_a0
		sw	$a1, save_a1
	
		# $at is the temporary register reserved for the assembler.
		# It may be modified by pseudo-instructions in this handler.
		# Since an interrupt could have occurred during a pseudo
		# instruction in user code, $at must be restored to ensure
		# that that pseudo instruction completes correctly.
		.set    noat		# Prevent assembler from modifying $at
		sw      $at, save_at
		.set    at
	
		# Determine cause of the exception
		mfc0    $k0, $13        # Get cause register from coprocessor 0
		srl     $a0, $k0, 2     # Extract exception code field (bits 2-6)
		andi    $a0, $a0, 0x1f
		
		# Check for program counter issues (exception 6)
		bne     $a0, 6, ok_pc
		nop
	
		mfc0    $a0, $14        # EPC holds PC at moment exception occurred
		andi    $a0, $a0, 0x3   # Is EPC word-aligned (multiple of 4)?
		beqz    $a0, ok_pc
		nop
	
		# Bail out if PC is unaligned
		# Normally you don't want to do syscalls in an exception handler,
		# but this is MARS and not a real computer
		li      $v0, 4
		la      $a0, __exc3_msg
		syscall
		li      $v0, 10
		syscall
	
	ok_pc:
		mfc0    $k0, $13
		srl     $a0, $k0, 2     # Extract exception code from $k0 again
		andi    $a0, $a0, 0x1f
		bnez    $a0, non_interrupt  # Code 0 means exception was an interrupt
		nop
	
		# External interrupt handler
		# Don't skip instruction at EPC since it has not executed.
		# Interrupts occur BEFORE the instruction at PC executes.
		# Other exceptions occur during the execution of the instruction,
		# hence for those increment the return address to avoid
		# re-executing the instruction that caused the exception.
		
		#Save temp registers used
		 sw	$t0,	save_t0
		 sw	$t1,	save_t1
	
	     # check if we are in here because of a character on the keyboard simulator
		 # go to nochar if some other interrupt happened
		 
		 # get the character from memory
		 lui	$t0,	0xffff
		 lw	$t1,	4 ($t0)
		 
		 #Check if the value in the keyboard input is an ASCII Char
		 #Branch to nochar if not a printable ASCII char
		 bgt	$t1,	127,	nochar
		 blt	$t1,	32,	nochar
		 
		 
		 # store it to a queue somewhere to be dealt with later by normal code	 
		 lw	$t0,	queueTracker
		 #addiu	$t1,	$t1,	-48
		 sw	$t1,	($t0)
		 addiu	$t0,	$t0,	4
		 sw	$t0,	queueTracker
		 
		 lw	$t0,	keyCount
		 addiu	$t1,	$t0,	1
		 sw	$t1,	keyCount
		 
		 #restore temp registers used
		 lw	$t0,	save_t0
		 lw	$t1,	save_t1
		 
		 #Exit Kyboard interrupt handler
		j	return
	
nochar:
		# not a character
		# Print interrupt level
		# Normally you don't want to do syscalls in an exception handler,
		# but this is MARS and not a real computer
		li      $v0, 4          # print_str
		la      $a0, __level_msg
		syscall
		
		li      $v0, 1          # print_int
		mfc0    $k0, $13        # Cause register
		srl     $a0, $k0, 11    # Right-justify interrupt level bits
		syscall
		
		li      $v0, 11         # print_char
		li      $a0, 10         # Line feed
		syscall
		
		j       return
	
	non_interrupt:
		# Print information about exception.
		# Normally you don't want to do syscalls in an exception handler,
		# but this is MARS and not a real computer
		li      $v0, 4          # print_str
		la      $a0, __start_msg_
		syscall
	
		li      $v0, 1          # print_int
		mfc0    $k0, $13        # Extract exception code again
		srl     $a0, $k0, 2
		andi    $a0, $a0, 0x1f
		syscall
	
		# Print message corresponding to exception code
		# Exception code is already shifted 2 bits from the far right
		# of the cause register, so it conveniently extracts out as
		# a multiple of 4, which is perfect for an array of 4-byte
		# string addresses.
		# Normally you don't want to do syscalls in an exception handler,
		# but this is MARS and not a real computer
		li      $v0, 4          # print_str
		mfc0    $k0, $13        # Extract exception code without shifting
		andi    $a0, $k0, 0x7c
		lw      $a0, __exc_msg_table($a0)
		nop
		syscall
	
		li      $v0, 4          # print_str
		la      $a0, __end_msg_
		syscall
	
		# Return from (non-interrupt) exception. Skip offending instruction
		# at EPC to avoid infinite loop.
		mfc0    $k0, $14
		addiu   $k0, $k0, 4
		mtc0    $k0, $14
	
	return:
		# Restore registers and reset processor state
		lw      $v0, save_v0    # Restore other registers
		lw      $a0, save_a0
		lw      $a1, save_a1
	
		.set    noat            # Prevent assembler from modifying $at
		lw      $at, save_at
		.set    at
	
		mtc0    $zero, $13      # Clear Cause register
	
		# Re-enable interrupts, which were automatically disabled
		# when the exception occurred, using read-modify-write cycle.
		mfc0    $k0, $12        # Read status register
		andi    $k0, 0xfffd     # Clear exception level bit
		ori     $k0, 0x0001     # Set interrupt enable bit
		mtc0    $k0, $12        # Write back
	
		# Return from exception on MIPS32:
		eret
	
	
	###############################################


#########################################################################
# Exception handling Data
#########################################################################
.data
# Status register bits
EXC_ENABLE_MASK:        .word   0x00000001

# Cause register bits
EXC_CODE_MASK:          .word   0x0000003c  # Exception code bits

EXC_CODE_INTERRUPT:     .word   0   # External interrupt
EXC_CODE_ADDR_LOAD:     .word   4   # Address error on load
EXC_CODE_ADDR_STORE:    .word   5   # Address error on store
EXC_CODE_IBUS:          .word   6   # Bus error instruction fetch
EXC_CODE_DBUS:          .word   7   # Bus error on load or store
EXC_CODE_SYSCALL:       .word   8   # System call
EXC_CODE_BREAKPOINT:    .word   9   # Break point
EXC_CODE_RESERVED:      .word   10  # Reserved instruction code
EXC_CODE_OVERFLOW:      .word   12  # Arithmetic overflow

# Status and cause register bits
EXC_INT_ALL_MASK:       .word   0x0000ff00  # Interrupt level enable bits

EXC_INT0_MASK:          .word   0x00000100  # Software
EXC_INT1_MASK:          .word   0x00000200  # Software
EXC_INT2_MASK:          .word   0x00000400  # Display
EXC_INT3_MASK:          .word   0x00000800  # Keyboard
EXC_INT4_MASK:          .word   0x00001000
EXC_INT5_MASK:          .word   0x00002000  # Timer
EXC_INT6_MASK:          .word   0x00004000
EXC_INT7_MASK:          .word   0x00008000




#End Kernel Data Section
#####################################################################

#####################################################################
#Start Data Section
#Setup variables, tables, etc.
.data
	#setup stack
	stackSetup:	.word	0:400
	stackBot:
	
	#Ask user for difficulty
	chooseDiff:	.asciiz	"\nPlease choose a difficulty (1, 2, or 3)\n1. Easy\n2. Normal\n3. Hard\n"
	
	#Get user input message
	usrInput:	.asciiz	"\nPlease enter a number:\n"
	
	#Exit Program Thank you Message
	thankYou:	.asciiz	"\n\nThank you for playing\n"
	
	#You Win endgame message
	youLose:		.asciiz	"\nYou Lose\n"
	
	#You Lose endgame message
	youWin:		.asciiz	"\nYou Win\n"
	
	#An error has occurred
	errorMsg:	.asciiz	"An error has occurred."
	
	#track if the user has entered a wrong input; 0 = lose; 1 = no incorrect answers;
	#used primarily for midi sound playback decision
	winTracker:	.word	1
	
	#Tracker user keyboard input
	keyCount:	.word	0
	keyQueue:	.word	0:100
	queueTracker:	.word	0
	
	#ColorTable [6] = lw ColorTable + 6*4
	ColorTable:
		.word	0x000000		#[0] - black
		.word	0x0000ff		#[1] - blue
		.word	0x00ff00		#[2] - green
		.word	0xff0000		#[3] - red
		.word	0x00ffff		#[4] - blue + green = Cyan
		.word	0xff00ff		#[5] - blue + red = Magenta
		.word	0xff6600		#[6] - red + green = Orange
		.word	0xffffff		#[7] - white
		
	#Base board address
	baseAddr:	.word	0x10040000
	
	#Standard box size	-	REVISIT
	boxSize:		.word	13
	
	#Bullet movement bounds
	upperBound:	.word	10
	lowerBound:	.word	510
	
	#Ship Size
	shipSize:	.word	24
	
	#Ship Position
	shipPosX:		.word	256
	shipPosY:		.word	450
	shipPosXNew:		.word	256
	#shipPosYNew:		.word	450
	
	#Ship Bullet info/specs
	shipBulletColor1:	.word	1
	shipBulletColor2:	.word	3
	bulletTipLen:		.word	6
	bulletBodyLen:		.word	12
	
	#Track bullets fired
	bulletsFired:	.word	0
	bulletSpeed:	.word	6
	maxShipBullets:	.word	5
	
	#Player Lives locations
	lifeY:	.word	490
	life1:	.word	30
	life2:	.word	80
	life3:	.word	130
	
	#Ship color
	shipColor:	.word	7
	
	#Bullet Locations
bullets:
	.word	0	#bullet1X
	.word	0	#bullet1Y
	.word	0	#bullet2X
	.word	0	#bullet2Y
	.word	0	#bullet3X
	.word	0	#bullet3Y
	.word	0	#bullet4X
	.word	0	#bullet4Y
	.word	0	#bullet5X
	.word	0	#bullet5Y
	.word	0,0,0,0	#buffer in case more bullets are drawn than should be
	
	#Mob positions and specs
	mobSize:	.word 24
	
mobBullets:
	.word	0	#bullet0X
	.word	0	#bullet0Y
	.word	0	#bullet1X
	.word	0	#bullet1Y
	.word	0	#bullet2X
	.word	0	#bullet2Y
	.word	0	#bullet3X
	.word	0	#bullet3Y
	.word	0	#bullet4X
	.word	0	#bullet4Y
	.word	0	#bullet5X
	.word	0	#bullet5Y
	.word	0	#bullet6X
	.word	0	#bullet6Y
	.word	0	#bullet7X
	.word	0	#bullet7Y
	.word	0	#bullet8X
	.word	0	#bullet8Y
	.word	0	#bullet9X
	.word	0	#bullet9Y
	
mobBulletsFired:
	.word	0
	
	#Comprised of the x, y coords of the buttom of the mobs
mobR1DetLines:
	.word	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	
	mobBulletSpeed:	.float	4.0
	
mobRow1Start:
	mobR1Sx:	.word	435
	mobR1Sy:	.word	30
	
mobRow1Pos:
	mob0x:	.word	30
	mob0y:	.word	30
	mob1x:	.word	75
	mob1y:	.word	30
	mob2x:	.word	120
	mob2y:	.word	30
	mob3x:	.word	165
	mob3y:	.word	30
	mob4x:	.word	210
	mob4y:	.word	30
	mob5x:	.word	255
	mob5y:	.word	30
	mob6x:	.word	300
	mob6y:	.word	30
	mob7x:	.word	345
	mob7y:	.word	30
	mob8x:	.word	390
	mob8y:	.word	30
	mob9x:	.word	435
	mob9y:	.word	30
	
mobBulletPath:
	.word	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	
mobXTable:
	.word	mob0x, mob1x, mob2x, mob3x, mob4x, mob5x, mob6x, mob7x, mob8x, mob9x
	
mobYTable:
	.word	mob0y, mob1y, mob2y, mob3y, mob4y, mob5y, mob6y, mob7y, mob8y, mob9y
	
mobColors:	.word	3, 6, 4

mobLives:
	.word	10
	
mobFired:
	.word	0,0,0,0,0,0,0,0,0,0
	
maxMobBullets:
	.word	10

mobFireTrigger:
	.word	156	
	
stageTracker:
	.word	0	
	
countDown:
	.asciiz	"5"
	.asciiz	"4"
	.asciiz	"3"
	.asciiz	"2"
	.asciiz	"1"

#End Data Section
#####################################################################

######################################################################
#Start Galaga
.text
	#Setup Stack
	la	$sp,	stackBot
	
	#Setup keyboard input tracker: Is this needed???????
	la	$t0,	keyQueue
	sw	$t0,	queueTracker
	
#################Enable interrupts####################
	# Enable interrupts in status register
	mfc0	$t0,	$12

	# Disable all interrupt levels
	lw	$t1,	EXC_INT_ALL_MASK
	not	$t1,	$t1
	and	$t0,	$t0,	$t1
	
	# Enable console interrupt levels
	lw	$t1,	EXC_INT3_MASK
	or	$t0,	$t0,	$t1
	#lw      $t1, EXC_INT4_MASK
	#or      $t0, $t0, $t1

	# Enable exceptions globally
	lw	$t1,	EXC_ENABLE_MASK
	or	$t0,	$t0,	$t1
	#Save to status register
	mtc0	$t0,	$12
	
	# Enable keyboard interrupts
	li      $t0,	0xffff0000	# Receiver control register
	li      $t1,	0x00000002	# Interrupt enable bit
	sw      $t1,	($t0)		#Save keyboard interrupt enabled

#######Initialize game######
	#Clear the Display
	jal	ClearDisp
	jal	SetupLives
	
	#Setup Ship at starting position
	lw	$a0,	shipPosX
	lw	$a1,	shipPosY
	lw	$a2,	shipColor
	jal	DrawShip
	
	#Game start countdown
	jal	StartGame
	
	#Setup mob line(s)
	la	$a0,	mobRow1Pos
	lw	$a1,	mobR1Sx
	lw	$a2,	mobR1Sy
	jal DrawMobLine
	
	#Setup main loop iterator
	li	$t9,	0
	
#Start Main Game loop
Main:	
	addiu	$sp,	$sp	-4
	sw	$t9,	($sp)
	#Check if key pressed
	lw	$t0,	keyCount
	beqz	$t0,	next1	#Skip updating ship or adding ship fire if no key is pressed
	#Key has been pressed; Go get it
	jal	CallKey
	lw	$t1,	shipPosXNew
	lw	$t2,	shipPosX
	beq	$t1,	$t2,	next1
	jal	UpdateShip
	
next1:
#Update any active ship fire
	lw	$t8,	bulletsFired
	blez	$t8,	skipShipFire
	jal	UpdateShipFire	#update the ship bullet(s)
	jal	ShipFireColDet	#check if bullet(s) hit mob(s)
	
skipShipFire:
#Update Mobs
	lw	$t9,	($sp)
	lw	$t8,	mobFireTrigger
	rem	$t8,	$t9,	$t8
	bnez	$t8,	skipMobFire
	jal	MobFire
skipMobFire:
	#Check if all mobs have been killed
	lw	$t8,	mobLives
	bnez	$t8,	skipMobRedraw
	#increment stage
	lw	$t8,	stageTracker
	addiu	$t8,	$t8,	1
	sw	$t8,	stageTracker
	#If all mobs killed, redraw mobs
	#Redraw mob line(s)
	la	$a0,	mobRow1Pos
	lw	$a1,	mobR1Sx
	lw	$a2,	mobR1Sy
	jal DrawMobLine

skipMobRedraw:
	#Check if there is any active mob bullets
	lw	$t8,	mobBulletsFired
	beqz	$t8,	skipUpdateMobFire
	#Update active Mob fire
	jal	UpdateMobFire
	
skipUpdateMobFire:
#get ready to restart game loop
	#Force 62.5 fram updates per second
	li	$a0,	16
	jal	Pause
	
	#restore main game loop counter
	lw	$t9,	($sp)
	addiu	$sp,	$sp,	4
	addiu	$t9,	$t9,	1
	#Check if counter needs to reset
	#Used to make sure that game does not exceed the max value of a single word
	blt	$t9,	15620, restartMain
	#reset main game counter
	li	$t9,	0
	
restartMain:
	j	Main
	#jal	Exit

#End Galaga
######################################################################

#########################################################################
#Start SCW5452 Routines

##################################
#Start Update Mob fire
#This routine is called from Main to update any mob bullets on the display
#Takes arguments: 
#None
#Returns:
#None
#Uses:
#Variables:
#bulletsFired
#shipBulletSpeed
#bullets
#upperBound
#Routines:
#DrawShipBullet
UpdateMobFire:
	#Save return address
	addiu	$sp,	$sp,	-24
	sw	$ra,	0($sp)
	
	#Check to see if any bullets need to be updated
	lw	$t0,	mobBulletsFired
	blez	$t0,	updateMobBulEnd
	li	$t0,	0
	#sw	$t0,	8($sp)	#store current bullet number
	
	#Setup arguments
	la	$t9,	mobBullets
	
#Draw Ship bullets
updateMobBulLoop:	
	sll	$t1,	$t0,	3
	sw	$t1,	20($sp)	#store offset
	addu	$t9,	$t9,	$t1
	lw	$a0,	0($t9)	#load current bullet x coord
	lw	$a1,	4($t9)	#load current bullet y coord
	sw	$t9,	4($sp)	#store bullet address
	jal	ClearMobBullet
	lw	$t9,	4($sp)	#load bullet address
	lw	$t0,	8($sp)	#load current bullet number
	lw	$a0,	0($t9)	#load current bullet x coord
	lw	$a1,	4($t9)	#load current bullet y coord
	la	$t8,	mobBulletPath	#Get change in x, y
	lw	$t1,	20($sp)	#load offset
	addu	$t8,	$t8,	$t1	#calculate current bullet path number
	lw	$t5,	($t8)		#Load path change in y
	lw	$t6,	4($t8)		#load path change in x
	addu	$a0,	$a0,	$t6	#Update bullet x coord
	addu	$a1,	$a1,	$t5	#Update bullet y coord
	#Check if ship bullet has reached bottom of screen
	lw	$t7,	lowerBound
	bgt	$a1,	$t7,	clearMobBul	
	#redraw bullet if it hasn't reach the bottom of the screen
	sw	$a0,	0($t9)	#Save new y coord for bullet
	sw	$a1,	4($t9)	#Save new y coord for bullet
	sw	$t0,	4($sp)	#store current bullet number
	sw	$t9,	8($sp)	#store bullets address
	sw	$a0,	12($sp)	#store x coord
	sw	$a1,	16($sp)	#store y coord
	jal	DrawMobBullet
	lw	$t0,	4($sp)	#Load current bullet number
	lw	$t9,	8($sp)	#load bullets address
	addiu	$t0,	$t0,	1	#increment counter till all bullets are updated
	lw	$t1,	mobBulletsFired
	blt	$t0,	$t1,	updateMobBulLoop
	j	updateMobBulEnd
	
clearMobBul:
	move	$a0,	$t9	#set a0 to bullet address 
	move	$a1,	$t0	#set a1 to the number of the current bullet
	jal	RemoveMobBullet
	
updateMobBulEnd:		
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	24
	
	#Return to caller
	jr	$ra

#End Update Mob fire
##################################

##################################
#Start Draw Mob bullet
#This routine is called to draw a mob bullet to the screen with its origin at the x, y of the mob. 
#This routine is also called to update the bullet location on the display.
#Takes arguments: 
#$a0 = x-coord of bullet
#$a1 = y-coord of bullet
#Returns:
#None
#Uses:
#Variables:
#None
#Routines:
#DrawTurret
DrawMobBullet:
	#Save return address
	addiu	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	
	#save arguments
	sw	$a0,	4($sp)
	sw	$a1,	8($sp)
	sw	$a2,	12($sp)
	
	#Load mob colors
	la	$t0,	mobColors
	sw	$t0,	16($sp)
	
	#load mob bullet values
	lw	$a0,	4($sp)
	lw	$a1,	8($sp)
	
#Draw mob bullet
	lw	$t0,	16($sp)
	#Draw bullet tail
	lw	$a0,	4($sp)
	lw	$a1,	8($sp)
	lw	$a2,	8($t0)
	lw	$a3,	bulletBodyLen
	subu	$a1,	$a1,	$a3
	jal	VertLine
	
	lw	$t0,	16($sp)
	#Draw bullet tip	
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	($t0)
	lw	$a3,	bulletTipLen
	jal	DrawTriDown
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Draw Mob bullet
##################################

##################################
#Start Remove Mob Bullet
#This routine is called to remove a mob bullet from the mobBullet queue
#Takes arguments: 
#$a0 = bullet address
#$a1 = which bullet to remove
#Returns:
#None
#Uses:
#Variables:
#bulletsFired
#Routines:
#DrawShipBullet
RemoveMobBullet:
	#Save return address
	addiu	$sp,	$sp,	-4
	sw	$ra,	0($sp)
	
	#move argument to temp register
	move	$t9,	$a0	#bullet mem address
	move	$t0,	$a1	#bullet number
	sll	$t1,	$t0,	3	#calc bullet offset
	addu	$t9,	$t9,	$t1	#calc bullet mem address
	
	#Setup loop constraints
	lw	$t8,	maxMobBullets
	addiu	$t8,	$t8,	-1	#Adjust loop iteration to exclude the final bullet slot

updateMobBulletsFired:
	lw	$t3,	8($t9)	#Load next bullet x coord 
	lw	$t4,	12($t9)	#load next bullet y coord
	seq	$t5,	$t3,	0	#check if bullet x = 0, $t5 = 1 if zero, 0 otherwise
	seq	$t6,	$t4,	0	#check if bullet y = 0, $t6 = 1 if zero, 0 otherwise
	addu	$t5,	$t5,	$t6	#If both x and y are zero ($t5 = 2), nothing more to do, skip to end
	beq	$t5,	2,	removeMobBulletEnd
	sw	$t3,	0($t9)	#move to current bullet x coord
	sw	$t4,	4($t9)	#move to current bullet y coord
	addiu	$t0,	$t0,	1	#increment iterator
	addiu	$t9,	$t9,	8	#move current bullet address to next bullet
	blt	$t0,	$t8,	updateMobBulletsFired
	#Set final bullet spot back to (0, 0) for x, y pair
	sw	$0,	0($t9)	#reset last bullet slot x coord to 0
	sw	$0,	4($t9)	#reset last bullet slot y coord to 0
	lw	$t0,	mobBulletsFired
	addiu	$t0,	$t0,	-1
	sw	$t0,	mobBulletsFired
	
removeMobBulletEnd:
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	4
	
	#Return to caller
	jr	$ra

#End Remove Mob Bullet
##################################

##################################
#Start Clear Mob bullet
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#$a0 = x-coord of bullet
#$a1 = y-coord of bullet
#Returns:
#None
#Uses:
#Variables:
#None
#Routines:
#DrawTurret
ClearMobBullet:
	#Save return address
	addiu	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	
	#Setup arguments
	sw	$a0,	4($sp)
	sw	$a1,	8($sp)
	li	$a2,	0
	sw	$a2,	12($sp)
	
#Clear Ship bullet
	#Draw bullet tail
	lw	$a0,	4($sp)
	lw	$a1,	8($sp)
	lw	$a2,	12($sp)
	lw	$a3,	bulletBodyLen
	subu	$a1,	$a1,	$a3
	jal	VertLine
	
	lw	$t0,	16($sp)
	#Draw bullet tip	
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	12($sp)
	lw	$a3,	bulletTipLen
	jal	DrawTriDown

	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Clear Mob bullet
##################################

##################################
#Start Next position for mob bullet
#This routine is called to calculate the change in x and change in y for the path of the mob bullet.
#It is calculated using the mob x, y origin and the current ship x, y position.
#Takes arguments: 
#$a0 = x-coord of mob bullet
#$a1 = y-coord of mob bullet
#$a2 = mob number shooting bullet
#Variables Used:
#mobRow1Pos
#mobBulletPath
#shipPosX
#shipPosY
MobBulletPath:
	#Save return address
	addiu	$sp,	$sp,	-4
	sw	$ra,	0($sp)
	
	#(shipY-mobY)/(SshipX-mobX) = x
	#mobBulletSpeed^2 * x^2 = y^2
	#y = sqrt(y^2)
	#Load address of mob storage
	la	$t0,	mobRow1Pos
	sll	$t1,	$a2,	3	#calculate mem shift amount
	addu	$t2,	$t0,	$t1	#calculate mob position in memory
	lw	$t3,	($t2)	#mob x
	lw	$t4,	4($t2)	#mob y
	lw	$t5,	shipPosX	#ship x
	lw	$t6,	shipPosY	#ship y
	subu	$t9,	$t5,	$t3	#shipX - mobX = run 
	subu	$t7,	$t6,	$t4	#shipY - mobY = rise
	mtc1	$t7,	$f6	#Move rise to FP coprocessor
	mtc1	$t9,	$f5	#Move run to FP coprocessor
	cvt.s.w	$f4,	$f6	#convert int to float
	cvt.s.w	$f7,	$f5	#convert int to float
	mul.s	$f5,	$f4,	$f4	#Y^2
	mul.s	$f6,	$f7,	$f7	#X^2
	add.s	$f11,	$f6,	$f5	#x^2 + y^2 = c^2
	sqrt.s	$f7,	$f11		#sqrt(c^2)
	l.s	$f8,	mobFireTrigger
	cvt.s.w	$f10,	$f8	#convert int to float
	div.s	$f9,	$f7,	$f10	#c/156
	l.s	$f4,	mobBulletSpeed
	add.s	$f11,	$f9,	$f4	#c + bullet speed
	#mov.s	$f4,	$f5	#Move new x to $f4
	mul.s	$f5,	$f11,	$f11	#c^2
	#mul.s	$f6,	$f4,	$f4	#x^2 = (x + bullet speed)^2
	sub.s	$f7,	$f5,	$f6	#c^2 - x^2 = y^2
	sqrt.s	$f8,	$f7		#sqrt(y^2)
	ceil.w.s	$f0,	$f8	#Take the ceiling of sqrt(y^2) = y
	mfc1	$t8,	$f0	#floor(sqrt(y^2) = mobBulletY
	la	$t0,	mobBulletPath
	addu	$t0,	$t0,	$t2	#adjust to mob position in mem
	sw	$t9,	($t0)		#Save mob bullet change in x
	bgez	$t8,	normStore	#Check if the y value returned is negative
	mul	$t8,	$t8,	-1	#Make sure that y is always positive 
normStore:
	sw	$t8,	4($t0)		#Save mob bullet change in y
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	4
	
	#Return to caller
	jr	$ra

#End Next position for mob bullet
##################################

##################################
#Start Draw Mob Fire
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#$a0 = x-coord of life
#$a1 = y-coord of life
#$a2 = color number (0-7)
#Returns:
#None
#Uses:
#Variables:
#mobRow1Pos
#mobFired
#shipPosX
#shipPosY
#Routines:
#DrawMobBullet
MobFire:
	#Save return address
	addiu	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	
	#Determine which mobs are firing
	#Update mobFired tracker
	#jal	WhichMobsFire	

	#Setup arguments
	la	$t0,	mobRow1Pos	#load mob base address
	la	$t7,	mobFired
	li	$t9,	0
	
#Draw Mob bullet
mobBulLoop:
	sw	$t0,	4($sp)
	sw	$t7,	8($sp)
	sw	$t9,	12($sp)
	lw	$t8,	($t7)	#load next mob fired tracker value
	blez	$t8,	checkMobBulLoop	#skip mob if tracker value = 0; execute loop if value = 1
	
	#save bullet origin x, y
	sll	$t1,	$t9,	3	#calculate mob offset
	addu	$t2,	$t0,	$t1	#calculate mob address
	la	$t0,	mobBullets	#Load mob bullet base address
	lw	$t1,	mobBulletsFired	#load number of bullets fired
	sw	$t1,	16($sp)		#Save the value of mobBulletsFired to update later
	sll	$t4,	$t1,	3	#calculate mob bullet offset
	addu	$t0,	$t0,	$t4	#calculate bullet mem address
	lw	$t3,	0($t2)	#load mob x
	sw	$t3,	0($t0)	#save as bullet origin x
	lw	$t3,	4($t2)	#load mob y
	sw	$t3,	4($t0)	#save as bullet origin y

	#restore arguments
	lw	$t0,	4($sp)
	lw	$t7,	8($sp)
	lw	$t9,	12($sp)
	
	#Load mob position
	lw	$a0,	($t0)	#mob x
	lw	$a1,	4($t0)	#mob y
	#store current mob and tracker positions
	sw	$t0,	4($sp)
	sw	$t7,	8($sp)
	sw	$t9,	12($sp)
	move	$a2,	$t9	#copy the mob number to pass to DrawMobBullet
	#jal	DrawMobBullet
	
	#Play sound when mob fires
	li	$a0,	1	#mob bullet sound
	jal	BulletMidi
	
	lw	$t0,	4($sp)
	lw	$t7,	8($sp)
	lw	$t9,	12($sp)
	#Calculate mob bullet path
	lw	$a0,	($t0)	#mob x
	lw	$a1,	4($t0)	#mob y
	move	$a2,	$t9	#copy the mob number to calculate the bullet trajectory
	jal	MobBulletPath
	
	#Update mob bullets fired
	lw	$t1,	16($sp)		#load mobBulletsFired value from stack
	addiu	$t1,	$t1,	1	#increment mob bullets fired
	sw	$t1,	mobBulletsFired	#save the new value of mobBulletsFired
	
	#restore current mob and tracker positions
	lw	$t0,	4($sp)
	lw	$t7,	8($sp)
	lw	$t9,	12($sp)
	
checkMobBulLoop:
	addiu	$t7,	$t7,	4	#update to next mob fired tracker
	addiu	$t9,	$t9,	1	#increment iterator
	addiu	$t0,	$t0,	8	#update to next mob location
	blt	$t9,	10,	mobBulLoop

mobBulletEnd:	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Draw Mob Fire
##################################

##################################
#Start Clear Mob
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#$a0 = x-coord of mob
#$a1 = y-coord of mob
#Returns:
#None
#Uses:
#Variables:
#mobSize
#Routines:
#DrawBox
ClearMob:
	#Save return address
	addiu	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	
	#Setup arguments
	sw	$a0,	4($sp)
	sw	$a1,	8($sp)
	li	$a2,	0
	sw	$a2,	12($sp)
	
#Draw Ship bullet
	#Draw bullet tip	
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	12($sp)
	lw	$a3,	mobSize
	jal	DrawBox

	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Clear Ship bullet
##################################

##################################
#Start Ship Fire collision detection
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#None
#Variables used:
#bullets
#mobR1DetLines
#mobSize
ShipFireColDet:
	#Save return address
	addiu	$sp,	$sp,	-28
	sw	$ra,	0($sp)
	
	#Check if any ship bullets have been fired
	lw	$t8,	bulletsFired
	blez	$t8,	shipBulDetEnd
	
	#Setup variables used
	la	$t1,	mobR1DetLines
	
	#setup iterator
	li	$t9,	0
	
shipToMobLoop:
	#setup iterator
	li	$t7,	0
	
	#Setup variables used
	la	$t0,	bullets
	
shipFireDetOLoop:
	sw	$t0,	4($sp)
	sw	$t1,	8($sp)
	lw	$t2,	4($t0)	#bullet y
	lw	$t3,	4($t1)	#mob y
	ble	$t2,	$t3,	shipFireDetILoop		#if bulY <= mobY then ILoop, else next bullet
	j	shipFireDetILoopEnd

	shipFireDetILoop:
		lw	$t0,	4($sp)
		lw	$t1,	8($sp)	
		lw	$t2,	($t0)	#bullet x
		lw	$t3,	($t1)	#mob x
		bge	$t2,	$t3,	shipFireLikelyCol	#if bulX >= mobX then likely col, else end iloop
		j	shipFireDetILoopEnd
		
			shipFireLikelyCol:
				lw	$t4,	mobSize
				addu	$t3,	$t3,	$t4	#Check rightmost bound of the mob x
				ble	$t2,	$t3,	shipBulCol	#if bulX  <= mobX then collision; else go to iloop end
				j	shipFireDetILoopEnd
					
					shipBulCol:
						#load bullet data
						lw	$a0,	($t0)	#bullet x
						lw	$a1,	4($t0)	#bullet y
						sw	$t0,	4($sp)	#store bullet address
						sw	$t1,	8($sp)	#store mob address
						jal	ClearShipBullet	#cleat bullet
						#update bullets fired and loop iterator
						lw	$t0,	4($sp)
						move	$a0,	$t0
						move	$a1,	$t9
						sw	$t0,	4($sp)	#store bullet address
						jal	RemoveShipBullet
						lw	$t0,	bulletsFired
						addiu	$t0,	$t0,	-1
						sw	$t0,	bulletsFired
						addiu	$t9,	$t9,	-1
						lw	$t0,	4($sp)
						addiu	$t0,	$t0,	-8
						sw	$t0,	4($sp)
						#Load mob data
						lw	$t0,	8($sp)	#mob address
						lw	$a0,	($t0)	#mob x
						lw	$a1,	4($t0)	#mob y
						#adjust y coord to mob y origin
						lw	$t5,	mobSize
						subu	$a1,	$a1,	$t5
						sw	$t0,	8($sp)	#store mob address
						jal	ClearMob
						#Update how many mobs are on the screen
						lw	$t5,	mobLives
						addiu	$t5,	$t5,	-1
						sw	$t5,	mobLives
						#fall through to end of iloop

	shipFireDetILoopEnd:
	addiu	$t1,	$t1,	8	#increment to next mob address
	addiu	$t7,	$t7,	1	#increment mob iterator
	blt	$t7,	10,	shipFireDetOLoop		#if mob iterator < max mob then Oloop, else ixit this loop
	#Fall through to oloop

lw	$t0,	4($sp)
lw	$t1,	8($sp)
addiu	$t0,	$t0,	8	#increment to next bullet address
lw	$t8,	bulletsFired	#load total bullets fired
addiu	$t9,	$t9,	1	#increment oloop iterator
blt	$t9,	$t8,	shipToMobLoop		#if iterator < total bullets fired then oloop, else exit
#fall through to oloop end
	
shipBulDetEnd:
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	28
	
	#Return to caller
	jr	$ra

#End Ship Fire collision detection
##################################

##################################
#Start Draw Mob Line
#This routine is called from Main to setup the game with the inital mobs to fight
#Takes arguments: 
#$a0 = mob storage base address
#$$a1 = line head x coord
#$a2 = line head y coord
DrawMobLine:
	#Save return address
	addiu	$sp,	$sp,	-32
	sw	$ra,	0($sp)
	
	#save arguments
	sw	$a0,	24($sp)	#address location of where to store the mob x, y coords
	
	#setup collision detection
	la	$t7,	mobR1DetLines
	sw	$t7,	28($sp)
	
	#Intialize iterator
	li	$t9,	0
	
	#Setup arguments
	move	$a0,	$a1	#Move x co[ord to $a0
	move	$a1,	$a2	#Move y coord to a1
	la	$t0,	mobColors	#setup mob color
	lw	$a2,	4($t0)	#load mob color
	lw	$a3,	mobSize	#load mob size
mobDrawLoop:
	#store arguments
	sw	$a0,	4($sp)	#x
	sw	$a1	8($sp)	#y
	sw	$a2,	12($sp)	#color
	sw	$a3,	16($sp)	#size
	sw	$t9,	20($sp)	#iterator
	jal	DrawBox
	#restore arguments
	lw	$a0,	4($sp)
	lw	$a1	8($sp)
	lw	$a2,	12($sp)
	lw	$a3,	16($sp)
	lw	$t9,	20($sp)
	lw	$t8,	24($sp)	#load mob storage location
	sw	$a0,	($t8)	#save mob x coord
	sw	$a1,	4($t8)	#save mob y coord
	addiu	$t8,	$t8,	8	#increment address to next mob storage location
	sw	$t8,	24($sp)	#store next mob storage location
	lw	$t7,	28($sp)	#load mob detection storage location
	addu	$t0,	$a1,	$a3	#adjust y coord to bottom of mob; y + mobSize = detection y
	sw	$a0,	0($t7)	#save detection x coord
	sw	$t0,	4($t7)	#save detection y coord
	addiu	$t7,	$t7,	8	#increment address to next mob detection location
	sw	$t7,	28($sp)	#store new mob detection storage location
	addiu	$t9,	$t9,	1	#increment iterator
	addiu	$a0,	$a0,	-45	#decrement x coord
	blt	$t9,	10,	mobDrawLoop

	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	32
	
	#Return to caller
	jr	$ra

#End Draw Mob Line
##################################

##################################
#Start Update ship fire
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#None
#Returns:
#None
#Uses:
#Variables:
#bulletsFired
#shipBulletSpeed
#bullets
#upperBound
#Routines:
#DrawShipBullet
UpdateShipFire:
	#Save return address
	addiu	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	
	#Check to see if any bullets need to be updated
	lw	$t0,	bulletsFired
	blez	$t0,	updateShipBulEnd
	li	$t0,	0
	
	#Setup arguments
	la	$t9,	bullets
	
#Draw Ship bullets
updateShipBulLoop:
	#addiu	$t0,	$t0,	-1	
	sll	$t0,	$t0,	3
	addu	$t9,	$t9,	$t0
	lw	$a0,	0($t9)	#load current bullet x coord
	lw	$a1,	4($t9)	#load current bullet y coord
	sw	$t9,	4($sp)	#store bullet address
	sw	$t0,	8($sp)	#store current bullet number 
	jal	ClearShipBullet
	lw	$t9,	4($sp)	#load bullet address
	lw	$t0,	8($sp)	#load current bullet number
	lw	$a0,	0($t9)	#load current bullet x coord
	lw	$a1,	4($t9)	#load current bullet y coord
	lw	$t8,	bulletSpeed	#Get change in y
	subu	$a1,	$a1,	$t8	#Update bullet y coord
	#Check if ship bullet has reached top of screen
	lw	$t7,	upperBound
	blt	$a1,	$t7,	clearShipBul	
	#redraw bullet if it hasn't reach the top of the screen
	sw	$a1,	4($t9)	#Save new y coord for bullet
	sw	$t0,	4($sp)	#store current bullet number
	sw	$t9,	8($sp)	#store bullets address
	sw	$a0,	12($sp)	#store x coord
	sw	$a1,	16($sp)	#store y coord
	jal	DrawShipBullet
	lw	$t0,	4($sp)	#Load current bullet number
	lw	$t9,	8($sp)	#load bullets address
	addiu	$t0,	$t0,	1	#increment counter till all bullets are updated
	lw	$t1,	bulletsFired
	blt	$t0,	$t1,	updateShipBulLoop
	j	updateShipBulEnd
	
clearShipBul:
	move	$a0,	$t9	#set a0 to bullet address 
	move	$a1,	$t0	#set a1 to the number of the current bullet
	jal	RemoveShipBullet
	
updateShipBulEnd:	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Update ship fire
##################################

##################################
#Start Remove Ship Bullet
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#$a0 = bullet address
#$a1 = which bullet to remove
#Returns:
#None
#Uses:
#Variables:
#bulletsFired
#Routines:
#DrawShipBullet
RemoveShipBullet:
	#Save return address
	addiu	$sp,	$sp,	-8
	sw	$ra,	0($sp)
	sw	$a1,	4($sp)
	
	#move argument to temp register
	move	$t9,	$a0	#bullet mem address
	move	$t0,	$a1	#bullet number
	sll	$t1,	$t0,	3	#calc bullet offset
	addu	$t9,	$t9,	$t1	#calc bullet mem address
	
	#Setup loop constraints
	lw	$t8,	maxShipBullets
	addiu	$t8,	$t8,	-2	#Adjust loop iteration to exclude the final bullet slot

updateBulletsFired:
	lw	$t3,	8($t9)	#Load next bullet x coord 
	lw	$t4,	12($t9)	#load next bullet y coord
	seq	$t5,	$t3,	0	#check if bullet x = 0, $t5 = 1 if zero, 0 otherwise
	seq	$t6,	$t4,	0	#check if bullet y = 0, $t6 = 1 if zero, 0 otherwise
	addu	$t5,	$t5,	$t6	#If both x and y are zero ($t5 = 2), nothing more to do, skip to end
	beq	$t5,	2,	removeShipBulletEnd
	sw	$t3,	0($t9)	#move to current bullet x coord
	sw	$t4,	4($t9)	#move to current bullet y coord
	addiu	$t0,	$t0,	1	#increment iterator
	addiu	$t9,	$t9,	8	#move current bullet address to next bullet
	blt	$t0,	$t8,	updateBulletsFired
	#Set final bullet spot back to (0, 0) for x, y pair
	sw	$0,	0($t9)	#reset last bullet slot x coord to 0
	sw	$0,	4($t9)	#reset last bullet slot y coord to 0
	lw	$t0,	bulletsFired
	addiu	$t0,	$t0,	-1
	sw	$t0,	bulletsFired

removeShipBulletEnd:	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	8
	
	#Return to caller
	jr	$ra

#End Remove Ship Bullet
##################################

##################################
#Start Draw Ship Fire
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#$a0 = x-coord of ship
#$a1 = y-coord of ship
#$a2 = color number (0-7)
#Returns:
#None
#Uses:
#Variables:
#bulletsFired
#shipPosX
#shipPosY
#shipBulletColor1
#shipBulletColor2
#bulletTipLen
#bulletBodyLen
#bullets
#Routines:
#DrawTurret
ShipFire:
	#Save return address
	addiu	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	
	#Update bullet fired tracker
	lw	$t9,	bulletsFired
	addiu	$t9,	$t9,	1
	
	#check if all bullets have been fired
	lw	$t8,	maxShipBullets
	bgt	$t9,	$t8,	skipShipBullet
	#save updated tracker if max not reached
	sw	$t9,	bulletsFired
	
	#Setup arguments
	lw	$a0,	shipPosX
	lw	$a1,	shipPosY
	lw	$t0,	shipSize
	srl,	$t0,	$t0,	1
	subu	$a1,	$a1,	$t0
	sw	$a0,	4($sp)
	sw	$a1,	8($sp)
	sw	$t9,	12($sp)
	
#Draw Ship bullet
	jal	DrawShipBullet
	
	li	$a0,	0
	jal	BulletMidi
	
	#Update bullet fired (X, Y) coords
	lw	$a0,	4($sp)	#Load ship X coord
	lw	$a1,	8($sp)	#Load ship Y coord
	lw	$t9,	12($sp)	#Load the number of bullets fired
	la	$t8,	bullets	#Load bullets base address
	addiu	$t9,	$t9,	-1	#Adjust the number of bullets to account for starting at 0
	sll	$t0,	$t9,	3	#multiply the number of bullets * 8
	addu	$t8,	$t8,	$t0	#Add bullet (num - 1) * 8 to bullet base address
	sw	$a0,	0($t8)		#Store the ship x coord to the bullet # x coord
	sw	$a1,	4($t8)		#Store the ship y coord to the bullet # y coord

skipShipBullet:	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Draw Ship Fire
##################################

##################################
#Start Draw Ship bullet
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#$a0 = x-coord of bullet
#$a1 = y-coord of bullet
#Returns:
#None
#Uses:
#Variables:
#None
#Routines:
#DrawTurret
DrawShipBullet:
	#Save return address
	addiu	$sp,	$sp,	-12
	sw	$ra,	0($sp)
	
	#save arguments
	sw	$a0,	4($sp)
	sw	$a1,	8($sp)
	
#Draw Ship bullet
	#Draw bullet tip	
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	shipBulletColor1
	lw	$a3,	bulletTipLen
	jal	DrawTriUp
	
	#Draw bullet tail
	lw	$a0,	4($sp)
	lw	$a1,	8($sp)
	lw	$a2,	shipBulletColor2
	lw	$a3,	bulletBodyLen
	srl	$t0,	$a3,	4
	addu	$a1,	$a1,	$t0
	jal	VertLine

	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	12
	
	#Return to caller
	jr	$ra

#End Draw Ship bullet
##################################

##################################
#Start Clear Ship bullet
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#$a0 = x-coord of bullet
#$a1 = y-coord of bullet
#Returns:
#None
#Uses:
#Variables:
#None
#Routines:
#DrawTurret
ClearShipBullet:
	#Save return address
	addiu	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	
	#Setup arguments
	sw	$a0,	4($sp)
	sw	$a1,	8($sp)
	li	$a2,	0
	sw	$a2,	12($sp)
	
#Draw Ship bullet
	#Draw bullet tip	
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	12($sp)
	lw	$a3,	bulletTipLen
	jal	DrawTriUp
	
	#Draw bullet tail
	lw	$a0,	4($sp)
	lw	$a1,	8($sp)
	lw	$a2,	12($sp)
	lw	$a3,	bulletBodyLen
	srl	$t0,	$a3,	4
	addu	$a1,	$a1,	$t0
	jal	VertLine

	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Clear Ship bullet
##################################

##################################
#Start Setup Lives
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#$a0 = x-coord of life
#$a1 = y-coord of life
#$a2 = color number (0-7)
#Returns:
#None
#Uses:
#Variables:
#None
#Routines:
#DrawShip
SetupLives:
	#Save return address
	addiu	$sp,	$sp,	-12
	sw	$ra,	0($sp)
	
	#Setup first life to iterate through
	la	$t9,	life1
	#Setup iterator
	li	$t8,	0
	
	#Draw lives
livesLoop:
	lw	$a0,	0($t9)
	lw	$a1,	lifeY
	lw	$a2,	shipColor
	sw	$t9,	4($sp)
	sw	$t8,	8($sp)
	jal	DrawLife
	lw	$t9,	4($sp)
	lw	$t8,	8($sp)
	addiu	$t9,	$t9,	4
	addiu	$t8,	$t8,	1
	blt	$t8,	3,	livesLoop
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	12
	
	#Return to caller
	jr	$ra

#End Setup Lives
##################################

##################################
#Start Draw Life
#This routine is called from Main to setup the game with a life in the bottom left corner of the screen.
#Takes arguments: 
#$a0 = x-coord of life
#$a1 = y-coord of life
#$a2 = color number (0-7)
#Returns:
#None
#Uses:
#Variables:
#None
#Routines:
#DrawShip
DrawLife:
	#Save return address
	addiu	$sp,	$sp,	-4
	sw	$ra,	0($sp)
	
	#Draw ship to represent a life
	jal	DrawShip
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	4
	
	#Return to caller
	jr	$ra

#End Draw Life
##################################

##################################
#Start Call Keyboard Input Routine
#This routine is called from Main when keyCount is greater than 0.
#It will adjust the ship's horizontal position according to the direction key pressed,
#a for left and d for right, and will call the ShipFire routine if they pressed the space bar.
#If the player presses the escape key, it will exit the game.
#If the user enters an invalid key this routine will ignore it and exit or move to the next
#key in the queue.
#Takes arguments: 
#None
#Returns:
#None
#Uses:
#Variables:
#shipPosX
#shipPosY
#shipPosXNew
#Routines:
#Exit
#ShipFire Routine
CallKey:
	addiu	$sp,	$sp,	-4
	sw	$ra,	0($sp)
	oLoop:
	lw	$t9,	keyCount
	bgtz	$t9,	iLoop
	nop
	j	oLoop
	iLoop:
	#lw	$t9,	12($sp)
	addiu	$t9,	$t9,	-1
	sw	$t9,	keyCount
	lw	$t0,	queueTracker
	addiu	$t0,	$t0,	-4
	lw	$t1,	($t0)
	sw	$t0,	queueTracker
	beq	$t1,	'q',	gameEnd
	beq	$t1,	32,	callFire
	beq	$t1,	'a',	moveLeft
	beq	$t1,	'd',	moveRight
	bgtz	$t9,	iLoop
	j	keyEnd

gameEnd:
	jal	Exit

moveLeft:
	lw	$a0,	shipPosXNew
	addiu	$a0,	$a0,	-8
	blt	$a0,	25,	keyEnd
	sw	$a0,	shipPosXNew
	j	keyEnd

moveRight:
	lw	$a0,	shipPosXNew
	addiu	$a0,	$a0,	8
	bgt	$a0,	487,	keyEnd
	sw	$a0,	shipPosXNew
	j	keyEnd

callFire:
	lw	$t0,	maxShipBullets
	lw	$t1,	bulletsFired
	bge	$t1,	$t0,	keyEnd
	lw	$a0,	shipPosX
	lw	$a1,	shipPosY
	jal	ShipFire
	
keyEnd:
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	4
	
	#Return to caller
	jr	$ra

#End Call Keyboard Input Routine
##################################

##################################
#Start Update Ship Position
#This routine is called from Main when the ship horizontal position has changed.
#It will adjust the ship's horizontal position according to the direction key pressed.
#Takes arguments: 
#None
#Returns:
#None
#Uses:
#Variables:
#shipPosX
#shipPosY
#shipPosXNew
#Routines:
#DrawShip
UpdateShip:
	#Save return address
	addiu	$sp,	$sp,	-4
	sw	$ra,	0($sp)
	
	#undraw ship
	lw	$a0,	shipPosX
	lw	$a1,	shipPosY
	li	$a2,	0
	jal	DrawShip
	
	#Draw ship in new position
	lw	$a0,	shipPosXNew
	lw	$a1,	shipPosY
	lw	$a2,	shipColor
	jal	DrawShip
	
	#update current ship position with new position
	lw	$t0,	shipPosXNew
	sw	$t0,	shipPosX
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	4
	
	#Return to caller
	jr	$ra

#End Update Ship Position
##################################

##################################
#Start Print Character Routine
#Takes arguments: 
#$a0 = address of the String to print
#Returns nothing
PrChar:	
	#Print String
	#String to char is already in $a0
	li	$v0,	11	#Load Print String Service
	syscall			#Print String
	
	#Return to caller
	jr	$ra

#End Print Character Routine
##################################

##################################
#Start Print String Routine
#Takes arguments: 
#$a0 = address of the String to print
#Returns nothing
PrStr:	
	#Print String
	#String to print is already in $a0
	li	$v0,	4	#Load Print String Service
	syscall			#Print String
	
	#Return to caller
	jr	$ra

#End Print String Routine
##################################

##################################
#Start Get User Input Routine
#Returns: 
#$v0 = user input (int)
#Uses ClrDsply Routine
#Uses PrStr Routine
GetUserInput:
	#Save original return address in case it is overwritten
	addi	$sp,	$sp,	-4
	sw	$ra,	0 ($sp)
	
	#Old user input
	#Get user input
	la	$a0,	usrInput		#Load address to Get User Input String
	jal	PrStr			#Call Print String Routine
	li	$v0,	5		#Load Read Integer Service
	syscall				#Get Integer
	
	#save user input
	move	$t0,	$v0

	
	#clear screen
	#jal	ClrDsply
	
	#Restore user input for return
	move	$v0, $t0
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	4
	
	#Return to caller
	jr	$ra

#End Get User Input Routine
##################################

##################################
#Start Choose Difficulty Routine
#Takes arguments: 
#$a0 = address String to print
#Returns:
#$v0 = user Difficulty chioce
#Uses PrStr Routine
#Uses GetUserInput Routine
ChooseDiff:
	#Save original return address in case it is overwritten
	addi	$sp,	$sp,	-4
	sw		$ra,	0 ($sp)
	
	#Get user Difficulty choice
	#String to print is already in $a0
	jal	PrStr
	#Get user choice
	jal	GetUserInput
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	4
	
	#Return to caller
	jr	$ra

#End Choose Difficulty Routine
##################################

##################################
#Start Get Difficulty Specifications
#Takes arguments: 
#$a0 = difficulty level
#Returns:
#$v0 = Max loop count (int)
#$v1 = wait time 
GetDiffSpecs:
	#Save original return address and other variables in case it is overwritten
	addi	$sp,	$sp,	-20
	sw	$ra,	0 ($sp)
	sw	$t0,	-4 ($sp)
	sw	$t6,	-8 ($sp)
	sw	$t7,	-12 ($sp)
	sw	$t8,	-16 ($sp)
	
	#Copy arguments to temp registers
	move	$t0,	$a0
	
	#Load Difficulty values
	li	$t6,	1
	li	$t7,	2
	li	$t8,	3
	
	#Set upper bound based on difficulty
	beq	$t0,	$t6,	Easy	
	beq	$t0,	$t7,	Normal
	beq	$t0,	$t8,	Hard
	
	#Create random number
Easy:
	li	$v0,	5
	li	$v1,	2000	#Milliseconds to wait between printing the sequence
	j	ReturnDiff
	
Normal:
	li	$v0,	8
	li	$v1,	1000	#Milliseconds to wait between printing the sequence
	j	ReturnDiff
	
Hard:	
	li	$v0,	11
	li	$v1,	500	#Milliseconds to wait between printing the sequence
	#Will fall through to ReturnDiff. This is intentional

ReturnDiff:
	#Save original return address and other variables in case it is overwritten
	sw	$ra,	0 ($sp)
	sw	$t0,	4 ($sp)
	sw	$t6,	8 ($sp)
	sw	$t7,	12 ($sp)
	sw	$t8,	16 ($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Get Difficulty Specifications
##################################

##################################
#Start Calculate Address 
#from (X, Y) Cooredinate Pair
#$a0 = x-coordinate (0-1023)
#$a1 = x-coordinate (0-1023)
#Returns $v0 = memory address
#Uses baseAddr variable
CalcAddr:
	#$v0 = base + $a0*4 + $a1*512*4
	lw	$v0, 	baseAddr		#Load the address of the base 
	sll	$a0,	$a0,	2	#Multiply $a0 by 4 - x coordinate by 4 to amtch memory addressing
	sll	$a1,	$a1,	11	#Multiply $a1 by 512*4 = 2048 = 2^11 - shift address for each change in y
	add	$v0,	$v0,	$a0	#Add $a0 to $v0 - add x-coord to base mem addr.
	add	$v0,	$v0,	$a1	#Add $a1 to $v0 - add y-coord to base addr. + x-coord
	#$v0 now holds the calculated address to be returned
	
	#Return to caller
	jr $ra
#End Calculate Address
##################################	

##################################	
#Start Lookup Color Number
#$a2 = color number (0-7) 
#Returns $v1 = actual number to write to the display
#Uses ColorTable variable
GetColor:
	la	$t0,	ColorTable	#load base
	sll	$a2,	$a2,	2	#Multiply index by 4
	add	$a2,	$a2,	$t0	#add base plus index offset
	lw	$v1,	0 ($a2)		#get actual color from memory

	#Return to caller
	jr	$ra
#End Lookup Color Number
##################################	

##################################	
#Start Draw a Dot
#$a0 = x coordinate (0-31)
#$a1 = y coordinate (0-31)
#$a2 = color number (0-7)
DrawDot:
	addiu	$sp,	$sp,	-8	#make room on the stack, 2 words
	sw	$ra,	4 ($sp)	#store$ra
	sw	$a2,	0 ($sp)	#store $a2
	
	jal	CalcAddr		#$v0 has address for pixel
	lw	$a2,	0 ($sp)	#restore $a2
	sw	$v0,	0 ($sp)	#save $v0
	
	jal	GetColor		#$v1 has color
	lw	$v0,	0 ($sp)	#restore $v0
	
	sw	$v1,	0 ($v0)	#make dot
	lw	$ra,	4 ($sp)	#load original $ra
	addiu	$sp,	$sp,	8	#adjust $sp
	
	#Return to caller
	jr	$ra
#End Draw a Dot
##################################

##################################
#Start Draw Horizxontoal Line
##$a0 = x coordinate (0-31)
#$a1 = y coordinate (0-31)
#$a2 = color number (0-7)
#$a3 = length of the line (1-32)
HorzLine:
	#create stack frame / save $ra, could store $a1, $a2 here
	addiu	$sp,	$sp,	-20	#make room on the stack, 5 words
	sw	$ra,	16 ($sp)	#store $ra
	sw	$a2,	12 ($sp)	#store $a2
	sw	$a1,	8 ($sp)	#store $a1
	
HorzLoop:
	#store a registers 
	sw	$a3,	4 ($sp)	#store $a3
	sw	$a0,	0 ($sp)	#store $a0
	jal	DrawDot	#Draw the dot on the bitmap display
	#restore a registers
	lw	$a0,	0 ($sp)	#restore $a0
	lw	$a3,	4 ($sp)	#restore $a3
	lw	$a1,	8 ($sp)	#restore $a1
	lw	$a2,	12 ($sp)	#restore $a2
	#Perform loop calclulations
	addi	$a0,	$a0,	1	#increment x coordinate ($a0)
	addi	$a3,	$a3,	-1	#Decrement line left to draw ($a3)
	bne	$a3,	$0,	HorzLoop
	
	#restore $ra
	lw	$ra,	16 ($sp)	#store $ra
	addiu	$sp,	$sp,	20	#restore the stack, 5 words
	
	#Return to caller
	jr	$ra
#End Draw Horizxontoal Line
##################################

##################################
#Start Draw Vertical Line
##$a0 = x coordinate (0-31)
#$a1 = y coordinate (0-31)
#$a2 = color number (0-7)
#$a3 = length of the line (1-32)
VertLine:
	#create stack frame / save $ra, could store $a0, $a2 here
	addiu	$sp,	$sp,	-20	#make room on the stack, 5 words
	sw	$ra,	16 ($sp)	#store $ra
	sw	$a2,	12 ($sp)	#store $a2
	sw	$a0,	8 ($sp)	#store $a0
VertLoop:
	#store a registers 
	sw	$a3,	4 ($sp)	#store $a3
	sw	$a1,	0 ($sp)	#store $a1
	jal	DrawDot
	#restore a registers
	lw	$a1,	0 ($sp)	#restore $a1
	lw	$a3,	4 ($sp)	#restore $a3
	lw	$a0,	8 ($sp)	#restore $a0
	lw	$a2,	12 ($sp)	#restore $a2
	
	#Perform loop calclulations
	addi	$a1,	$a1,	1	#increment y coordinate ($a1)
	addi	$a3,	$a3,	-1	#Decrement line left to draw ($a3)
	bne	$a3,	$0,	VertLoop
	
	#restore $ra
	lw	$ra,	16 ($sp)	#restore $ra
	addiu	$sp,	$sp,	20	#restore the stack, 5 words
	
	#Return to caller
	jr	$ra
#End Draw Vertical Line
##################################

##################################
#Start Clear Display
ClearDisp:
	#create stack frame / save $ra
	addiu	$sp,	$sp,	-4	#make room on the stack
	sw	$ra,	0 ($sp)	#store $ra
	
	li	$a3,	0
		
	#start at 0,0 (a0=0, a1=0)
	move	$a0,	$0
	move	$a1,	$0
	#set color to black
	move	$a2,	$0		
	#Full screen size (a0=1023, a1=1023)
	addiu	$a3,	$a3,	511
	
	jal DrawBox
	
	#restore $ra
	lw	$ra,	0 ($sp)	#store $ra
	addiu	$sp,	$sp,	4	#make room on the stack
	
	#Return to caller
	jr	$ra
#End Clear Display
##################################

##################################
#Start Circle Color
#$a0 = number from sequence
#$a1 = Clear
#Returns $v1 = returns circle color number
#Uses GetColor Routine
CircColor:
	#create stack frame / save $ra
	addiu	$sp,	$sp,	-4	#make room on the stack
	sw	$ra,	0 ($sp)		#store $ra
	
	#Check to see if clear bit is set
	beq	$a1,	1,	clearCircl	#Skip other color checks if clear bit is set
	
	#Select which quadrant the box should be in
	beq	$a0,	1,	topCircle	
	beq	$a0,	2,	leftCircle
	beq	$a0,	3,	rightCircle
	beq	$a0,	4,	botCircle
	#jal	ErrOccurred
	
#[0] - black
#[1] - blue
#[2] - green
#[3] - red
#[4] - blue + green = Cyan
#[5] - blue + red = Magenta
#[6] - green + red = Orange
#[7] - white

#Select the correct color for the quadrant the box will be in
topCircle:	#Orange
	li	$v1,	6
	j	CircColorEnd
	
leftCircle:	#Blue
	li	$v1,	1
	j	CircColorEnd

rightCircle:	#Red
	li	$v1,	3
	j	CircColorEnd

botCircle:	#Green
	li	$v1,	2
	j	CircColorEnd

#Set color to black if clear bit is set
clearCircl:	#Black
	li	$v1,	0
	j	CircColorEnd

CircColorEnd:
	#$v1 will hold the box color number
	#restore $ra
	lw	$ra,	0 ($sp)	#store $ra
	addiu	$sp,	$sp,	4	#make room on the stack
	
	#Return to caller
	jr	$ra

#End Circle Color
##################################

##################################
#Start Draw circle
#Draw a circle based on the center (X,Y) provided in arguments (a0, a1) 
#This will be implemented using the midpoint circle algorithm 
#from https://en.wikipedia.org/wiki/Midpoint_circle_algorithm 
#Modified using the example from OpenGenus(https://iq.opengenus.org/bresenhams-circle-drawing-algorithm/)
#Based on code from DazedFury - StackExchange(https://stackoverflow.com/questions/53247462/mips-midpoint-circle-algorithm)
#$a0 = x-center
#$a1 = y-center
#$a2 = color number (0-7)
#a3 = radius of the circle - if used
#Uses:
#HorzLine Routine
DrawCircle:
	#Make room on the stack / save $ra
	addi	$sp, $sp, -20	#Make room on stack for 1 words
	sw	$ra, 0($sp)	#Store $ra on element 0 of stack
	sw	$a0, 4($sp)	#Store $a0 on element 1 of stack
	sw	$a1, 8($sp)	#Store $a1 on element 2 of stack
	sw	$a2, 12($sp)	#Store $a2 on element 3 of stack
	sw	$a3, 16($sp)	#Store $a3 on element 4 of stack

	#Move arguments to temp registers
	move	$t0,	$a0		#xc
	move	$t1,	$a1		#yc
	move	$t2,	$a3		#radius
	

#Start Do While (r > 0)
circleOutLoop:
	li	$t3,	0		#x
	move	$t4,	$t2		#y = r  to setup (0, r)
	li	$t5,	0		#dx
	li	$t6,	0		#dy
	li	$t7,	0		#Radius Error (Err) = E
	li	$t9,	3		#Initially used to compute E in $t7
	
	#Calculate E = 3 - 2r
	sll	$t8, $t2, 1	#$t8 = 2r
	subu	$t7, $t9, $t8	#E = 3 -2r, initial E value
	
#Start While loop
	#While(y >= x)
circleLoop:
	blt	$t4, $t3, endCircleLoop	#If y < x, exit loop
	
	#Save temp registers to be restored after each function call
	addiu	$sp,	$sp,	-40
	sw	$t0,	0 ($sp)
	sw	$t1,	4 ($sp)
	sw	$t2,	8 ($sp)
	sw	$t3,	12 ($sp)
	sw	$t4,	16 ($sp)
	sw	$t5,	20 ($sp)
	sw	$t6,	24 ($sp)
	sw	$t7,	28 ($sp)
	sw	$t8,	32 ($sp)
	sw	$t9,	36 ($sp)

	#Draw Dot (xc + x, yc + y)
	addu	$a0, $t0, $t3	#xc + x
	addu	$a1, $t1, $t4	#yc + y
	lw	$a2, 52($sp)	#restore color number
	li	$a3,	2
	jal	HorzLine		#Call Horizontral Line
	#Restore temp registers 
	lw	$t0,	0 ($sp)
	lw	$t1,	4 ($sp)
	lw	$t2,	8 ($sp)
	lw	$t3,	12 ($sp)
	lw	$t4,	16 ($sp)
	lw	$t5,	20 ($sp)
	lw	$t6,	24 ($sp)
	lw	$t7,	28 ($sp)
	lw	$t8,	32 ($sp)
	lw	$t9,	36 ($sp)

	#Draw Dot (xc + y, yc + x)
	addu	$a0, $t0, $t4	#xc + y
	addu	$a1, $t1, $t3	#yc + x
	lw	$a2, 52($sp)	#restore color number
	li	$a3,	2
	jal	HorzLine		#Call Horizontral Line
	#Restore temp registers 
	lw	$t0,	0 ($sp)
	lw	$t1,	4 ($sp)
	lw	$t2,	8 ($sp)
	lw	$t3,	12 ($sp)
	lw	$t4,	16 ($sp)
	lw	$t5,	20 ($sp)
	lw	$t6,	24 ($sp)
	lw	$t7,	28 ($sp)
	lw	$t8,	32 ($sp)
	lw	$t9,	36 ($sp)
	
	#Draw Dot (xc - x, yc + y)
	subu	$a0, $t0, $t3	#xc - x
	addu	$a1, $t1, $t4	#yc + y
	lw	$a2, 52($sp)	#restore color number
	li	$a3,	2
	jal	HorzLine		#Call Horizontral Line
	#Restore temp registers 
	lw	$t0,	0 ($sp)
	lw	$t1,	4 ($sp)
	lw	$t2,	8 ($sp)
	lw	$t3,	12 ($sp)
	lw	$t4,	16 ($sp)
	lw	$t5,	20 ($sp)
	lw	$t6,	24 ($sp)
	lw	$t7,	28 ($sp)
	lw	$t8,	32 ($sp)
	lw	$t9,	36 ($sp)

	#Draw Dot (xc - y, yc + x)
	subu	$a0, $t0, $t4	#xc - y
	addu	$a1, $t1, $t3	#yc + x
	lw	$a2, 52($sp)	#restore color number
	li	$a3,	2
	jal	HorzLine		#Call Horizontral Line
	#Restore temp registers 
	lw	$t0,	0 ($sp)
	lw	$t1,	4 ($sp)
	lw	$t2,	8 ($sp)
	lw	$t3,	12 ($sp)
	lw	$t4,	16 ($sp)
	lw	$t5,	20 ($sp)
	lw	$t6,	24 ($sp)
	lw	$t7,	28 ($sp)
	lw	$t8,	32 ($sp)
	lw	$t9,	36 ($sp)

	#Draw Dot (xc - x, yc - y)
	subu	$a0, $t0, $t3	#xc - x
	subu	$a1, $t1, $t4	#yc - y
	lw	$a2, 52($sp)	#restore color number
	li	$a3,	2
	jal	HorzLine		#Call Horizontral Line
	#Restore temp registers 
	lw	$t0,	0 ($sp)
	lw	$t1,	4 ($sp)
	lw	$t2,	8 ($sp)
	lw	$t3,	12 ($sp)
	lw	$t4,	16 ($sp)
	lw	$t5,	20 ($sp)
	lw	$t6,	24 ($sp)
	lw	$t7,	28 ($sp)
	lw	$t8,	32 ($sp)
	lw	$t9,	36 ($sp)

	#Draw Dot (xc - y, yc - x)
	subu	$a0, $t0, $t4	#xc - y
	subu	$a1, $t1, $t3	#yc - x
	lw	$a2, 52($sp)	#restore color number
	li	$a3,	2
	jal	HorzLine		#Call Horizontral Line
	#Restore temp registers 
	lw	$t0,	0 ($sp)
	lw	$t1,	4 ($sp)
	lw	$t2,	8 ($sp)
	lw	$t3,	12 ($sp)
	lw	$t4,	16 ($sp)
	lw	$t5,	20 ($sp)
	lw	$t6,	24 ($sp)
	lw	$t7,	28 ($sp)
	lw	$t8,	32 ($sp)
	lw	$t9,	36 ($sp)

	#Draw Dot (xc + y, yc - x)
	addu	$a0, $t0, $t4	#xc + y
	subu	$a1, $t1, $t3	#yc - x
	lw	$a2, 52 ($sp)	#restore color number
	li	$a3,	2
	jal	HorzLine		#Call Horizontral Line
	#Restore temp registers 
	lw	$t0,	0 ($sp)
	lw	$t1,	4 ($sp)
	lw	$t2,	8 ($sp)
	lw	$t3,	12 ($sp)
	lw	$t4,	16 ($sp)
	lw	$t5,	20 ($sp)
	lw	$t6,	24 ($sp)
	lw	$t7,	28 ($sp)
	lw	$t8,	32 ($sp)
	lw	$t9,	36 ($sp)

	#Draw Dot (xc + x, yc - y)
	addu	$a0, $t0, $t3	#xc + x
	subu	$a1, $t1, $t4	#yc - y
	lw	$a2, 52($sp)	#restore color number
	li	$a3,	2
	jal	HorzLine		#Call Horizontral Line
	#Restore temp registers 
	lw	$t0,	0 ($sp)
	lw	$t1,	4 ($sp)
	lw	$t2,	8 ($sp)
	lw	$t3,	12 ($sp)
	lw	$t4,	16 ($sp)
	lw	$t5,	20 ($sp)
	lw	$t6,	24 ($sp)
	lw	$t7,	28 ($sp)
	lw	$t8,	32 ($sp)
	lw	$t9,	36 ($sp)
	
	#Shrink stack back to previous value
	addiu	$sp,	$sp,	40
	
	#Increment X
	addiu	$t3,	$t3,	1

#Start If/Else Statement
	#E > 0 then E = E + 4(x - y) + 10
	#If (err > 0)
	blez	$t7, else		#Jump to Else if err <= 0
	addi	$t4, 	$t4, 	-1	#y--
	subu	$t8,	$t3,	$t4	#(x - y)
	sll	$t8,	$t8,	2	#4(x - y)
	addiu	$t8,	$t8,	10	#4(x - y) + 10
	addu	$t7, 	$t7, 	$t8	#E = E + 4(x - y) + 10 = $t7 + $t8
	j	circleLoop

	#E <= 0 then E = E + 4x + 6
	#Else (err <= 0)
else:
	sll	$t8,	$t3,	2	#4x
	addiu	$t8,	$t8,	6	#4x + 6
	addu	$t7, 	$t7, 	$t8	#E = E + 4x + 6 = $t7 + $t8
	j	circleLoop	#Skip else stmt / Restart loop

#End inner loop While (y >= x)
endCircleLoop:	 
	#While r > 0
	#Decrement radius to complete the circle
	addiu	$t2,	$t2,	-1
	beqz	$t2,	circleEnd
	#Restart circle loop to draw next circle while r >0
	j	circleOutLoop

#End loop and finish up routine
circleEnd	:
	#restore $ra and the stack
	lw	$ra,	0 ($sp)		#Restore $ra
	addiu	$sp,	$sp,	20	#Restore the stack
	
	#Return to caller
	jr	$ra

#End Draw circle
##################################

##################################
#Start Left to Right Diagonal line
#$a0 = starting x-coord
#$a1 = starting y-coord
#$a2 = color number (0-7)
#$a3 = length of the line
#Uses:
#HorzLine Routine
DrawLTRDiagLine:
	#create stack frame / save $ra
	addiu	$sp,	$sp,	-20	#make room on the stack
	sw	$ra,	0 ($sp)		#store $ra

LeftToRight:
	sw	$a0,	4 ($sp)		#Store a0
	sw	$a1,	8 ($sp)		#Store a1
	sw	$a2,	12 ($sp)		#Store a2
	sw	$a3,	16 ($sp)		#Store a3
	li	$a3,	5		#Load the length of the line into a3; $a3 = 2 hardcoded
	jal	HorzLine			#Draw the line on the bitmap display
	lw	$a0,	4 ($sp)		#Restore a0
	lw	$a1,	8 ($sp)		#Restore a1
	lw	$a2,	12 ($sp)		#Restore a2
	lw	$a3,	16 ($sp)		#Restore a2
	addi	$a0,	$a0,	1	#Decrement the x-coord
	addi	$a1,	$a1,	1	#Increment the y-coord
	addi	$a3,	$a3,	-1	#Decrement length by 1
	bnez	$a3,	LeftToRight	#Exit ones the length has been decremented to 0
	
	#restore $ra
	lw	$ra,	0 ($sp)		#Restore $ra
	addiu	$sp,	$sp,	20	#Restore the stack
	
	#Return to caller
	jr	$ra

#End Left to Right Diagonal line
##################################

##################################
#Start Right to Left Diagonal line
#$a0 = starting x-coord
#$a1 = starting y-coord
#$a2 = color number (0-7)
#$a3 = length of the line
#Uses:
#HorzLine Routine
DrawRTLDiagLine:
	#create stack frame / save $ra
	addiu	$sp,	$sp,	-20	#make room on the stack
	sw	$ra,	0 ($sp)		#store $ra

RightToLeft:
	sw	$a0,	4 ($sp)		#Store a0
	sw	$a1,	8 ($sp)		#Store a1
	sw	$a2,	12 ($sp)		#Store a2
	sw	$a3,	16 ($sp)		#Store a3
	li	$a3,	2		#Load the length of the line into a3; $a3 = 2 hardcoded
	jal	HorzLine			#Draw the line on the bitmap display
	lw	$a0,	4 ($sp)		#Store a0
	lw	$a1,	8 ($sp)		#Store a1
	lw	$a2,	12 ($sp)		#Store a2
	lw	$a3,	16 ($sp)		#Store a2
	addi	$a0,	$a0,	-1	#Decrement the x-coord
	addi	$a1,	$a1,	1	#Increment the y-coord
	addi	$a3,	$a3,	-1	#Decrement length by 1
	bnez	$a3,	RightToLeft	#Exit ones the length has been decremented to 0

	#restore $ra
	lw	$ra,	0 ($sp)	#Restore $ra
	addiu	$sp,	$sp,	20	#Restore the stack
	
	#Return to caller
	jr	$ra

#End Right to Left Diagonal line
##################################

##################################
#Start Right to Left upward Diagonal line
#$a0 = starting x-coord
#$a1 = starting y-coord
#$a2 = color number (0-7)
#$a3 = length of the line
#Uses:
#HorzLine Routine
DrawRTLUpDiagLine:
	#create stack frame / save $ra
	addiu	$sp,	$sp,	-20	#make room on the stack
	sw	$ra,	0 ($sp)		#store $ra

RightToLeftUp:
	sw	$a0,	4 ($sp)		#Store a0
	sw	$a1,	8 ($sp)		#Store a1
	sw	$a2,	12 ($sp)		#Store a2
	sw	$a3,	16 ($sp)		#Store a3
	li	$a3,	2		#Load the length of the line into a3; $a3 = 2 hardcoded
	jal	HorzLine			#Draw the line on the bitmap display
	lw	$a0,	4 ($sp)		#Store a0
	lw	$a1,	8 ($sp)		#Store a1
	lw	$a2,	12 ($sp)		#Store a2
	lw	$a3,	16 ($sp)		#Store a2
	addi	$a0,	$a0,	-1	#Decrement the x-coord
	addi	$a1,	$a1,	-1	#Decrement the y-coord
	addi	$a3,	$a3,	-1	#Decrement length by 1
	bnez	$a3,	RightToLeftUp	#Exit ones the length has been decremented to 0

	#restore $ra
	lw	$ra,	0 ($sp)	#Restore $ra
	addiu	$sp,	$sp,	20	#Restore the stack
	
	#Return to caller
	jr	$ra

#End Right to Left Diagonal line
##################################

##################################
#Start Draw Filled Box
#$a0 = x coordinate (0-31)
#$a1 = y coordinate (0-31)
#$a2 = color number (0-7)
#$a3 = length of the line (1-32)	
DrawBox:
	#create stack frame / 
	addiu	$sp,	$sp,	-24	#make room on the stack, 6 words
	#Save original $s0
	sw	$s0,	20 ($sp)
	#save $ra
	sw	$ra,	16 ($sp)	#store $ra
	#Save all a registers
	sw	$a3,	12 ($sp)	#store $a2
	sw	$a2,	8 ($sp)	#store $a0
	sw	$a0,	4 ($sp)	#store $a3
	sw	$a1,	0 ($sp)	#store $a1
	
	#Copy loop counter to $s0
	move	$s0,	$a3	#copy $a3 -> temp register
	
BoxLoop:
	#restore a registers
	lw	$a0,	4 ($sp)	#restore $a0
	sw	$a1,	0 ($sp)	#restore $a1
	lw	$a2,	8 ($sp)	#restore $a2
	lw	$a3,	12 ($sp)	#restore $a3
	
	jal	HorzLine		#Draw horizontal line
	
	#restore a registers
	lw	$a1,	0 ($sp)	#restore $a1
	addiu	$a1,	$a1,	1	#increment y coordinate ($a1)
	addiu	$s0, 	$s0,	-1	#decrement counter
	bnez	$s0,	BoxLoop
	
	move	$a3,	$s0	#This should be a value of 0
	#Restore original $s0
	lw	$s0,	20 ($sp)
	#Restore $ra
	lw	$ra,	16 ($sp)	#store $ra
	#Restore a registers
	lw	$a2,	8 ($sp)	#store $a0
	lw	$a0,	4 ($sp)	#store $a3
	lw	$a1,	0 ($sp)	#store $a1
	#Restore the stack, 6 words
	addiu	$sp,	$sp,	24		
	
	#Return to caller
	jr	$ra
#End Draw Filled Box
##################################

##################################
#Start Box Location
#$a0 = number from sequence
#Returns $v0 = x coordinate of the box
#Returns $v1 = y coordinate of the box
BoxLoc:
	#create stack frame / save $ra
	addiu	$sp,	$sp,	-4	#make room on the stack
	sw	$ra,	0 ($sp)	#store $ra
	
	#Determine which quadrant to return based on the random number generated
	beq	$a0,	1,	UpLeft
	beq	$a0,	2,	UpRight
	beq	$a0,	3,	BotLeft
	beq	$a0,	4,	BotRight
	#jal	ErrOccurred

#Select the quadrant (X,Y) coordinate pair to return
UpLeft:
	li	$v0,	1
	li	$v1,	1
	j	BoxLocEnd
	
UpRight:
	li	$v0,	17
	li	$v1,	1
	j	BoxLocEnd

BotLeft:
	li	$v0,	1
	li	$v1,	17
	j	BoxLocEnd

BotRight:
	li	$v0,	17
	li	$v1,	17
	j	BoxLocEnd

BoxLocEnd:
	#Return: $v0 = X, $v1 = Y
	#restore $ra
	lw	$ra,	0 ($sp)		#store $ra
	addiu	$sp,	$sp,	4	#make room on the stack
	
	#Return to caller
	jr	$ra

#End Box Location
##################################

##################################
#Start Box Color
#$a0 = number from sequence
#Returns $v1 = returns box color number
#Uses GetColor Routine
BoxColor:
	#create stack frame / save $ra
	addiu	$sp,	$sp,	-4	#make room on the stack
	sw	$ra,	0 ($sp)		#store $ra
	
	#Select which quadrant the box should be in
	beq	$a0,	1,	UpLeftCol	
	beq	$a0,	2,	UpRightCol
	beq	$a0,	3,	BotLeftCol
	beq	$a0,	4,	BotRightCol
	#jal	ErrOccurred
	
#[0] - black
#[1] - blue
#[2] - green
#[3] - red
#[4] - blue + green = Cyan
#[5] - blue + red = Magenta
#[6] - green + red = Yellow
#[7] - white

#Select the correct color for the quadrant the box will be in
UpLeftCol:	#Yellow
	li	$v1,	6
	j	BoxColorEnd
	
UpRightCol:	#Blue
	li	$v1,	1
	j	BoxColorEnd

BotLeftCol:	#Green
	li	$v1,	2
	j	BoxColorEnd

BotRightCol:	#Red
	li	$v1,	3
	j	BoxColorEnd

BoxColorEnd:
	#$v1 will hold the box color number
	#restore $ra
	lw	$ra,	0 ($sp)	#store $ra
	addiu	$sp,	$sp,	4	#make room on the stack
	
	#Return to caller
	jr	$ra

#End Box Color
##################################

##################################
#Start Exit Program Routine
#Uses thankYou variable
#Uses PrStr Routine
Exit:
	jal	ClearDisp
	la	$a0,	thankYou	#Load address to string
	jal	PrStr		#Call the Print String Routine
	li	$v0,	10	#Load Exit program service
	syscall			#exit program
#End Exit Program Routine
##################################

##################################
#Start Draw Space Ship
#This routine draws the ship to the screen with the center of the ship being drawn
#on the coordinates provided. 
#$a0 = x-center
#$a1 = y-center
#$a2 = color number (0-7)
#Uses:
#DrawTriUp Routine
#DrawTriDown Routine
#DrawTurret Routine
#shipColor Variable
#shipSize Variable
DrawShip:
	#save $ra and any variables used
	addi	$sp,	$sp,	-44
	sw	$ra,	($sp)
	sw	$a0,	4 ($sp)
	sw	$a1,	8 ($sp)
	sw	$a2,	12($sp)
	
#Draw Ship
	#Draw gun turrets from left to right
	#Left most turret
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	12($sp)
	lw	$t0,	shipSize
	srl	$t1,	$t0,	1
	srl	$t2,	$t0,	2
	subu	$a0,	$a0,	$t1
	subu	$a1,	$a1,	$t2
	jal	DrawTurret
	
	#Center turret
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	12($sp)
	lw	$t0,	shipSize
	srl	$t1,	$t0,	1
	srl	$t2,	$t0,	2
	subu	$a1,	$a1,	$t1
	subu	$a1,	$a1,	$t2
	srl	$t2,	$t2,	2
	addu	$a1,	$a1,	$t2
	jal	DrawTurret
		
	#Right most turret
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	12($sp)
	lw	$t0,	shipSize
	srl	$t1,	$t0,	1
	srl	$t2,	$t0,	2
	addu	$a0,	$a0,	$t1
	subu	$a1,	$a1,	$t2
	jal	DrawTurret
	
	#Ship Main body
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	12($sp)
	lw	$a3,	shipSize
	jal	DrawTriUp
	
	#Calc left wing position from ship position
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a2,	12($sp)
	lw	$t0,	shipSize
	srl	$t1,	$t0,	2
	subu	$a0,	$a0,	$t1
	addu	$a1,	$a1,	$t1
	#Left wing
	#li	$a0,	231
	#li	$a1,	289
	li	$a2,	0	#Color Black
	lw	$a3,	shipSize
	srl	$a3	$a3,	1
	jal	DrawTriUp
	
	#Calc right wing position from ship position
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$t0,	shipSize
	srl	$t1,	$t0,	2
	addu	$a0,	$a0,	$t1
	addu	$a1,	$a1,	$t1
	#Right wing
	#li	$a0,	281
	#li	$a1,	289
	li	$a2,	0	#Color Black
	lw	$a3,	shipSize
	srl	$a3	$a3,	1
	jal	DrawTriUp

	#Restore $ra and any variables used
	lw	$ra,	($sp)
	addi	$sp,	$sp,	44
	
	#Return to caller
	jr	$ra

#End Draw Space Ship
##################################

##################################
#Start Draw Turret of space ship
#This routine draws the ship to the screen with the center of the ship being drawn centered
#on the coordinates provided. 
#$a0 = x-center
#$a1 = y-center
#$a2 = color number (0-7)
#Uses:
#HorzLine Routine
DrawTurret:
	#save $ra and any variables used
	addi	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	sw	$a0,	4 ($sp)
	sw	$a1,	8 ($sp)
	sw	$a2,	12 ($sp)
	
	#Initialize iterator
	move	$t0,	$0
	
	addiu	$a0,	$a0,	-1
	
turLoop:
	sw	$a0,	4 ($sp)
	sw	$a1,	8 ($sp)
	sw	$t0,	16 ($sp)
	lw	$a2,	12 ($sp)
	lw	$a3,	shipSize
	srl	$a3,	$a3,	2
	jal	VertLine
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$t0,	16 ($sp)
	addiu	$a0,	$a0,	1
	addiu	$t0,	$t0,	1
	blt	$t0,	3	turLoop
	
	#Restore $ra and any variables used
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Draw Turret
##################################

##################################
#Start Draw upright Equilateral Triangle
#This routine draws an equilateral triangle to the screen
#It puts the center of the triangle at the position provided by the (x, y) pair 
#$a0 = x-center
#$a1 = y-center
#$a2 = color number (0-7)
#$a3 = width/height of triangle
#Uses:
#HorzLine Routine
DrawTriUp:
	#save $ra and any variables used
	addi	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	sw	$a0,	4 ($sp)
	sw	$a1,	8 ($sp)
	sw	$a2,	12 ($sp)
	sw	$a3,	16 ($sp)

	#Adjust Y for the traingle so that the point provided is the center of the triangle
	srl	$t0,	$a3,	1	#Get the width/height
	subu	$a1,	$a1,	$t0	#Move Y to the bottom of the triangle

	#Triangle Loop
triUpLoop:
	##$a0 = x coordinate (0-31)
	#$a1 = y coordinate (0-31)
	#$a2 = color number (0-7)
	#$a3 = length of the line (1-32)
	sw	$a0,	4 ($sp)
	sw	$a1,	8 ($sp)
	sw	$a3,	16 ($sp)
	lw	$a2,	12 ($sp)
	jal	DrawRTLDiagLine
	lw	$a0,	4 ($sp)
	lw	$a1,	8 ($sp)
	lw	$a3,	16 ($sp)
	addiu	$a0,	$a0,	1
	addiu	$a1,	$a1,	1
	addiu	$a3,	$a3,	-1
	bgt	$a3,	1,	triUpLoop 
	
		
	#Restore $ra and any variables used
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Draw upright Equilateral Triangle
##################################

##################################
#Start Draw upside down Equilateral Triangle
#This routine draws an equilateral triangle to the screen
#It puts the center of the triangle at the position provided by the (x, y) pair 
#$a0 = x-center
#$a1 = y-center
#$a2 = color number (0-7)
#$a3 = width/height of triangle
#Uses:
#HorzLine Routine
DrawTriDown:
	#save $ra and any variables used
	addi	$sp,	$sp,	-20
	sw	$ra,	($sp)
	sw	$a0,	4 ($sp)
	sw	$a1,	8 ($sp)
	sw	$a2,	12 ($sp)
	sw	$a3,	16 ($sp)
	
	#Adjust Y for the traingle so that the point provided is the center of the triangle
	srl	$t0,	$a3,	1	#Get the width/height
	addu	$a1,	$a1,	$t0	#Move Y to the bottom of the triangle
	
	#Triangle Loop
triDownLoop:
	##$a0 = x coordinate (0-31)
	#$a1 = y coordinate (0-31)
	#$a2 = color number (0-7)
	#$a3 = length of the line (1-32)
	sw	$a0,	4($sp)
	sw	$a1,	8($sp)
	sw	$a3,	16($sp)
	lw	$a2,	12 ($sp)
	jal	DrawRTLUpDiagLine
	lw	$a0,	4($sp)
	lw	$a1,	8($sp)
	lw	$a3,	16($sp)
	addiu	$a0,	$a0,	1
	addiu	$a1,	$a1,	-1
	addiu	$a3,	$a3,	-1
	bgt	$a3,	1,	triDownLoop 
	
	#Restore $ra and any variables used
	lw	$ra,	($sp)
	addi	$sp,	$sp,	20
	
	#Return to caller
	jr	$ra

#End Draw upside down Equilateral Triangle
##################################

##################################
#Start Pause Routine
#Takes arguments: 
#$a0 = naumber of milliseconds to wait
Pause:
	#Save original return address in case it is overwritten
	addi	$sp,	$sp,	-4
	sw	$ra,	0 ($sp)
	
	move	$t0,	$a0	#Save time to wait, in milliseconds
	li	$v0,	30	#Load get time service
	syscall			#Get current time
	move	$t1,	$a0	#Save Initial time

	#Check to see if enough time has elapsed
ChkTimeLoop:
	syscall			#Get current time
	subu	$t2,	$a0,	$t1	#Find elapsed time
	#Compare if elapsed time is greater than ro equal to time to wait
	bltu	$t2,	$t0,	ChkTimeLoop	#Brancj if not enough time has elapsed
	
	#Restore return address
	lw	$ra,	0 ($sp)
	addi	$sp,	$sp,	4
	
	#Return to caller
	jr	$ra

#End Pause Routine
##################################

##################################
#Start Play Midi
#Arguments:
#$a0 = ship or mob fire
#Uses Variables:
#winTracker
BulletMidi:
	#create stack frame / save $ra
	addiu	$sp,	$sp,	-4	#make room on the stack
	sw	$ra,	0 ($sp)		#store $ra
	
	#Ship = 0, mob = 1
	beqz	$a0,	play
	sll	$a0,	$a0,	5
	
play:	
	addiu	$a0,	$a0,	80
	li	$a1,	100
	li	$a2,	84
	li	$a3,	80
	li	$v0,	31
	syscall
	
	#restore $ra
	lw	$ra,	0 ($sp)	#store $ra
	addiu	$sp,	$sp,	4	#make room on the stack
	
	#Return to caller
	jr	$ra

#End Play Midi
##################################

##################################
#Start Countdown
#Arguments:
#$a0 = ship or mob fire
#Uses Routine(s):
#OutText
#Uses Variable(s):
#countDown
# $a0 = horizontal pixel co-ordinate (0-255)
# $a1 = vertical pixel co-ordinate (0-255)
# $a2 = pointer to asciiz text (to be displayed)
StartGame:
	addiu	$sp,	$sp,	-12
	sw	$ra,	($sp)
	
	#Load the countdown sequence address
	la	$t9,	countDown
	li	$t0,	0
	
countLoop:	
	sw	$t9,	4($sp)
	sw	$t0,	8($sp)
	#Load x, y coords
	li	$a0,	256
	li	$a1,	256
	move	$a2,	$t9	#Move next digit string into $a2
	jal	OutText
	#Pause between each number in the countdown
	li	$a0,	1000
	jal	Pause
	#retsore loop information
	lw	$t9,	4($sp)
	lw	$t0,	8($sp)
	addiu	$t0,	$t0,	1
	addiu	$t9,	$t9,	2
	blt	$t0,	5,	countLoop
	
	li	$a0,	246
	li	$a1,	246
	li	$a2,	0
	li	$a3,	24
	jal	DrawBox
	
	#restore $ra
	lw	$ra,	0 ($sp)	#store $ra
	addiu	$sp,	$sp,	12	#make room on the stack
	
	#Return to caller
	jr	$ra
#End Play Midi
##################################

#End SCW5452 Routines
#########################################################################

#########################################################################
#Start Provided Routines from Prof. Nunez
.data
#########################################################################
#Start .data section from provided routine(s)
Colors: .word   0x000000        # background color (black)
        .word   0xffffff        # foreground color (white)

DigitTable:
        .byte   ' ', 0,0,0,0,0,0,0,0,0,0,0,0
        .byte   '0', 0x7e,0xff,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xff,0x7e
        .byte   '1', 0x38,0x78,0xf8,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18
        .byte   '2', 0x7e,0xff,0x83,0x06,0x0c,0x18,0x30,0x60,0xc0,0xc1,0xff,0x7e
        .byte   '3', 0x7e,0xff,0x83,0x03,0x03,0x1e,0x1e,0x03,0x03,0x83,0xff,0x7e
        .byte   '4', 0xc3,0xc3,0xc3,0xc3,0xc3,0xff,0x7f,0x03,0x03,0x03,0x03,0x03
        .byte   '5', 0xff,0xff,0xc0,0xc0,0xc0,0xfe,0x7f,0x03,0x03,0x83,0xff,0x7f
        .byte   '6', 0xc0,0xc0,0xc0,0xc0,0xc0,0xfe,0xfe,0xc3,0xc3,0xc3,0xff,0x7e
        .byte   '7', 0x7e,0xff,0x03,0x06,0x06,0x0c,0x0c,0x18,0x18,0x30,0x30,0x60
        .byte   '8', 0x7e,0xff,0xc3,0xc3,0xc3,0x7e,0x7e,0xc3,0xc3,0xc3,0xff,0x7e
        .byte   '9', 0x7e,0xff,0xc3,0xc3,0xc3,0x7f,0x7f,0x03,0x03,0x03,0x03,0x03
        .byte   '+', 0x00,0x00,0x00,0x18,0x18,0x7e,0x7e,0x18,0x18,0x00,0x00,0x00
        .byte   '-', 0x00,0x00,0x00,0x00,0x00,0x7e,0x7e,0x00,0x00,0x00,0x00,0x00
        .byte   '*', 0x00,0x00,0x00,0x66,0x3c,0x18,0x18,0x3c,0x66,0x00,0x00,0x00
        .byte   '/', 0x00,0x00,0x18,0x18,0x00,0x7e,0x7e,0x00,0x18,0x18,0x00,0x00
        .byte   '=', 0x00,0x00,0x00,0x00,0x7e,0x00,0x7e,0x00,0x00,0x00,0x00,0x00
        .byte   'A', 0x18,0x3c,0x66,0xc3,0xc3,0xc3,0xff,0xff,0xc3,0xc3,0xc3,0xc3
        .byte   'B', 0xfc,0xfe,0xc3,0xc3,0xc3,0xfe,0xfe,0xc3,0xc3,0xc3,0xfe,0xfc
        .byte   'C', 0x7e,0xff,0xc1,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc1,0xff,0x7e
        .byte   'D', 0xfc,0xfe,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xfe,0xfc
        .byte   'E', 0xff,0xff,0xc0,0xc0,0xc0,0xfe,0xfe,0xc0,0xc0,0xc0,0xff,0xff
        .byte   'F', 0xff,0xff,0xc0,0xc0,0xc0,0xfe,0xfe,0xc0,0xc0,0xc0,0xc0,0xc0
# add additional characters here....
# first byte is the ascii character
# next 12 bytes are the pixels that are "on" for each of the 12 lines
        .byte    0, 0,0,0,0,0,0,0,0,0,0,0,0

#  0x80----  ----0x08
#  0x40--- || ---0x04
#  0x20-- |||| --0x02
#  0x10- |||||| -0x01
#       ||||||||
#       84218421

#   1   ...xx...      0x18
#   2   ..xxxx..      0x3c
#   3   .xx..xx.      0x66
#   4   xx....xx      0xc3
#   5   xx....xx      0xc3
#   6   xx....xx      0xc3
#   7   xxxxxxxx      0xff
#   8   xxxxxxxx      0xff
#   9   xx....xx      0xc3
#  10   xx....xx      0xc3
#  11   xx....xx      0xc3
#  12   xx....xx      0xc3
#End .data section from provided routine(s)
#########################################################################

.text
##################################
#Start Digits
# OutText: display ascii characters on the bit mapped display
# $a0 = horizontal pixel co-ordinate (0-255)
# $a1 = vertical pixel co-ordinate (0-255)
# $a2 = pointer to asciiz text (to be displayed)
OutText:
        addiu   $sp, $sp, -24
        sw      $ra, 20($sp)

        li      $t8, 1          # line number in the digit array (1-12)
_text1:
        la      $t9, 0x10040000 # get the memory start address
        sll     $t0, $a0, 2     # assumes mars was configured as 256 x 256
        addu    $t9, $t9, $t0   # and 1 pixel width, 1 pixel height
        sll     $t0, $a1, 11    # (a0 * 4) + (a1 * 4 * 256)
        addu    $t9, $t9, $t0   # t9 = memory address for this pixel

        move    $t2, $a2        # t2 = pointer to the text string
_text2:
        lb      $t0, 0($t2)     # character to be displayed
        addiu   $t2, $t2, 1     # last character is a null
        beq     $t0, $zero, _text9

        la      $t3, DigitTable # find the character in the table
_text3:
        lb      $t4, 0($t3)     # get an entry from the table
        beq     $t4, $t0, _text4
        beq     $t4, $zero, _text4
        addiu   $t3, $t3, 13    # go to the next entry in the table
        j       _text3
_text4:
        addu    $t3, $t3, $t8   # t8 is the line number
        lb      $t4, 0($t3)     # bit map to be displayed

        sw      $zero, 0($t9)   # first pixel is black
        addiu   $t9, $t9, 4

        li      $t5, 8          # 8 bits to go out
_text5:
        la      $t7, Colors
        lw      $t7, 0($t7)     # assume black
        andi    $t6, $t4, 0x80  # mask out the bit (0=black, 1=white)
        beq     $t6, $zero, _text6
        la      $t7, Colors     # else it is white
        lw      $t7, 4($t7)
_text6:
        sw      $t7, 0($t9)     # write the pixel color
        addiu   $t9, $t9, 4     # go to the next memory position
        sll     $t4, $t4, 1     # and line number
        addiu   $t5, $t5, -1    # and decrement down (8,7,...0)
        bne     $t5, $zero, _text5

        sw      $zero, 0($t9)   # last pixel is black
        addiu   $t9, $t9, 4
        j       _text2          # go get another character

_text9:
        addiu   $a1, $a1, 1     # advance to the next line
        addiu   $t8, $t8, 1     # increment the digit array offset (1-12)
        bne     $t8, 13, _text1

        lw      $ra, 20($sp)
        addiu   $sp, $sp, 24
        jr      $ra
#End Digits
##################################

#End Provided Routines from Prof. Nunez
#########################################################################
