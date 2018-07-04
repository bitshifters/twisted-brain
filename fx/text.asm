\ ******************************************************************
\ *	Write some text
\ ******************************************************************

text_temp = locals_start + 0
text_scroll = locals_start + 6

text_block_ptr = locals_start + 7
text_block_index = locals_start + 9
text_pattern_ptr = locals_start + 10

.text_start

.text_init
{
	JSR font_clear_screen_stiple

    SET_ULA_MODE ULA_Mode1
	LDX #LO(text_pal)
	LDY #HI(text_pal)
	JSR ula_set_palette

	STZ text_scroll
	STZ text_block_index

	\\ Starts with no text block
	STZ text_block_ptr+1

	\\ But default pattern
	LDA #textPattern_Horizontal
	JSR text_set_pattern

	RTS
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
	JSR font_plot_glyph

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
\{
	\\ Should be exactly on scanline 0

	LDX #0					; 2c
	LDY text_scroll			; 3c

		; shift timing so palette change happens during hblank as much as possible

	FOR n,1,38,1
	NOP
	NEXT

.text_draw_fg_table_sm1
	LDA text_fg_table_pastel, Y	; 4c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c
	EOR #&40		; 2c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c

.text_draw_bg_table_sm1
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

	.text_draw_here

	FOR n,1,33,1
	NOP
	NEXT
	BIT 0			; 3c

.text_draw_fg_table_sm2
	LDA text_fg_table_pastel, Y	; 4c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c
	EOR #&40		; 2c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c

.text_draw_bg_table_sm2
	LDA text_bg_table, Y	; 4c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c
	EOR #&40		; 2c
	STA &FE21				; 4c
	EOR #&10		; 2c
	STA &FE21				; 4c

	INY
	INX				; 2c
	BNE text_draw_here		; 3c

    RTS
\}

.text_kill
{
	SET_ULA_MODE ULA_Mode2
	JSR crtc_reset
	JMP ula_pal_reset
}

IF 0
.text_clear_palette
{
	LDA #&00 + PAL_magenta
	FOR n,0,255,1
	STA text_bg_table+n
	NEXT
	RTS
}
ENDIF

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

.text_set_palette
{
	CMP #0
	BEQ pastel
	\\ Copper
	LDA #LO(text_fg_table_copper)
	STA text_draw_fg_table_sm1+1
	STA text_draw_fg_table_sm2+1
	LDA #HI(text_fg_table_copper)
	STA text_draw_fg_table_sm1+2
	STA text_draw_fg_table_sm2+2
	RTS

	.pastel
	LDA #LO(text_fg_table_pastel)
	STA text_draw_fg_table_sm1+1
	STA text_draw_fg_table_sm2+1
	LDA #HI(text_fg_table_pastel)
	STA text_draw_fg_table_sm1+2
	STA text_draw_fg_table_sm2+2
	RTS
}

.text_pal
{
	EQUB &00 + PAL_black
	EQUB &10 + PAL_black
	EQUB &20 + PAL_black
	EQUB &30 + PAL_black
	EQUB &40 + PAL_black
	EQUB &50 + PAL_black
	EQUB &60 + PAL_black
	EQUB &70 + PAL_black
	EQUB &80 + PAL_black
	EQUB &90 + PAL_black
	EQUB &A0 + PAL_black
	EQUB &B0 + PAL_black
	EQUB &C0 + PAL_black
	EQUB &D0 + PAL_black
	EQUB &E0 + PAL_black
	EQUB &F0 + PAL_black
}

PAGE_ALIGN
.text_bg_table
{
	IF 0
	FOR n,0,255,1
	EQUB PAL_black
	NEXT
	ELSE
	FOR n,1,43,1
	EQUB MODE1_COL0 + PAL_red
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL0 + PAL_magenta
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL0 + PAL_blue
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL0 + PAL_cyan
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL0 + PAL_green
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL0 + PAL_yellow
	NEXT
	ENDIF
}

.text_fg_table_pastel
{
	IF 0
	FOR n,0,255,1
	EQUB PAL_black
	NEXT
	ELSE
	FOR n,1,21,1
	EQUB MODE1_COL2 + PAL_white
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL2 + PAL_black
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL2 + PAL_white
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL2 + PAL_black
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL2 + PAL_white
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL2 + PAL_black
	NEXT
	FOR n,1,22,1
	EQUB MODE1_COL2 + PAL_white
	NEXT
	ENDIF
}

.text_fg_table_copper
{
	IF 0
	FOR n,0,255,1
	EQUB PAL_black
	NEXT
	ELSE
	FOR n,1,21,1
	EQUB MODE1_COL2 + PAL_red
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL2 + PAL_magenta
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL2 + PAL_blue
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL2 + PAL_cyan
	NEXT
	FOR n,1,43,1
	EQUB MODE1_COL2 + PAL_green
	NEXT
	FOR n,1,42,1
	EQUB MODE1_COL2 + PAL_yellow
	NEXT
	FOR n,1,22,1
	EQUB MODE1_COL2 + PAL_red
	NEXT
	ENDIF
}

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

.text_pattern_0	; top-to-bottom, left-to-right
TEXT_PATTERN_SPIRAL 0,0,18,14
FOR y,1,TEXT_BLOCK_HEIGHT-2,1
FOR x,1,TEXT_BLOCK_WIDTH-2,1
	TEXT_PATTERN_ADDR x, y
NEXT
NEXT

.text_pattern_1	; left-to-right, top-to-bottom
;TEXT_PATTERN_SPIRAL 0,0,18,14
FOR x,0,TEXT_BLOCK_WIDTH-1,2
FOR y,0,TEXT_BLOCK_HEIGHT-1,1
	TEXT_PATTERN_ADDR x, y
NEXT
FOR y,TEXT_BLOCK_HEIGHT-1,0,-1
	TEXT_PATTERN_ADDR x+1, y
NEXT
NEXT

.text_pattern_2	; spiral
TEXT_PATTERN_SPIRAL 0,0,18,14
TEXT_PATTERN_SPIRAL 1,1,16,12
TEXT_PATTERN_SPIRAL 2,2,14,10
TEXT_PATTERN_SPIRAL 3,3,12,8
TEXT_PATTERN_SPIRAL 4,4,10,6
TEXT_PATTERN_SPIRAL 5,5,8,4
TEXT_PATTERN_SPIRAL 6,6,6,2

.text_pattern_3	; top-to-bottom, left-to-right
TEXT_PATTERN_SPIRAL 0,0,18,14
FOR y,1,TEXT_BLOCK_HEIGHT-2,2
FOR x,1,TEXT_BLOCK_WIDTH-2,1
	TEXT_PATTERN_ADDR x, y
NEXT
FOR x,TEXT_BLOCK_WIDTH-2,1,-1
	TEXT_PATTERN_ADDR x, y+1
NEXT
NEXT

.font_font_data
; TEMP TEMP TEMP
INCBIN "data\font_razor.bin"

.text_end
