\ ******************************************************************
\ *	Twister
\ ******************************************************************

twister_crtc_row = locals_start + 0

twister_spin_index = locals_start + 1		; index into spin table for top line
twister_spin_step = locals_start + 3		; rate at which spin index is updated each frame

twister_twist_index = locals_start + 5		; index into twist table for top line
twister_twist_step = locals_start + 7		; rate at which twist index is update each frame

twister_knot_index = locals_start + 9		; index into knot table for top line
twister_knot_step = locals_start + 11		; rate at which knot index is updated each frame

twister_spin_brot = locals_start + 13		; rotation amount of top line
twister_twist_brot = locals_start + 15		; rotation amount per row

twister_knot_i = locals_start + 17			; per row index into knot table
twister_knot_y = locals_start + 19			; rate at which knot index is updated vertical

TWISTER_SPIN_STEP = &0000	; if this is zero then spin speed stays the same from frame-to-frame
TWISTER_TWIST_STEP = &0000	; if this is zero then the twist amount stays same from frame-to-frame
TWISTER_KNOT_Y = &0000		; if this is zero every row shares same twist (no knots)
TWISTER_KNOT_STEP = &0000	; if this is zero then the amount of knots stays same from frame-to-frame

TWISTER_DEFAULT_SPIN_INDEX = 0 * &100		; no spin
TWISTER_DEFAULT_TWIST_INDEX = 0 * &100		; no twist
TWISTER_DEFAULT_KNOT_INDEX = 0 * &100		; no knots

.twister_start

.twister_init
{
    SET_ULA_MODE ULA_Mode1

	LDX #LO(twister_pal)
	LDY #HI(twister_pal)
	JSR ula_set_palette

;	LDA #20:JSR twister_set_displayed

	LDX #LO(twister_screen_data)
	LDY #HI(twister_screen_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

	\\ Starting paramaters

	LDA #LO(TWISTER_DEFAULT_SPIN_INDEX): STA twister_spin_index
	LDA #HI(TWISTER_DEFAULT_SPIN_INDEX): STA twister_spin_index+1
	
	LDA #LO(TWISTER_DEFAULT_TWIST_INDEX): STA twister_twist_index
	LDA #HI(TWISTER_DEFAULT_TWIST_INDEX): STA twister_twist_index+1

	LDA #LO(TWISTER_DEFAULT_KNOT_INDEX): STA twister_knot_index
	LDA #HI(TWISTER_DEFAULT_KNOT_INDEX): STA twister_knot_index+1

	LDA #LO(TWISTER_SPIN_STEP): STA twister_spin_step
	LDA #HI(TWISTER_SPIN_STEP): STA twister_spin_step+1
	
	LDA #LO(TWISTER_TWIST_STEP): STA twister_twist_step
	LDA #HI(TWISTER_TWIST_STEP): STA twister_twist_step+1

	LDA #LO(TWISTER_KNOT_STEP): STA twister_knot_step
	LDA #HI(TWISTER_KNOT_STEP): STA twister_knot_step+1

	LDA #LO(TWISTER_KNOT_Y): STA twister_knot_y
	LDA #HI(TWISTER_KNOT_Y): STA twister_knot_y+1

	\\ Starting variables

	STZ twister_spin_brot
	STZ twister_spin_brot+1
	STZ twister_twist_brot
	STZ twister_twist_brot+1

	.return
	RTS
}

.twister_update
{
	\\ Update rotation of the top line by indexing into the spin table

	CLC
	LDA twister_spin_brot
	LDX twister_spin_index+1
	ADC twister_spin_table_LO,X
	STA twister_spin_brot

	LDA twister_spin_brot+1
	ADC twister_spin_table_HI,X
	STA twister_spin_brot+1

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
	ADC twister_spin_step
	STA twister_spin_index

	LDA twister_spin_index+1
	ADC twister_spin_step+1
	STA twister_spin_index+1

	\\ Update the index into the twist table

	CLC
	LDA twister_twist_index
	ADC twister_twist_step
	STA twister_twist_index

	LDA twister_twist_index+1
	ADC twister_twist_step+1
	STA twister_twist_index+1

	\\ Update the index into the knot table

	CLC
	LDA twister_knot_index
	ADC twister_knot_step
	STA twister_knot_index

	LDA twister_knot_index+1
	ADC twister_knot_step+1
	STA twister_knot_index+1

	\\ Calculate rotation of 2nd scanline by indexing twist table

	CLC
	LDA twister_spin_brot
	LDY twister_twist_index+1
	ADC twister_twist_table_LO, Y
	STA twister_twist_brot

	LDA twister_spin_brot+1
	ADC twister_twist_table_HI, Y
	STA twister_twist_brot+1

	\\ Copy the twist index into a local variable for drawing

	LDA twister_knot_index
	STA twister_knot_i
	LDA twister_knot_index+1
	STA twister_knot_i+1

	\\ Add knot for second line

	CLC
	LDA twister_twist_brot
	LDY twister_knot_i+1
	ADC twister_knot_table_LO, Y
	STA twister_twist_brot

	LDA twister_twist_brot+1
	ADC twister_knot_table_HI, Y
	STA twister_twist_brot+1
	
	\ Beat flash experiment - harder than it looks
IF 0
	LDA vgm_beat_counter
	AND #&1
	BEQ no_beat

	LDA vgm_beat_frames
	CMP #4
	BCS no_beat

	\\ Beat
	LDA #PAL_white
	JSR pal_set_mode1_colour2
	LDA #PAL_white
	JSR pal_set_mode1_colour1
	BRA return

	.no_beat
	LDA #PAL_yellow
	JSR pal_set_mode1_colour2
	LDA #PAL_red
	JSR pal_set_mode1_colour1
ENDIF

	.return
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

	LDA twister_twist_brot+1
	AND #&7F
	TAY

	\\ R12,13 - frame buffer address
	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	FOR n,1,8,1
	NOP
	NEXT

	\\ Should be exactly on next scanline

	LDA #254					; 2c
	STA twister_crtc_row

	LDX #2

	.here

	\\ Apply the (global) twist value to the row first

	CLC
	LDA twister_twist_brot
	LDY twister_twist_index+1
	ADC twister_twist_table_LO, Y
	STA twister_twist_brot

	LDA twister_twist_brot+1
	ADC twister_twist_table_HI, Y
	STA twister_twist_brot+1

	\\ Update local twist index value by incrementing by step

	CLC
	LDA twister_knot_i
	ADC twister_knot_y
	STA twister_knot_i
	LDA twister_knot_i+1
	ADC twister_knot_y+1
	STA twister_knot_i+1
	TAY

	\\ Use the local twist index to calculate additional rotation value 'knot'

	CLC
	LDA twister_twist_brot
	ADC twister_knot_table_LO, Y
	STA twister_twist_brot

	LDA twister_twist_brot+1
	ADC twister_knot_table_HI, Y
	STA twister_twist_brot+1
	
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

	FOR n,1,5,1
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
	JSR crtc_reset_from_single
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

.twister_set_position
{
	PHA
	LDA #2
	STA &FE00
	PLA
	STA &FE01
	RTS
}

.twister_set_spin_step_LO
{
	STA twister_spin_step
	RTS
}

.twister_set_spin_step_HI
{
	STA twister_spin_step+1
	RTS
}

.twister_set_twist_step_LO
{
	STA twister_twist_step
	RTS
}

.twister_set_twist_step_HI
{
	STA twister_twist_step+1
	RTS
}

.twister_set_knot_step_LO
{
	STA twister_knot_step
	RTS
}

.twister_set_knot_step_HI
{
	STA twister_knot_step+1
	RTS
}

.twister_set_knot_y_LO
{
	STA twister_knot_y
	RTS
}

.twister_set_knot_y_HI
{
	STA twister_knot_y+1
	RTS
}

.twister_set_spin_index
{
	STA twister_spin_index+1
	STZ twister_spin_index
	RTS
}

.twister_set_twist_index
{
	STA twister_twist_index+1
	STZ twister_twist_index
	RTS
}

.twister_set_knot_index
{
	STA twister_knot_index+1
	STZ twister_knot_index
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
	EQUB &80 + PAL_green
	EQUB &90 + PAL_green
	EQUB &A0 + PAL_blue
	EQUB &B0 + PAL_blue
	EQUB &C0 + PAL_green
	EQUB &D0 + PAL_green
	EQUB &E0 + PAL_blue
	EQUB &F0 + PAL_blue
}

PAGE_ALIGN

\\ Maps our 128 rotations values to screen buffer address

.twister_vram_table_LO
FOR n,0,127,1
EQUB LO((&3000 + n*160)/8)
NEXT

.twister_vram_table_HI
FOR n,0,127,1
EQUB HI((&3000 + n*160)/8)
NEXT

MACRO TWISTER_TWIST_LO deg_per_frame
	brads = 256 * 128 * (deg_per_frame / 256) / 360
	PRINT "TWIST: deg/frame=", deg_per_frame, " brads=", ~brads
	EQUB LO(brads)
ENDMACRO

MACRO TWISTER_TWIST_HI deg_per_frame
	brads = 256 * 128 * (deg_per_frame / 256) / 360
	EQUB HI(brads)
ENDMACRO

MACRO TWISTER_SPIN_LO deg_per_sec
	brads = 256 * 128 * (deg_per_sec / 50) / 360
	PRINT "SPIN: deg/sec=", deg_per_sec, " brads=", ~brads
	EQUB LO(brads)
ENDMACRO

MACRO TWISTER_SPIN_HI deg_per_sec
	brads = 256 * 128 * (deg_per_sec / 50) / 360
	EQUB HI(brads)
ENDMACRO

\\ Vary twist over time and/or vertical

.twister_twist_table_LO			; global rotation increment per row of the twister
FOR n,0,255,1
{
;	t = 360 * SIN(2 * PI * n / 256)
	IF n < 128
	m = (64 - ABS(n-64))/64
	ELSE
	m = -(64 - ABS(n-192))/64
	ENDIF
	t = 480 * m
	TWISTER_TWIST_LO t
}
NEXT

.twister_twist_table_HI			; global rotation increment per row of the twister
FOR n,0,255,1
{
;	t = 360 * SIN(2 * PI * n / 256)
	IF n < 128
	m = (64 - ABS(n-64))/64
	ELSE
	m = -(64 - ABS(n-192))/64
	ENDIF
	t = 480 * m
	TWISTER_TWIST_HI t
}
NEXT

.twister_knot_table_LO			; local rotation increment per row of the twister
FOR n,0,255,1
{
	m = (128 - ABS(n-128))/128
	t = 720 * m * m
	TWISTER_TWIST_LO t
}
NEXT

.twister_knot_table_HI			; local rotation increment per row of the twister
FOR n,0,255,1
{
	m = (128 - ABS(n-128))/128
	t = 720 * m * m
	TWISTER_TWIST_HI t
}
NEXT

\\ Vary spin over time

.twister_spin_table_LO			; rotation increment of top angle per frame
FOR n,0,255,1
{
;	v = 210						; spin at 210 deg/sec
	v = 360 * SIN(2 * PI * n/ 256)
	TWISTER_SPIN_LO v
}
NEXT

.twister_spin_table_HI			; rotation increment of top angle per frame
FOR n,0,255,1
{
;	v = 210						; spin at 210 deg/sec
	v = 360 * SIN(2 * PI * n/ 256)
	TWISTER_SPIN_HI v
}
NEXT

PAGE_ALIGN
.twister_screen_data
INCBIN "data/twist.pu"

.twister_end
