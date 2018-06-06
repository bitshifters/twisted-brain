\ ******************************************************************
\ *	Single scanline framebuffers
\ ******************************************************************

_RESET_WITH_312_LINE_FRAME = FALSE	; otherwise 312 line frame

.single_start

\ ******************************************************************
\ Initialise FX
\
\ The initialise function is used to set up all variables, tables and
\ any precalculated screen memory etc. required for the FX.
\
\ This function will be called during vblank
\ The CRTC registers & ULA will be set to default MODE 2 values
\ The screen display will already be turned OFF with CRTC R8
\
\ The function can take as long as is necessary to initialise BUT:
\ MUST BE RESPONSIBLE FOR POLLING THE MUSIC PLAYER IF A VSYNC OCCURS
\ There are* helper functions to assit with this for decrunch etc.
\ ******************************************************************

.single_init
{
	LDX #0
	JSR screen_clear_line_0X

	LDA #&AA
	FOR n,40,79,1
	STA &3000+n*8
	NEXT

	RTS
}

\ ******************************************************************
\ Update FX
\
\ The update function is used to update / tick any variables used
\ in the FX. It may also prepare part of the screen buffer before
\ drawing commenses but note the strict timing constraints!
\
\ This function will be called during vblank, after the music player
\ has been polled and after the scripting system has been updated
\
\ The function MUST COMPLETE BEFORE TIMER 1 REACHES 0, i.e. before
\ scanline 0 begins. If you are late then the draw function will be
\ late and your raster timings will be wrong!
\ ******************************************************************

.single_update
{
	\\ We're only ever going to display this one scanline
	LDA #12: STA &FE00
	LDA #HI(screen_base_addr/8): STA &FE01

	LDA #13: STA &FE00
	LDA #LO(screen_base_addr/8): STA &FE01

	RTS
}

\ ******************************************************************
\ Draw FX
\
\ The draw function is the main body of the FX.
\
\ This function will be exactly at the start* of scanline 0 with a
\ maximum jitter of up to +10 cycles.
\
\ This means that a new CRTC cycle has just started! If you didn't
\ specify the registers from the previous frame then they will be
\ the default MODE 2 values as per initialisation.
\
\ If messing with CRTC registers, THIS FUNCTION MUST ALWAYS PRODUCE
\ A FULL AND VALID 312 line PAL signal before exiting!
\ ******************************************************************

.single_draw
{
	\\ Start of rasterline 0 (we hope)

	LDA #PAL_green
	STA &FE21

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

	\\ Rest of rasterline 0

	FOR n,1,25,1
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

	\\ Start of rasterline 255 (we hope)

	LDA #PAL_red:STA &FE21

	\\ R9 = scanlines/row = 1 scanline (not needed)
	LDA #9: STA &FE00
	LDA #0:	STA &FE01

	\\ R4 = vertical total (from rasterline 255) = 312 - 255 = 57
	LDA #4: STA &FE00
	LDA #57-1: STA &FE01		; 312 - 255 = 57 scanlines

	\\ R7 = vertical sync at rasterline 35*8 = 280 = 280 - 255 = 25
	LDA #7:	STA &FE00
	LDA #25: STA &FE01			; 280 - 255 = 25 scanlines

	\\ R6 = vertical displayed = 1 (display this rasterline)
	LDA #6: STA &FE00
	LDA #1: STA &FE01

    RTS
}

.single_kill
{
IF _RESET_WITH_312_LINE_FRAME = FALSE
	JMP crtc_reset
ELSE
	\\ Create a 311 line frame one time only...

	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00
	LDA #6:	STA &FE01		; 7 scanlines?

	\\ R4=6 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #38: STA &FE01		; 312

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #35: STA &FE01		; 280 - 256 = 24 scanlines - was +1
	
	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #32: STA &FE01			; was +1
	
	\\ Wait 7 scanlines so next character row
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128

	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00
	LDA #7:	STA &FE01		; 8 scanlines?

	LDA #12: STA &FE00
	LDA #HI(screen_base_addr/8): STA &FE01
	LDA #13: STA &FE00
	LDA #LO(screen_base_addr/8): STA &FE01

	\\ Horizontal values
	LDA #0: STA &FE00
	LDA #127: STA &FE01

	LDA #1: STA &FE00
	LDA #80: STA &FE01

	LDA #2: STA &FE00
	LDA #98: STA &FE01

	RTS
ENDIF
}

.single_end
