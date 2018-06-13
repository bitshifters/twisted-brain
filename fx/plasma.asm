\ ******************************************************************
\ *	Plasma-ish FX
\ ******************************************************************

plasma_offset = locals_start + 0
plasma_row = locals_start + 2
plasma_crtc_count = locals_start + 3
plasma_count = locals_start + 4
plasma_colour = locals_start + 5
plasma_anim = locals_start + 6

PLASMA_MAX_OFFSET = 96	; 192/2		;160
PLASMA_MAX_COLOURS = 6

.plasma_start

.plasma_init
{
    LDX #LO(plasma_screen_data)
    LDY #HI(plasma_screen_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

    SET_ULA_MODE ULA_Mode0

	STZ plasma_anim
	STZ plasma_colour
	STZ plasma_row
	STZ plasma_offset
	STZ plasma_offset+1

	JSR plasma_set_colour

    RTS
}

.plasma_update
{
	LDX plasma_offset
	INX							; increment this on another sinewave?
	CPX #PLASMA_MAX_OFFSET
	BCC ok

	\\ Next row
	LDA plasma_row
	INC A
	AND #&F
	STA plasma_row

	\\ Next colour
	LDA plasma_colour
	INC A
	CMP #PLASMA_MAX_COLOURS
	BCC next_col
	LDA #0
	.next_col
	STA plasma_colour
	JSR plasma_set_colour

	LDX #0
	.ok
	STX plasma_offset

\\ Set the address for first screen row

	CLC							; 2c
	LDA plasma_offset_table, X	; 4c
	ADC plasma_offset			; 3c
	TAX							; 2c

	LDY plasma_row
	JSR plasma_set_charrow		; 172c

    RTS
}

.plasma_draw
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

	\\ Set up second charrow

	LDY plasma_row				; 3c

	LDX plasma_offset			; 3c
	STX plasma_count			; 3c

	INX							; 2c
	CLC							; 2c
	LDA plasma_offset_table, X	; 4c
	ADC plasma_offset			; 3c
	TAX							; 2c

	JSR plasma_set_charrow		; 46c

	\\ Cycle count to end of charrow (4 scanlines)

	FOR n,1,49,1
	NOP
	NEXT

	JSR cycles_wait_128
	JSR cycles_wait_128

	.start_of_charrow_1

	LDA #62						; 2c
	STA plasma_crtc_count		; 3c

	.here

	INC plasma_count			\\ could maybe increment this on another sinewave?

	LDX plasma_count			; 3c
	CLC							; 2c
	LDA plasma_offset_table, X	; 4c
	ADC plasma_offset			; 3c
	TAX							; 2c
	JSR plasma_set_charrow		; 46c

	\\ Cycle count to end of charrow (4 scanlines)

	FOR n,1,24,1
	NOP
	NEXT

	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	
	DEC plasma_crtc_count		; 5c
	BNE here					; 3c

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

.plasma_kill
{
    \\ Will need a kill fn if in MODE 0
    SET_ULA_MODE ULA_Mode2
	JSR crtc_reset
    JMP ula_pal_reset
}

.plasma_set_charrow
{
	\\ Set screen to character row Y with character offset X

	LDA #13: STA &FE00				; 6c

	CLC								; 2c
	TXA								; 2c
    ADC plasma_lookup_LO, Y			; 4c
	STA &FE01						; 4c

   	LDA #12: STA &FE00				; 6c
    LDA plasma_lookup_HI, Y			; 4c
	ADC #0							; 2c
	STA &FE01						; 4c

	RTS								; 6c
}	\\ total = 6c + 40c = 46c

.plasma_set_colour
{
	LDY plasma_colour

	\\ Set black to this
	LDA plasma_colour_black, Y		; 4c
	STA &FE21						; 4c
	AND #&F:ORA #&10:STA &FE21		; 8c
	AND #&F:ORA #&20:STA &FE21		; 8c
	AND #&F:ORA #&30:STA &FE21		; 8c
	AND #&F:ORA #&40:STA &FE21		; 8c
	AND #&F:ORA #&50:STA &FE21		; 8c
	AND #&F:ORA #&60:STA &FE21		; 8c
	AND #&F:ORA #&70:STA &FE21		; 8c

	\\ Set white to this
	LDA plasma_colour_white, Y		; 4c
	AND #&F:ORA #&80:STA &FE21		; 8c
	AND #&F:ORA #&90:STA &FE21		; 8c
	AND #&F:ORA #&A0:STA &FE21		; 8c
	AND #&F:ORA #&B0:STA &FE21		; 8c
	AND #&F:ORA #&C0:STA &FE21		; 8c
	AND #&F:ORA #&D0:STA &FE21		; 8c
	AND #&F:ORA #&E0:STA &FE21		; 8c
	AND #&F:ORA #&F0:STA &FE21		; 8c

	RTS
}

\\ Have 16 double character rows

PAGE_ALIGN
.plasma_lookup_LO
{
	FOR n,0,15,1
	EQUB LO((screen_base_addr + n*1280)/8)
	NEXT
}

.plasma_lookup_HI
{
	FOR n,0,15,1
	EQUB HI((screen_base_addr + n*1280)/8)
	NEXT
}


.plasma_colour_white
{
\\ By Hue white = red, blue, green
	EQUB PAL_red
	EQUB PAL_blue
	EQUB PAL_green

\\ By Brightness white = red, blue, green, white
	EQUB PAL_red
;	EQUB PAL_blue
	EQUB PAL_green
	EQUB PAL_white

\\ Mono
;	EQUB PAL_white
}

.plasma_colour_black
{
\\ By Hue black = magenta, cyan, yellow
	EQUB PAL_magenta
	EQUB PAL_cyan
	EQUB PAL_yellow

\\ By Brightness black = magenta, black, cyan, white
	EQUB PAL_magenta
;	EQUB PAL_black
	EQUB PAL_cyan
	EQUB PAL_yellow

\\ Mono
;	EQUB PAL_black
}

PAGE_ALIGN
.plasma_offset_table
{
	FOR n,0,255,1
	EQUB (PLASMA_MAX_OFFSET/2) + (PLASMA_MAX_OFFSET/2)*SIN(n * 2 * PI / 256)
	NEXT
}

PAGE_ALIGN
.plasma_screen_data
INCBIN "data/hdither.pu"

.plasma_end
