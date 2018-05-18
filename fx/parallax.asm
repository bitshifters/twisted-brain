\ ******************************************************************
\ *	Parallax bars
\ ******************************************************************

parallax_crtc_row = locals_start + 0
parallax_x = locals_start + 1		; x position of top row
parallax_top_idx = locals_start + 2	; index into sine table for top row
parallax_wavey = locals_start + 3	; how much each row increments index into sine table
parallax_wavef = locals_start + 4	; how much each frame increments index for top row
parallax_incx = locals_start + 5	; how much x is incremented by each frame

.parallax_start

.parallax_init
{
	LDA #0
	STA parallax_x
	STA parallax_top_idx

	LDA #1
	STA parallax_incx

	LDA #0
	STA parallax_wavef

	LDA #0
	STA parallax_wavey

    SET_ULA_MODE ULA_Mode1

	LDX #LO(parallax_pal)
	LDY #HI(parallax_pal)
	JSR ula_set_palette

	\\ Expand our MODE 5 128 line parallax_screen_data into appropriate CRTC format

	\ Ensure MAIN RAM is writeable
    LDA &FE34:AND #&FB:STA &FE34

	LDX #LO(parallax_screen1)
	LDY #HI(parallax_screen1)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

	\ Ensure SHADOW RAM is writeable
    LDA &FE34:ORA #&4:STA &FE34

	LDX #LO(parallax_screen2)
	LDY #HI(parallax_screen2)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

	\ Ensure MAIN RAM is writeable
    LDA &FE34:AND #&FB:STA &FE34

	.return
	RTS
}

.parallax_update
{
	LDA parallax_x
	CLC
	ADC parallax_incx
	AND #&3F
	STA parallax_x

	CLC
	LDA parallax_top_idx
	ADC parallax_wavef
	STA parallax_top_idx	

	LDX parallax_top_idx
	LDA parallax_sine_table, X
	CLC
	ADC parallax_x
	AND #&3F
	TAY

	LDA #12: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	\\ Set correct video page - OK as long as in VBlank

	LDA &FE34					; 4c++
	AND #&FE					; 2c
	ORA parallax_vram_table_page, Y		; 4c
	STA &FE34					; 4c++

    RTS
}

.parallax_draw
{
	\\ R9=0 - character row = 4 scanlines
	LDA #9: STA &FE00
	LDA #3:	STA &FE01

	\\ R4=0 - CRTC cycle is one row
	LDA #4: STA &FE00
	LDA #0: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #&FF: STA &FE01

	\\ R6=1 - one row displayed
	LDA #6: STA &FE00
	LDA #1: STA &FE01

	FOR n,1,55,1
	NOP
	NEXT

	\\ Should be exactly on next scanline
	JSR cycles_wait_128
	JSR cycles_wait_128

	LDA parallax_top_idx			; 3c
	CLC							; 2c
	ADC parallax_wavey			; 3c
	TAX 						; 2c
	LDA parallax_sine_table, X	; 4c
	CLC							; 2c
	ADC parallax_x				; 3c
	AND #&3F					; 2c
	TAY							; 2c

	\\ R12,13 - frame buffer address
	LDA #12: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	\\ Set correct video page

	LDA &FE34					; 4c++
	AND #&FE					; 2c
	ORA parallax_vram_table_page, Y		; 4c
	STA &FE34					; 4c++

	LDA #62
	STA parallax_crtc_row

	.here

	TXA							; 2c
	CLC							; 2c
	ADC parallax_wavey			; 3c
	TAX 						; 2c
	LDA parallax_sine_table, X	; 4c
	CLC							; 2c
	ADC parallax_x				; 3c
	AND #&3F					; 2c
	TAY							; 2c

	FOR n,1,24,1
	NOP
	NEXT

	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128

	LDA #12: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++
	
	\\ 30c min + 10c loop, need 88c NOPs

	\\ Set correct video page

	LDA &FE34					; 4c++
	AND #&FE					; 2c
	ORA parallax_vram_table_page, Y		; 4c
	STA &FE34					; 4c++

	DEC parallax_crtc_row		; 5c
	BNE here		; 3c

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

    RTS
}

\ ******************************************************************
\ Kill FX
\
\ The kill function is used to tidy up any craziness that your FX
\ might have created and return the system back to the expected
\ default state, ready to initialise the next FX.
\
\ This function will be exactly at the start* of scanline 0 with a
\ maximum jitter of up to +10 cycles.
\
\ This means that a new CRTC cycle has just started! If you didn't
\ specify the registers from the previous frame then they will be
\ the default MODE 2 values as per initialisation.
\
\ THIS FUNCTION MUST ALWAYS ENSURE A FULL AND VALID 312 line PAL
\ signal will take place this frame! The easiest way to do this is
\ to simply call crtc_reset.
\
\ ******************************************************************

.parallax_kill
{
	JSR crtc_reset
    SET_ULA_MODE ULA_Mode2
    JSR ula_pal_reset

	\\ Ensure we're displaying main memory

	LDA &FE34:AND #&FE:STA &FE34
	RTS
}

\ ******************************************************************
\ PARAMS for SEQUENCE
\ ******************************************************************

.parallax_set_inc_x
{
	STA parallax_incx
	RTS
}

.parallax_set_wave_y
{
	STA parallax_wavey
	RTS
}

.parallax_set_wave_f
{
	STA parallax_wavef
	RTS
}

\\ For rot value N ptr to framebuffer

PAGE_ALIGN
.parallax_vram_table_LO
FOR n,0,63,1
EQUB LO((&3000 + (n AND &1F) *640)/8)
NEXT

.parallax_vram_table_HI
FOR n,0,63,1
EQUB HI((&3000 + (n AND &1F) *640)/8)
NEXT

.parallax_vram_table_page
FOR n,0,63,1
EQUB (n AND &20) >> 5
NEXT

.parallax_pal
{
	EQUB &00 + PAL_black
	EQUB &10 + PAL_black
	EQUB &20 + PAL_red
	EQUB &30 + PAL_red
	EQUB &40 + PAL_black
	EQUB &50 + PAL_black
	EQUB &60 + PAL_red
	EQUB &70 + PAL_red
	EQUB &80 + PAL_yellow
	EQUB &90 + PAL_yellow
	EQUB &A0 + PAL_white
	EQUB &B0 + PAL_white
	EQUB &C0 + PAL_yellow
	EQUB &D0 + PAL_yellow
	EQUB &E0 + PAL_white
	EQUB &F0 + PAL_white
}

PAGE_ALIGN
.parallax_sine_table
FOR n,0,255,1
EQUB 32 + 31 * SIN(2 * PI * n / 256)
NEXT

PAGE_ALIGN
.parallax_screen1
INCBIN "data/parallax1.pu"

PAGE_ALIGN
.parallax_screen2
INCBIN "data/parallax2.pu"

.parallax_end
