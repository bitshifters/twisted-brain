\ ******************************************************************
\ *	Font glyph plot
\ ******************************************************************

FONT_MAX_GLYPHS = 60	;90
FONT_GLYPH_WIDTH_BYTES = 2
FONT_GLYPH_HEIGHT = 15	;25
FONT_GLYPH_SIZE = FONT_GLYPH_WIDTH_BYTES * FONT_GLYPH_HEIGHT

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

MODE1_COL0=&00
MODE1_COL1=&20
MODE1_COL2=&80
MODE1_COL3=&A0

.font_start

.font_init
{
	LDA #LO(font_map_1bpp_to_2bpp_line_A)
	STA font_stiple
	LDA #HI(font_map_1bpp_to_2bpp_line_A)
	STA font_stiple+1
	RTS
}

.font_clear_screen_stiple
{
	LDX #FONT_LINE_A_BG
	LDY #FONT_LINE_B_BG

  STX temp
  TYA
  EOR temp
  STA smToggle+1

	JSR music_poll_if_vsync

  ldx #HI(SCREEN_SIZE_BYTES)
  lda #HI(screen_base_addr)
  sta loop+2

  lda temp
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

; A=glyph# writeptr already set up for screen
.font_plot_glyph
{
	TAX
	LDA font_glyph_addr_LO, X
	STA readptr
	LDA font_glyph_addr_HI, X
	STA readptr+1

	LDA writeptr
	STA font_storeptr

	AND #&1
	ASL A:ASL A:ASL A: ASL A
	EOR #LO(font_map_1bpp_to_2bpp_line_A)
	STA font_stiple

	LDA writeptr+1
	STA font_storeptr+1

	LDA #FONT_GLYPH_HEIGHT
	STA font_yco

	.rowloop

	\\ Plot a row

	FOR n,0,FONT_GLYPH_WIDTH_BYTES-1,1

	LDY #(n):LDA (readptr), Y
	TAX:LSR A:LSR A:LSR A:LSR A:TAY
	LDA (font_stiple), Y
	LDY #(n*16):STA (writeptr), Y
	TXA:AND #&F:TAY
	LDA (font_stiple), Y
	LDY #(n*16)+8:STA (writeptr), Y

	NEXT

	DEC font_yco
	BEQ done_rowloop

	CLC
	LDA readptr
	ADC #FONT_GLYPH_WIDTH_BYTES
	STA readptr
	BCC no_carry
	INC readptr+1
	.no_carry

	LDA font_stiple
	EOR #&10
	STA font_stiple

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
	LDA font_storeptr
	ADC #16*FONT_GLYPH_WIDTH_BYTES
	STA writeptr
	LDA font_storeptr+1
	ADC #0
	STA writeptr+1

	RTS
}

IF 0    \\ UNUSED
.font_plot_string
{
	STX loop+1
	STY loop+2

	LDX #0

	.loop
	LDA &FFFF, X
	BMI done

;	SEC
;	SBC #' '
	CMP #FONT_MAX_GLYPHS
	BCS skip

	PHX
	JSR font_plot_glyph
	PLX

	.skip
	INX
	BNE loop

	.done
	RTS
}
ENDIF

.font_glyph_addr_LO
{
	FOR n,0,FONT_MAX_GLYPHS-1,1
	EQUB LO(font_font_data + n * FONT_GLYPH_SIZE)
	NEXT
}

.font_glyph_addr_HI
{
	FOR n,0,FONT_MAX_GLYPHS-1,1
	EQUB HI(font_font_data + n * FONT_GLYPH_SIZE)
	NEXT
}

FONT_LINE_A_FG = (MODE1_P0_C1 OR MODE1_P1_C3 OR MODE1_P2_C1 OR MODE1_P3_C3)
FONT_LINE_A_BG = (MODE1_P0_C2 OR MODE1_P1_C0 OR MODE1_P2_C2 OR MODE1_P3_C0)
FONT_LINE_B_FG = (MODE1_P0_C3 OR MODE1_P1_C1 OR MODE1_P2_C3 OR MODE1_P3_C1)
FONT_LINE_B_BG = (MODE1_P0_C0 OR MODE1_P1_C2 OR MODE1_P2_C0 OR MODE1_P3_C2)

ALIGN 32
.font_map_1bpp_to_2bpp_line_A
{
	FOR b,0,15,1
	c0=(b AND 8) DIV 8
	c1=(b AND 4) DIV 4
	c2=(b AND 2) DIV 2
	c3=(b AND 1) DIV 1
	m=(c0*MODE1_P0_MASK) OR (c1*MODE1_P1_MASK) OR (c2*MODE1_P2_MASK) OR (c3*MODE1_P3_MASK)
	n=m EOR &FF
	
	EQUB (m AND FONT_LINE_A_FG) OR (n AND FONT_LINE_A_BG)
	NEXT
}
.font_map_1bpp_to_2bpp_line_B
{
	FOR b,0,15,1
	c0=(b AND 8) DIV 8
	c1=(b AND 4) DIV 4
	c2=(b AND 2) DIV 2
	c3=(b AND 1) DIV 1
	m=(c0*MODE1_P0_MASK) OR (c1*MODE1_P1_MASK) OR (c2*MODE1_P2_MASK) OR (c3*MODE1_P3_MASK)
	n=m EOR &FF
	
	EQUB (m AND FONT_LINE_B_FG) OR (n AND FONT_LINE_B_BG)
	NEXT
}

.font_end
