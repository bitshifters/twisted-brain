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

MODE1_COL0=&00
MODE1_COL1=&20
MODE1_COL2=&80
MODE1_COL3=&A0

TEXT_MAX_GLYPHS = 60	;90
TEXT_GLYPH_WIDTH_BYTES = 2
TEXT_GLYPH_HEIGHT = 15	;25
TEXT_GLYPH_SIZE = TEXT_GLYPH_WIDTH_BYTES * TEXT_GLYPH_HEIGHT

text_temp = locals_start + 0
text_yco = locals_start + 1
text_storeptr = locals_start + 2
text_pattern = locals_start + 4
text_scroll = locals_start + 6

text_block_ptr = locals_start + 7
text_block_index = locals_start + 9
text_pattern_ptr = locals_start + 10

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
	
	STZ text_scroll
	STZ text_block_index

	\\ Starts with no text block
	STZ text_block_ptr+1

	\\ But default pattern
	LDA #textPattern_Horizontal
	JSR text_set_pattern

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

.text_update
{
	INC text_scroll

	\\ Do we have a text block to display?

	LDA text_block_ptr+1
	BEQ return

	\\ Get writeptr
	LDY text_block_index
	LDA (text_pattern_ptr), Y
	TAX
	LDA text_block_addr_LO, X
	STA writeptr
	LDA text_block_addr_HI, X
	STA writeptr+1

	\\ Get glyph
	TXA:TAY
	LDA (text_block_ptr), Y
	JSR text_plot_glyph

	LDA text_block_index
	INC A
	STA text_block_index
	CMP #TEXT_BLOCK_SIZE
	BCC not_finished

	\\ Finished
	STZ text_block_ptr+1
	RTS

	.not_finished

	.return
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

.text_kill
{
	SET_ULA_MODE ULA_Mode2
	JSR crtc_reset
	JMP ula_pal_reset
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
	BMI done

;	SEC
;	SBC #' '
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

.text_set_pattern
{
	PHX
	ASL A:TAX
	LDA text_pattern_table, X
	STA text_pattern_ptr
	LDA text_pattern_table+1, X
	STA text_pattern_ptr+1
	PLX
	RTS
}

.text_set_block
{
	PHX
	ASL A:TAX
	LDA text_block_table, X
	STA text_block_ptr
	LDA text_block_table+1, X
	STA text_block_ptr+1
	STZ text_block_index
	PLX
	RTS
}

.text_pal
{
	EQUB &00 + PAL_black
	EQUB &10 + PAL_black
	EQUB &20 + PAL_black;PAL_red
	EQUB &30 + PAL_black;PAL_red
	EQUB &40 + PAL_black
	EQUB &50 + PAL_black
	EQUB &60 + PAL_black;PAL_red
	EQUB &70 + PAL_black;PAL_red
	EQUB &80 + PAL_black
	EQUB &90 + PAL_black
	EQUB &A0 + PAL_black;PAL_white
	EQUB &B0 + PAL_black;PAL_white
	EQUB &C0 + PAL_black
	EQUB &D0 + PAL_black
	EQUB &E0 + PAL_black;PAL_white
	EQUB &F0 + PAL_black;PAL_white
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
IF 0
	FOR n,0,255,1
	IF ((n DIV 32) AND 1) = 1
	EQUB MODE1_COL1 + PAL_magenta
	ELSE
	EQUB MODE1_COL1 + PAL_green
	ENDIF
	NEXT
ELSE
	FOR n,1,43,1
	EQUB MODE1_COL1 + PAL_red
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL1 + PAL_magenta
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL1 + PAL_blue
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL1 + PAL_cyan
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL1 + PAL_green
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL1 + PAL_yellow
	NEXT
ENDIF

.text_fg_table
IF 0
	FOR n,0,255,1
	IF ((n DIV 32) AND 1) = 1
	EQUB MODE1_COL3 + PAL_white;PAL_yellow
	ELSE
	EQUB MODE1_COL3 + PAL_white
	ENDIF
	NEXT
ELSE
	FOR n,1,21,1
	EQUB MODE1_COL3 + PAL_red
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL3 + PAL_magenta
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL3 + PAL_blue
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL3 + PAL_cyan
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL3 + PAL_green
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL3 + PAL_yellow
	NEXT
	FOR n,1,22,1
	EQUB MODE1_COL3 + PAL_red
	NEXT
ENDIF

.text_font_data
INCBIN "data\font_razor.bin"

.text_block_addr_LO
FOR y,0,TEXT_BLOCK_HEIGHT-1,1
FOR x,0,TEXT_BLOCK_WIDTH-1,1
	EQUB LO(screen_base_addr + (y+1) * 2 * 640 + (x+1) * 4 * 8)
NEXT
NEXT

.text_block_addr_HI
FOR y,0,TEXT_BLOCK_HEIGHT-1,1
FOR x,0,TEXT_BLOCK_WIDTH-1,1
	EQUB HI(screen_base_addr + (y+1) * 2 * 640 + (x+1) * 4 * 8)
NEXT
NEXT

.text_pattern_table
{
	EQUW text_pattern_0		; textPattern_Horizontal
	EQUW text_pattern_1		; textPattern_Vertical
	EQUW text_pattern_2		; textPattern_Spiral
	EQUW text_pattern_3		; textPattern_Snake
}

MACRO TEXT_PATTERN_ADDR x, y
;EQUW screen_base_addr + (y+1) * 2 * 640 + (x+1) * 4 * 8
EQUB y*TEXT_BLOCK_WIDTH + x
ENDMACRO

.text_pattern_0	; top-to-bottom, left-to-right
FOR x,0,TEXT_BLOCK_WIDTH-1,1
	TEXT_PATTERN_ADDR x, 0
NEXT
FOR y,1,TEXT_BLOCK_HEIGHT-2,1
	TEXT_PATTERN_ADDR 0, y
	TEXT_PATTERN_ADDR TEXT_BLOCK_WIDTH-1, y
NEXT
FOR x,TEXT_BLOCK_WIDTH-1,0,-1
	TEXT_PATTERN_ADDR x, TEXT_BLOCK_HEIGHT-1
NEXT
FOR y,1,TEXT_BLOCK_HEIGHT-2,1
FOR x,1,TEXT_BLOCK_WIDTH-2,1
	TEXT_PATTERN_ADDR x, y
NEXT
NEXT

.text_pattern_1	; left-to-right, top-to-bottom
FOR x,0,TEXT_BLOCK_WIDTH-1,2
FOR y,0,TEXT_BLOCK_HEIGHT-1,1
	TEXT_PATTERN_ADDR x, y
NEXT
FOR y,TEXT_BLOCK_HEIGHT-1,0,-1
	TEXT_PATTERN_ADDR x+1, y
NEXT
NEXT

MACRO TEXT_PATTERN_SPIRAL l, t, w, h
	FOR x,l,l+w-1
		TEXT_PATTERN_ADDR x, t
	NEXT
	FOR y,t+1,t+h-1
		TEXT_PATTERN_ADDR l+w-1, y
	NEXT
	FOR x,l+w-2,l,-1
		TEXT_PATTERN_ADDR x, t+h-1
	NEXT
	FOR y,t+h-2,t+1,-1
		TEXT_PATTERN_ADDR l, y
	NEXT
ENDMACRO

.text_pattern_2	; spiral
TEXT_PATTERN_SPIRAL 0,0,18,14
TEXT_PATTERN_SPIRAL 1,1,16,12
TEXT_PATTERN_SPIRAL 2,2,14,10
TEXT_PATTERN_SPIRAL 3,3,12,8
TEXT_PATTERN_SPIRAL 4,4,10,6
TEXT_PATTERN_SPIRAL 5,5,8,4
TEXT_PATTERN_SPIRAL 6,6,6,2

.text_pattern_3	; top-to-bottom, left-to-right
FOR y,0,TEXT_BLOCK_HEIGHT-1,2
FOR x,0,TEXT_BLOCK_WIDTH-1,1
	TEXT_PATTERN_ADDR x, y
NEXT
FOR x,TEXT_BLOCK_WIDTH-1,0,-1
	TEXT_PATTERN_ADDR x, y+1
NEXT
NEXT

.text_end
