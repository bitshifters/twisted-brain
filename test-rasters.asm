\ ******************************************************************
\ *	#noteletext #justrasters
\ ******************************************************************

\ ******************************************************************
\ *	OS defines
\ ******************************************************************

CPU 1	; master only!

INCLUDE "lib/bbc.h.asm"

\ ******************************************************************
\ *	DEBUG defines
\ ******************************************************************

_DEBUG = TRUE
_HEARTBEAT_CHAR = FALSE

\ ******************************************************************
\ *	MACROS
\ ******************************************************************

MACRO PAGE_ALIGN
    PRINT "ALIGN LOST ", ~LO(((P% AND &FF) EOR &FF)+1), " BYTES"
    ALIGN &100
ENDMACRO

MACRO SET_ULA_MODE ula_mode
{
	LDA #ula_mode
    STA &FE20:STA &248
}
ENDMACRO

MACRO CYCLES_WAIT cycles
{
	IF cycles=128
	JSR cycles_wait_128
	ELSE
	FOR n,1,cycles DIV 2,1
	NOP
	NEXT
	ENDIF
}
ENDMACRO

\ ******************************************************************
\ *	DEMO defines
\ ******************************************************************

fx_Null = 0
fx_Single = 1
fx_Standard = 2
fx_MAX = 3

\ ******************************************************************
\ *	GLOBAL constants
\ ******************************************************************

; Default screen address
screen_base_addr = &3000
SCREEN_SIZE_BYTES = &8000 - screen_base_addr

; Exact time for a 50Hz frame less latch load time
FramePeriod = 312*64-2

; Calculate here the timer value to interrupt at the desired line
TimerValue = 32*64 - 2*64 - 2 - 22

\\ 40 lines for vblank
\\ 32 lines for vsync (vertical position = 35 / 39)
\\ interupt arrives 2 lines after vsync pulse
\\ 2 us for latch
\\ XX us to fire the timer before the start of the scanline so first colour set on column -1
\\ YY us for code that executes after timer interupt fires


\ ******************************************************************
\ *	ZERO PAGE
\ ******************************************************************

ORG &0
GUARD &90

INCLUDE "lib/script.h.asm"

\\ Vars used by main system routines
.delta_time				SKIP 1
.main_fx_enum			SKIP 1		; which FX are we running?
.main_new_fx			SKIP 1		; which FX do we want?

IF _DEBUG
.vsync_counter			SKIP 2		; counts up with each vsync
ENDIF

\ ******************************************************************
\ *	CODE START
\ ******************************************************************

ORG &1900	      				; code origin (like P%=&2000)
GUARD screen_base_addr			; ensure code size doesn't hit start of screen memory

.start

.main_start

\ ******************************************************************
\ *	Code entry
\ ******************************************************************

.main
{
	\\ Clear RAM on BREAK as things are going to get messy
	
	LDA #200
	LDX #3
	JSR osbyte

	\\ Reset stack

	LDX #&FF					; X=11111111
	TXS							; reset stack	- DON'T RESET STACK IN A SUBROUTINE!

	\\ Set interrupts

	SEI							; disable interupts
	LDA #&7F					; A=01111111
	STA &FE4E					; R14=Interrupt Enable (disable all interrupts)
	STA &FE43					; R3=Data Direction Register "A" (set keyboard data direction)
	LDA #&C2					; A=11000010
	STA &FE4E					; R14=Interrupt Enable (enable main_vsync and timer interrupt)
	CLI							; enable interupts
	\\ Initalise system vars

	IF _DEBUG
	LDA #0
	STA vsync_counter
	STA vsync_counter+1
	ENDIF

	STZ main_new_fx
	STZ delta_time
	
	\\ Initialise script

	LDX #LO(sequence_script_start)
	LDY #HI(sequence_script_start)
	JSR script_init

	\\ Set initial screen mode manually
	\\ Stop us seeing any garbage that has been loaded into screen memory
	\\ And hides the screen until first FX is ready to be shown

	JSR wait_vsync
	JSR crtc_reset
	JSR ula_pal_reset
	JSR ula_control_reset
	JSR screen_clear_all

	\ ******************************************************************
	\ *	DEMO START - from here on out there is no OS to help you!!
	\ ******************************************************************

	SEI

	\\ Exact cycle VSYNC by Tom Seddon (?) and Tricky

	{
		lda #2
		.vsync1
		bit &FE4D
		beq vsync1 \ wait for vsync

		\now we're within 10 cycles of vsync having hit

		\delay just less than one frame
		.syncloop
		sta &FE4D \ 4(stretched), ack vsync

		\{ this takes (5*ycount+2+4)*xcount cycles
		\x=55,y=142 -> 39902 cycles. one frame=39936
		ldx #142 \2
		.deloop
		ldy #55 \2
		.innerloop
		dey \2
		bne innerloop \3
		\ =152
		dex \ 2
		bne deloop \3
		\}

		nop:nop:nop:nop:nop:nop:nop:nop:nop \ +16
		bit &FE4D \4(stretched)
		bne syncloop \ +3
		\ 4+39902+16+4+3+3 = 39932
		\ ne means vsync has hit
		\ loop until it hasn't hit

		\now we're synced to vsync
	}

	\\ Set up Timers

	.set_timers
	; Write T1 low now (the timer will not be written until you write the high byte)
    LDA #LO(TimerValue):STA &FE44
    ; Get high byte ready so we can write it as quickly as possible at the right moment
    LDX #HI(TimerValue):STX &FE45             		; start T1 counting		; 4c +1/2c 

  	; Latch T1 to interupt exactly every 50Hz frame
	LDA #LO(FramePeriod):STA &FE46
	LDA #HI(FramePeriod):STA &FE47

	\\ Initialise FX modules here

	.main_init_fx

	\\ Screen already hidden to cover any initialisation

	{
		LDA main_new_fx
		STA main_fx_enum

	\\ Copy our callback fn addresses into code

		ASL A:ASL A: ASL A:TAX	; *8
		LDA main_fx_table+0, X
		STA call_init+1
		LDA main_fx_table+1, X
		STA call_init+2

		LDA main_fx_table+2, X
		STA call_update+1
		LDA main_fx_table+3, X
		STA call_update+2

		LDA main_fx_table+4, X
		STA call_draw+1
		LDA main_fx_table+5, X
		STA call_draw+2

		LDA main_fx_table+6, X
		STA call_kill+1
		LDA main_fx_table+7, X
		STA call_kill+2
	}

IF 1
	{
		lda #&42
		sta &FE4D	\ clear vsync & timer 1 flags

		\\ Wait for Timer1 at scanline 0

		lda #&40
		.waitTimer1
		bit &FE4D
		beq waitTimer1
		sta &FE4D
	}
ENDIF

	\\ Call init fn exactly on scanline 0 in case we want to set new mode

	.call_init
	JSR &FFFF

	\\ We don't know how long the init took so resync to timer 1

	{
		lda #&42
		sta &FE4D	\ clear vsync & timer 1 flags

		\\ Wait for Timer1 at scanline 0

		lda #&40
		.waitTimer1
		bit &FE4D
		beq waitTimer1
		sta &FE4D

		\\ Now can enter main loop with enough time to do work
	}

IF 1
	\\ Update typically happens during vblank so wait 255 lines
	\\ But don't forget that the loop also takes time!!

	{
		LDX #245
		.loop
		JSR cycles_wait_128
		DEX
		BNE loop
	}
ENDIF

	\ ******************************************************************
	\ *	MAIN LOOP
	\ ******************************************************************

.main_loop

	\\  Do useful work during vblank (vsync will occur at some point)
	IF _DEBUG
	{
		INC vsync_counter
		BNE no_carry
		INC vsync_counter+1
		.no_carry
	}
	ENDIF

	\\ Update the scripting system

	JSR script_update

	\\ Music player will update this

	STZ delta_time

	\\ FX update callback here!

	.call_update
	JSR &FFFF

	\\ Debug (are we alive?)

	IF _HEARTBEAT_CHAR
	{
		LDA vsync_counter		; 3c
		STA &3000:STA &3001:STA &3002:STA &3003
		STA &3004:STA &3005:STA &3006:STA &3007					; 8x 4c = 32c
	}
	ENDIF

	\\ Wait for first scanline

	{
		LDA #&40
		.waitTimer1
		BIT &FE4D				; 4c + 1/2c
		BEQ waitTimer1         	; poll timer1 flag
		STA &FE4D             	; clear timer1 flag ; 4c +1/2c
	}

	.stable		; not actually stable raster

	\\ Check if our FX has changed?

	LDA main_new_fx
	CMP main_fx_enum
	BEQ continue

	\\ FX has changed so get current module to return CRTC to known state
	\\ NB. screen display already turned off at this point

	.call_kill
	JSR crtc_reset

	\\ Then init our new FX and resync to vsync

	JMP main_init_fx

	.continue

	\\ FX draw callback here!

	.call_draw
	JSR &FFFF

	\\ Loop as fast as possible

	JMP main_loop				; 3c

	\\ Maybe one day we'l escape the loop...

	.return

    CLI

	\\ Exit gracefully (in theory)

	RTS
}

.main_set_fx
{
\\ Remember our new FX until correct place in the frame to kill/init

	STA main_new_fx
}
.do_nothing
{
	RTS
}

.main_end

\ ******************************************************************
\ *	LIBRARY CODE
\ ******************************************************************

INCLUDE "lib/script.asm"

\ ******************************************************************
\ *	DEMO
\ ******************************************************************

INCLUDE "fx/helpers.asm"
INCLUDE "fx/sequence.asm"
PAGE_ALIGN
INCLUDE "fx/standard.asm"
PAGE_ALIGN
INCLUDE "fx/single256.asm"

\ ******************************************************************
\ *	DATA
\ ******************************************************************

.data_start

.main_fx_table
{
\\ FX initialise, update, draw and kill functions
\\ 
	EQUW do_nothing,      do_nothing,        do_nothing,      do_nothing
	EQUW single_init,     single_update,     single_draw,     single_kill
	EQUW standard_init,   do_nothing,        standard_draw,   crtc_reset
}
.data_end

\ ******************************************************************
\ *	Text and strings
\ ******************************************************************

\ ******************************************************************
\ *	End address to be saved
\ ******************************************************************

.end

\ ******************************************************************
\ *	Save the code
\ ******************************************************************

SAVE "TestRas", start, end

\ ******************************************************************
\ *	Space reserved for runtime buffers not preinitialised
\ ******************************************************************

\\ Add BSS here

\ ******************************************************************
\ *	Memory Info
\ ******************************************************************

PRINT "------"
PRINT "INFO"
PRINT "------"
PRINT "MAIN size =", ~main_end-main_start
PRINT "SCRIPT size =",~script_end-script_start
PRINT "------"
PRINT "HELPERS size =",~helpers_end-helpers_start
PRINT "SEQUENCE size =",~sequence_end-sequence_start
PRINT "SINGLE size =", ~single_end-single_start
PRINT "STANDARD size =", ~standard_end-standard_start
PRINT "DATA size =",~data_end-data_start
PRINT "------"
PRINT "HIGH WATERMARK =", ~P%
PRINT "FREE =", ~screen_base_addr-P%
PRINT "------"

