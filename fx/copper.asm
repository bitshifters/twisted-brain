\ ******************************************************************
\ *	Copper colours
\ ******************************************************************

_COPPER_SCROLL = TRUE

copper_top_line = locals_start + 0
copper_stretch_index = locals_start + 1
copper_delta = locals_start + 2
copper_accum = locals_start + 3
copper_wibble_index = locals_start + 4

COPPER_MAX_INDEX = 96

.copper_start

.copper_init
{
    LDX #LO(copper_screen_data)
    LDY #HI(copper_screen_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

    SET_ULA_MODE ULA_Mode0

	STZ copper_top_line
	STZ copper_stretch_index
	STZ copper_wibble_index

    RTS
}

.copper_update
{
\\ This is the top line of our copper

IF _COPPER_SCROLL
	LDY copper_top_line
	INY
	CPY #COPPER_MAX_INDEX
	BCC ok
	LDY #0
	.ok
	STY copper_top_line
ELSE
	INC copper_wibble_index
	LDY copper_wibble_index
	LDA copper_wibble, Y
	STA copper_top_line
	TAY
ENDIF

\\ Set the address & palette for first screen row

	JSR copper_set_charrow		; 172c

\\ Update our ripple

	LDY copper_stretch_index
	INY
	STY copper_stretch_index

	LDA copper_stretch_table, Y
	STA copper_delta
    RTS
}

.copper_draw
{
	\\ R9=3 - character row = 4 scanlines
	LDA #9: STA &FE00
	LDA #3:	STA &FE01

	\\ R4=0 - CRTC cycle is one row
	LDA #4: STA &FE00
	LDA #0: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #&FF: STA &FE01

	\\ R6=0 - one row displayed
	LDA #6: STA &FE00
	LDA #1: STA &FE01		; 8 * 6c = 48c

	LDA copper_delta		; 3c
	STA copper_accum		; 3c

	\\ Set up second charrow

	LDY copper_top_line			; 3c
	JSR copper_accumulate	; 36c
	JSR copper_set_charrow	; 172c

	\\ Cycle count to end of charrow (4 scanlines)

	FOR n,1,46,1
	NOP
	NEXT

	JSR cycles_wait_128

	.start_of_charrow_1

	LDX #62					; 2c

	.here

	JSR copper_accumulate	; 36c
	JSR copper_set_charrow	; 172c

	\\ Cycle count to end of charrow (4 scanlines)

	FOR n,1,17,1
	NOP
	NEXT

	JSR cycles_wait_128
	JSR cycles_wait_128
	
	DEX							; 2c
	BNE here

	\\ Should arrive here on scanline 255 = last row but scanline 3
	.start_of_charrow_63

	\\ R9=0 - character row = 2 scanlines
	LDA #9: STA &FE00
	LDA #3:	STA &FE01			; 4 scanlines

	\\ R4=56 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #14-1+1: STA &FE01		; 312 - 256 = 56 scanlines = 14 rows + the one we're on

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #6+1: STA &FE01			; 280 - 256 = 24 scanlines = 6 rows

	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #1: STA &FE01

	\\ Don't set anything else here - will happen in update for charrow 0

    RTS
}

.copper_kill
{
    \\ Will need a kill fn if in MODE 0
    SET_ULA_MODE ULA_Mode2
	JSR crtc_reset
    JMP ula_pal_reset
}

.copper_set_charrow
{
	\\ Set screen row to this
   	LDA #12: STA &FE00				; 6c
    LDA copper_lookup_HI, Y			; 4c
	STA &FE01						; 4c

	LDA #13: STA &FE00				; 6c
    LDA copper_lookup_LO, Y			; 4c
	STA &FE01						; 4c

	\\ Set black to this
	LDA copper_colour_black, Y		; 4c
	STA &FE21						; 4c
	AND #&F:ORA #&10:STA &FE21		; 8c
	AND #&F:ORA #&20:STA &FE21		; 8c
	AND #&F:ORA #&30:STA &FE21		; 8c
	AND #&F:ORA #&40:STA &FE21		; 8c
	AND #&F:ORA #&50:STA &FE21		; 8c
	AND #&F:ORA #&60:STA &FE21		; 8c
	AND #&F:ORA #&70:STA &FE21		; 8c

	\\ Set white to this
	LDA copper_colour_white, Y		; 4c
	AND #&F:ORA #&80:STA &FE21		; 8c
	AND #&F:ORA #&90:STA &FE21		; 8c
	AND #&F:ORA #&A0:STA &FE21		; 8c
	AND #&F:ORA #&B0:STA &FE21		; 8c
	AND #&F:ORA #&C0:STA &FE21		; 8c
	AND #&F:ORA #&D0:STA &FE21		; 8c
	AND #&F:ORA #&E0:STA &FE21		; 8c
	AND #&F:ORA #&F0:STA &FE21		; 8c

	RTS
}	\\ Total time = 28 + 64 + 64 + 4 + 6 + 6 = 172c

.copper_accumulate
{
	\\ Accumulate an amount of delta

	CLC								; 2c
	LDA copper_accum				; 3c
	ADC copper_delta				; 3c
	STA copper_accum				; 3c

	\\ Add the carry to our index

	TYA						; 2c
	ADC #0					; 2c
	TAY						; 2c
	
	\\ Wrap our index

	CPY #COPPER_MAX_INDEX
	BCC path2

	\\ path1 = 2+2+3=7c
	LDY #0
	BEQ return

	.path2	\\ 3+2+2=7c
	NOP:NOP

	.return
	RTS
}	\\ 12 + 17 + 7 = 36c

.copper_screen_data
INCBIN "data/dither.pu"

.copper_lookup_LO
{
	\\ Solid white
    FOR n,0,16,1
    EQUB LO((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid black
    FOR n,15,1,-1
    EQUB LO((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid white
    FOR n,0,16,1
    EQUB LO((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid black
    FOR n,15,1,-1
    EQUB LO((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid white
    FOR n,0,16,1
    EQUB LO((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid black
    FOR n,15,1,-1
    EQUB LO((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid white
}

.copper_lookup_HI
{
	\\ Solid white
    FOR n,0,16,1
    EQUB HI((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid black
    FOR n,15,1,-1
    EQUB HI((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid white
    FOR n,0,16,1
    EQUB HI((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid black
    FOR n,15,1,-1
    EQUB HI((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid white
    FOR n,0,16,1
    EQUB HI((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid black
    FOR n,15,1,-1
    EQUB HI((screen_base_addr + n*640)/8)
    NEXT
	\\ Solid white
}

\\ Row 0: white = red, black = magenta
\\ Row 16: black = magenta, white = blue
\\ Row 32: white = blue, black = cyan
\\ Row 48: black = cyan, white = green
\\ Row 64: white = green, black = yellow
\\ Row 80: black = yellow, white = red
\\ Row 96 = Row 0

\\ White = red, blue, green
.copper_colour_white
{
	FOR n,0,15,1
	EQUB PAL_red
	NEXT
	FOR n,0,31,1
	EQUB PAL_blue
	NEXT
	FOR n,0,31,1
	EQUB PAL_green
	NEXT
	FOR n,0,15,1
	EQUB PAL_red
	NEXT
}

\\ Black = magenta, cyan, yellow
.copper_colour_black
{
	FOR n,0,31,1
	EQUB PAL_magenta
	NEXT
	FOR n,0,31,1
	EQUB PAL_cyan
	NEXT
	FOR n,0,31,1
	EQUB PAL_yellow
	NEXT
}

PAGE_ALIGN
.copper_stretch_table	\\ this linearly stretches the copper by factor below
FOR n,0,255,1
EQUB 128 + 127 * SIN(2 * PI * n / 256)
NEXT

IF _COPPER_SCROLL = FALSE	\\ doesn't quite do what I want it to yet!
.copper_wibble
FOR n,0,255,1
EQUB 48 + (47 * SIN(PI * n / 256)) * SIN(2 * PI * n / 256)
NEXT
ENDIF

.copper_end
