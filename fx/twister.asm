\ ******************************************************************
\ *	Twister
\ ******************************************************************

twister_crtc_row = locals_start + 0

;twister_row_vel_const = locals_start + 1		; constant increment per row (if any)
twister_row_vel_idx_start = locals_start + 3	; index into row velocity table of top line

twister_row_vel_idx = locals_start + 5			; per row index into velocity table
twister_frame_vel_idx = locals_start + 7		; per frame index into velocity table

twister_row_vel_idx_speed = locals_start + 9	; speed at which row vel idx is updated each row
twister_row_vel_idx_frame = locals_start + 11	; speed at which row vel idx start is update each frame

twister_frame_vel_idx_speed = locals_start + 13	; speed at which per frame index is updated each frame

;ROT_SPEED_ROW = &0040
;ROT_SPEED_TOP = &0000

ROW_INDEX_SPEED = &0060			; if this is zero every row shares same 'velocity' (amount of twist)
ROW_INDEX_FRAME = &0080			; if this is zero then the starting 'velocity' of the top row doesn't change

FRAME_INDEX_SPEED = &0100		; if this is zero then index into the velocity table doesn't change

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

;	LDA #LO(ROT_SPEED_ROW):	STA twister_row_vel_const
;	LDA #HI(ROT_SPEED_ROW):	STA twister_row_vel_const+1

	LDA #LO(ROW_INDEX_SPEED): STA twister_row_vel_idx_speed
	LDA #HI(ROW_INDEX_SPEED): STA twister_row_vel_idx_speed+1

	LDA #LO(ROW_INDEX_FRAME): STA twister_row_vel_idx_frame
	LDA #HI(ROW_INDEX_FRAME): STA twister_row_vel_idx_frame+1

	LDA #LO(FRAME_INDEX_SPEED): STA twister_frame_vel_idx_speed
	LDA #HI(FRAME_INDEX_SPEED): STA twister_frame_vel_idx_speed+1
		
	STZ twister_row_vel_idx_start
	STZ twister_row_vel_idx_start+1
	STZ twister_frame_vel_idx
	STZ twister_frame_vel_idx+1

	.return
	RTS
}

.twister_update
{
	CLC
	LDA twister_x_LO+0
;	ADC #LO(ROT_SPEED_TOP)
	LDX twister_frame_vel_idx+1
	ADC twister_frame_vel_LO,X
	STA twister_x_LO+0

	LDA twister_x_HI+0
;	ADC #HI(ROT_SPEED_TOP)
	ADC twister_frame_vel_HI,X
	STA twister_x_HI+0

	AND #&7F
	TAY

	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	CLC
	LDA twister_frame_vel_idx
	ADC twister_frame_vel_idx_speed
	STA twister_frame_vel_idx
	LDA twister_frame_vel_idx+1
	ADC twister_frame_vel_idx_speed+1
	STA twister_frame_vel_idx+1

	CLC
	LDA twister_row_vel_idx_start
	ADC twister_row_vel_idx_frame
	STA twister_row_vel_idx_start

	LDA twister_row_vel_idx_start+1
	ADC twister_row_vel_idx_frame+1
	STA twister_row_vel_idx_start+1

	LDA twister_row_vel_idx_start
	STA twister_row_vel_idx
	LDA twister_row_vel_idx_start+1
	STA twister_row_vel_idx+1
	
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

	CLC
	LDA twister_x_LO+0
;	ADC #LO(ROT_SPEED_ROW)
;	ADC twister_row_vel_const
	LDY twister_row_vel_idx+1
	ADC twister_row_vel_LO, Y
	STA twister_x_LO+1

	LDA twister_x_HI+0
;	ADC #HI(ROT_SPEED_ROW)
;	ADC twister_row_vel_const+1
	ADC twister_row_vel_HI, Y
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

;	INC twister_row_vel_idx
	CLC
	LDA twister_row_vel_idx
	ADC twister_row_vel_idx_speed
	STA twister_row_vel_idx
	LDA twister_row_vel_idx+1
	ADC twister_row_vel_idx_speed+1
	STA twister_row_vel_idx+1
	TAY
	
	CLC
	LDA twister_x_LO-1,X
;	ADC #LO(ROT_SPEED_ROW)
;	ADC twister_row_vel_const
;	LDY twister_row_vel_idx
	ADC twister_row_vel_LO, Y
	STA twister_x_LO+0,X

	LDA twister_x_HI-1,X
;	ADC #HI(ROT_SPEED_ROW)
;	ADC twister_row_vel_const+1
	ADC twister_row_vel_HI, Y
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

.twister_row_vel_LO			; rotation increment per row
FOR n,0,255,1
;v = 128 + ABS(n - 128)
;v = &400 * (SIN(n * PI / 256) * SIN(n * PI / 256))
v = &80 * ABS(n-128)/128
EQUB LO(v)
NEXT

.twister_row_vel_HI			; rotation increment per row
FOR n,0,255,1
;EQUB ABS(n-128)
;v = 128 + ABS(n - 128)
;v = &400 * (SIN(n * PI / 256) * SIN(n * PI / 256))
v = &80 * ABS(n-128)/128
EQUB HI(v)
NEXT

.twister_frame_vel_LO			; rotation increment of top angle per frame
FOR n,0,255,1
;v = &400 * ABS(n-128)/128
v = &180
EQUB LO(v)
NEXT

.twister_frame_vel_HI			; rotation increment of top angle per frame
FOR n,0,255,1
;v = &400 * ABS(n-128)/128
v = &180
EQUB HI(v)
NEXT

PAGE_ALIGN
.twister_screen_data
INCBIN "data/twist.pu"

.twister_end
