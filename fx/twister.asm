\ ******************************************************************
\ *	Twister
\ ******************************************************************

twister_crtc_row = locals_start + 0

;twister_row_vel_const = locals_start + 1		; constant increment per row (if any)
twister_row_vel_idx_start = locals_start + 3	; index into row velocity table of top line

twister_row_vel_idx = locals_start + 5			; per row index into velocity table

twister_row_vel_idx_speed = locals_start + 9	; speed at which row vel idx is updated each row
twister_row_vel_idx_frame = locals_start + 11	; speed at which row vel idx start is update each frame


ROW_INDEX_SPEED = &0000			; if this is zero every row shares same 'velocity' (amount of twist)
ROW_INDEX_FRAME = &0000			; if this is zero then the starting 'velocity' of the top row doesn't change


twister_velocity = locals_start + 15		; speed of top line of twister in half brads/frame
twister_target_vel = locals_start + 17		; target velocity of top line
twister_accel = locals_start + 19			; acceleration value used to accelerate to target velocity
twister_accelN = locals_start + 21

twister_diff = locals_start + 23

twister_twist = locals_start + 25			; constant twist in brads/row
twister_target_twist = locals_start + 27
twister_twist_speed = locals_start + 29
twister_twist_speedN = locals_start + 31

TWISTER_DEFAULT_VELOCITY = &0000			; 8.8 brads/frame
TWISTER_DEFAULT_ACCEL = &0001				; 8.8 brads/frame
TWISTER_DEFAULT_TWIST = &0000				; 8.8 brads/row
TWISTER_DEFAULT_TWIST_SPEED = &0001			; 8.8 brads/row

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

	STZ twister_row_vel_idx_start
	STZ twister_row_vel_idx_start+1

	LDA #LO(TWISTER_DEFAULT_ACCEL): JSR twister_set_accel_LO
	LDA #HI(TWISTER_DEFAULT_ACCEL): JSR twister_set_accel_HI

	LDA #LO(TWISTER_DEFAULT_VELOCITY): STA twister_velocity
	LDA #HI(TWISTER_DEFAULT_VELOCITY): STA twister_velocity+1

	LDA twister_velocity: STA twister_target_vel
	LDA twister_velocity+1: STA twister_target_vel+1

	LDA #LO(TWISTER_DEFAULT_TWIST_SPEED): JSR twister_set_twist_speed_LO
	LDA #HI(TWISTER_DEFAULT_TWIST_SPEED): JSR twister_set_twist_speed_HI

	LDA #LO(TWISTER_DEFAULT_TWIST): STA twister_twist
	LDA #HI(TWISTER_DEFAULT_TWIST): STA twister_twist+1

	LDA twister_twist: STA twister_target_twist
	LDA twister_twist+1: STA twister_target_twist+1
	

	.return
	RTS
}

.twister_set_accel_LO
{
	STA twister_accel
	RTS
}

.twister_set_accel_HI
{
	STA twister_accel+1

	CLC
	LDA twister_accel
	EOR #&FF
	CLC
	ADC #1
	STA twister_accelN
	LDA twister_accel+1
	EOR #&FF
	ADC #0
	STA twister_accelN+1
	RTS
}

.twister_set_twist_speed_LO
{
	STA twister_twist_speed
	RTS
}

.twister_set_twist_speed_HI
{
	STA twister_twist_speed+1

	CLC
	LDA twister_twist_speed
	EOR #&FF
	CLC
	ADC #1
	STA twister_twist_speedN
	LDA twister_twist_speed+1
	EOR #&FF
	ADC #0
	STA twister_twist_speedN+1
	RTS
}

.twister_set_target_vel_LO
{
	STA twister_target_vel
	RTS
}

.twister_set_target_vel_HI
{
	STA twister_target_vel+1
	RTS
}

.twister_set_target_twist_LO
{
	STA twister_target_twist
	RTS
}

.twister_set_target_twist_HI
{
	STA twister_target_twist+1
	RTS
}

.twister_update
{
	\\ Update velocity according to target
	SEC
	LDA twister_target_vel
	SBC twister_velocity
	STA twister_diff
	LDA twister_target_vel+1
	SBC twister_velocity+1
	STA twister_diff+1
	
	{
		LDA twister_diff
		BNE not_zero
		\\ Zero diff LO
		LDA twister_diff+1
		BEQ zero_diff
		.not_zero
		\\ Move towards target!

		LDA twister_diff+1
		CMP #&80
		BCC positive

		\\ Diff is negative
		{
			\\ Is our diff smaller than our acceleration value?
			LDA twister_accelN+1
			CMP twister_diff+1
			BCC is_smaller
			BNE is_larger_or_equal
			\\ Same HI
			LDA twister_accelN
			CMP twister_diff
			BCC is_smaller

			.is_larger_or_equal
			CLC
			LDA twister_velocity
			ADC twister_accelN
			STA twister_velocity
			LDA twister_velocity+1
			ADC twister_accelN+1
			STA twister_velocity+1
			BRA done
		}

		.positive
		{
			\\ Is our diff smaller than our acceleration value?
			LDA twister_diff+1
			CMP twister_accel+1
			BCC is_smaller
			BNE is_larger_or_equal
			\\ Same HI
			LDA twister_diff
			CMP twister_accel
			BCC is_smaller

			.is_larger_or_equal
			CLC
			LDA twister_velocity
			ADC twister_accel
			STA twister_velocity
			LDA twister_velocity+1
			ADC twister_accel+1
			STA twister_velocity+1
			BRA done
		}

			.is_smaller
			CLC
			LDA twister_velocity
			ADC twister_diff
			STA twister_velocity
			LDA twister_velocity+1
			ADC twister_diff+1
			STA twister_velocity+1

		.done
		.zero_diff	; we're at target
	}

	\\ Update twist according to target
	SEC
	LDA twister_target_twist
	SBC twister_twist
	STA twister_diff
	LDA twister_target_twist+1
	SBC twister_twist+1
	STA twister_diff+1
	
	{
		LDA twister_diff
		BNE not_zero
		\\ Zero diff LO
		LDA twister_diff+1
		BEQ zero_diff
		.not_zero
		\\ Move towards target!

		LDA twister_diff+1
		CMP #&80
		BCC positive

		\\ Diff is negative
		{
			\\ Is our diff smaller than our acceleration value?
			LDA twister_twist_speedN+1
			CMP twister_diff+1
			BCC is_smaller
			BNE is_larger_or_equal
			\\ Same HI
			LDA twister_twist_speedN
			CMP twister_diff
			BCC is_smaller

			.is_larger_or_equal
			CLC
			LDA twister_twist
			ADC twister_twist_speedN
			STA twister_twist
			LDA twister_twist+1
			ADC twister_twist_speedN+1
			STA twister_twist+1
			BRA done
		}

		.positive
		{
			\\ Is our diff smaller than our acceleration value?
			LDA twister_diff+1
			CMP twister_twist_speed+1
			BCC is_smaller
			BNE is_larger_or_equal
			\\ Same HI
			LDA twister_diff
			CMP twister_twist_speed
			BCC is_smaller

			.is_larger_or_equal
			CLC
			LDA twister_twist
			ADC twister_twist_speed
			STA twister_twist
			LDA twister_twist+1
			ADC twister_twist_speed+1
			STA twister_twist+1
			BRA done
		}

			.is_smaller
			CLC
			LDA twister_twist
			ADC twister_twist_speed
			STA twister_twist
			LDA twister_twist+1
			ADC twister_twist_speed+1
			STA twister_twist+1

		.done
		.zero_diff	; we're at target
	}

	\\ Update rotational angle of top of twister
	CLC
	LDA twister_x_LO+0
	ADC twister_velocity
	STA twister_x_LO+0

	LDA twister_x_HI+0
	ADC twister_velocity+1
	STA twister_x_HI+0
	
	\\ Set the address to be displayed on scanline 0
	AND #&7F
	TAY

	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	\\ Update various row indices
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
	ADC twister_twist
	STA twister_x_LO+1

	LDA twister_x_HI+0
	ADC twister_twist+1
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
	ADC twister_twist
;	LDY twister_row_vel_idx
;	ADC twister_row_vel_LO, Y
	STA twister_x_LO+0,X

	LDA twister_x_HI-1,X
;	ADC twister_row_vel_const+1
;	ADC twister_row_vel_HI, Y
	ADC twister_twist+1
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

	FOR n,1,14,1
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
;v = &80 * ABS(n-128)/128
v = 0
EQUB LO(v)
NEXT

.twister_row_vel_HI			; rotation increment per row
FOR n,0,255,1
;EQUB ABS(n-128)
;v = 128 + ABS(n - 128)
;v = &400 * (SIN(n * PI / 256) * SIN(n * PI / 256))
;v = &80 * ABS(n-128)/128
v = 0
EQUB HI(v)
NEXT

PAGE_ALIGN
.twister_screen_data
INCBIN "data/twist.pu"

.twister_end
