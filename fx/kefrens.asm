\ ******************************************************************
\ *	Kefrens bars
\ ******************************************************************

kefrens_dummy = locals_start + 0
kefrens_index_offset = locals_start + 1
kefrens_crtc_row = locals_start + 2
kefrens_bar_index = locals_start + 3

.kefrens_start

\ ******************************************************************
\ Initialise FX
\
\ The initialise function is used to set up all variables, tables and
\ any precalculated screen memory etc. required for the FX.
\
\ This function will be called during vblank
\ The CRTC registers & ULA will be set to default MODE 2 values
\ The screen display will already be turned OFF with CRTC R8
\
\ The function can take as long as is necessary to initialise BUT:
\ MUST BE RESPONSIBLE FOR POLLING THE MUSIC PLAYER IF A VSYNC OCCURS
\ There are* helper functions to assit with this for decrunch etc.
\ ******************************************************************

.kefrens_init
{
    STZ kefrens_index_offset
	RTS
}

\ ******************************************************************
\ Update FX
\
\ The update function is used to update / tick any variables used
\ in the FX. It may also prepare part of the screen buffer before
\ drawing commenses but note the strict timing constraints!
\
\ This function will be called during vblank, after the music player
\ has been polled and after the scripting system has been updated
\
\ The function MUST COMPLETE BEFORE TIMER 1 REACHES 0, i.e. before
\ scanline 0 begins. If you are late then the draw function will be
\ late and your raster timings will be wrong!
\ ******************************************************************

.kefrens_update
{
	INC kefrens_index_offset
	LDX #0
	JSR screen_clear_line_0X
	LDX #1
	JSR screen_clear_line_0X
	RTS
}

\ ******************************************************************
\ Draw FX
\
\ The draw function is the main body of the FX.
\
\ This function will be exactly at the start* of scanline 0 with a
\ maximum jitter of up to +10 cycles.
\
\ This means that a new CRTC cycle has just started! If you didn't
\ specify the registers from the previous frame then they will be
\ the default MODE 2 values as per initialisation.
\
\ If messing with CRTC registers, THIS FUNCTION MUST ALWAYS PRODUCE
\ A FULL AND VALID 312 line PAL signal before exiting!
\ ******************************************************************

.kefrens_draw
{
	\\ We're only ever going to display this one scanline
	LDA #12: STA &FE00
	LDA #HI(screen_base_addr/8): STA &FE01

	LDA #13: STA &FE00
	LDA #LO(screen_base_addr/8): STA &FE01

	\\ R9=0 - character row = 2 scanline
	LDA #9: STA &FE00
	LDA #1:	STA &FE01

	\\ R4=0 - CRTC cycle is one row
	LDA #4: STA &FE00
	LDA #0: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #&FF: STA &FE01

	\\ R6=1 - one row displayed
	LDA #6: STA &FE00
	LDA #1: STA &FE01

;	FOR n,1,14,1
;	NOP
;	NEXT

	JSR cycles_wait_128

	LDA #126
	STA kefrens_crtc_row

	STZ kefrens_bar_index
	LDX kefrens_index_offset

	.here

IF 0
	LDA kefrens_code_table_LO, Y		; 4c
	STA jump_command+1			; 4c
	LDA kefrens_code_table_HI, Y		; 4c
	STA jump_command+2			; 4c

	INY
	;TXA
	LDA kefrens_colour_lookup_A, X		; 4c-2c

	.jump_command
	JSR &FFFF					; 6c

	\\ 16+2+6 = 24c + 8c loop = 32c fn must take 96c including RTS

	BIT 0						; 3c
ELSE

	LDA kefrens_sine_table, X		; 4c
	TAY								; 2c
\	CPY #40							; 2c
\	BCC left_side_nop_later
									; 2c
	\\ Right side NOP first
\	FOR n,1,13,1
\	NOP
\	NEXT

	.left_side_nop_later
	LDA kefrens_addr_table_LO, Y	; 4c
	STA writeptr					; 3c
	LDA kefrens_addr_table_HI, Y	; 4c
	STA writeptr+1					; 3c

	LDY kefrens_bar_index			; 3c
	LDA kefrens_colour_lookup_A, Y	; 4c
	LDY #0:STA (writeptr), Y		; 8c
	LDY #8:STA (writeptr), Y
	LDY #16:STA (writeptr), Y
	LDY #24:STA (writeptr), Y
	LDY #32:STA (writeptr), Y
	LDY #40:STA (writeptr), Y
	LDY #48:STA (writeptr), Y
	LDY #56:STA (writeptr), Y
	\\ 8*8c = 64c

	LDY kefrens_bar_index			; 3c
	LDA kefrens_colour_lookup_B, Y	; 4c
	LDY #1:STA (writeptr), Y		; 8c
	LDY #9:STA (writeptr), Y
	LDY #17:STA (writeptr), Y
	LDY #25:STA (writeptr), Y
	LDY #33:STA (writeptr), Y
	LDY #41:STA (writeptr), Y
	LDY #49:STA (writeptr), Y
	LDY #57:STA (writeptr), Y
	INC kefrens_bar_index
	\\ 8*8c = 64c

	FOR n,1,37,1
	NOP
	NEXT
	BIT 0

	.continue
	INX								; 2c

ENDIF

	DEC kefrens_crtc_row
	BEQ done
	JMP here		; 3c
	.done
	\\ R9=0 - character row = 2 scanlines
	LDA #9: STA &FE00
	LDA #2-1:	STA &FE01		; 2 scanline

	\\ R4=56 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #28-1+1: STA &FE01		; 312 - 256 = 56 scanlines = 28 rows

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #12+1: STA &FE01			; 280 - 256 = 24 scanlines = 12 rows

	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #1: STA &FE01
	
    RTS
}

NUM_NOPS=27

IF 0
.kefrens_code_gen
FOR x,0,79,1
{
	\\ Code must take 96c including RTS = 6c = 90c total
	;N%=x DIV 2
	N%=0
	PRINT N%
	IF N% < 1
	; no NOPs	
	ELIF N% < NUM_NOPS
	FOR i,1,N%,1
	NOP
	NEXT
	ELSE
	FOR i,1,NUM_NOPS,1
	NOP
	NEXT
	ENDIF
	STA &3000 + x * 8
	STA &3008 + x * 8
	STA &3010 + x * 8
	STA &3018 + x * 8
	STA &3020 + x * 8
	STA &3028 + x * 8
	STA &3030 + x * 8
	STA &3038 + x * 8
	\\ 8x 4c = 32c
	M%=NUM_NOPS-N%
	PRINT M%
	IF M% < 1
	; no NOPs
	ELIF M% < NUM_NOPS
	FOR i,1,M%,1
	NOP
	NEXT
	ELSE
	FOR i,1,NUM_NOPS,1
	NOP
	NEXT
	ENDIF
	\\ 30 NOPs = 60c
	RTS		; 6c
}
NEXT

PAGE_ALIGN
.kefrens_code_table_LO
FOR y,0,255,1
x=INT(36+30*SIN(y * 2 * PI / 255))
addr=kefrens_code_gen + x * (NUM_NOPS + 8 * 3 + 1)
EQUB LO(addr)
NEXT

PAGE_ALIGN
.kefrens_code_table_HI
FOR y,0,255,1
x=INT(36+30*SIN(y * 2 * PI / 255))
addr=kefrens_code_gen + x * (NUM_NOPS + 8 * 3 + 1)
EQUB HI(addr)
NEXT
ENDIF

PAGE_ALIGN
.kefrens_colour_lookup_A
{
	FOR n,0,15,1
	EQUB PIXEL_LEFT_0 OR PIXEL_RIGHT_0			; 0 = black
	EQUB PIXEL_LEFT_1 OR PIXEL_RIGHT_0			; 1 = red/black
	EQUB PIXEL_LEFT_1 OR PIXEL_RIGHT_1			; 2 = red/red
	EQUB PIXEL_LEFT_3 OR PIXEL_RIGHT_1			; 3 = yellow/red
	EQUB PIXEL_LEFT_3 OR PIXEL_RIGHT_3			; 4 = yellow/yellow
	EQUB PIXEL_LEFT_2 OR PIXEL_RIGHT_3			; 5 = green/yellow
	EQUB PIXEL_LEFT_2 OR PIXEL_RIGHT_2			; 6 = green/green
	EQUB PIXEL_LEFT_6 OR PIXEL_RIGHT_2			; 7 = cyan/green
	EQUB PIXEL_LEFT_6 OR PIXEL_RIGHT_6			; 8 = cyan/cyan
	EQUB PIXEL_LEFT_4 OR PIXEL_RIGHT_6			; 9 = blue/cyan
	EQUB PIXEL_LEFT_4 OR PIXEL_RIGHT_4			;10 = blue/blue
	EQUB PIXEL_LEFT_5 OR PIXEL_RIGHT_4			;11 = magenta/blue
	EQUB PIXEL_LEFT_5 OR PIXEL_RIGHT_5			;12 = magenta/magenta
	EQUB PIXEL_LEFT_7 OR PIXEL_RIGHT_5			;13 = white/magenta
	EQUB PIXEL_LEFT_7 OR PIXEL_RIGHT_7			;14 = white/white
	EQUB PIXEL_LEFT_0 OR PIXEL_RIGHT_7			;15 = black/white
	\\ Or can wrap around to red again
	NEXT
}

PAGE_ALIGN
.kefrens_colour_lookup_B
{
	FOR n,0,15,1
	EQUB PIXEL_RIGHT_0 OR PIXEL_LEFT_0			; 0 = black
	EQUB PIXEL_RIGHT_1 OR PIXEL_LEFT_0			; 1 = red/black
	EQUB PIXEL_RIGHT_1 OR PIXEL_LEFT_1			; 2 = red/red
	EQUB PIXEL_RIGHT_3 OR PIXEL_LEFT_1			; 3 = yellow/red
	EQUB PIXEL_RIGHT_3 OR PIXEL_LEFT_3			; 4 = yellow/yellow
	EQUB PIXEL_RIGHT_2 OR PIXEL_LEFT_3			; 5 = green/yellow
	EQUB PIXEL_RIGHT_2 OR PIXEL_LEFT_2			; 6 = green/green
	EQUB PIXEL_RIGHT_6 OR PIXEL_LEFT_2			; 7 = cyan/green
	EQUB PIXEL_RIGHT_6 OR PIXEL_LEFT_6			; 8 = cyan/cyan
	EQUB PIXEL_RIGHT_4 OR PIXEL_LEFT_6			; 9 = blue/cyan
	EQUB PIXEL_RIGHT_4 OR PIXEL_LEFT_4			;10 = blue/blue
	EQUB PIXEL_RIGHT_5 OR PIXEL_LEFT_4			;11 = magenta/blue
	EQUB PIXEL_RIGHT_5 OR PIXEL_LEFT_5			;12 = magenta/magenta
	EQUB PIXEL_RIGHT_7 OR PIXEL_LEFT_5			;13 = white/magenta
	EQUB PIXEL_RIGHT_7 OR PIXEL_LEFT_7			;14 = white/white
	EQUB PIXEL_LEFT_0 OR PIXEL_RIGHT_7			;15 = black/white
	\\ Or can wrap around to red again
	NEXT
}

PAGE_ALIGN
.kefrens_addr_table_LO
FOR x,0,79,1
EQUB LO(screen_base_addr + x*8)
NEXT

.kefrens_addr_table_HI
FOR x,0,79,1
EQUB HI(screen_base_addr + x*8)
NEXT

PAGE_ALIGN
.kefrens_sine_table
FOR y,0,255,1
x=INT(36 + 30 * SIN(y * 2 * PI / 255))
EQUB x
NEXT

.kefrens_end
