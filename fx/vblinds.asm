\ ******************************************************************
\ *	Vertical blinds
\ ******************************************************************

LINE_BUFFER_size = 128
LINE_BUFFER_width = 80
LINE_BUFFER_start = 24

LINEAR_BUFFER_size = 256
LINEAR_BUFFER_width = 160
LINEAR_BUFFER_start = 48

vblinds_bar_xpos = locals_start + 0
vblinds_bar_width = locals_start + 1
vblinds_bar_A_byte = locals_start + 2
vblinds_bar_B_byte = locals_start + 3
vblinds_odd_pixel = locals_start + 4
vblinds_bar_index1 = locals_start + 5
vblinds_bar_index2 = locals_start + 6
vblinds_scr_ptr = locals_start+7
vblinds_buffer = locals_start+9

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
	STA vblinds_buffer

	JSR vblinds_erase_line
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

VBLINDS_ROW0_ADDR = screen_base_addr
VBLINDS_ROW1_ADDR = screen_base_addr + 640

.vblinds_update
{
	JSR vblinds_draw_row
;	JSR vblinds_copy_row		/ do this in draw

	LDA vblinds_buffer
	BEQ set_second

	\\ Set first
	LDA #LO(screen_base_addr)
	STA vblinds_scr_ptr
	LDA #HI(screen_base_addr)
	STA vblinds_scr_ptr+1

	\\ Display row 1 when new frame starts
	LDA #12: STA &FE00
	LDA #HI(VBLINDS_ROW1_ADDR/8): STA &FE01

	LDA #13: STA &FE00
	LDA #LO(VBLINDS_ROW1_ADDR/8): STA &FE01

	\\ But write into row 1	
	LDA #LO(VBLINDS_ROW0_ADDR)
	STA vblinds_scr_ptr
	LDA #HI(VBLINDS_ROW0_ADDR)
	STA vblinds_scr_ptr+1

	BRA done

	\\ Set second
	.set_second

	\\ Display row 0 when new frame starts
	LDA #12: STA &FE00
	LDA #HI(VBLINDS_ROW0_ADDR/8): STA &FE01

	LDA #13: STA &FE00
	LDA #LO(VBLINDS_ROW0_ADDR/8): STA &FE01

	\\ But write into row 1	
	LDA #LO(VBLINDS_ROW1_ADDR)
	STA vblinds_scr_ptr
	LDA #HI(VBLINDS_ROW1_ADDR)
	STA vblinds_scr_ptr+1

	.done
	LDA vblinds_buffer
	EOR #&FF
	STA vblinds_buffer

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

	FOR n,1,28,1
	NOP
	NEXT
	BIT 0

	.start_of_scanline1

	LDX #LINEAR_BUFFER_start		

	.linear_to_screen_loop
	STX vblinds_bar_xpos					; 3c

	\\ Load colour from our linear buffer
	LDA vblinds_linear_buffer, X			; 4c
	TAX										; 2c

	\\ Look up pixel pair for even line
	LDA vblinds_colour_lookup_A, X			; 4c
	AND #MODE2_LEFT_MASK					; 2c

	\\ Write it to screen buffer
	LDY #0									; 2c
	STA (vblinds_scr_ptr), Y				; 6c

	\\ Look up pixel pair for odd line
	LDA vblinds_colour_lookup_B, X			; 4c
	AND #MODE2_LEFT_MASK					; 2c
	
	\\ Write it to screen buffer
	INY										; 2c
	STA (vblinds_scr_ptr), Y				; 6c

	\\ Reset colour to black in linear buffer
	LDX vblinds_bar_xpos					; 3c
	LDA #0									; 2c
	STA vblinds_linear_buffer, X			; 5c

	\\ Get next colour from linear buffer (same screen byte)
	INX										; 2c
	STX vblinds_bar_xpos					; 3c

	\\ Look up pixel pair for even line
	LDA vblinds_linear_buffer, X			; 4c
	TAX										; 2c
	
	LDA vblinds_colour_lookup_A, X			; 4c

	\\ This time mask in right pixel
	AND #MODE2_RIGHT_MASK					; 2c
	LDY #0									; 2c
	ORA (vblinds_scr_ptr), Y				; 6c
	STA (vblinds_scr_ptr), Y				; 6c

	\\ Look up pixel pair for odd line
	LDA vblinds_colour_lookup_B, X			; 4c

	\\ This time mask in right pixel
	AND #MODE2_RIGHT_MASK					; 2c
	INY										; 2c
	ORA (vblinds_scr_ptr), Y				; 6c
	STA (vblinds_scr_ptr), Y				; 6c

	\\ Increment screen point in constant time
	CLC										; 2c
	LDA vblinds_scr_ptr						; 3c
	ADC #8									; 2c
	STA vblinds_scr_ptr						; 3c
	LDA vblinds_scr_ptr+1					; 3c
	ADC #0									; 2c
	STA vblinds_scr_ptr+1					; 3c

	\\ Reset colour to black in linear buffer
	LDX vblinds_bar_xpos					; 3c
	LDA #0									; 2c
	STA vblinds_linear_buffer, X			; 5c

	\\ Have we completed all pixel?
	INX										; 2c
	CPX #LINEAR_BUFFER_start + LINEAR_BUFFER_width	; 2c
	BCC linear_to_screen_loop				; 3c

	\\ Total 10640c = 83 scanlines + 16c

	\\ How much time left?

	LDX #82					; 2c

	.here

	\\ Literally do nothing
	FOR n,1,61,1
	NOP
	NEXT
	
	INX				; 2c
	BNE here		; 3c

	\\ Should arrive here on scanline 255 = last row but scanline 1
	.start_of_scanline_255

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

.vblinds_draw_bar			; A=colour#;X=xpos;Y=width
{
	CPY #0
	BEQ return						; 2c
	
	\\ Start at column X
	
	.loop
	STA vblinds_linear_buffer, X
	INX
	DEY
	BNE loop
	
	.return
	RTS
}

.vblinds_draw_row
{
	LDX vblinds_bar_index1
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #1
	JSR vblinds_draw_bar

	LDX vblinds_bar_index1
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #2
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #3
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #4
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #5
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #6
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #7
	JSR vblinds_draw_bar

IF 0
	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #8
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #9
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #10
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #11
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #12
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #13
	JSR vblinds_draw_bar

	LDX vblinds_bar_index2
	INX:INX:INX:INX
	STX vblinds_bar_index2
	LDA vblinds_wib2,X
	TAY
	LDA vblinds_wibble,X
	TAX
	LDA #14
	JSR vblinds_draw_bar
ENDIF
	RTS
}

.vblinds_erase_line
{
	LDA #0
	FOR n,LINEAR_BUFFER_start,LINEAR_BUFFER_start+LINEAR_BUFFER_width-1,1
	STA vblinds_linear_buffer + n
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
.vblinds_linear_buffer
SKIP LINEAR_BUFFER_size

VBLINDS_MAX_COLOURS=15

.vblinds_colour_lookup_A
{
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
	\\ Or can wrap around to red again
}

.vblinds_colour_lookup_B
{
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
	\\ Or can wrap around to red again
}

.vblinds_end
