\ ******************************************************************
\ *	Logo glitch
\ ******************************************************************

logo_charrow = locals_start + 0
logo_bottom_scanline = locals_start + 1
logo_scroll = locals_start + 2
logo_speed = locals_start + 3

.logo_start

.logo_init
{
    LDX #LO(logo_screen_data)
    LDY #HI(logo_screen_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

    SET_ULA_MODE ULA_Mode1
	LDX #LO(logo_pal)
	LDY #HI(logo_pal)
	JSR ula_set_palette

	STZ logo_scroll

	LDA #0
	JSR logo_set_anim

	LDA #255
	STA logo_bottom_scanline

    RTS
}

.logo_update
{
	\\ Which line in the table is the bottom?

	LDX logo_bottom_scanline
	INX
	STX logo_bottom_scanline

	\\ Update our index into sine table

	CLC
	LDA logo_scroll
	ADC logo_speed
	STA logo_scroll
	BCC no_carry

	\\ Larger than one page

	INC logo_set_charrow_smLO+2
	INC logo_set_charrow_smHI+2

	\\ Wrap table

	LDA logo_set_charrow_smLO+2
	CMP #HI(logo_sinewave_HI)
	BCC no_carry

	\\ Reset to beginning

	LDA #HI(logo_sinewave_LO)
	STA logo_set_charrow_smLO+2
	LDA #HI(logo_sinewave_HI)
	STA logo_set_charrow_smHI+2

	.no_carry

	\\ Take new entry from sine table and move bottom scanline

	LDY logo_scroll
	.logo_set_charrow_smLO
	LDA logo_sinewave_LO, Y
	STA logo_scanline_offset_LO, X
	.logo_set_charrow_smHI
	LDA logo_sinewave_HI, Y
	STA logo_scanline_offset_HI, X
	
\\ Set the address & palette for first screen row

	LDA logo_bottom_scanline
	INC A
	STA logo_charrow

	LDX #0
	JSR logo_set_white		; 46c

    RTS
}

.logo_draw
{
	\\ R9=3 - character row = 1 scanline
	LDA #9: STA &FE00
	LDA #0:	STA &FE01

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

	LDX #1
	INC logo_charrow		; 5c
	JSR logo_set_charrow	; 46c

	\\ Cycle count to end of charrow

;	FOR n,1,4,1
;	NOP
;	NEXT

	.start_of_charrow_1

	.here

	INC logo_charrow		; 5c
	JSR logo_set_white		; 46c

	\\ Cycle count to end of charrow

;	FOR n,1,5,1
;	NOP
;	NEXT
	
	INX							; 2c
	CPX #255					; 2c
	BNE here					; 3c

	\\ Should arrive here on scanline 255 = last row but scanline 3
	.start_of_charrow_255

	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00
	LDA #1-1:	STA &FE01		; 1 scanline

	\\ R4=6 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #56-1+1: STA &FE01		; 312 - 256 = 56 scanlines

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #24+1: STA &FE01		; 280 - 256 = 24 scanlines

	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #1: STA &FE01

	\\ Don't set anything else here - will happen in update for charrow 0

    RTS
}

.logo_kill
{
    \\ Will need a kill fn if in MODE 0
	JSR crtc_reset_from_single
    SET_ULA_MODE ULA_Mode2
    JMP ula_pal_reset
}

.logo_set_white
{
	TXA								; 2c
	LSR A:LSR A:LSR A:LSR A:LSR A:LSR A	; 10c
	TAY								; 2c
	LDA logo_colour, Y				; 4c
	ORA #&A0:STA &FE21				; 6c
	LDA logo_colour, Y				; 4c
	ORA #&B0:STA &FE21				; 6c
	LDA logo_colour, Y				; 4c
	ORA #&E0:STA &FE21				; 6c
	LDA logo_colour, Y				; 4c
	ORA #&F0:STA &FE21				; 6c

}	\\ Total time = 12c + 14c + 40c = 66c
\\ Fall through!
.logo_set_charrow
{
	LDY logo_charrow				; 3c

	CLC							; 2c

	LDA #13: STA &FE00				; 6c
    LDA logo_default_LO, X			; 4c
	ADC logo_scanline_offset_LO, Y				; 4c
	STA &FE01						; 4c

	\\ Set screen row to this
   	LDA #12: STA &FE00				; 6c
    LDA logo_default_HI, X			; 4c
	ADC logo_scanline_offset_HI, Y				; 4c
	STA &FE01						; 4c

	RTS
	\\ Total time = 12c + 6c + 14c + 14c = 46c
}

.logo_set_anim
{
	STA logo_speed
	RTS

IF 0
	ASL A:ASL A
	TAX

	LDA logo_anim_table, X
	STA logo_set_charrow_smLO+1
	LDA logo_anim_table+1, X
	STA logo_set_charrow_smLO+2

	LDA logo_anim_table+2, X
	STA logo_set_charrow_smHI+1
	LDA logo_anim_table+3, X
	STA logo_set_charrow_smHI+2

	RTS
ENDIF
}

.logo_pal
{
	EQUB &00 + PAL_black
	EQUB &10 + PAL_black
	EQUB &20 + PAL_red
	EQUB &30 + PAL_red
	EQUB &40 + PAL_black
	EQUB &50 + PAL_black
	EQUB &60 + PAL_red
	EQUB &70 + PAL_red
	EQUB &80 + PAL_yellow
	EQUB &90 + PAL_yellow
	EQUB &A0 + PAL_white
	EQUB &B0 + PAL_white
	EQUB &C0 + PAL_yellow
	EQUB &D0 + PAL_yellow
	EQUB &E0 + PAL_white
	EQUB &F0 + PAL_white
}

.logo_colour
{
	EQUB PAL_red
	EQUB PAL_green
	EQUB PAL_yellow
	EQUB PAL_blue
}

.logo_screen_data
INCBIN "data/shift.pu"

PAGE_ALIGN
.logo_default_LO
{
FOR a,0,3,1
	FOR n,1,7,1
	SCREEN_ADDR_LO 15		; blank
	NEXT

	\\ Separated teletext look
	FOR n,0,14,1
	SCREEN_ADDR_LO n
	SCREEN_ADDR_LO n
	IF n MOD 3 = 1
	SCREEN_ADDR_LO n
	ENDIF
	SCREEN_ADDR_LO 15		; blank
	NEXT

	FOR n,1,7,1
	SCREEN_ADDR_LO 15		; blank
	NEXT
NEXT
}

.logo_default_HI
{
FOR a,0,3,1
	FOR n,1,7,1
	SCREEN_ADDR_HI 15		; blank
	NEXT

	\\ Separated teletext look
	FOR n,0,14,1
	SCREEN_ADDR_HI n
	SCREEN_ADDR_HI n
	IF n MOD 3 = 1
	SCREEN_ADDR_HI n
	ENDIF
	SCREEN_ADDR_HI 15		; blank
	NEXT

	FOR n,1,7,1
	SCREEN_ADDR_HI 15		; blank
	NEXT
NEXT
}

.logo_offset_none
{
	FOR n,0,255,1
	EQUB 0
	NEXT
}

.logo_sinewave_LO
{
	FOR n,0,255,1
	x = INT(10 * SIN(4 * PI * n / 256))
	IF (x AND 1) = 1
		IF x < 0
		a = &500 - ((x-1) DIV 2)
		ELSE
		a = &500 - (x DIV 2)
		ENDIF
	ELSE
	a = -(x DIV 2)
	ENDIF
	EQUB LO(a)
	NEXT

	FOR n,0,255,1
	x = INT(20 * SIN(2 * PI * n / 256))
	IF (x AND 1) = 1
		IF x < 0
		a = &500 - ((x-1) DIV 2)
		ELSE
		a = &500 - (x DIV 2)
		ENDIF
	ELSE
	a = -(x DIV 2)
	ENDIF
	EQUB LO(a)
	NEXT	
}

.logo_sinewave_HI
{
	FOR n,0,255,1
	x = INT(10 * SIN(4 * PI * n / 256))
	IF (x AND 1) = 1
		IF x < 0
		a = &500 - ((x-1) DIV 2)
		ELSE
		a = &500 - (x DIV 2)
		ENDIF
	ELSE
	a = -(x DIV 2)
	ENDIF
	PRINT "x=",x," a=",~a
	EQUB HI(a)
	NEXT

	FOR n,0,255,1
	x = INT(20 * SIN(2 * PI * n / 256))
	IF (x AND 1) = 1
		IF x < 0
		a = &500 - ((x-1) DIV 2)
		ELSE
		a = &500 - (x DIV 2)
		ENDIF
	ELSE
	a = -(x DIV 2)
	ENDIF
	PRINT "x=",x," a=",~a
	EQUB HI(a)
	NEXT
}

.logo_scanline_offset_LO
{
	FOR n,0,255,1
	EQUB 0
	NEXT
}

.logo_scanline_offset_HI
{
	FOR n,0,255,1
	EQUB 0
	NEXT
}

.logo_anim_table
{
	EQUW logo_offset_none, logo_offset_none
	EQUW logo_sinewave_LO, logo_sinewave_HI
	\\ static
	\\ glitch
	\\ flip
	\\ etc.
}

.logo_end
