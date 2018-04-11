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

	\\ Expand our MODE 5 128 line parallax_screen_data into appropriate CRTC format

	\\ Ensure main RAM paged in
	LDA &FE34
	AND #4
	STA &FE34

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

	\\ Page in SHADOW ram
	LDA &FE34
	ORA #4
	STA &FE34

	BNE screenloop

	.donescreenloop
	\\ Page main RAM back in
	LDA &FE34
	AND #4
	STA &FE34

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

;	FOR n,1,3,1
;	NOP
;	NEXT

	\\ Should be exactly on next scanline

	LDX #2					; 2c

	LDA parallax_delta
	STA parallax_accum

	.here

IF 0
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
ELSE
\\ Sit here and do nothing!!!
    FOR n,1,9,1
    NOP
    NEXT
ENDIF

	LDA #12: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA parallax_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++
	
	\\ 30c min + 10c loop, need 88c NOPs

	FOR n,1,27,1
	NOP
	NEXT
	
	\\ Set correct video page

	LDA &FE34					; 4c++
	AND #&FE					; 2c
	ORA parallax_vram_table_page, Y		; 4c
	STA &FE34					; 4c++

;	BIT 0			; 3c
	INX				; 2c
	BNE here		; 3c

IF 0 ; this resets CRTC to  8 scanline character rows for vsync
	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00
	LDA #7:	STA &FE01

	\\ R4=6 - CRTC cycle is 7 more rows
	LDA #4: STA &FE00
	LDA #6: STA &FE01

	\\ R7=2 - vsync is at row 34
	LDA #7:	STA &FE00
	LDA #2: STA &FE01

	\\ R6=0 - no more rows to display
	LDA #6: STA &FE00
	LDA #1: STA &FE01
ELSE ; this just keeps 1 scanline character rows and calculates vsync that way
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
ENDIF

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

	LDA &FE34					; 4c++
	AND #&FE					; 2c
	ORA parallax_vram_table_page, Y		; 4c
	STA &FE34					; 4c++

    RTS
}

\\ For rot value N ptr to framebuffer

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

PAGE_ALIGN
.parallax_delta_wave
FOR n,0,255,1
EQUB 32 + 31 * SIN(2 * PI * n / 256)
NEXT

PAGE_ALIGN
.parallax_screen_data
INCBIN "data/parallax.bin"

.parallax_end
