\ ******************************************************************
\ *	Logo glitch
\ ******************************************************************

LOGO_NUM_ANGLES = 32
LOGO_HEIGHT_APPARENT = 70
LOGO_HEIGHT_TOTAL = 64
LOGO_HEIGHT_ACTUAL = 50
LOGO_DEFAULT_START = 7

logo_charrow = locals_start + 0
logo_scroll = locals_start + 1
logo_angle = locals_start + 2
logo_rotation_ptr = locals_start + 3
logo_temp = locals_start + 5
logo_side = locals_start + 6
logo_scanline = locals_start + 7

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
	STZ logo_angle

	LDA #0
	JSR logo_set_anim

    RTS
}

.logo_update
{
\\ Set the address & palette for first screen row
IF 0
	INC logo_scroll
	LDA logo_scroll
	STA logo_charrow

	LDX #0
	JSR logo_set_white		; 46c
ELSE
	LDA logo_angle
	INC A
	STA logo_angle

	AND #LOGO_NUM_ANGLES-1
	TAX
	LDA logo_rotation_LO, X
	STA logo_rotation_ptr
	LDA logo_rotation_HI, X
	STA logo_rotation_ptr+1

	LDA logo_angle
	LSR A:LSR A:LSR A:LSR A:LSR A;:LSR A
	STA logo_side

	LDY #0
	JSR logo_set_white
ENDIF
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

	LDY #1
	JSR logo_set_white	; 46c

	\\ Cycle count to end of charrow

	FOR n,1,1,1
	NOP
	NEXT

	LDA #254
	STA logo_scanline

	.start_of_charrow_1

	.here

	INY						; 2c
	CPY #LOGO_HEIGHT_TOTAL
	BCS path2
	\\path 1; 2c
	NOP:BIT 0 ; 5c
	BRA ok  ; 3c

	.path2	; 3c
	LDY #0  ; 2c
	INC logo_side ; 5c

	.ok
	JSR logo_set_white	; 47c

	\\ Cycle count to end of charrow

;	FOR n,1,1,1
;	NOP
;	NEXT

	DEC logo_scanline			; 5c	
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
    SET_ULA_MODE ULA_Mode2
	JSR crtc_reset
    JMP ula_pal_reset
}

.logo_set_white
{
	LDA (logo_rotation_ptr), Y		; 5c
	AND #&3F						; 2c
	TAX								; 2c

	LDA #13: STA &FE00				; 6c
    LDA logo_default_LO, X			; 4c
	STA &FE01						; 4c

	\\ Set screen row to this
   	LDA #12: STA &FE00				; 6c
    LDA logo_default_HI, X			; 4c
	STA &FE01						; 4c

	LDA (logo_rotation_ptr), Y		; 5c
	CLC:ROL A:ROL A: ROL A		; 8c
	CLC
	ADC logo_side				; 3c
	AND #3
	TAX								; 2c
	LDA logo_colour, X				; 4c
	ORA #&A0:STA &FE21				; 6c
	EOR #&10:STA &FE21				; 6c
	EOR #&40:STA &FE21				; 6c
	ORA #&10:STA &FE21				; 6c

	RTS
}	\\ 47c

.logo_set_anim
{
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
ENDIF

	RTS
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

.logo_anim_table
{
	EQUW logo_offset_none, logo_offset_none
	EQUW logo_sinewave_LO, logo_sinewave_HI
	\\ static
	\\ glitch
	\\ flip
	\\ etc.
}

.logo_rotation_LO
FOR n,0,LOGO_NUM_ANGLES-1,1
EQUB LO(logo_rotation_tables + n*LOGO_HEIGHT_TOTAL)
NEXT

.logo_rotation_HI
FOR n,0,LOGO_NUM_ANGLES-1,1
EQUB HI(logo_rotation_tables + n*LOGO_HEIGHT_TOTAL)
NEXT

PAGE_ALIGN
.logo_rotation_tables
FOR n,0,LOGO_NUM_ANGLES-1,1
a = 0.25 * PI + 0.5 * PI * n / LOGO_NUM_ANGLES
PRINT "LOGO ROTATION TABLE=",n," angle=", a
h = LOGO_HEIGHT_APPARENT/2
y1 = INT(h + h * SIN(a))
y2 = INT(h + h * SIN(a + 0.5 * PI))
y3 = INT(h + h * SIN(a + 1.0 * PI))
y4 = INT(h + h * SIN(a + 1.5 * PI))
PRINT "y1=", y1, "y2=", y2, "y3=", y3, "y4=", y4

FOR m,0,LOGO_HEIGHT_TOTAL-1,1
y = m + (LOGO_HEIGHT_APPARENT-LOGO_HEIGHT_TOTAL)/2
; Twister
IF y1 < y2 AND y >= y1 AND y < y2
	EQUB (LOGO_DEFAULT_START + LOGO_HEIGHT_ACTUAL * (y - y1) / (y2 - y1)) OR &C0
ELIF y2 < y3 AND y >= y2 AND y < y3
	EQUB (LOGO_DEFAULT_START + LOGO_HEIGHT_ACTUAL * (y - y2) / (y3 - y2)) OR &80
ELIF y3 < y4 AND y >= y3 AND y < y4
	EQUB (LOGO_DEFAULT_START + LOGO_HEIGHT_ACTUAL * (y - y3) / (y4 - y3)) OR &40
ELIF y4 < y1 AND y >= y4 AND y < y1
	EQUB (LOGO_DEFAULT_START + LOGO_HEIGHT_ACTUAL * (y - y4) / (y1 - y4)) OR &00
ELSE
	EQUB 0	; blank
ENDIF

NEXT

NEXT

.logo_colour
{
	IF 1
	EQUB PAL_red
	EQUB PAL_green
	EQUB PAL_yellow
	EQUB PAL_blue
	ELSE
	FOR n,0,255,1
	c=n >> 6
	IF c=0
	EQUB PAL_red
	ELIF c=1
	EQUB PAL_green
	ELIF c=2
	EQUB PAL_yellow
	ELSE
	EQUB PAL_blue
	ENDIF
	NEXT
	ENDIF
}

.logo_end
