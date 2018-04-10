\ ******************************************************************
\ *	Twister
\ ******************************************************************

twister_delta = locals_start + 0
twister_delta_lookup = locals_start + 1
twister_temp = locals_start + 2
twister_angle = locals_start + 3
twister_accum = locals_start + 4

.twister_start

.twister_init
{
    STZ twister_delta
    STZ twister_delta_lookup

	\\ Expand our MODE 5 128 line twister_screen_data into appropriate CRTC format

	LDA #LO(twister_screen_data)
	STA readptr
	LDA #HI(twister_screen_data)
	STA readptr+1

	LDA #LO(&3000)
	STA writeptr
	LDA #HI(&3000)
	STA writeptr+1

	LDA #128
	STA twister_temp

	.screenloop

	\\ Copying characters remember!

	LDY #0
	.copyloop
	LDA (readptr), Y
	STA (writeptr), Y

	TYA
	CLC
	ADC #8
	TAY

	CPY #160
	BNE copyloop

	\\ Next read line
	LDA readptr
	AND #&7
	CMP #&7
	BEQ next_char_row

	INC readptr
	BCC no_carry
	INC readptr+1
	.no_carry
	JMP continue

	.next_char_row
	CLC
	LDA readptr
	ADC #LO(320-7)
	STA readptr
	LDA readptr+1
	ADC #HI(320-7)
	STA readptr+1

	.continue
	\\ Next write line
	CLC
	LDA writeptr
	ADC #160
	STA writeptr
	LDA writeptr+1
	ADC #0
	STA writeptr+1

	DEC twister_temp
	BNE screenloop

	.return
	RTS
}

.twister_update
{
	LDY twister_delta_lookup
	INY
	STY twister_delta_lookup
	LDA twister_delta_wave, Y
	STA twister_delta
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

	LDY twister_angle

	\\ R12,13 - frame buffer address
	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	FOR n,1,6,1
	NOP
	NEXT

	\\ Should be exactly on next scanline

	LDX #2					; 2c

	LDA twister_delta
	STA twister_accum

	.here

	\\ Add our twister_delta to the accumulator
	CLC						; 2c
	LDA twister_accum				; 3c
	ADC twister_delta				; 3c
	STA twister_accum				; 3c

	\\ Add the carry to our index
	TYA						; 2c
	ADC #0					; 2c
	AND #&7F				; 2c
	TAY						; 2c

	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++
	
	\\ 30c min + 10c loop, need 88c NOPs

	FOR n,1,34,1
	NOP
	NEXT
	
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

\\ This sets the twister_screen_data address for the top line next time around...

	LDY twister_angle
	INY
	TYA
	AND #&7F
	STA twister_angle
	TAY

IF 1
	LDA #12: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA twister_vram_table_LO, Y		; 4c
	STA &FE01					; 4c++
ELSE
	LDA #12: STA &FE00			; 2c + 4c++
	LDA #HI(&3000/8)
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA #LO(&3000/8)
	STA &FE01					; 4c++
ENDIF

    RTS
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

.twister_delta_wave
FOR n,0,255,1
EQUB 16 + 16 * SIN(2 * PI * n / 256)
NEXT

.twister_screen_data
INCBIN "data/twist.bin"

.twister_end
