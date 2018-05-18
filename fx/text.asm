\ ******************************************************************
\ *	Write some text
\ ******************************************************************

MODE1_P0_MASK=&88
MODE1_P1_MASK=&44
MODE1_P2_MASK=&22
MODE1_P3_MASK=&11

MODE1_C0=&00
MODE1_C1=&01
MODE1_C2=&10
MODE1_C3=&11

MODE1_P0_C0=&00
MODE1_P1_C0=&00
MODE1_P2_C0=&00
MODE1_P3_C0=&00
MODE1_P0_C1=MODE1_C1 << 3
MODE1_P1_C1=MODE1_C1 << 2
MODE1_P2_C1=MODE1_C1 << 1
MODE1_P3_C1=MODE1_C1 << 0
MODE1_P0_C2=MODE1_C2 << 3
MODE1_P1_C2=MODE1_C2 << 2
MODE1_P2_C2=MODE1_C2 << 1
MODE1_P3_C2=MODE1_C2 << 0
MODE1_P0_C3=MODE1_C3 << 3
MODE1_P1_C3=MODE1_C3 << 2
MODE1_P2_C3=MODE1_C3 << 1
MODE1_P3_C3=MODE1_C3 << 0

TEXT_MAX_GLYPHS = 60	;90
TEXT_GLYPH_WIDTH_BYTES = 4
TEXT_GLYPH_HEIGHT = 32	;25
TEXT_GLYPH_SIZE = TEXT_GLYPH_WIDTH_BYTES * TEXT_GLYPH_HEIGHT

text_temp = locals_start + 0
text_yco = locals_start + 1
text_storeptr = locals_start + 2
text_pattern = locals_start + 4
text_scroll = locals_start + 6

.text_start

.text_init
{
\\ Sadly we don't know what state our screen buffer will be in

;	JSR text_clear_palette

	LDX #TEXT_LINE_A_BG
	LDY #TEXT_LINE_B_BG
	JSR text_clear_screen_pattern

    SET_ULA_MODE ULA_Mode1
	LDX #LO(text_pal)
	LDY #HI(text_pal)
	JSR ula_set_palette

	LDA #LO(text_map_1bpp_to_2bpp_line_A)
	STA text_pattern
	LDA #HI(text_map_1bpp_to_2bpp_line_A)
	STA text_pattern+1
	
	LDA #LO(&4E00+20*8)
	STA writeptr
	LDA #HI(&4E00+20*8)
	STA writeptr+1
	LDX #LO(text_string_1)
	LDY #HI(text_string_1)
	JSR text_plot_string

	LDA #LO(&5800+20*8)
	STA writeptr
	LDA #HI(&5800+20*8)
	STA writeptr+1
	LDX #LO(text_string_2)
	LDY #HI(text_string_2)
	JSR text_plot_string

	STZ text_scroll

	RTS
}

.text_clear_screen_pattern
{
  STX text_temp
  TYA
  EOR text_temp
  STA smToggle+1

  ldx #HI(SCREEN_SIZE_BYTES)
  lda #HI(screen_base_addr)
  sta loop+2

  lda text_temp
  ldy #0
  .loop
  sta &3000,Y

  .smToggle
  EOR #&00

  iny
  bne loop
  inc loop+2

	JSR music_poll_if_vsync

  dex
  bne loop
  rts
}

.text_string_1
EQUS "HELLO",0
.text_string_2
EQUS "WORLD",0

.text_update
{
	INC text_scroll
	RTS
}

.text_draw
{
	\\ Should be exactly on scanline 0

	LDX #0					; 2c
	LDY text_scroll			; 3c

		; shift timing so palette change happens during hblank as much as possible

	FOR n,1,38,1
	NOP
	NEXT

	LDA text_fg_table, Y	; 4c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c
	EOR #&40		; 2c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c

	LDA text_bg_table, Y	; 4c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c
	EOR #&40		; 2c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c

	INY				; 2c
	INX				; 2c

	.here

	FOR n,1,34,1
	NOP
	NEXT

	LDA text_fg_table, Y	; 4c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c
	EOR #&40		; 2c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c

	LDA text_bg_table, Y	; 4c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c
	EOR #&40		; 2c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c

;	BIT 0			; 3c
	INY
	INX				; 2c
	BNE here		; 3c

    RTS
}

.text_clear_palette
{
	LDA #&00 + PAL_magenta
	FOR n,0,255,1
	STA text_bg_table+n
	NEXT
	RTS
}

.text_plot_string
{
	STX loop+1
	STY loop+2

	LDX #0

	.loop
	LDA &FFFF, X
	BEQ done

	SEC
	SBC #' '
	CMP #TEXT_MAX_GLYPHS
	BCS skip

	PHX
	JSR text_plot_glyph
	PLX

	.skip
	INX
	BNE loop

	.done
	RTS
}

; A=glyph# writeptr already set up for screen
.text_plot_glyph
{
	TAX
	LDA text_glyph_addr_LO, X
	STA readptr
	LDA text_glyph_addr_HI, X
	STA readptr+1

	LDA writeptr
	STA text_storeptr

	AND #&1
	ASL A:ASL A:ASL A: ASL A
	EOR #LO(text_map_1bpp_to_2bpp_line_A)
	STA text_pattern

	LDA writeptr+1
	STA text_storeptr+1

	LDA #TEXT_GLYPH_HEIGHT
	STA text_yco

	.rowloop

	\\ Plot a row

	FOR n,0,TEXT_GLYPH_WIDTH_BYTES-1,1

	LDY #(n):LDA (readptr), Y
	TAX:LSR A:LSR A:LSR A:LSR A:TAY
	LDA (text_pattern), Y
	LDY #(n*16):STA (writeptr), Y
	TXA:AND #&F:TAY
	LDA (text_pattern), Y
	LDY #(n*16)+8:STA (writeptr), Y

	NEXT

	DEC text_yco
	BEQ done_rowloop

	CLC
	LDA readptr
	ADC #TEXT_GLYPH_WIDTH_BYTES
	STA readptr
	BCC no_carry
	INC readptr+1
	.no_carry

	LDA text_pattern
	EOR #&10
	STA text_pattern

	LDA writeptr
	AND #&7
	CMP #&7
	BEQ next_charrow

	INC writeptr
	JMP rowloop

	.next_charrow
	CLC
	LDA writeptr
	ADC #LO(640-7)
	STA writeptr
	LDA writeptr+1
	ADC #HI(640-7)
	STA writeptr+1
	JMP rowloop

	.done_rowloop
	CLC
	LDA text_storeptr
	ADC #16*TEXT_GLYPH_WIDTH_BYTES
	STA writeptr
	LDA text_storeptr+1
	ADC #0
	STA writeptr+1

	RTS
}

.text_pal
{
	EQUB &00 + PAL_black
	EQUB &10 + PAL_black
	EQUB &20 + PAL_red
	EQUB &30 + PAL_red
	EQUB &40 + PAL_black
	EQUB &50 + PAL_black
	EQUB &60 + PAL_red
	EQUB &70 + PAL_red
	EQUB &80 + PAL_blue
	EQUB &90 + PAL_blue
	EQUB &A0 + PAL_white
	EQUB &B0 + PAL_white
	EQUB &C0 + PAL_blue
	EQUB &D0 + PAL_blue
	EQUB &E0 + PAL_white
	EQUB &F0 + PAL_white
}

TEXT_LINE_A_FG = (MODE1_P0_C1 OR MODE1_P1_C3 OR MODE1_P2_C1 OR MODE1_P3_C3)
TEXT_LINE_A_BG = (MODE1_P0_C2 OR MODE1_P1_C0 OR MODE1_P2_C2 OR MODE1_P3_C0)
TEXT_LINE_B_FG = (MODE1_P0_C3 OR MODE1_P1_C1 OR MODE1_P2_C3 OR MODE1_P3_C1)
TEXT_LINE_B_BG = (MODE1_P0_C0 OR MODE1_P1_C2 OR MODE1_P2_C0 OR MODE1_P3_C2)

ALIGN 32
.text_map_1bpp_to_2bpp_line_A
{
	FOR b,0,15,1
	c0=(b AND 8) DIV 8
	c1=(b AND 4) DIV 4
	c2=(b AND 2) DIV 2
	c3=(b AND 1) DIV 1
	m=(c0*MODE1_P0_MASK) OR (c1*MODE1_P1_MASK) OR (c2*MODE1_P2_MASK) OR (c3*MODE1_P3_MASK)
	n=m EOR &FF
	
	EQUB (m AND TEXT_LINE_A_FG) OR (n AND TEXT_LINE_A_BG)
	NEXT
}
.text_map_1bpp_to_2bpp_line_B
{
	FOR b,0,15,1
	c0=(b AND 8) DIV 8
	c1=(b AND 4) DIV 4
	c2=(b AND 2) DIV 2
	c3=(b AND 1) DIV 1
	m=(c0*MODE1_P0_MASK) OR (c1*MODE1_P1_MASK) OR (c2*MODE1_P2_MASK) OR (c3*MODE1_P3_MASK)
	n=m EOR &FF
	
	EQUB (m AND TEXT_LINE_B_FG) OR (n AND TEXT_LINE_B_BG)
	NEXT
}

.text_glyph_addr_LO
{
	FOR n,0,TEXT_MAX_GLYPHS-1,1
	EQUB LO(text_font_data + n * TEXT_GLYPH_SIZE)
	NEXT
}

.text_glyph_addr_HI
{
	FOR n,0,TEXT_MAX_GLYPHS-1,1
	EQUB HI(text_font_data + n * TEXT_GLYPH_SIZE)
	NEXT
}

PAGE_ALIGN
.text_bg_table
FOR n,0,255,1
IF ((n DIV 32) AND 1) = 1
EQUB &00 + PAL_magenta
ELSE
EQUB &00 + PAL_black
ENDIF
NEXT

.text_fg_table
FOR n,0,255,1
IF ((n DIV 32) AND 1) = 1
EQUB &A0 + PAL_yellow
ELSE
EQUB &A0 + PAL_white
ENDIF
NEXT

.text_font_data
INCBIN "data\font_replic.bin"

.text_end
