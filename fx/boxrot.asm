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

.boxrot_start

.boxrot_init
{
	LDA #0
	STA boxrot_counter
	STA boxrot_angle
	STA boxrot_index

\\ Sadly we don't know what state our screen buffer will be in

	JMP screen_clear_all
}

.boxrot_update
{
	LDX boxrot_index
	LDA boxrot_delta_table, X
	CLC
	ADC boxrot_angle
	STA boxrot_angle
	INX
	STX boxrot_index

	JMP boxrot_do_rotation
}

.boxrot_draw
{
	\\ Should be exactly on next scanline

	LDX #0					; 2c

	.here

	FOR n,1,56,1
	NOP
	NEXT
	
	LDA boxrot_palette_table, X	; 4c
	STA &FE21				; 6c?
	
	BIT 0			; 3c
	INX				; 2c
	BNE here		; 3c

    RTS
}

.boxrot_clear_palette
{
	LDA #&00 + PAL_magenta
	FOR n,0,255,1
	STA boxrot_palette_table+n
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

	TAX
	LDA #&00 + PAL_black
	STA boxrot_palette_table, X
	LDA #&00 + PAL_red
	BNE line1_here

	.line1_loop
	STA boxrot_palette_table, X
	.line1_here
	INX
	CPX boxrot_x2
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

	TAX
	LDA #&00 + PAL_black
	STA boxrot_palette_table, X
	LDA #&00 + PAL_yellow
	BNE line2_here

	.line2_loop
	STA boxrot_palette_table, X
	.line2_here
	INX
	CPX boxrot_x3
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

	TAX
	LDA #&00 + PAL_black
	STA boxrot_palette_table, X
	LDA #&00 + PAL_green
	BNE line3_here

	.line3_loop
	STA boxrot_palette_table, X
	.line3_here
	INX
	CPX boxrot_x4
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

	TAX
	LDA #&00 + PAL_black
	STA boxrot_palette_table, X
	LDA #&00 + PAL_blue
	BNE line4_here

	.line4_loop
	STA boxrot_palette_table, X
	.line4_here
	INX
	CPX boxrot_x1
	BNE line4_loop

	LDX boxrot_x1
	CPX boxrot_max_x
	BCC skip_line4
	STX boxrot_max_x

	.skip_line4
	LDX boxrot_max_x
	LDA #&00 + PAL_black
	STA boxrot_palette_table, X

	.return
	RTS
}

PAGE_ALIGN
.boxrot_palette_table
FOR n,0,255,1
;EQUB n AND &F
EQUB &00 + PAL_black
NEXT

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
