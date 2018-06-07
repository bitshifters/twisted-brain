\ ******************************************************************
\ *	Kefrens bars
\ ******************************************************************

kefrens_dummy = locals_start + 0
kefrens_crtc_row = locals_start + 1
kefrens_top_angle = locals_start + 2
kefrens_row_angle = locals_start + 3
kefrens_top_add = locals_start + 4
kefrens_add_index = locals_start + 5

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
	STZ kefrens_top_angle
	STZ kefrens_top_add
	
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
	LDX #0
	JSR screen_clear_line_0X

	DEC kefrens_top_angle
	LDA kefrens_top_angle
	STA kefrens_row_angle

;	INC kefrens_top_add
	LDA kefrens_top_add
	STA kefrens_add_index

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

;	FOR n,1,14,1
;	NOP
;	NEXT

	LDA #254
	STA kefrens_crtc_row
;	STZ kefrens_add_index
	BIT 0
	BIT 0

	.here

	LDY kefrens_row_angle	; actually our angle
	LDA fx_particles_table, y		; SIN(y)
;	CLC
;	ADC fx_particles_table_cos, Y	; COS(y)
	TAY
	LDA kefrens_sine_table, Y

	CLC
	LDY kefrens_add_index
	ADC kefrens_add_table, Y
	TAY

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

	TYA:LSR A
	BCS right

	;2c
	\\ Left
	LDA # PIXEL_LEFT_7 OR PIXEL_RIGHT_3
	LDY #0:STA (writeptr), Y		; 8c
	LDA # PIXEL_LEFT_6 OR PIXEL_RIGHT_2
	LDY #8:STA (writeptr), Y
	LDA # PIXEL_LEFT_5 OR PIXEL_RIGHT_1
	LDY #16:STA (writeptr), Y
	LDY #24:

	LDA (writeptr),Y		; 6c
	AND #&55				; 2c
	ORA #PIXEL_LEFT_4		; 2c
	STA (writeptr), Y

	BRA continue ;3c

	.right	;3c
	\\ Left
	LDY #0
	LDA (writeptr),Y		; 6c
	AND #&AA				; 2c
	ORA #PIXEL_RIGHT_7		; 2c
	STA (writeptr), Y

	LDA # PIXEL_LEFT_3 OR PIXEL_RIGHT_6			; yellow/cyan
	LDY #8:STA (writeptr), Y
	LDA # PIXEL_LEFT_2 OR PIXEL_RIGHT_5			; green/magenta
	LDY #16:STA (writeptr), Y
	LDA # PIXEL_LEFT_1 OR PIXEL_RIGHT_4			; red/blue
	LDY #24:STA (writeptr), Y
	NOP
	
	.continue
	INC kefrens_row_angle
	INC kefrens_add_index ;-5c
	\\ 8*10c = 80c

	FOR n,1,7,1
	NOP
	NEXT

	INX								; 2c

	DEC kefrens_crtc_row
	BNE here

	.done

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

.kefrens_kill
{
	JMP crtc_reset_from_single
}

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
FOR x,0,255,1
EQUB LO(screen_base_addr + ((x-48-2) DIV 2)*8)
NEXT

PAGE_ALIGN
.kefrens_addr_table_HI
FOR x,0,255,1
EQUB HI(screen_base_addr + ((x-48-2) DIV 2)*8)
NEXT

PAGE_ALIGN
.kefrens_sine_table
FOR y,0,255,1
x=INT(128 + 76 * SIN(y * 2 * PI / 256) * SIN(y * 4 * PI / 256))
EQUB x
NEXT

.kefrens_add_table
FOR y,0,255,1
;EQUB 10 * SIN(SIN(y * 2 * PI / 256) * 2 * PI)
EQUB 10 * SIN(y * 2 * PI / 256)
NEXT

.kefrens_bar_pixels
{
	EQUB PIXEL_LEFT_1 OR PIXEL_RIGHT_1			; red
	EQUB PIXEL_LEFT_1 OR PIXEL_RIGHT_5			; red/amgenta
	EQUB PIXEL_LEFT_1 OR PIXEL_RIGHT_5			; red/amgenta
	EQUB PIXEL_LEFT_5 OR PIXEL_RIGHT_5			; magenta
	EQUB PIXEL_LEFT_5 OR PIXEL_RIGHT_5			; magenta
	EQUB PIXEL_LEFT_5 OR PIXEL_RIGHT_1			; magenta/red
	EQUB PIXEL_LEFT_5 OR PIXEL_RIGHT_1			; magenta/red
	EQUB PIXEL_LEFT_1 OR PIXEL_RIGHT_1			; red
}

.fx_particles_table
FOR n,0,&13F,1
EQUB 127 * SIN(2 * PI * n / 256)	; 255 or 256?
NEXT

fx_particles_table_cos = fx_particles_table + 64

.kefrens_end
