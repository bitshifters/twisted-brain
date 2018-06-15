\ ******************************************************************
\ *	Plasma-ish FX
\ ******************************************************************

plasma_crtc_count = locals_start + 0
plasma_addr = locals_start + 2
plasma_incx = locals_start + 4

plasma_f_idx = locals_start + 6
plasma_wavef = locals_start + 7
plasma_wavey = locals_start + 8
plasma_y_idx = locals_start + 9
plasma_wavex = locals_start + 10
plasma_waveyf = locals_start + 11

plasma_x16 = locals_start + 12		; x offset of top row

PLASMA_MAX_X16 = &A00

.plasma_start

.plasma_init
{
    LDX #LO(plasma_screen_data)
    LDY #HI(plasma_screen_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

    SET_ULA_MODE ULA_Mode0

	LDA #PAL_black
	JSR pal_set_mode0_colour0
	LDA #PAL_white
	JSR pal_set_mode0_colour1

	STZ plasma_f_idx
	STZ plasma_y_idx

	LDA #0
	STA plasma_incx
	STA plasma_incx+1
	LDA #0
	STA plasma_wavef
	LDA #0
	STA plasma_wavey
	LDA #0
	STA plasma_wavex

	LDA #1
	JSR plasma_set_x16

    RTS
}

.plasma_update
{
	\\ Move top row along

	CLC
	LDA plasma_x16
	ADC plasma_incx
	STA plasma_x16
	LDA plasma_x16+1
	ADC plasma_incx+1
	STA plasma_x16+1

	\\ Increment frame index

	CLC
	LDA plasma_f_idx
	ADC plasma_wavef
	STA plasma_f_idx

	\\ Increment row index?

	CLC
	LDA plasma_y_idx
	ADC plasma_waveyf
	STA plasma_y_idx

	\\ Address = x16 offset + wavef[f_idx] + wavey[y_idx]

	LDX plasma_f_idx
	CLC
	LDA plasma_x16
	ADC plasma_wavef_table_LO, X
	STA plasma_addr
	LDA plasma_x16+1
	ADC plasma_wavef_table_HI, X
	STA plasma_addr+1

	LDY plasma_y_idx
	CLC
	LDA plasma_addr
	ADC plasma_wavey_table_LO, Y
	STA plasma_addr
	LDA plasma_addr+1
	ADC plasma_wavey_table_HI, Y
	STA plasma_addr+1

	JSR plasma_set_charrow

	\\ Setup for draw

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

	\\ Cycle count to end of scanline

	FOR n,1,33,1
	NOP
	NEXT

	.start_of_scanline_1 \ still in charrow 0

	LDA #63						; 2c
	STA plasma_crtc_count		; 3c

	LDY plasma_f_idx
	LDX plasma_y_idx

	.here

	TYA
	CLC
	ADC plasma_wavey
	TAY

	CLC							; 2c
	LDA plasma_x16				; 3c
	ADC plasma_wavef_table_LO, Y	; 4c
	STA plasma_addr				; 3c
	LDA plasma_x16+1			; 3c
	ADC plasma_wavef_table_HI, Y	; 4c
	STA plasma_addr+1			; 3c

	TXA
	CLC
	ADC plasma_wavex
	TAX

	CLC
	LDA plasma_addr
	ADC plasma_wavey_table_LO, X
	STA plasma_addr
	LDA plasma_addr+1
	ADC plasma_wavey_table_HI, X
	STA plasma_addr+1

	\\ Set adddress of character row

	JSR plasma_set_charrow		; 42c

	FOR n,1,5,1
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
	LDA #13: STA &FE00				; 6c

	\\ Set x value, X=LO byte & Y=HI byte
	CLC
	LDA plasma_addr					; 2c
	ADC #LO(screen_base_addr/8)		; 2c
	STA &FE01						; 4c

   	LDA #12: STA &FE00				; 6c
    LDA plasma_addr+1				; 2c
	ADC #HI(screen_base_addr/8)		; 2c
	STA &FE01						; 4c
	
	RTS								; 6c
}	\\ total = 6c + 40c = 46c

.plasma_set_wave_f
{
	STA plasma_wavef
	RTS
}

.plasma_set_wave_y
{
	STA plasma_wavey
	RTS
}

.plasma_set_wave_yf
{
	STA plasma_waveyf
	RTS
}

.plasma_set_wave_x
{
	STA plasma_wavex
	RTS
}

.plasma_set_x16
{
	PHX
	TAX
	LDA plasma_lookup_LO, X
	STA plasma_x16
	LDA plasma_lookup_HI, X
	STA plasma_x16+1
	PLX
	RTS
}

.plasma_set_inc_x
{
	STZ plasma_incx+1
	STA plasma_incx
	BPL positive
	LDA #&FF
	STA plasma_incx+1
	.positive
	RTS
}

\\ Map character row number to screen offset

.plasma_lookup_LO
{
	FOR n,0,31,1
	EQUB LO(n * 80)
	NEXT
}

.plasma_lookup_HI
{
	FOR n,0,31,1
	EQUB HI(n * 80)
	NEXT
}

PAGE_ALIGN
.plasma_wavef_table_LO
{
	FOR n,0,255,1
	w=40*SIN(n * 2 * PI / 256)		; in screen chars
	EQUB LO(w)
	NEXT
}

.plasma_wavef_table_HI
{
	FOR n,0,255,1
	w=40*SIN(n * 2 * PI / 256)		; in screen chars
	EQUB HI(w)
	NEXT
}

PAGE_ALIGN
.plasma_wavey_table_LO
{
	FOR n,0,255,1
	w=20*SIN(n * 2 * PI / 256)		; in screen chars
;	w=10 * SIN(SIN(n * 2 * PI / 256) * 2 * PI)	\\ config 2
	EQUB LO(w) 
	NEXT
}
.plasma_wavey_table_HI
{
	FOR n,0,255,1
	w=20*SIN(n * 2 * PI / 256)		; in screen chars
;	w=10 * SIN(SIN(n * 2 * PI / 256) * 2 * PI)	\\ config 2
	EQUB HI(w) 
	NEXT
}

PAGE_ALIGN
.plasma_screen_data
INCBIN "data/hdither.pu"

.plasma_end
