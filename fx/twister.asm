\ ******************************************************************
\ *	Twister
\ ******************************************************************

twister_crtc_row = locals_start + 0

twister_spin_index = locals_start + 1		; index into spin table for top line
twister_spin_index_step = locals_start + 3	; rate at which spin index is updated each frame

twister_twist_index = locals_start + 5		; index into twist table for top line
twister_twist_frame_step = locals_start + 7	; rate at which twist index is update each frame
twister_twist_row_step = locals_start + 9	; rate at which twist indx is updated each row

twister_twist_local = locals_start + 11		; per row index into twist table


TWIST_INDEX_ROW_STEP = &0060	; if this is zero every row shares same twist
TWIST_INDEX_FRAME_STEP = &0080	; if this is zero then the twist amount stays same from frame-to-frame

SPIN_INDEX_STEP = &0100			; if this is zero then spin speed stays the same from frame-to-frame


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

	\\ Starting vars

	LDA #LO(TWIST_INDEX_ROW_STEP): STA twister_twist_row_step
	LDA #HI(TWIST_INDEX_ROW_STEP): STA twister_twist_row_step+1

	LDA #LO(TWIST_INDEX_FRAME_STEP): STA twister_twist_frame_step
	LDA #HI(TWIST_INDEX_FRAME_STEP): STA twister_twist_frame_step+1

	LDA #LO(SPIN_INDEX_STEP): STA twister_spin_index_step
	LDA #HI(SPIN_INDEX_STEP): STA twister_spin_index_step+1
	
	STZ twister_twist_index
	STZ twister_twist_index+1
	STZ twister_spin_index
	STZ twister_spin_index+1

	.return
	RTS
}

.twister_update
{
	\\ Update rotation of the top line by indexing into the spin table

	CLC
	LDA twister_x_LO+0
	LDX twister_spin_index+1
	ADC twister_spin_table_LO,X
	STA twister_x_LO+0

	LDA twister_x_HI+0
	ADC twister_spin_table_HI,X
	STA twister_x_HI+0

	\\ Set the first scanline

	AND #&7F
	TAY

	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	\\ Update the index into the spin table

	CLC
	LDA twister_spin_index
	ADC twister_spin_index_step
	STA twister_spin_index

	LDA twister_spin_index+1
	ADC twister_spin_index_step+1
	STA twister_spin_index+1

	\\ Update the index into the twist table

	CLC
	LDA twister_twist_index
	ADC twister_twist_frame_step
	STA twister_twist_index

	LDA twister_twist_index+1
	ADC twister_twist_frame_step+1
	STA twister_twist_index+1

	\\ Copy the twist index into a local variable for drawing

	LDA twister_twist_index
	STA twister_twist_local
	LDA twister_twist_index+1
	STA twister_twist_local+1

	\\ Could also compute 2nd scanline here
	
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

	\\ Calculate rotation of next line by indexing twist table

	CLC
	LDA twister_x_LO+0
	LDY twister_twist_local+1
	ADC twister_twist_table_LO, Y
	STA twister_x_LO+1

	LDA twister_x_HI+0
	ADC twister_twist_table_HI, Y
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

	FOR n,1,1,1
	NOP
	NEXT

	\\ Should be exactly on next scanline

	LDA #254					; 2c
	STA twister_crtc_row

	LDX #2

	.here

	\\ Update local twist index value by incrementing by step

	CLC
	LDA twister_twist_local
	ADC twister_twist_row_step
	STA twister_twist_local
	LDA twister_twist_local+1
	ADC twister_twist_row_step+1
	STA twister_twist_local+1
	TAY

	\\ Use the locl twist index to calculate rotation value

	CLC
	LDA twister_x_LO-1,X
	ADC twister_twist_table_LO, Y
	STA twister_x_LO+0,X

	LDA twister_x_HI-1,X
	ADC twister_twist_table_HI, Y
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

	FOR n,1,13,1
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

MACRO TWISTER_TWIST_LO deg_per_frame
	brads = 256 * 128 * (deg_per_frame / 256) / 360
	EQUB LO(brads)
ENDMACRO

MACRO TWISTER_TWIST_HI deg_per_frame
	brads = 256 * 128 * (deg_per_frame / 256) / 360
	EQUB HI(brads)
ENDMACRO

MACRO TWISTER_SPIN_LO deg_per_sec
	brads = 256 * 128 * (deg_per_sec / 50) / 360
	EQUB LO(brads)
ENDMACRO

MACRO TWISTER_SPIN_HI deg_per_sec
	brads = 256 * 128 * (deg_per_sec / 50) / 360
	EQUB HI(brads)
ENDMACRO

.twister_twist_table_LO			; rotation increment per row of the twister
FOR n,0,255,1
	t = 360 * ABS(n-128)/128
	TWISTER_TWIST_LO t
NEXT

.twister_twist_table_HI			; rotation increment per row of the twister
FOR n,0,255,1
	t = 360 * ABS(n-128)/128
	TWISTER_TWIST_HI t
NEXT

.twister_spin_table_LO			; rotation increment of top angle per frame
FOR n,0,255,1
	v = 210						; spin at 210 deg/sec
	TWISTER_SPIN_LO v
NEXT

.twister_spin_table_HI			; rotation increment of top angle per frame
FOR n,0,255,1
	v = 210						; spin at 210 deg/sec
	TWISTER_SPIN_HI v
NEXT

PAGE_ALIGN
.twister_screen_data
INCBIN "data/twist.pu"

.twister_end
