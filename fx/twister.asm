\ ******************************************************************
\ *	Twister
\ ******************************************************************

delta=locals_start+0
delta_lookup=locals_start+1
tmp=locals_start+2
top_angle=locals_start+3
accum=locals_start+4

.twister_start

.twister_init
{
    STZ delta
    STZ delta_lookup

	\\ Expand our MODE 5 128 line screen into appropriate CRTC format

	LDA #LO(screen)
	STA readptr
	LDA #HI(screen)
	STA readptr+1

	LDA #LO(&3000)
	STA writeptr
	LDA #HI(&3000)
	STA writeptr+1

	LDA #128
	STA tmp

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

	DEC tmp
	BNE screenloop

	.return
	RTS
}

.twister_update
{
	LDY delta_lookup
	INY
	STY delta_lookup
	LDA delta_wave, Y
	STA delta
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

	LDY top_angle

	\\ R12,13 - frame buffer address
	LDA #12: STA &FE00			; 2c + 4c++
	LDA vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

	FOR n,1,3,1
	NOP
	NEXT

	\\ Should be exactly on next scanline

	LDX #1					; 2c

	LDA delta
	STA accum

	.here

	\\ Add our delta to the accumulator
	CLC						; 2c
	LDA accum				; 3c
	ADC delta				; 3c
	STA accum				; 3c

	\\ Add the carry to our index
	TYA						; 2c
	ADC #0					; 2c
	AND #&7F				; 2c
	TAY						; 2c

	LDA #12: STA &FE00			; 2c + 4c++
	LDA vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA vram_table_LO, Y		; 4c
	STA &FE01					; 4c++
	
	\\ 30c min + 10c loop, need 88c NOPs

	FOR n,1,34,1
	NOP
	NEXT
	
;	BIT 0			; 3c
	INX				; 2c
	BNE here		; 3c

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

	LDY top_angle
	INY
	TYA
	AND #&7F
	STA top_angle
	TAY

	LDA #12: STA &FE00			; 2c + 4c++
	LDA vram_table_HI, Y		; 4c
	STA &FE01					; 4c++

	LDA #13: STA &FE00			; 2c + 4c++
	LDA vram_table_LO, Y		; 4c
	STA &FE01					; 4c++

    RTS
}

PAGE_ALIGN

\\ For rot value N ptr to framebuffer

.vram_table_LO
FOR n,0,127,1
EQUB LO((&3000 + n*160)/8)
NEXT

.vram_table_HI
FOR n,0,127,1
EQUB HI((&3000 + n*160)/8)
NEXT

.delta_wave
FOR n,0,255,1
EQUB 16 + 16 * SIN(2 * PI * n / 256)
NEXT

.screen
INCBIN "data/twist.bin"

.twister_end
