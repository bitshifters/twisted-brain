\ ******************************************************************
\ *	Twister
\ ******************************************************************

twister_crtc_row = locals_start + 0

twister_row_rot = locals_start + 1

twister_row_rot_index = locals_start + 3
twister_row_rot_local = locals_start + 4

twister_top_index = locals_start + 5

ROT_SPEED_ROW = &0040
ROT_SPEED_TOP = &0100

.twister_start

.twister_init
{
    SET_ULA_MODE ULA_Mode1

	LDX #LO(twister_pal)
	LDY #HI(twister_pal)
	JSR ula_set_palette

	LDA #20:JSR twister_set_displayed

	LDX #LO(twister_screen_data)
	LDY #HI(twister_screen_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

	LDA #LO(ROT_SPEED_ROW)
	STA twister_row_rot
	LDA #HI(ROT_SPEED_ROW)
	STA twister_row_rot+1

	STZ twister_row_rot_index
	STZ twister_top_index

	.return
	RTS
}

.twister_update
{
	CLC
	LDA twister_x_LO+0
;	ADC #LO(ROT_SPEED_TOP)
	ADC twister_top_change,X
	STA twister_x_LO+0
	LDA twister_x_HI+0
	ADC #HI(ROT_SPEED_TOP)
	LDX twister_top_index
	STA twister_x_HI+0

	AND #&7F
	TAY

	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	INC twister_top_index

	INC twister_row_rot_index

	LDA twister_row_rot_index
	STA twister_row_rot_local

    RTS
}

.twister_draw
{
	\\ R9=0 - character row = 1 scanline
	LDA #9: STA &FE00
	LDA #0:	STA &FE01

	\\ R4=0 - CRTC cycle is one row
	LDA #4: STA &FE00
	LDA #0: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #&FF: STA &FE01

	\\ R6=1 - one row displayed
	LDA #6: STA &FE00
	LDA #1: STA &FE01

	LDA twister_x_LO+0
;	ADC #LO(ROT_SPEED_ROW)
;	ADC twister_row_rot
	LDY twister_row_rot_local
	ADC twister_row_rot_change, Y
	STA twister_x_LO+1
	LDA twister_x_HI+0
;	ADC #HI(ROT_SPEED_ROW)
	ADC twister_row_rot+1
	STA twister_x_HI+1

	AND #&7F
	TAY

	\\ R12,13 - frame buffer address
	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	FOR n,1,4,1
	NOP
	NEXT

	\\ Should be exactly on next scanline

	LDA #254					; 2c
	STA twister_crtc_row

	LDX #2

	.here

	CLC
	LDA twister_x_LO-1,X
;	ADC #LO(ROT_SPEED_ROW)
	LDY twister_row_rot_local
	ADC twister_row_rot_change, Y
;	ADC twister_row_rot
	STA twister_x_LO+0,X
	LDA twister_x_HI-1,X
	INC twister_row_rot_local
;	ADC #HI(ROT_SPEED_ROW)
	ADC twister_row_rot+1
	STA twister_x_HI+0,X
	
	AND #&7F
	TAY
	INX

	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++
	
	\\ 30c min + 10c loop, need 88c NOPs

	FOR n,1,20,1
	NOP
	NEXT
	
	DEC twister_crtc_row
	BNE here		; 3c

	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00
	LDA #1-1:	STA &FE01		; 1 scanline

	\\ R4=6 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #56-1+1: STA &FE01		; 312 - 256 = 56 scanlines

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #24+1: STA &FE01			; 280 - 256 = 24 scanlines

	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #1: STA &FE01

    RTS
}

.twister_kill
{
	JSR crtc_reset
    SET_ULA_MODE ULA_Mode2
    JMP ula_pal_reset
}

.twister_set_displayed
{
	PHA
	LDA #1
	STA &FE00
	PLA
	STA &FE01
	RTS
}

.twister_pal
{
	EQUB &00 + PAL_black
	EQUB &10 + PAL_black
	EQUB &20 + PAL_red
	EQUB &30 + PAL_red
	EQUB &40 + PAL_black
	EQUB &50 + PAL_black
	EQUB &60 + PAL_red
	EQUB &70 + PAL_red
	EQUB &80 + PAL_cyan
	EQUB &90 + PAL_cyan
	EQUB &A0 + PAL_white
	EQUB &B0 + PAL_white
	EQUB &C0 + PAL_cyan
	EQUB &D0 + PAL_cyan
	EQUB &E0 + PAL_white
	EQUB &F0 + PAL_white
}

PAGE_ALIGN

\\ For rot value N ptr to framebuffer

.twister_vram_table_LO
FOR n,0,127,1
EQUB LO((&3000 + n*160)/8)
NEXT

.twister_vram_table_HI
FOR n,0,127,1
EQUB HI((&3000 + n*160)/8)
NEXT

.twister_x_LO
FOR n,0,255,1
EQUB 0
NEXT

.twister_x_HI
FOR n,0,255,1
EQUB 0
NEXT

.twister_row_rot_change
FOR n,0,255,1
EQUB ABS(n-128)
NEXT

.twister_top_change
FOR n,0,255,1
EQUB 128
NEXT

PAGE_ALIGN
.twister_screen_data
INCBIN "data/twist.pu"

.twister_end
