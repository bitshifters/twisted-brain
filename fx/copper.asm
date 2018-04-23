\ ******************************************************************
\ *	Copper colours
\ ******************************************************************

copper_index = locals_start + 0
copper_col = locals_start + 1
copper_idx2 = locals_start + 2

COPPER_ROW_ADDR = screen_base_addr + 8 * 640

.copper_start

.copper_init
{
    LDX #LO(copper_screen_data)
    LDY #HI(copper_screen_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

    SET_ULA_MODE ULA_Mode0

    LDX #LO(copper_pal)
    LDY #HI(copper_pal)
    JSR ula_set_palette

    STZ copper_index
	STZ copper_idx2

    RTS
}

.copper_pal
{
	EQUB &00 + PAL_black
	EQUB &10 + PAL_black
	EQUB &20 + PAL_black
	EQUB &30 + PAL_black
	EQUB &40 + PAL_black
	EQUB &50 + PAL_black
	EQUB &60 + PAL_black
	EQUB &70 + PAL_black
	EQUB &80 + PAL_black
	EQUB &90 + PAL_white
	EQUB &A0 + PAL_white
	EQUB &B0 + PAL_white
	EQUB &C0 + PAL_white
	EQUB &D0 + PAL_white
	EQUB &E0 + PAL_white
	EQUB &F0 + PAL_white
}

.copper_update
{
    INC copper_index

	LDA copper_index
	AND #&1F
	TAY

   	LDA #12: STA &FE00		; 6c
    LDA copper_lookup_HI, Y	; 4c
	STA &FE01				; 4c

	LDA #13: STA &FE00		; 6c
    LDA copper_lookup_LO, Y	; 4c
	STA &FE01				; 4c
	
	LDA copper_idx2
	INC A
	CMP #96
	BCC ok
	LDA #0
	.ok
	STA copper_idx2

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
	LDA #1: STA &FE01

	LDA copper_idx2
	STA copper_col

    LDA copper_index		; 3c
    AND #&1F				; 2c
    TAY						; 2c

   	LDA #12: STA &FE00		; 6c
    LDA copper_lookup_HI, Y	; 4c
	STA &FE01				; 4c

	LDA #13: STA &FE00		; 6c
    LDA copper_lookup_LO, Y	; 4c
	STA &FE01				; 4c
 
	FOR n,1,1,1
	NOP
	NEXT
	BIT 0

	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128

	.start_of_charrow_1

	LDX #62					; 2c

	.here

	INY						; 2c
	TYA						; 2c
	AND #&1F				; 2c
	TAY						; 2c
   	LDA #12: STA &FE00		; 6c
    LDA copper_lookup_HI, Y	; 4c
	STA &FE01				; 4c

	LDA #13: STA &FE00		; 6c
    LDA copper_lookup_LO, Y	; 4c
	STA &FE01				; 4c

IF 1
	PHY
	LDY copper_col

	LDA copper_colour_black, Y	; 4c		\\ black=this
	STA &FE21				; 4c
	AND #&F:ORA #&10:STA &FE21		; 8c
	AND #&F:ORA #&20:STA &FE21		; 8c
	AND #&F:ORA #&30:STA &FE21		; 8c
	AND #&F:ORA #&40:STA &FE21		; 8c
	AND #&F:ORA #&50:STA &FE21		; 8c
	AND #&F:ORA #&60:STA &FE21		; 8c
	AND #&F:ORA #&70:STA &FE21		; 8c

	LDA copper_colour_white, Y	; 4c		\\ white=this
	AND #&F:ORA #&80:STA &FE21		; 8c
	AND #&F:ORA #&90:STA &FE21		; 8c
	AND #&F:ORA #&A0:STA &FE21		; 8c
	AND #&F:ORA #&B0:STA &FE21		; 8c
	AND #&F:ORA #&C0:STA &FE21		; 8c
	AND #&F:ORA #&D0:STA &FE21		; 8c
	AND #&F:ORA #&E0:STA &FE21		; 8c
	AND #&F:ORA #&F0:STA &FE21		; 8c

	INY
	CPY #96
	BCC path2
	\\ path1 = 2+2+3c
	LDY #0
	BRA cont

	.path2 \\= 3+2+2c
	NOP:NOP

	.cont
	STY copper_col
	PLY
ELSE
	JSR cycles_wait_128
ENDIF

	FOR n,1,25,1
	NOP
	NEXT

	JSR cycles_wait_128
	JSR cycles_wait_128
	
	DEX							; 2c
	BEQ start_of_charrow_63	; 2c
	JMP here					; 3c

	\\ Should arrive here on scanline 255 = last row but scanline 3
	.start_of_charrow_63

	\\ R9=0 - character row = 2 scanlines
	LDA #9: STA &FE00
	LDA #3:	STA &FE01		; 4 scanlines

	\\ R4=56 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #14-1+1: STA &FE01		; 312 - 256 = 56 scanlines = 14 rows + the one we're on

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #6+1: STA &FE01			; 280 - 256 = 24 scanlines = 6 rows

	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #1: STA &FE01

	INY						; 2c
	TYA
	AND #&1F
	TAY
   	LDA #12: STA &FE00		; 6c
    LDA copper_lookup_HI, Y	; 4c
	STA &FE01				; 4c

	LDA #13: STA &FE00		; 6c
    LDA copper_lookup_LO, Y	; 4c
	STA &FE01				; 4c

    RTS
}

.copper_kill
{
    \\ Will need a kill fn if in MODE 0
    SET_ULA_MODE ULA_Mode2
	JSR crtc_reset
    JMP ula_pal_reset
}

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
}

.copper_lookup_HI
{
    FOR n,0,16,1
    EQUB HI((screen_base_addr + n*640)/8)
    NEXT
    FOR n,15,1,-1
    EQUB HI((screen_base_addr + n*640)/8)
    NEXT
}

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

\\ Row 0 - white = red & black = magenta
\\ Row 16 - black = magenta, white = blue
\\ Row 32 - white = blue, black = cyan
\\ Row 48 - black = cyan, white = green

\\ White = red, blue, green
\\ Black = magenta, cyan, yellow

.copper_end
