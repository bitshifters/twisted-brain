\ ******************************************************************
\ *	Vertical blinds
\ ******************************************************************

LINE_BUFFER_size = 128
LINE_BUFFER_width = 80
LINE_BUFFER_start = 24

vblinds_bar_xpos = locals_start + 0
vblinds_bar_width = locals_start + 1
vblinds_bar_A_byte = locals_start + 2
vblinds_bar_B_byte = locals_start + 3
vblinds_odd_pixel = locals_start + 4
vblinds_bar_index1 = locals_start + 5
vblinds_bar_index2 = locals_start + 6

.vblinds_start

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

.vblinds_init
{
	LDA #0
	STA vblinds_bar_index1
	STA vblinds_bar_index2
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

.vblinds_update
{
	JSR vblinds_erase_line
	JSR vblinds_draw_row
	JSR vblinds_copy_row

	INC vblinds_bar_index1
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

.vblinds_draw
{
	\\ We're only ever going to display this one scanline
	LDA #12: STA &FE00
	LDA #HI(screen_base_addr/8): STA &FE01

	LDA #13: STA &FE00
	LDA #LO(screen_base_addr/8): STA &FE01

	\\ R9=1 - character row = 2 scanlines
	LDA #9: STA &FE00
	LDA #1:	STA &FE01

	\\ R4=0 - CRTC cycle is one row
	LDA #4: STA &FE00
	LDA #0: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #&FF: STA &FE01

	\\ R6=0 - one row displayed
	LDA #6: STA &FE00
	LDA #1: STA &FE01

	FOR n,1,14,1
	NOP
	NEXT
	BIT 0

	LDX #2					; 2c

	.here

	\\ Literally do nothing
	FOR n,1,61,1
	NOP
	NEXT
	
	INX				; 2c
	BNE here		; 3c

	\\ Should arrive here on scanline 255 = last row but scanline 1

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

.vblinds_draw_bar			; at pos vblinds_bar_xpos, byte_A Y, byte_B X
{
	STX vblinds_bar_A_byte
	STY vblinds_bar_B_byte

	\\ Start at column X
	
	LDA vblinds_bar_xpos					; 3c
	LSR A							; 2c
	TAX								; 2c

	\\ This many pixels to draw
	
	LDY vblinds_bar_width					; 3c
	BEQ return						; 2c
	
	\\ Do we start with an odd pixel?
	
	LDA vblinds_bar_xpos					; 3c
	AND #1							; 2c
	BEQ even_loop					; 3c

	\\ Write right-hand pixel column into line buffer A
	
	LDA vblinds_bar_A_byte					; 3c
	AND #PIXEL_RIGHT_F				; 2c
	STA vblinds_odd_pixel					; 3c

	LDA line_buffer_A+0,X			; 5c
	AND #PIXEL_LEFT_F				; 2c
	ORA vblinds_odd_pixel					; 5c
	STA line_buffer_A+0,X			; 5c

	\\ Write right-hand pixel column into line buffer B
	
	LDA vblinds_bar_B_byte
	AND #PIXEL_RIGHT_F				; 2c
	STA vblinds_odd_pixel					; 3c

	LDA line_buffer_B+0,X
	AND #PIXEL_LEFT_F
	ORA vblinds_odd_pixel
	STA line_buffer_B+0,X

	\\ Done first column
	
	INX
	
	\\ Done first pixel
	
	DEY

	.even_loop
	CPY #2
	BCC even_loop_done
	
	LDA vblinds_bar_A_byte
	STA line_buffer_A+0,X
	LDA vblinds_bar_B_byte
	STA line_buffer_B+0,X
	INX
	DEY:DEY
	JMP even_loop

	.even_loop_done
	\\ Just tested Y - if zero then exit
	BEQ return
	
	\\ Assert Y == 1!
	\\ Write left-hand pixel column into line buffer

	LDA vblinds_bar_A_byte
	AND #PIXEL_LEFT_F				; 2c
	STA vblinds_odd_pixel					; 3c
	
	LDA line_buffer_A+0,X
	AND #PIXEL_RIGHT_F				; 2c keep only right pixel
	ORA vblinds_odd_pixel					; 3c
	STA line_buffer_A+0,X
	
	\\ Write left-hand pixel column into line buffer

	LDA vblinds_bar_B_byte
	AND #PIXEL_LEFT_F				; 2c
	STA vblinds_odd_pixel					; 3c
	
	LDA line_buffer_B+0,X
	AND #PIXEL_RIGHT_F				; 2c keep only right pixel
	ORA vblinds_odd_pixel					; 3c
	STA line_buffer_B+0,X
	
	.return
	RTS								; 6c
}									; 54 cycle overhead + 512c (even) or 746c (odd)

.vblinds_draw_row
{
	LDX vblinds_bar_index1
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_1 + PIXEL_RIGHT_0
	LDY #PIXEL_LEFT_0 + PIXEL_RIGHT_1
	JSR vblinds_draw_bar

	LDX vblinds_bar_index1
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_1 + PIXEL_RIGHT_1
	LDY #PIXEL_LEFT_1 + PIXEL_RIGHT_1
	JSR vblinds_draw_bar

IF 0
	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_1 + PIXEL_RIGHT_2
	LDY #PIXEL_LEFT_2 + PIXEL_RIGHT_1
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_2 + PIXEL_RIGHT_2
	LDY #PIXEL_LEFT_2 + PIXEL_RIGHT_2
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_3 + PIXEL_RIGHT_2
	LDY #PIXEL_LEFT_2 + PIXEL_RIGHT_3
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_3 + PIXEL_RIGHT_3
	LDY #PIXEL_LEFT_3 + PIXEL_RIGHT_3
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_4 + PIXEL_RIGHT_3
	LDY #PIXEL_LEFT_3 + PIXEL_RIGHT_4
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_4 + PIXEL_RIGHT_4
	LDY #PIXEL_LEFT_4 + PIXEL_RIGHT_4
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_5 + PIXEL_RIGHT_4
	LDY #PIXEL_LEFT_4 + PIXEL_RIGHT_5
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_5 + PIXEL_RIGHT_5
	LDY #PIXEL_LEFT_5 + PIXEL_RIGHT_5
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_6 + PIXEL_RIGHT_5
	LDY #PIXEL_LEFT_5 + PIXEL_RIGHT_6
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_6 + PIXEL_RIGHT_6
	LDY #PIXEL_LEFT_6 + PIXEL_RIGHT_6
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_7 + PIXEL_RIGHT_6
	LDY #PIXEL_LEFT_6 + PIXEL_RIGHT_7
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wibble,X
	STA vblinds_bar_xpos
	LDA vblinds_wib2,X
	STA vblinds_bar_width
	LDX #PIXEL_LEFT_7 + PIXEL_RIGHT_7
	LDY #PIXEL_LEFT_7 + PIXEL_RIGHT_7
	JSR vblinds_draw_bar
ENDIF

	RTS
}

.vblinds_erase_line
{
	\\ Clear line buffer
	LDA #0
	FOR n,0,LINE_BUFFER_width-1,1
	STA line_buffer_A + LINE_BUFFER_start + n
	STA line_buffer_B + LINE_BUFFER_start + n
	NEXT
	
	RTS
}

.vblinds_copy_row
{
	FOR n,0,LINE_BUFFER_width-1,1
	LDA line_buffer_A + LINE_BUFFER_start + n
	STA screen_base_addr + (n*8) + 0
	LDA line_buffer_B + LINE_BUFFER_start + n
	STA screen_base_addr + (n*8) + 1
	NEXT
	RTS
}

PAGE_ALIGN
.vblinds_wibble
FOR n, 0, 255, 1
;EQUB n MOD 144
EQUB 128 + 80 * SIN(2 * PI * n / 256)
NEXT

.vblinds_wib2
FOR n, 0, 255, 1
EQUB 20 + 19 * SIN(2 * PI * n / 64)
NEXT

PAGE_ALIGN
.line_buffer_A
SKIP LINE_BUFFER_size

.line_buffer_B
SKIP LINE_BUFFER_size

.vblinds_end
