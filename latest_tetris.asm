################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Akshaya Deepak Ramachandran, 1008806810
# Student 2: Jessie Kim, 1009066662
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    64
# - Display height in pixels:   64
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################
    .data
    displayaddress: .word 0x100080000
    grid: .space 1020
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

# The address of the colors used in game
white_color: 
    .word 0xffffff
dark_grey:
    .word 0x17161A
light_grey: 
    .word 0x1b1b1b
game_over_light:
    .word 0x90e0ef
game_over_dark:
    .word 0x00b4d8

##############################################################################
# Mutable Data
##############################################################################
# the type of block that is being handled
block_type:
    .word 1
    
# temporary space to store register values when making sound effects
tmp_store:
    .space 12

# temporary space to store coordinates of latest block added to diplay
tmp_block:
    .space 16
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
main:                               # Initialize values needed to create background + walls
    li $v1, 0
    li $s3, 1
    lw $t1, white_color 
    lw $t0, ADDR_DSPL      
    lw $t2, dark_grey
    la $t3, grid
    add $t4, $zero, $zero
    add $t5, $zero, $zero
    add $t6, $zero, $zero
    addi $t7, $zero, 64
    lw $t9, light_grey
    lw $a1, block_type
    add $s1, $zero, $zero
    b paint_bg
    
game_loop:                           # Initialize values required for creating blocks + moving them
	li 		$v0, 32
	li 		$a0, 1
	li      $t7, 64
	add $t6, $zero, $zero
	add $t5, $zero, $zero
	lw $t0, ADDR_DSPL
	syscall
	jal draw_block                 # draw a new block
	
	add $a1, $zero, $zero
    jal check_last_block            # check if the the game should be over or not
    
    lw $a1, block_type
    lw $t1, white_color 
    lw $t9, light_grey
    
    lw $s5, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($s5)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    b game_loop

draw_block:
    beq $a1, 1, draw_block_s
	beq $a1, 2, draw_block_i
	beq $a1, 3, draw_block_z
	beq $a1, 4, draw_block_o
	beq $a1, 5, draw_block_l
	beq $a1, 6, draw_block_j
	beq $a1, 7, draw_block_t
	jr $ra

check_last_block:       # check if the game should be over
    beq $a1, 4, return
    la $t9, tmp_block
    lw $t1, 0($t9)
    addi $t9, $t9, -4
    addi $a1, $a1, 1
    j compare

compare:        # if there is an overlap between the new block and last block, game is over
    beq $t1, $s2, game_over
    beq $t1, $a2, game_over
    beq $t1, $a3, game_over
    beq $t1, $t4, game_over
    j compare_row

compare_row:    
    beq $t1, 8, game_over
    beq $t1, 12, game_over
    beq $t1, 16, game_over
    beq $t1, 20, game_over
    beq $t1, 24, game_over
    beq $t1, 28, game_over
    beq $t1, 32, game_over
    beq $t1, 36, game_over
    beq $t1, 40, game_over
    beq $t1, 44, game_over
    beq $t1, 48, game_over
    beq $t1, 52, game_over
    beq $t1, 56, game_over
    beq $t1, 60, game_over
    b check_last_block

keyboard_input:                     # A key is pressed
    lw $a0, 4($s5)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x73, respond_to_S     # Check if the key s was pressed
    beq $a0, 0x61, respond_to_A     # Check if the key a was pressed
    beq $a0, 0x64, respond_to_D     # Check if the key d was pressed
    beq $a0, 0x77, respond_to_W     # Check if the key w was pressed
    beq $a0, 0x70, respond_to_P     # Check if the key w was pressed
    li $v0, 0                       # ask system to print $a0
    syscall

    b game_loop

reset:
    li $a1, 7
    sw $a1, block_type
    b new_block

new_block:
    lw $a1, block_type
    beq $a1, 14, reset              # When a block has finished moving, create a
    addi $a1, $a1, -6               # new block and store the old block's 
    sw $a1, block_type
    li $v1, 0                       # coordinates in memory
    
    add $s3, $zero, $zero           # store values on the stack
    addi $sp, $sp, -4
    sw $s2, 0($sp)
    addi $sp, $sp, -4
    sw $a2, 0($sp)
    addi $sp, $sp, -4
    sw $a3, 0($sp)
    addi $sp, $sp, -4
    sw $t4, 0($sp)
    addi $sp, $sp, -4
    sw $s1, 0($sp)
    
    jal save_to_grid
    
    la $t9, tmp_block 
    sw $s2, 0($t9)
    addi $t9, $t9, 4
    sw $a2, 0($t9)
    addi $t9, $t9, 4
    sw $a3, 0($t9)
    addi $t9, $t9, 4
    sw $t4, 0($t9)
    
    addi $t6, $zero, 15
    b check_line
    
paint_existing_blocks:              # display the stored coordinates
    li $v0, 0
    addi $s5, $s5, 4
    lw $t7, 0($s5)
    beq $t7, $zero, return_after_paint
    addi $s5, $s5, 4
    lw $t8, 0($s5)
    beq $v0, $zero, paint_block

    b paint_existing_blocks
    
paint_block:
    addi $s5, $s5, -4
    beq $t8, 0xff0000, paint_existing_blocks
    beq $t8, 0x00ffff, paint_existing_blocks
    beq $t8, 0x00ff00, paint_existing_blocks
    beq $t8, 0xffff00, paint_existing_blocks
    beq $t8, 0xffa500, paint_existing_blocks
    beq $t8, 0xff6ec7, paint_existing_blocks
    beq $t8, 0x800080, paint_existing_blocks
    beq $t8, $zero, return_after_paint
    addi $s5, $s5, 4
    sw $t7, 0($t8)
    addi $s5, $s5, 4
    lw $t8, 0($s5)
    addi $s5, $s5, -4
    beq $t8, 0xff0000, paint_existing_blocks
    beq $t8, 0x00ffff, paint_existing_blocks
    beq $t8, 0x00ff00, paint_existing_blocks
    beq $t8, 0xffff00, paint_existing_blocks
    beq $t8, 0xffa500, paint_existing_blocks
    beq $t8, 0xff6ec7, paint_existing_blocks
    beq $t8, 0x800080, paint_existing_blocks
    beq $t8, $zero, return_after_paint
    addi $s5, $s5, 4
    sw $t7, 0($t8)
    addi $s5, $s5, 4
    lw $t8, 0($s5)
    addi $s5, $s5, -4
    beq $t8, 0xff0000, paint_existing_blocks
    beq $t8, 0x00ffff, paint_existing_blocks
    beq $t8, 0x00ff00, paint_existing_blocks
    beq $t8, 0xffff00, paint_existing_blocks
    beq $t8, 0xffa500, paint_existing_blocks
    beq $t8, 0xff6ec7, paint_existing_blocks
    beq $t8, 0x800080, paint_existing_blocks
    beq $t8, $zero, return_after_paint
    addi $s5, $s5, 4
    sw $t7, 0($t8)
    addi $s5, $s5, 4
    lw $t8, 0($s5)
    addi $s5, $s5, -4
    beq $t8, 0xff0000, paint_existing_blocks
    beq $t8, 0x00ffff, paint_existing_blocks
    beq $t8, 0x00ff00, paint_existing_blocks
    beq $t8, 0xffff00, paint_existing_blocks
    beq $t8, 0xffa500, paint_existing_blocks
    beq $t8, 0xff6ec7, paint_existing_blocks
    beq $t8, 0x800080, paint_existing_blocks
    beq $t8, $zero, return_after_paint
    sw $t7, 0($t8)
    addi $s5, $s5, 4
    
    b paint_existing_blocks
    
return_after_paint:
    add $t7, $zero, 64
    jr $ra

respond_to_Q:
    jal play_sound_Q                  # make a sound effect 
	li $v0, 10                      # Quit gracefully
	syscall
	
respond_to_P:
    la $t9, tmp_store 
    sw $a0, 0($t9)
    addi $t9, $t9, 4
    sw $a2, 0($t9)
    addi $t9, $t9, 4
    sw $a3, 0($t9)
    
    jal play_sound_P                  # make a sound effect 
    # update value as before
    lw $a3, 0($t9)
    addi $t9, $t9, -4
    lw $a2, 0($t9)
    addi $t9, $t9, -4
    lw $a0, 0($t9)
    lw $a1, block_type
    
    lw $t9, light_grey
    add $a0, $zero, $zero
    addi $sp, $sp, -4
    sw $s2, 0($sp)
    addi $sp, $sp, -4
    sw $a2, 0($sp)
    addi $sp, $sp, -4
    sw $a3, 0($sp)
    addi $sp, $sp, -4
    sw $t4, 0($sp)
    
    jal draw_pixels
    
    jal sleep
    
    lw $t0, ADDR_DSPL
    
    jal paint_bg
    
    lw $t4, 0($sp)
    sw $s1, 0($t4)
    addi $sp, $sp, 4
    lw $a3, 0($sp)
    sw $s1, 0($a3)
    addi $sp, $sp, 4
    lw $a2, 0($sp)
    sw $s1, 0($a2)
    addi $sp, $sp, 4
    lw $s2, 0($sp)
    sw $s1, 0($s2)
    addi $sp, $sp, 4
    
    jal paint
    
    b game_loop

sleep:
    lw $s5, ADDR_KBRD
    lw $t8, 0($s5)                  # Load first word from keyboard
    beq $t8, 1, check_output      # If first word 1, key is pressed
    syscall
    
    b sleep

check_output:
    lw $a0, 4($s5)
    beq $a0, 0x70, exit_sleep
    
    j sleep

exit_sleep:
    jr $ra
    
draw_pixels:
    addi $t0, $t0, 340
    lw $t1, white_color
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)

    addi $t0, $t0, 12
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 44
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 12
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 44
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 12
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 44
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 12
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 44
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 12
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    jr $ra

respond_to_S:
    # save values of registers in a temporary space
    la $t9, tmp_store 
    sw $a0, 0($t9)
    addi $t9, $t9, 4
    sw $a2, 0($t9)
    addi $t9, $t9, 4
    sw $a3, 0($t9)
    
    jal play_sound_move                  # make a sound effect 
    # update registers
    lw $a3, 0($t9)
    addi $t9, $t9, -4
    lw $a2, 0($t9)
    addi $t9, $t9, -4
    lw $a0, 0($t9)
    lw $a1, block_type
    
    lw $t9, light_grey
    addi $s7, $t0, 960              # check if the new coordinates are out of bounds
    add $s4, $zero, $zero
    addi $s4, $s2, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    addi $s4, $a2, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    addi $s4, $a3, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    add $s4, $zero, $zero
    addi $s4, $t4, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    
    
    jal paint_bg                    # repaint the bg + previous blocks
    jal paint
    
    addi $s2, $s2, 64
    addi $a2, $a2, 64
    addi $a3, $a3, 64
    addi $t4, $t4, 64
    
    addi $s5, $sp, -4
    jal check_block_S
    
    addi $s2, $s2, 64
    addi $a2, $a2, 64
    addi $a3, $a3, 64
    addi $t4, $t4, 64
    
    addi $s5, $sp, -4
    jal check_block_S
    
    addi $s2, $s2, -64
    addi $a2, $a2, -64
    addi $a3, $a3, -64
    addi $t4, $t4, -64
    
    sw $s1, 0($s2)                  # display new coordinates
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

paint:
    addi $s5, $sp, -4
    add $t7, $zero, $zero
    beq $s3, 0, paint_existing_blocks
    add $t7, $zero, 64
    jr $ra

check_block_S:

    add $s5, $s5, 4
    lw $t8, 0($s5)
    beq $t8, $s2, new_block_S
    beq $t8, $a2, new_block_S
    beq $t8, $a3, new_block_S
    beq $t8, $t4, new_block_S
    beq $t8, $zero, return
    b check_block_S
    
new_block_S:
    addi $s2, $s2, -64
    addi $a2, $a2, -64
    addi $a3, $a3, -64
    addi $t4, $t4, -64
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b new_block

respond_to_A:
    # save values of registers in a temporary space
    la $t9, tmp_store 
    sw $a0, 0($t9)
    addi $t9, $t9, 4
    sw $a2, 0($t9)
    addi $t9, $t9, 4
    sw $a3, 0($t9)
    
    jal play_sound_move                  # make a sound effect 
    # update registers
    lw $a3, 0($t9)
    addi $t9, $t9, -4
    lw $a2, 0($t9)
    addi $t9, $t9, -4
    lw $a0, 0($t9)
    lw $a1, block_type
    
    lw $t9, light_grey
    addi $a2, $a2, -4               # check if the new coordinates are out of bounds
    addi $t4, $t4, -4
    
    div $a2, $t7
    mfhi $s4
    div $t4, $t7
    mfhi $s6
    
    addi $a2, $a2, 4
    addi $t4, $t4, 4
    beq $s4, $zero, game_loop
    beq $s6, $zero, game_loop
    
    addi $s2, $s2, -4
    addi $a3, $a3, -4
    
    div $s2, $t7
    mfhi $s4
    div $a3, $t7
    mfhi $s6
    
    addi $s2, $s2, 4
    addi $a3, $a3, 4
    beq $s4, $zero, game_loop
    beq $s6, $zero, game_loop

    jal paint_bg                    # repaint the background + previous coordinates
    jal paint
    
    addi $s2, $s2, -4
    addi $a2, $a2, -4
    addi $a3, $a3, -4
    addi $t4, $t4, -4
    
    addi $s5, $sp, -4
    jal check_block_A
    
    sw $s1, 0($s2)                  #display new coordinates
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop
    
check_block_A:
    add $s5, $s5, 4
    lw $t8, 0($s5)
    beq $t8, $s2, do_not_move_A
    beq $t8, $a2, do_not_move_A
    beq $t8, $a3, do_not_move_A
    beq $t8, $t4, do_not_move_A
    beq $t8, $zero, return
    b check_block_A
    
do_not_move_A:
    addi $s2, $s2, 4
    addi $a2, $a2, 4
    addi $a3, $a3, 4
    addi $t4, $t4, 4
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

respond_to_D:
    # save values of registers in a temporary space
    la $t9, tmp_store 
    sw $a0, 0($t9)
    addi $t9, $t9, 4
    sw $a2, 0($t9)
    addi $t9, $t9, 4
    sw $a3, 0($t9)
    
    jal play_sound_move                  # make a sound effect 
    # update registers
    lw $a3, 0($t9)
    addi $t9, $t9, -4
    lw $a2, 0($t9)
    addi $t9, $t9, -4
    lw $a0, 0($t9)
    lw $a1, block_type
    
    lw $t9, light_grey
    addi $a2, $a2, 8
    addi $a3, $a3, 8
    
    div $a2, $t7
    mfhi $s4
    div $a3, $t7
    mfhi $s6
    
    addi $a2, $a2, -8
    addi $a3, $a3, -8
    beq $s4, $zero, game_loop
    beq $s6, $zero, game_loop
    
    addi $s2, $s2, 8
    addi $t4, $t4, 8
    
    div $s2, $t7
    mfhi $s4
    div $t4, $t7
    mfhi $s6
    
    addi $s2, $s2, -8
    addi $t4, $t4, -8
    beq $s4, $zero, game_loop
    beq $s6, $zero, game_loop
    
    jal paint_bg
    jal paint
    
    addi $s2, $s2, 4
    addi $a2, $a2, 4
    addi $a3, $a3, 4
    addi $t4, $t4, 4
    
    addi $s5, $sp, -4
    jal check_block_D
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

check_block_D:
    add $s5, $s5, 4
    lw $t8, 0($s5)
    beq $t8, $s2, do_not_move_D
    beq $t8, $a2, do_not_move_D
    beq $t8, $a3, do_not_move_D
    beq $t8, $t4, do_not_move_D
    beq $t8, $zero, return
    b check_block_D
    
do_not_move_D:
    addi $s2, $s2, -4
    addi $a2, $a2, -4
    addi $a3, $a3, -4
    addi $t4, $t4, -4
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

respond_to_W:
    # save values of registers in a temporary space
    la $t9, tmp_store 
    sw $a0, 0($t9)
    addi $t9, $t9, 4
    sw $a2, 0($t9)
    addi $t9, $t9, 4
    sw $a3, 0($t9)
    
    jal play_sound_move                  # make a sound effect 
    # update registers
    lw $a3, 0($t9)
    addi $t9, $t9, -4
    lw $a2, 0($t9)
    addi $t9, $t9, -4
    lw $a0, 0($t9)
    lw $a1, block_type
    
    lw $t9, light_grey
    beq $a1, 8, rotate_s
	beq $a1, 9, rotate_i
	beq $a1, 10, rotate_z
	beq $a1, 11, rotate_o
	beq $a1, 12, rotate_l
	beq $a1, 13, rotate_j
	beq $a1, 14, rotate_t

rotate_s:
    addi $s7, $t0, 960
    add $s4, $zero, $zero
    addi $s4, $a3, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    
    beq $v1, 1, rotate_clockwise_s    # rotate back to original position if already rotated once
    
    jal paint_bg
    jal paint
    
    addi $s2, $s2, -4
    addi $a2, $a2, 56
    addi $a3, $a3, 4
    addi $t4, $t4, 64
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 1
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

rotate_clockwise_s:
    addi $a2, $a2, 12
    div $a2, $t7
    mfhi $s4
    
    addi $a2, $a2, -12
    beq $s4, $zero, game_loop
    
    jal paint_bg
    jal paint
    addi $s2, $s2, 4
    addi $a2, $a2, -56
    addi $a3, $a3, -4
    addi $t4, $t4, -64
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 0
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_i:    
    addi $s7, $t0, 960
    add $s4, $zero, $zero
    addi $s4, $a3, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    
    beq $v1, 1, rotate_clockwise_i    # rotate back to original position if already rotated once
    
    addi $s2, $s2, 60
    div $s2, $t7
    mfhi $s4
    
    addi $s2, $s2, -60
    beq $s4, $zero, game_loop
    
    addi $a3, $a3, -56
    div $a3, $t7
    mfhi $s4
    
    addi $a3, $a3, 56
    beq $s4, $zero, game_loop
    
    addi $t4, $t4, -116
    div $t4, $t7
    mfhi $s4
    
    addi $t4, $t4, 116
    beq $s4, $zero, game_loop
    
    jal paint_bg
    jal paint
    
    addi $s2, $s2, 60
    addi $a2, $a2, 0
    addi $a3, $a3, -60
    addi $t4, $t4, -120
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 1
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_clockwise_i:
    jal paint_bg
    jal paint
    addi $s2, $s2, -60
    addi $a2, $a2, 0
    addi $a3, $a3, 60
    addi $t4, $t4, 120
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 0
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_z:
    addi $s7, $t0, 960
    add $s4, $zero, $zero
    addi $s4, $a3, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    
    beq $v1, 1, rotate_clockwise_z
    
    jal paint_bg
    jal paint
    
    addi $s2, $s2, 8
    addi $a2, $a2, 128
    addi $a3, $a3, 0
    addi $t4, $t4, 0
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 1
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_clockwise_z:
    addi $s2, $s2, -8
    div $s2, $t7
    mfhi $s4
    
    addi $s2, $s2, 8
    beq $s4, $zero, game_loop
    
    jal paint_bg
    jal paint
    addi $s2, $s2, -8
    addi $a2, $a2, -128
    addi $a3, $a3, 0
    addi $t4, $t4, 0
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 0
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop
    
rotate_o:
    b game_loop

rotate_l:
    addi $s7, $t0, 960
    add $s4, $zero, $zero
    addi $s4, $a3, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    
    beq $v1, 1, rotate_l_1
    beq $v1, 2, rotate_l_2
    beq $v1, 3 rotate_l_3
    
    addi $t4, $t4, -8
    div $t4, $t7
    mfhi $s4
    
    addi $t4, $t4, 8
    beq $s4, $zero, game_loop
    
    jal paint_bg
    jal paint
    
    addi $s2, $s2, 68
    addi $a2, $a2, 0
    addi $a3, $a3, -68
    addi $t4, $t4, -8
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 1
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_l_1:
    jal paint_bg
    jal paint
    addi $s2, $s2, 60
    addi $a2, $a2, 0
    addi $a3, $a3, -60
    addi $t4, $t4, -128
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 2
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop
    
rotate_l_2:
    addi $t4, $t4, 12
    div $t4, $t7
    mfhi $s4
    
    addi $t4, $t4, -12
    beq $s4, $zero, game_loop
    
    jal paint_bg
    jal paint
    addi $s2, $s2, -68
    addi $a2, $a2, 0
    addi $a3, $a3, 68
    addi $t4, $t4, 8
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 3
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_l_3:
    jal paint_bg
    jal paint
    
    addi $s2, $s2, -60
    addi $a2, $a2, 0
    addi $a3, $a3, 60
    addi $t4, $t4, 128
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 0
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_j:
    addi $s7, $t0, 960
    add $s4, $zero, $zero
    addi $s4, $a3, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    
    beq $v1, 1, rotate_j_1
    beq $v1, 2, rotate_j_2
    beq $v1, 3 rotate_j_3
    
    addi $s2, $s2, 72
    div $s2, $t7
    mfhi $s4
    
    addi $s2, $s2 -72
    beq $s4, $zero, game_loop
    
    jal paint_bg
    jal paint
    
    addi $s2, $s2, 68
    addi $a2, $a2, 0
    addi $a3, $a3, -128
    addi $t4, $t4, -68
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 1
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_j_1:    
    jal paint_bg
    jal paint
    
    addi $s2, $s2, 60
    addi $a2, $a2, 0
    addi $a3, $a3, 8
    addi $t4, $t4, -60
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 2
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_j_2:
    addi $s2, $s2, -68
    div $s2, $t7
    mfhi $s4
    
    addi $s2, $s2 68
    beq $s4, $zero, game_loop
    
    jal paint_bg
    jal paint
    
    addi $s2, $s2, -68
    addi $a2, $a2, 0
    addi $a3, $a3, 128
    addi $t4, $t4, 68
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 3
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_j_3:
    jal paint_bg
    jal paint
    
    addi $s2, $s2, -60
    addi $a2, $a2, 0
    addi $a3, $a3, -8
    addi $t4, $t4, 60
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 0
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_t:
    addi $s7, $t0, 960
    add $s4, $zero, $zero
    addi $s4, $a3, 64
    sle $s6, $s7, $s4
    bne $s6, $zero, new_block
    
    beq $v1, 1, rotate_t_1
    beq $v1, 2, rotate_t_2
    beq $v1, 3 rotate_t_3
    
    jal paint_bg
    jal paint
    
    addi $s2, $s2, 4
    addi $a2, $a2, 64
    addi $a3, $a3, 124
    addi $t4, $t4, -4
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 1
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_t_1:
    jal paint_bg
    jal paint
    
    addi $s2, $s2, 68
    addi $a2, $a2, 0
    addi $a3, $a3, -68
    addi $t4, $t4, -60
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 2
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_t_2:
    jal paint_bg
    jal paint
    
    addi $s2, $s2, 60
    addi $a2, $a2, 0
    addi $a3, $a3, -60
    addi $t4, $t4, 68
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 3
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

rotate_t_3:
    jal paint_bg
    jal paint
    
    addi $s2, $s2, -68
    addi $a2, $a2, 0
    addi $a3, $a3, 68
    addi $t4, $t4, 60
    
    addi $s5, $sp, -4
    jal check_block_Q
    
    li $v1, 0
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop

check_block_Q:
    add $s5, $s5, 4
    lw $t8, 0($s5)
    beq $t8, $s2, do_not_move_Q
    beq $t8, $a2, do_not_move_Q
    beq $t8, $a3, do_not_move_Q
    beq $t8, $t4, do_not_move_Q
    beq $t8, $zero, return
    b check_block_Q
    
do_not_move_Q:
    lw $a1, block_type
    beq $a1, 8, dnm_s
	beq $a1, 9, dnm_i
	beq $a1, 10, dnm_z
	beq $a1, 12, dnm_l
	beq $a1, 13, dnm_j
	beq $a1, 14, dnm_t

dnm_s:
    beq $v1, 1, return_Q_clockwise_s
    beq $v1, 0, return_Q_s

return_Q_s:
    addi $s2, $s2, 4
    addi $a2, $a2, -56
    addi $a3, $a3, -4
    addi $t4, $t4, -64
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

return_Q_clockwise_s:
    addi $s2, $s2, -4
    addi $a2, $a2, 56
    addi $a3, $a3, 4
    addi $t4, $t4, 64
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

dnm_i:
    beq $v1, 1, return_Q_clockwise_i
    beq $v1, 0, return_Q_i

return_Q_i:
    addi $s2, $s2, -60
    addi $a2, $a2, 0
    addi $a3, $a3, 60
    addi $t4, $t4, 120
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

return_Q_clockwise_i:
    addi $s2, $s2, 60
    addi $a2, $a2, 0
    addi $a3, $a3, -60
    addi $t4, $t4, -120
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

dnm_z:
    beq $v1, 1, return_Q_clockwise_z
    beq $v1, 0, return_Q_z

return_Q_z:
    addi $s2, $s2, -8
    addi $a2, $a2, -128
    addi $a3, $a3, 0
    addi $t4, $t4, 0
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

return_Q_clockwise_z:
    addi $s2, $s2, 8
    addi $a2, $a2, 128
    addi $a3, $a3, 0
    addi $t4, $t4, 0
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
dnm_l:
    beq $v1, 0, return_Q_l
    beq $v1, 1, return_Q_l_1
    beq $v1, 2, return_Q_l_2
    beq $v1, 3, return_Q_l_3

return_Q_l:
    addi $s2, $s2, -68
    addi $a2, $a2, 0
    addi $a3, $a3, 68
    addi $t4, $t4, 8
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

return_Q_l_1:
    addi $s2, $s2, -60
    addi $a2, $a2, 0
    addi $a3, $a3, 60
    addi $t4, $t4, 128
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
return_Q_l_2:
    addi $s2, $s2, 68
    addi $a2, $a2, 0
    addi $a3, $a3, -68
    addi $t4, $t4, -8
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
return_Q_l_3:
    addi $s2, $s2, 60
    addi $a2, $a2, 0
    addi $a3, $a3, -60
    addi $t4, $t4, -128
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
dnm_j:
    beq $v1, 0, return_Q_j
    beq $v1, 1, return_Q_j_1
    beq $v1, 2, return_Q_j_2
    beq $v1, 3, return_Q_j_3

return_Q_j:
    addi $s2, $s2, -68
    addi $a2, $a2, 0
    addi $a3, $a3, 128
    addi $t4, $t4, 68
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

return_Q_j_1:
    addi $s2, $s2, -60
    addi $a2, $a2, 0
    addi $a3, $a3, -8
    addi $t4, $t4, 60
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
return_Q_j_2:
    addi $s2, $s2, 68
    addi $a2, $a2, 0
    addi $a3, $a3, -128
    addi $t4, $t4, -68
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
return_Q_j_3:
    addi $s2, $s2, 60
    addi $a2, $a2, 0
    addi $a3, $a3, 8
    addi $t4, $t4, -60
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

dnm_t:
    beq $v1, 0, return_Q_t
    beq $v1, 1, return_Q_t_1
    beq $v1, 2, return_Q_t_2
    beq $v1, 3, return_Q_t_3

return_Q_t:
    addi $s2, $s2, -4
    addi $a2, $a2, -64
    addi $a3, $a3, -124
    addi $t4, $t4, 4
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

return_Q_t_1:
    addi $s2, $s2, -60
    addi $a2, $a2, 0
    addi $a3, $a3, 68
    addi $t4, $t4, 60
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
return_Q_t_2:
    addi $s2, $s2, -60
    addi $a2, $a2, 0
    addi $a3, $a3, 60
    addi $t4, $t4, -68
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
return_Q_t_3:
    addi $s2, $s2, 68
    addi $a2, $a2, 0
    addi $a3, $a3, -68
    addi $t4, $t4, -60
    
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
paint_bg:
    beq $t6, 120, paint_bg_even     # alternate the coordinates with each row to 
                                    # get a checkered pattern
    lw $t2, dark_grey
    lw $t9, light_grey
    sw $t2, 0($t0)
    sw $t9, 4($t0)
    addi $t0, $t0, 8
    
    addi $t6, $t6, 1
    
    div $t0, $t7
    mfhi $t8
    beq $t8, $zero, paint_bg_even
    
    j paint_bg

paint_bg_even:
    beq $t6, 120, reset_t0

    sw $t2, 4($t0)
    sw $t9, 8($t0)
    addi $t0, $t0, 8
    
    addi $t6, $t6, 1
    
    div $t0, $t7
    mfhi $t8
    beq $t8, $zero, paint_bg
    
    j paint_bg_even

return:
    jr $ra                          # jump back to previous position

reset_t0:
    lw $t0, ADDR_DSPL
    b paint_wall

paint_wall:                         # display walls for the game
    beq $t5, 15, paint_floor
    
    lw $t1, white_color
    
    sw $t1, 0($t0)
    sw $t1, 60($t0)
    addi $t0, $t0, 64
    
    addi $t5, $t5, 1
    j paint_wall

paint_floor:                        # display the floor for the game
    bne $s1, $zero, return
    beq $t4, 16, game_loop
    
    lw $t1, white_color
    
    sw $t1, 0($t0)
    addi $t0, $t0,4
    
    addi $t4, $t4, 1
    j paint_floor

draw_block_s:                       # draw block with s shape
    addi $a1, $a1, 7
    sw $a1, block_type
    lw $s0, ADDR_DSPL
    li $s1, 0xff0000
    
    addi $s2, $s0, 32
    addi $a2, $s0, 36
    addi $a3, $s0, 92
    addi $t4, $s0, 96
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    
    b game_loop
    
draw_block_i:                       # draw block with l shape
    addi $a1, $a1, 7
    sw $a1, block_type
    lw $s0, ADDR_DSPL
    li $s1, 0x00ffff
    
    addi $s2, $s0, 32
    addi $a2, $s0, 96
    addi $a3, $s0, 160
    addi $t4, $s0, 224
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
draw_block_z:
    addi $a1, $a1, 7
    sw $a1, block_type
    lw $s0, ADDR_DSPL
    li $s1, 0x00ff00
    
    addi $s2, $s0, 28
    addi $a2, $s0, 32
    addi $a3, $s0, 100
    addi $t4, $s0, 96
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop

draw_block_o:
    addi $a1, $a1, 7
    sw $a1, block_type
    lw $s0, ADDR_DSPL
    li $s1, 0xffff00
    
    addi $s2, $s0, 28
    addi $a2, $s0, 32
    addi $a3, $s0, 92
    addi $t4, $s0, 96
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
draw_block_l:
    addi $a1, $a1, 7
    sw $a1, block_type
    lw $s0, ADDR_DSPL
    li $s1, 0xffa500
    
    addi $s2, $s0, 28
    addi $a2, $s0, 92
    addi $a3, $s0, 156
    addi $t4, $s0, 160
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
draw_block_j:
    addi $a1, $a1, 7
    sw $a1, block_type
    lw $s0, ADDR_DSPL
    li $s1, 0xff6ec7
    
    addi $s2, $s0, 32
    addi $a2, $s0, 96
    addi $a3, $s0, 156
    addi $t4, $s0, 160
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    
draw_block_t:
    addi $a1, $a1, 7
    sw $a1, block_type
    lw $s0, ADDR_DSPL
    li $s1, 0x800080
    
    addi $s2, $s0, 28
    addi $a2, $s0, 32
    addi $a3, $s0, 36
    addi $t4, $s0, 96
    sw $s1, 0($s2)
    sw $s1, 0($a2)
    sw $s1, 0($a3)
    sw $s1, 0($t4)
    b game_loop
    

# play sound effects
play_sound_Q:       # sound when press q
    li $v0, 33    # async play note syscall
    li $a0, 60    # midi pitch
    li $a1, 500  # duration
    li $a2, 127    # instrument
    li $a3, 100   # volume
    syscall
    jr $ra

play_sound_P:       # sound when press p
    li $v0, 33    # async play note syscall
    li $a0, 60    # midi pitch
    li $a1, 500  # duration
    li $a2, 50    # instrument
    li $a3, 100   # volume
    syscall
    jr $ra

play_sound_move:    # sound when press W, A, S, D
    li $v0, 33    # async play note syscall
    li $a0, 60    # midi pitch
    li $a1, 100  # duration
    li $a2, 13    # instrument
    li $a3, 100   # volume
    syscall
    jr $ra

play_sound_GO:      # sound when game is over
    li $v0, 33    # async play note syscall
    li $a0, 60    # midi pitch
    li $a1, 500  # duration
    li $a2, 127    # instrument
    li $a3, 100   # volume
    syscall
    jr $ra
    

replay:             # replay the game
    # clear all tmeporary storage
    la $t9, tmp_store
    sw $zero, 0($t9)
    addi $t9, $t9, 4
    sw $zero, 0($t9)
    addi $t9, $t9, 4
    sw $zero, 0($t9)
    
    la $t9, tmp_block
    sw $zero, 0($t9)
    addi $t9, $t9, 4
    sw $zero, 0($t9)
    addi $t9, $t9, 4
    sw $zero, 0($t9)
    addi $t9, $t9, 4
    sw $zero, 0($t9)
    
    # clear the stack
    j clear_stack


clear_register:         # clear all registers
    addi $a1, $zero, 1
    sw $a1, block_type

    li $v0, 0
    li $v1, 0
    
    li $a0, 0
    li $a1, 0
    li $a2, 0
    li $a3, 0
    
    li $t0, 0
    li $t1, 0
    li $t2, 0
    li $t3, 0
    li $t4, 0
    li $t5, 0
    li $t6, 0
    li $t7, 0
    li $t8, 0
    
    li $s0, 0
    li $s1, 0
    li $s2, 0
    li $s3, 0
    li $s4, 0
    li $s5, 0
    li $s6, 0
    li $s7, 0
    
    # call main function to initialize and play the game again from the beginning
    b main
    

clear_stack:        # clear the stack 
    lw $t9, 0($sp)
    beq $t9, $zero, clear_register  # if reached the end of the stack, clear all the registers
    sw $zero 0($sp)
    addi $sp, $sp, 4
    b clear_stack
    

game_over:              # when the game is over
    # save values of registers in a temporary space
    la $t9, tmp_store 
    sw $a0, 0($t9)
    addi $t9, $t9, 4
    sw $a2, 0($t9)
    addi $t9, $t9, 4
    sw $a3, 0($t9)
    
    jal play_sound_GO                  # make a sound effect 
    # update registers
    lw $a3, 0($t9)
    addi $t9, $t9, -4
    lw $a2, 0($t9)
    addi $t9, $t9, -4
    lw $a0, 0($t9)
    lw $a1, block_type
    lw $t9, light_grey
    j draw_game_over
    
check_go:               # check for user input on what to do when game is over
    li 		$v0, 32
	li 		$a0, 1
	
    lw $s5, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($s5)                  # Load first word from keyboard
    beq $t8, 1, go_input      # If first word 1, key is pressed

go_input:
    lw $a0, 4($s5)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x72, replay           # check if key r was pressed, then replay the game from scratch

draw_game_over:     # prints out "GAME OVER"
    lw $t0, ADDR_DSPL
    lw $t1, game_over_dark  # start with dark color
    addi $t0, $t0, 128
    j draw_G        # draw each letter of "GAME OVER"
   
draw_G:
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 56
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    jal draw_A

draw_A:
    lw $t1, game_over_light
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 8
    sw $t1, 0($t0)
    
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    
    addi $t0, $t0, 128
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    
    addi $t0, $t0, -8
    sw $t1, 0($t0)
    jal draw_M
   
    
draw_M:
    lw $t1, game_over_dark
    addi $t0, $t0, 12
    sw $t1, 0($t0)
    
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, -64
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, -64
    addi, $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    jal draw_E_up
    
draw_E_up:
    lw $t1, game_over_light
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, -256
    sw $t1, 0($t0)
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    jal draw_R
    
draw_R:
    lw $t1, game_over_dark
    addi $t0, $t0, 320
    sw $t1, 0($t0)
    
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    
    addi $t0, $t0, 8
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    
    addi $t0, $t0, -64
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 8
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    jal draw_E_down
    
draw_E_down:
    lw $t1, game_over_light
    addi $t0, $t0, -16
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    
    addi $t0, $t0, 128
    sw $t1, 0($t0)
    addi $t0, $t0, 128
    sw $t1, 0($t0)
    
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    
    addi $t0, $t0, -128
    sw $t1, 0($t0)
    addi $t0, $t0, -128
    sw $t1, 0($t0)
    
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    jal draw_V
    
draw_V:
    lw $t1, game_over_dark
    addi $t0, $t0, -8
    sw $t1, 0($t0)
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    
    addi $t0, $t0, -64
    addi $t0, $t0, 8
    sw $t1, 0($t0)
    
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    
    addi $t0, $t0, -12
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    jal draw_O
    
draw_O:
    lw $t1, game_over_light
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    addi $t0, $t0, -64
    sw $t1, 0($t0)
    
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    addi $t0, $t0, -4
    sw $t1, 0($t0)
    
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    addi $t0, $t0, 64
    sw $t1, 0($t0)
    
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sw $t1, 0($t0)
    j check_go      # check for user keyboard input

save_to_grid:
    lw $t0, ADDR_DSPL
    sub $s2, $s2, $t0
    sub $a2, $a2, $t0
    sub $a3, $a3, $t0
    sub $t4, $t4, $t0
    add $t7, $t3, $s2
    sw $a1 , 0($t7)
    add $t7, $t3, $a2
    sw $a1 , 0($t7)
    add $t7, $t3, $a3
    sw $a1 , 0($t7)
    add $t7, $t3, $t4
    sw $a1 , 0($t7)
    add $s2, $s2, $t0
    add $a2, $a2, $t0
    add $a3, $a3, $t0
    add $t4, $t4, $t0
    
    li $t7, 64
    jr $ra

check_line:
    beq $t6, $zero, game_loop
    add $t5, $zero, $zero
    mult $t7, $t6, 64
    add $t7, $t3, $t7
    b check_block

check_block:
    beq $t5, 14, clear_row_setup
    addi $t7, $t7, 4
    lw $t8, 0($t7)
    beq $t8, $zero, decrement 
    addi $t5, $t5, 1
    b check_block

decrement:
    addi $t6, $t6, -1
    b check_line

clear_row_setup:
    add $t5, $zero, $zero
    add $a0, $sp, $zero
    add $v0, $zero, $zero
    b clear_row

clear_row:
    lw $t8, 0($t7)
    sub $t7, $t7, $t3
    add $t7, $t7, $t0
    lw $s5, 0($a0)
    beq $s5, $t7, remove_block
    sub $t7, $t7, $t0
    add $t7, $t7, $t3
    sw $s5, 0($a0)
    beq $s5, $zero, move_rows
    addi $a0, $a0, 4
    add $v0, $v0, 4
    b clear_row

remove_block:
    jal remove_pixel_from_sp
    sub $t7, $t7, $t0
    add $t7, $t7, $t3
    lw $a0, 0($t7)
    sw $zero, 0($t7)
    add $t7, $t7, -4
    add $a0, $sp, $zero
    add $v0, $zero, $zero
    addi $t5, $t5, 1
    beq $t5, 14, move_rows
    b clear_row

remove_pixel_from_sp:
    lw $t0, ADDR_DSPL
    add $sp, $sp, $v0
    lw $s5, 0($sp)
    sw $zero, 0($sp)
    b remove_gap_in_stack

remove_gap_in_stack:
    addi $sp, $sp, 4
    lw $s5, 0($sp)
    addi $sp, $sp, -4
    sw $s5, 0($sp)
    addi $sp, $sp, 4
    addi $v0, $v0, 4
    lw $s5, 0($sp)
    beq $s5, $zero, return_to_remove_block
    b remove_gap_in_stack

return_to_remove_block:
    sub $sp, $sp, $v0
    jr $ra
    
move_rows:
    lw $t0, ADDR_DSPL
    add $v0, $zero, $zero
    addi $t5, $t6, 1
    li $t7, 64
    mult $t5, $t7, $t5
    add $t5, $t5, $t0
    lw $s5, 0($sp)
    # sw $s1 0($t5)
    b actually_move_rows

actually_move_rows:
    beq $s5, 0xff0000, move_to_next
    beq $s5, 0x00ffff, move_to_next
    beq $s5, 0x00ff00, move_to_next
    beq $s5, 0xffff00, move_to_next
    beq $s5, 0xffa500, move_to_next
    beq $s5, 0xff6ec7, move_to_next
    beq $s5, 0x800080, move_to_next
    beq $s5, $zero, do_smth
    slt $t0, $s5, $t5
    bne $t0, $zero, actually_actually_move_the_row
    addi $sp, $sp, 4
    addi $v0, $v0, 4
    lw $s5, 0($sp)
    beq $s5, $zero, do_smth
    b actually_move_rows

actually_actually_move_the_row:
    lw $t0, ADDR_DSPL
    sub $s5, $s5, $t0
    add $a0, $t3, $s5
    sw $zero, 0($a0)
    add $s5, $s5, $t0
    addi $s5, $s5, 64
    sw $s5, 0($sp)
    sub $s5, $s5, $t0
    add $a0, $t3, $s5
    sw $a1, 0($a0)
    add $s5, $s5, $t0
    addi $sp, $sp, 4
    addi $v0, $v0, 4
    lw $s5, 0($sp)
    
    beq $s5, $zero, do_smth
    b actually_move_rows

do_smth:
    sub $sp, $sp, $v0
    b continue_loop

move_to_next:
    add $sp, $sp, 4
    add $v0, $v0, 4
    lw $s5, 0($sp)
    b actually_move_rows

continue_loop:
    beq $t6, $zero, game_loop
    b check_line