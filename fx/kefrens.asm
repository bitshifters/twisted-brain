\ ******************************************************************
\ *	Kefrens bars
\ ******************************************************************

kefrens_dummy = locals_start + 0
kefrens_index_offset = locals_start + 1

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
	JMP screen_clear_line0
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

	\\ R9=0 - character row = 1 scanline
	LDA #9: STA &FE00
	LDA #0:	STA &FE01

	\\ R4=0 - CRTC cycle is one row
	LDA #4: STA &FE00
	LDA #0: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #&FF: STA &FE01

	\\ R6=1 - one row displayed
	LDA #6: STA &FE00
	LDA #1: STA &FE01

	FOR n,1,14,1
	NOP
	NEXT

	LDX #2					; 2c
	LDY kefrens_index_offset

	.here

	\\ 8x6c = 48c
IF 0
	LDA #PIXEL_LEFT_1 + PIXEL_RIGHT_1: STA &3140
	LDA #PIXEL_LEFT_2 + PIXEL_RIGHT_2: STA &3148
	LDA #PIXEL_LEFT_3 + PIXEL_RIGHT_3: STA &3150
	LDA #PIXEL_LEFT_4 + PIXEL_RIGHT_4: STA &3158
	LDA #PIXEL_LEFT_5 + PIXEL_RIGHT_5: STA &3160
	LDA #PIXEL_LEFT_6 + PIXEL_RIGHT_6: STA &3168
	LDA #PIXEL_LEFT_7 + PIXEL_RIGHT_7: STA &3170
	LDA #PIXEL_LEFT_8 + PIXEL_RIGHT_8: STA &3178

	\\ Need 80-10 more cycles

	FOR n,1,35,1	; 
	NOP
	NEXT
	INC dummy		; 5c

ELSE
;	TXA
;	AND #&3F
;	TAY				; 6c

	LDA kefrens_code_table_LO, Y		; 4c
	STA jump_command+1			; 4c
	LDA kefrens_code_table_HI, Y		; 4c
	STA jump_command+2			; 4c

	INY
	TXA
;	LDA #PIXEL_LEFT_1 + PIXEL_RIGHT_1	;2c

	.jump_command
	JSR &FFFF					; 6c

	\\ 16+2+6 = 24c + 8c loop = 32c fn must take 96c including RTS

	BIT 0						; 3c
ENDIF
	
	INX				; 2c
	BNE here		; 3c

	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00
	LDA #1-1:	STA &FE01		; 1 scanline

	\\ R4=6 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #56-1+1: STA &FE01		; 312 - 256 = 56 scanlines

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #24+1: STA &FE01			; 280 - 256 = 24 scanlines

	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #1: STA &FE01
	
    RTS
}

NUM_NOPS=28

.kefrens_code_gen
FOR x,0,79,1
{
	\\ Code must take 96c including RTS = 6c = 90c total
	N%=x DIV 2
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

.kefrens_code_table_HI
FOR y,0,255,1
x=INT(36+30*SIN(y * 2 * PI / 255))
addr=kefrens_code_gen + x * (NUM_NOPS + 8 * 3 + 1)
EQUB HI(addr)
NEXT

.kefrens_end
