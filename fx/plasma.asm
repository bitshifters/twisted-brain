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

.plasma_draw		\\ [vert] enter PAL line 0
{
	\\ [effect-summary]
	\\ EFFECT : Vertical Rupture -- 4 scanlines/row x 63 rows (252 lines); PAL 312, vsync PAL 280; no per-scanline CRTC writes
	\\ SETUP  : ~1.1 lines -- rupture CRTC regs R4/R6/R7/R9 set, padded to the scanline boundary
	\\ LOOP   : 63x @ 513c (4 line/iter) -- calls JSR plasma_set_charrow, 3x JSR cycles_wait_128
	\\ FIXUP  : ~0.5 lines -- tail CRTC frame R4/R6/R7/R9 restored, RTS; free-runs to the frame boundary
	\\ GOTCHA : loop 513c = 4 scanlines +1c -> CRTC address writes drift each row (soft window, tolerable)
	\\ [/effect-summary]
	\\ R9=3 - character row = 4 scanlines
	LDA #9: STA &FE00		; 8c
	LDA #3:	STA &FE01		; 8c
	\\ <== 16c

	\\ R4=0 - CRTC cycle is one row
	LDA #4: STA &FE00		; 8c
	LDA #0: STA &FE01		; 8c
	\\ <== 32c

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00		; 8c
	LDA #&FF: STA &FE01		; 8c
	\\ <== 48c

	\\ R6=0 - one row displayed
	LDA #6: STA &FE00		; 8c
	LDA #1: STA &FE01		; 8c 8 * 6c = 48c
	\\ <== 64c

	\\ Cycle count to end of scanline

	FOR n,1,33,1
	NOP		; 66c
	NEXT

	.start_of_scanline_1 \ still in charrow 0

	LDA #63						; 2c
	STA plasma_crtc_count		; 3c
	\\ <== 7c

	LDY plasma_f_idx		; 3c
	LDX plasma_y_idx		; 3c
	\\ <== 13c

	.here		\\ [vert] loop x63: PAL lines 1..252
	\\ <== 13c

	TYA		; 2c
	CLC		; 2c
	ADC plasma_wavey		; 3c
	TAY		; 2c
	\\ <== 22c

	CLC							; 2c
	LDA plasma_x16				; 3c
	ADC plasma_wavef_table_LO, Y	; 4c
	STA plasma_addr				; 3c
	LDA plasma_x16+1			; 3c
	ADC plasma_wavef_table_HI, Y	; 4c
	STA plasma_addr+1			; 3c
	\\ <== 44c

	TXA		; 2c
	CLC		; 2c
	ADC plasma_wavex		; 3c
	TAX		; 2c
	\\ <== 53c

	CLC		; 2c
	LDA plasma_addr		; 3c
	ADC plasma_wavey_table_LO, X		; 4c
	STA plasma_addr		; 3c
	LDA plasma_addr+1		; 3c
	ADC plasma_wavey_table_HI, X		; 4c
	STA plasma_addr+1		; 3c
	\\ <== 75c

	\\ Set adddress of character row

	JSR plasma_set_charrow		; 49c
	\\ <== 124c

	FOR n,1,5,1
	NOP		; 10c
	NEXT

	JSR cycles_wait_128		; 128c
	\\ <== 128c/0c
	JSR cycles_wait_128		; 128c
	\\ <== 128c/0c
	JSR cycles_wait_128		; 128c
	\\ <== 128c/0c
	
	DEC plasma_crtc_count		; 5c
	BNE here					; 3c
	\\ <== 14c

	\\ Should arrive here on scanline 255 = last row but scanline 3
	.start_of_charrow_63

	\\ R9=0 - character row = 2 scanlines
	LDA #9: STA &FE00		; 7c (odd stretch +1)
	LDA #3:	STA &FE01			; 8c 4 scanlines
	\\ <== 28c

	\\ R4=56 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00		; 8c
	LDA #14-1+1: STA &FE01		; 8c 312 - 256 = 56 scanlines = 14 rows + the one we're on
	\\ <== 44c

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00		; 8c
	LDA #6+1: STA &FE01			; 8c 280 - 256 = 24 scanlines = 6 rows
	\\ <== 60c

	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00		; 8c
	LDA #1: STA &FE01		; 8c
	\\ <== 76c

	\\ Don't set anything else here - will happen in update for charrow 0

    RTS		; 6c
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
	LDA #13: STA &FE00				; 7c (odd stretch +1)

	\\ Set x value, X=LO byte & Y=HI byte
	CLC		; 2c
	LDA plasma_addr					; 3c
	ADC #LO(screen_base_addr/8)		; 2c
	STA &FE01						; 5c (odd stretch +1)

   	LDA #12: STA &FE00				; 8c
    LDA plasma_addr+1				; 3c
	ADC #HI(screen_base_addr/8)		; 2c
	STA &FE01						; 5c (odd stretch +1)
	
	RTS								; 6c
}	\\ total = 43c body + 6c JSR = 49c

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
