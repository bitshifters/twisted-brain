\ ******************************************************************
\ *	Rotating box
\ ******************************************************************

boxrot_counter = locals_start + 0
boxrot_angle = locals_start + 1
boxrot_x1 = locals_start + 2
boxrot_x2 = locals_start + 3
boxrot_x3 = locals_start + 4
boxrot_x4 = locals_start + 5
boxrot_max_x = locals_start + 6
boxrot_index = locals_start + 7
boxrot_stripe = locals_start + 8
boxrot_page = locals_start + 9
boxrot_table_LO = locals_start + 10
boxrot_table_HI = locals_start + 11

BOXROT_MAX_STRIPES = 10

.boxrot_start

.boxrot_init
{
	LDA #0
	STA boxrot_counter
	STA boxrot_angle
	STA boxrot_index

	STZ boxrot_table_LO
	LDA #HI(boxrot_palette_table)
	STA boxrot_table_HI

\\ Sadly we don't know what state our screen buffer will be in

	JMP boxrot_clear_stripes
}

.boxrot_update
{
\\ Updaate the angle of box according to a sine table that cycles back and forth

	LDX boxrot_index
	LDA boxrot_delta_table, X
	CLC
	ADC boxrot_angle
	STA boxrot_angle
	INX
	STX boxrot_index

\\ Update which palette buffer we're updating this frame

	LDA boxrot_table_HI
	INC A
	CMP #HI(boxrot_palette_end)
	BCC ok
	LDA #HI(boxrot_palette_table)
	.ok
	STA boxrot_table_HI
	TAY

\\ Now self-mod the draw code to shuffle which buffer each palette change affects

	LDX #0
	.loop
	TYA
	STA boxrot_draw_here + 2, X
	TXA
	CLC
	ADC #8
	CMP #8*BOXROT_MAX_STRIPES
	BCS done
	TAX
	DEY
	CPY #HI(boxrot_palette_table)
	BCS loop
	LDY #HI(boxrot_palette_end - &100)
	BNE loop

\\ Update one palette buffer with our new rotation values

	.done
	JMP boxrot_do_rotation
}

.boxrot_draw
	\\ Should be exactly on next scanline

	NOP:NOP:NOP:NOP:NOP:NOP:NOP
	LDX #0					; 2c

	.boxrot_draw_here

	FOR n,0,BOXROT_MAX_STRIPES-1,1
	LDA boxrot_palette_table + n*&100, X	; 4c
	ORA #&10*n				; 2c
	STA &FE21				; 4c
	NEXT
	
	NOP:NOP:NOP:NOP:NOP

	BIT 0			; 3c
	INX				; 2c
	BNE boxrot_draw_here		; 3c

    RTS

.boxrot_clear_palette
{
	LDA #&00 + PAL_magenta
	FOR n,0,255,1
	LDY #n:STA (boxrot_table_LO), Y
	NEXT
	RTS
}

.boxrot_do_rotation
{
	JSR boxrot_clear_palette

	\\ Rotation
	LDX #0
	STX boxrot_max_x

	\\ Compute 4x points - could also have a double size table
	
	LDX boxrot_angle
	LDA boxrot_sine_table, X			; boxrot_x1
	STA boxrot_x1

	CLC
	TXA
	ADC #64
	TAX
	LDA boxrot_sine_table, X			; boxrot_x2
	STA boxrot_x2

	CLC
	TXA
	ADC #64
	TAX
	LDA boxrot_sine_table, X			; boxrot_x2
	STA boxrot_x3

	CLC
	TXA
	ADC #64
	TAX
	LDA boxrot_sine_table, X			; boxrot_x2
	STA boxrot_x4
	
	\\ Draw line 1
	CLC
	LDA boxrot_x1
	CMP boxrot_x2
	BCS skip_line1

	TAY
	LDA #&00 + PAL_black
	STA (boxrot_table_LO), Y
	LDA #&00 + PAL_red
	BNE line1_here

	.line1_loop
	STA (boxrot_table_LO), Y
	.line1_here
	INY
	CPY boxrot_x2
	BNE line1_loop

	LDX boxrot_x2
	CPX boxrot_max_x
	BCC skip_line1
	STX boxrot_max_x

	.skip_line1

	\\ Draw line 2
	CLC
	LDA boxrot_x2
	CMP boxrot_x3
	BCS skip_line2

	TAY
	LDA #&00 + PAL_black
	STA (boxrot_table_LO), Y
	LDA #&00 + PAL_yellow
	BNE line2_here

	.line2_loop
	STA (boxrot_table_LO), Y
	.line2_here
	INY
	CPY boxrot_x3
	BNE line2_loop

	LDX boxrot_x3
	CPX boxrot_max_x
	BCC skip_line2
	STX boxrot_max_x

	.skip_line2

	\\ Draw line 3
	CLC
	LDA boxrot_x3
	CMP boxrot_x4
	BCS skip_line3

	TAY
	LDA #&00 + PAL_black
	STA (boxrot_table_LO), Y
	LDA #&00 + PAL_green
	BNE line3_here

	.line3_loop
	STA (boxrot_table_LO), Y
	.line3_here
	INY
	CPY boxrot_x4
	BNE line3_loop

	LDX boxrot_x4
	CPX boxrot_max_x
	BCC skip_line3
	STX boxrot_max_x

	.skip_line3

	\\ Draw line 4
	CLC
	LDA boxrot_x4
	CMP boxrot_x1
	BCS skip_line4

	TAY
	LDA #&00 + PAL_black
	STA (boxrot_table_LO), Y
	LDA #&00 + PAL_blue
	BNE line4_here

	.line4_loop
	STA (boxrot_table_LO), Y
	.line4_here
	INY
	CPY boxrot_x1
	BNE line4_loop

	LDX boxrot_x1
	CPX boxrot_max_x
	BCC skip_line4
	STX boxrot_max_x

	.skip_line4
	LDY boxrot_max_x
	LDA #&00 + PAL_black
	STA (boxrot_table_LO), Y

	.return
	RTS
}

.boxrot_clear_stripes
{
  ldx #HI(SCREEN_SIZE_BYTES)
  stx boxrot_page

  lda #HI(screen_base_addr)
  sta loop+2

  ldx #0
  stx boxrot_stripe
  lda boxrot_stripe_data, X

  ldy #0
  ldx #(640/BOXROT_MAX_STRIPES)
  .loop
  sta &3000,Y
  dex
  bne ok

  lda boxrot_stripe
  inc a
  cmp #BOXROT_MAX_STRIPES
  bcc cont
  lda #0
  .cont
  sta boxrot_stripe
  tax
  lda boxrot_stripe_data, X
  ldx #(640/BOXROT_MAX_STRIPES)

  .ok
  iny
  bne loop
  inc loop+2
  dec boxrot_page
  bne loop
  rts
}

.boxrot_stripe_data
{
	EQUB PIXEL_LEFT_0 OR PIXEL_RIGHT_0
	EQUB PIXEL_LEFT_1 OR PIXEL_RIGHT_1
	EQUB PIXEL_LEFT_2 OR PIXEL_RIGHT_2
	EQUB PIXEL_LEFT_3 OR PIXEL_RIGHT_3
	EQUB PIXEL_LEFT_4 OR PIXEL_RIGHT_4
	EQUB PIXEL_LEFT_5 OR PIXEL_RIGHT_5
	EQUB PIXEL_LEFT_6 OR PIXEL_RIGHT_6
	EQUB PIXEL_LEFT_7 OR PIXEL_RIGHT_7
	EQUB PIXEL_LEFT_8 OR PIXEL_RIGHT_8
	EQUB PIXEL_LEFT_9 OR PIXEL_RIGHT_9
	EQUB PIXEL_LEFT_A OR PIXEL_RIGHT_A
	EQUB PIXEL_LEFT_B OR PIXEL_RIGHT_B
	EQUB PIXEL_LEFT_C OR PIXEL_RIGHT_C
	EQUB PIXEL_LEFT_D OR PIXEL_RIGHT_D
	EQUB PIXEL_LEFT_E OR PIXEL_RIGHT_E
	EQUB PIXEL_LEFT_F OR PIXEL_RIGHT_F
}

PAGE_ALIGN
.boxrot_palette_table
FOR m,0,15,1
FOR n,0,255,1
EQUB &00 + PAL_black
NEXT
NEXT
.boxrot_palette_end

.boxrot_sine_table
FOR n,0,255,1
EQUB 128 + 64 * SIN(2 * PI * n / 256)
NEXT

.boxrot_delta_table
FOR n,0,255,1
EQUB 8 * SIN(2 * PI * n / 256)
NEXT

\\ For rot value N ptr to framebuffer

.boxrot_end
