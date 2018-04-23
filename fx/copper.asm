\ ******************************************************************
\ *	Copper colours
\ ******************************************************************

copper_index = locals_start + 0

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

	LDA #12: STA &FE00
	LDA #HI(COPPER_ROW_ADDR/8): STA &FE01

	LDA #13: STA &FE00
	LDA #LO(COPPER_ROW_ADDR/8): STA &FE01

    STZ copper_index

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
    AND #&F
    ASL A
    TAX

   	LDA #12: STA &FE00
    LDA copper_lookup+1, X
	STA &FE01

	LDA #13: STA &FE00
    LDA copper_lookup, X
	STA &FE01
 
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

	FOR n,1,30,1
	NOP
	NEXT
	BIT 0

	.start_of_scanline1

	LDX #2					; 2c

	.here

	\\ Literally do nothing
	FOR n,1,61,1
	NOP
	NEXT
	
	INX				; 2c
	BNE here		; 3c

	\\ Should arrive here on scanline 255 = last row but scanline 3
	.start_of_scanline_255

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

    RTS
}

.copper_kill
{
    \\ Will need a kill fn if in MODE 0
    SET_ULA_MODE ULA_Mode2
    RTS
}

.copper_screen_data
INCBIN "data/dither.pu"

.copper_lookup
{
    FOR n,0,16,1
    EQUW (screen_base_addr + n*640)/8
    NEXT
}

.copper_end
