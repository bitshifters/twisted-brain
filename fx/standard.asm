\ ******************************************************************
\ *	Standard CRTC configuration
\ * 8 scanlines / row
\ * 39 rows / frame
\ * 32 rows visible
\ ******************************************************************

.standard_start

.standard_init
{
	LDX #0
	JSR screen_clear_line_0X

	LDA #&AA

	FOR n,0,39,1
	STA &3000+n*8
	NEXT

    RTS
}

.standard_draw
{
	\\ Start of rasterline 0

	LDA #PAL_green
	STA &FE21

	\\ Wait one rasterline (minus time for palette set)

	FOR n,1,58,1
	NOP
	NEXT
	
	LDA #PAL_black
	STA &FE21

	\\ Wait 254 rasterlines

    LDX #254

    .here

    FOR n,1,61,1
    NOP
    NEXT

    DEX
    BNE here

	\\ Start of rasterline 255

  	LDA #PAL_red
	STA &FE21
  
    RTS
}

.standard_end
