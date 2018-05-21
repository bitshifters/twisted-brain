\ ******************************************************************
\ *	Twister
\ ******************************************************************

twister_crtc_row = locals_start + 0
twister_angle = locals_start + 1
twister_frame_speed = locals_start + 3
twister_prop = locals_start + 5
twister_prop_idx = locals_start + 7

twister_sine_idx = locals_start + 9

twister_amp = locals_start + 10

twister_prop_speed = locals_start + 12
twister_prop_step = locals_start + 14
twister_amp_idx = locals_start + 16

.twister_start

.twister_init
{
	STZ twister_angle
	STZ twister_angle+1
	STZ twister_sine_idx

	LDA #0:STA twister_amp_idx			; index into amp_table per frame
	LDA #0:STA twister_amp_idx+1

	LDA #0:STA twister_prop_idx			; index into amp_table per row
	LDA #0:STA twister_prop_idx+1

	LDA #33:STA twister_frame_speed	; twist angle increment per frame
	LDA #3:STA twister_frame_speed+1

	LDA #64:STA twister_amp				; twist amplitude for this frame (not used)
	LDA #0:STA twister_amp+1

	LDA #64:STA twister_prop_speed		; per row increment of prop_idx
	LDA #0:STA twister_prop_speed+1

	LDA #0:STA twister_prop_step		; per frame increment of twister_amp_idx (broken?)
	LDA #1:STA twister_prop_step+1

    SET_ULA_MODE ULA_Mode1

	LDX #LO(twister_pal)
	LDY #HI(twister_pal)
	JSR ula_set_palette

;	LDA #20:JSR twister_set_displayed

	LDX #LO(twister_screen_data)
	LDY #HI(twister_screen_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

	.return
	RTS
}

.twister_update
{
	IF 1
	CLC
	LDA twister_angle
	ADC twister_frame_speed		; speed of top line
	STA twister_angle

	LDA twister_angle+1
	ADC twister_frame_speed+1		; speed of top line
	STA twister_angle+1
	ELSE

	LDX twister_sine_idx
	LDA twister_sine_table, X
	STA twister_angle+1

	INC twister_sine_idx
	ENDIF

	LDA twister_angle
	STA twister_prop
	LDA twister_angle+1
	STA twister_prop+1

	AND #&7F
	TAY

	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	LDA twister_amp_idx
	CLC
	ADC twister_prop_step
	STA twister_amp_idx
	LDA twister_amp_idx+1
	ADC twister_prop_step+1
	STA twister_amp_idx+1

	LDA twister_amp_idx
	STA twister_prop_idx
	LDA twister_amp_idx+1
	STA twister_prop_idx+1

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

IF 0
	LDA twister_angle
	CLC
	ADC twister_row_speed	; twist amount
	TAX
ELSE
	LDA twister_prop
	CLC
	LDX twister_prop_idx+1
	ADC twister_amp_table_LO,X
;	ADC twister_amp
	STA twister_prop
	LDA twister_prop+1
;	ADC #0
;	ADC twister_amp+1
	ADC twister_amp_table_HI,X
	STA twister_prop+1
ENDIF
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

	.here

IF 0
	TXA
	CLC
	ADC twister_row_speed	; row amount
	TAX
ELSE
	LDA twister_prop_idx
	CLC
	ADC twister_prop_speed
	LDA twister_prop_idx+1
	ADC twister_prop_speed+1
	STA twister_prop_idx+1
	TAX

	LDA twister_prop
	CLC
;	ADC twister_amp
	ADC twister_amp_table_LO,X ; +1c
	STA twister_prop
	LDA twister_prop+1
;	ADC #0
;	ADC twister_amp+1
	ADC twister_amp_table_HI,X ; +1c
	STA twister_prop+1
ENDIF

	AND #&7F
	TAY

	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++
	
	\\ 30c min + 10c loop, need 88c NOPs

	FOR n,1,19,1
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

.twister_amp_table_LO
FOR n,0,255,1
;EQUB 32 + 32 * SIN(2 * PI * n / 256)
;EQUB n			; amplitude = 128*n/255
;EQUB 128 - ABS(n-128)
a = 128 + 128 * SIN(2 * PI * n / 256) * SIN(3 * 2 * PI * n / 2565)
EQUB LO(a)
NEXT

.twister_amp_table_HI
FOR n,0,255,1
a = &100 * SIN(2 * PI * n / 256) * SIN(3 * 2 * PI * n / 256)
;EQUB HI(a)
EQUB 0
NEXT

.twister_sine_table
FOR n,0,255,1
;EQUB 128 * SIN(2 * PI * n / 256)
EQUB n-128
NEXT


PAGE_ALIGN
.twister_screen_data
INCBIN "data/twist.pu"

.twister_end
