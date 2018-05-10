\ ******************************************************************
\ *	Rotating texture map
\ ******************************************************************

TEXTURE_SEGMENTS = 8
TEXTURE_COLUMNS_PER_SEGMENT = TEXTURE_WIDTH_BYTES / TEXTURE_SEGMENTS
TEXTURE_SEGMENT_SIZE_BYTES = TEXTURE_COLUMNS_PER_SEGMENT * TEXTURE_HEIGHT_BYTES

\\ Centred 8 character rows down
TEXTURE_SCREEN_X = (80 - TEXTURE_WIDTH_BYTES)/2
TEXTURE_SCREEN_Y = (256 - TEXTURE_HEIGHT_BYTES)/2

texture_offset_ptrs = locals_start + 0
texture_offset_top = texture_offset_ptrs + TEXTURE_SEGMENTS * 2

texture_angle = texture_offset_top + 0

.texture_start

.texture_init
{
	\\ SET UP DOUBLE BUFFERING
	\\ CLEAR BOTH SCREENS
	STZ texture_angle

	LDX #0
	LDA texture_rotation_LO, X
	FOR n,0,TEXTURE_SEGMENTS-1,1
	STA texture_offset_ptrs + n*2
	NEXT
	LDA texture_rotation_HI, X
	FOR n,0,TEXTURE_SEGMENTS-1,1
	STA texture_offset_ptrs + 1 + n*2
	NEXT

    ; we set bits 0 and 2 of ACCCON, so that display=Main RAM, and shadow ram is selected as main memory
    lda &fe34
    and #255-1  ; set D to 0
    ora #4    	; set X to 1
    sta &fe34

	JMP screen_clear_all
}

.texture_update
{
	\\ SWAP BUFFERS
	\\ UPDATE ROTATION ANGLE
	\\ SPECIFY WHICH ANGLE EACH SEGMENT HAS BY UPDATING SEGMENT ROTATION PTRS
	{
		LDA texture_angle
		INC A
		CMP #TEXTURE_NUM_ANGLES
		BCC angle_ok
		LDA #0
		.angle_ok
		STA texture_angle
	}

	TAX
	LDA texture_rotation_LO, X
	LDY #0
	STA texture_offset_ptrs, Y
	LDA texture_rotation_HI, X
	INY
	STA texture_offset_ptrs, Y

	{
		.loop
		DEX
		BPL ok
		LDX #TEXTURE_NUM_ANGLES-1
		.ok
		LDA texture_rotation_LO, X
		INY
		STA texture_offset_ptrs, Y
		LDA texture_rotation_HI, X
		INY
		STA texture_offset_ptrs, Y
		CPY #(TEXTURE_SEGMENTS*2)-1
		BCC loop
	}

    lda &fe34
    eor #1+4	; invert bits 0 (CRTC) & 2 (RAM)
    sta &fe34

	RTS
}

.texture_kill
{
    ; we set bits 0 and 2 of ACCCON, so that display=Main RAM, and shadow ram is selected as main memory
    lda &fe34
    and #&fa	; set D and X to 0
    sta &fe34
	rts	
}

.texture_draw
{
	\\ We're double buffered so just need to complete within 32768 cycles...

	FOR segment,0,TEXTURE_SEGMENTS-1,1

	PRINT "SEGMENT ", segment

		\\ Each segment has own rotation
		LDY #0

	FOR row,0,TEXTURE_HEIGHT_BYTES-1,1

		\\ Each row has same offset
		LDA (texture_offset_ptrs + segment * 2), Y
		TAX

	FOR column,0,TEXTURE_COLUMNS_PER_SEGMENT-1,1

		LDA texture_data + (segment * TEXTURE_SEGMENT_SIZE_BYTES) + (column * TEXTURE_HEIGHT_BYTES), X

		screen_x = TEXTURE_SCREEN_X + segment * TEXTURE_COLUMNS_PER_SEGMENT + column
		screen_y = TEXTURE_SCREEN_Y + row

		screen_addr = &3000 + (screen_x * 8) +((screen_y DIV 8) * 640) + ((screen_y MOD 8))

		;PRINT "x=",screen_x,"y=",screen_y,"a=",~screen_addr

		STA screen_addr

	NEXT	

		\\ Next row
		INY

	NEXT

		\\ Next segment

	NEXT

    RTS
}

TEXTURE_CYCLES_PER_SEGMENT = 2
TEXTURE_CYCLES_PER_ROW = 8
TEXTURE_CYCLES_PER_COLUMN = 8

TEXTURE_TOTAL_CYCLES = ((TEXTURE_COLUMNS_PER_SEGMENT * TEXTURE_CYCLES_PER_COLUMN + TEXTURE_CYCLES_PER_ROW) * TEXTURE_HEIGHT_BYTES + TEXTURE_CYCLES_PER_SEGMENT) * TEXTURE_SEGMENTS

TEXTURE_CODE_PER_SEGMENT = 2
TEXTURE_CODE_PER_ROW = 4
TEXTURE_CODE_PER_COLUMN = 6

TEXTURE_TOTAL_CODE = ((TEXTURE_COLUMNS_PER_SEGMENT * TEXTURE_CODE_PER_COLUMN + TEXTURE_CODE_PER_ROW) * TEXTURE_HEIGHT_BYTES + TEXTURE_CODE_PER_SEGMENT) * TEXTURE_SEGMENTS

PRINT "------"
PRINT "TEXTURE INFO"
PRINT "------"
PRINT "SEGMENTS = ", TEXTURE_SEGMENTS
PRINT "TEXTURE DIMENSIONS = ", TEXTURE_WIDTH_BYTES, "x", TEXTURE_HEIGHT_BYTES
PRINT "TEXTURE TOTAL CYCLES = ", TEXTURE_TOTAL_CYCLES
PRINT "TEXTURE FRAME USED = ", TEXTURE_TOTAL_CYCLES/(256*128)
PRINT "TEXTURE TOTAL CODE SIZE = ", ~TEXTURE_TOTAL_CODE
PRINT "------"

.texture_end
