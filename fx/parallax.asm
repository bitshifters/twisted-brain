\ ******************************************************************
\ *	Parallax bars
\ ******************************************************************

parallax_temp = locals_start + 0
parallax_delta = locals_start + 1
parallax_accum = locals_start + 2
parallax_angle = locals_start + 3
parallax_delta_lookup = locals_start + 4

parallax_readrowptr = locals_start + 5
parallax_writerowptr = locals_start + 7

.parallax_start

.parallax_init
{
	LDA #0
	STA parallax_accum
	STA parallax_delta
	STA parallax_angle
    STA parallax_delta_lookup

    SET_ULA_MODE ULA_Mode1

	LDX #LO(parallax_pal)
	LDY #HI(parallax_pal)
	JSR ula_set_palette

	\\ Expand our MODE 5 128 line parallax_screen_data into appropriate CRTC format

	\ Ensure MAIN RAM is writeable
    LDA &FE34:AND #&FB:STA &FE34

IF 1
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
ELSE
	LDA #LO(parallax_screen_data)
	STA parallax_readrowptr
	LDA #HI(parallax_screen_data)
	STA parallax_readrowptr+1

	LDA #LO(&3000)
	STA writeaddr+1
	LDA #HI(&3000)
	STA writeaddr+2

	LDA #64
	STA parallax_temp

	.screenloop

	\\ Copying characters remember!

	LDY #0
	.rowloop

	LDA parallax_readrowptr
	STA readptr
	LDA parallax_readrowptr+1
	STA readptr+1

	LDX #0
	.copyloop
	LDA (readptr), Y

	.writeaddr
	STA &FFFF

	CLC
	LDA readptr
	ADC #8
	STA readptr
	LDA readptr+1
	ADC #0
	STA readptr+1

	CLC
	LDA writeaddr+1
	ADC #8
	STA writeaddr+1
	LDA writeaddr+2
	ADC #0
	STA writeaddr+2

	INX
	CPX #80
	BNE copyloop

	DEC parallax_temp
	BEQ donescreenloop

	\\ Next read line
	INY
	CPY #8
	BNE rowloop

	.next_char_row
	CLC
	LDA parallax_readrowptr
	ADC #LO(640)
	STA parallax_readrowptr
	LDA parallax_readrowptr+1
	ADC #HI(640)
	STA parallax_readrowptr+1

	\\ Next write line
	LDA writeaddr+2
	CMP #&80
	BCC screenloop

	LDA #LO(&3000)
	STA writeaddr+1
	LDA #HI(&3000)
	STA writeaddr+2

	\ Ensure SHADOW RAM is writeable
    LDA &FE34:ORA #&4:STA &FE34

	BNE screenloop

	.donescreenloop
ENDIF

	\ Ensure MAIN RAM is writeable
    LDA &FE34:AND #&FB:STA &FE34

	.return
	RTS
}

.parallax_update
{
	LDY parallax_delta_lookup
	INY
	STY parallax_delta_lookup
	LDA parallax_delta_wave, Y
	STA parallax_delta
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

;	FOR n,1,1,1
;	NOP
;	NEXT
	BIT 0

	\\ Should be exactly on next scanline
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128

	LDY parallax_angle

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

	LDX #256-62					; 2c

	LDA parallax_delta
	STA parallax_accum

	.here

IF 1
	\\ Add our parallax_delta to the parallax_accumulator
	CLC						; 2c
	LDA parallax_accum				; 3c
	ADC parallax_delta				; 3c
	STA parallax_accum				; 3c

	\\ Add the carry to our index
	TYA						; 2c
	ADC #0					; 2c
	AND #&3F				; 2c
	TAY						; 2c

	FOR n,1,27,1
	NOP
	NEXT

ELSE
\\ Sit here and do nothing!!!
    FOR n,1,37,1
    NOP
    NEXT
ENDIF

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

;	BIT 0			; 3c
	INX				; 2c
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

	\\ Could/should do this in Update

	LDY parallax_angle
	INY
	TYA
	AND #&3F
	STA parallax_angle
	TAY

	LDA #12: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	\\ Set correct video page - MAY NEED A DELAY HERE?
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128

	LDA &FE34					; 4c++
	AND #&FE					; 2c
	ORA parallax_vram_table_page, Y		; 4c
	STA &FE34					; 4c++

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
.parallax_delta_wave
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
