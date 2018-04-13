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

\ ******************************************************************
\ *	DEMO defines
\ ******************************************************************

SLOT_MUSIC = 4

fx_Null = 0
fx_Kefrens = 1
fx_Twister = 2
fx_BoxRot = 3
fx_Parallax = 4
fx_MAX = 5

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

\\ Vars used by main system routines
.vsync_counter			SKIP 2		; counts up with each vsync
.delta_time				SKIP 1
.main_fx_enum			SKIP 1		; which FX are we running?
.main_new_fx			SKIP 1		; which FX do we want?
.first_frame			SKIP 1		; have we completed the first frame of FX?

\\ Generic vars that can be shared (volatile)
.readptr				SKIP 2		; generic read ptr
.writeptr				SKIP 2		; generic write ptr

INCLUDE "lib/vgmplayer.h.asm"
INCLUDE "lib/exomiser.h.asm"

.locals_start

\ ******************************************************************
\ *	CODE START
\ ******************************************************************

ORG &E00	      					; code origin (like P%=&2000)
GUARD screen_base_addr			; ensure code size doesn't hit start of screen memory

.start

.main_start

\ ******************************************************************
\ *	Code entry
\ ******************************************************************

.main
{
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

	\\ Load SIDEWAYS RAM modules here

	LDA #4:JSR swr_select_slot
	LDA #HI(bank0_start)
	LDX #LO(bank0_filename)
	LDY #HI(bank0_filename)
	JSR disksys_load_file

	LDA #5:JSR swr_select_slot
	LDA #HI(bank1_start)
	LDX #LO(bank1_filename)
	LDY #HI(bank1_filename)
	JSR disksys_load_file

	LDA #SLOT_MUSIC:JSR swr_select_slot

	\\ Initalise system vars

	LDA #0
	STA vsync_counter
	STA vsync_counter+1

	LDA #0				; initial FX
	STA main_new_fx

	LDA #1
	STA delta_time
	
	\\ Initialise music player

	LDX #LO(music_data)
	LDY #HI(music_data)
	JSR vgm_init_stream

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
	JSR crtc_hide_screen
	JSR screen_clear_all

;	LDA #22:JSR oswrch
;	LDA #2:JSR oswrch

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

	\\ Hide the screen to cover any initialisation

	JSR crtc_hide_screen
	STZ first_frame

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

	\\ Select correct SWRAM bank for FX

		LDX main_fx_enum
		LDA main_fx_slot, X
		JSR swr_select_slot
	}

	.call_init
	JSR &FFFF


	\\ We don't know how long the init took so resync

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

	\ ******************************************************************
	\ *	MAIN LOOP
	\ ******************************************************************

.main_loop

	\\  Do useful work during vblank (vsync will occur at some point)

	{
		INC vsync_counter
		BNE no_carry
		INC vsync_counter+1
		.no_carry
	}

	\\ Service music player (move to music module)

	LDA #SLOT_MUSIC:JSR swr_select_slot
	JSR vgm_poll_player

	\\ Select SWRAM bank for our current FX

	LDX main_fx_enum
	LDA main_fx_slot, X
	JSR swr_select_slot

	\\ Update the scripting system

	JSR script_update

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
		STA &FE4D             		; clear timer1 flag ; 4c +1/2c
	}

	\\ We could stabilise the raster here with a NOP slide
	\\ But it is much harder than it looks! Can't use Timer 1 to
	\\ allow us to complete arbitrary amounts of work total cycle count
	\\ will be different on each loop due to cycle stretching.
	\\ To do this properly need to guarantee the cycle count for a loop
	\\ is exactly the same each frame - a massive ball ache TBH.

IF 0
	LDA &FE44					; 4c + 1c - will be even already?

	\\ NOP slide for stable raster fun

	SEC							; 2c
	LDA #&F7					; 2c largest observed
	SBC &FE44					; 4c + 1/2c
	; larger number = less time passed -> more NOPs -> nearer branch
	; smaller number = more time passed -> fewer NOPs -> longer branch
	STA branch+1				; 4c
	.branch
	BNE branch					; 3c

	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
ENDIF

	.stable

	\\ Check if our FX has changed?

	LDA main_new_fx
	CMP main_fx_enum
	BEQ continue

	\\ It has so we'd better put the CRTC straight for the rest of this frame

	.call_kill
	JSR crtc_reset

	\\ Then init our new FX and resync to vsync

	JMP main_init_fx

	.continue

	\\ FX draw callback here!

	.call_draw
	JSR &FFFF

	\\ We now know we've completed at least one frame

	LDA first_frame
	BNE done_first_frame

	\\ If this is the first frame we can show the screen

	DEC A:STA first_frame
	JSR crtc_show_screen

	\\ Loop as fast as possible

	.done_first_frame
	JMP main_loop				; 3c

	\\ Maybe one day we'l escape the loop...

	.return

    CLI

	\\ Exit gracefully (in theory)

	RTS
}

.main_set_fx
{
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

INCLUDE "lib/vgmplayer.asm"
INCLUDE "lib/exomiser.asm"
INCLUDE "lib/disksys.asm"
INCLUDE "lib/unpack.asm"
INCLUDE "lib/swr.asm"
INCLUDE "lib/script.asm"

\ ******************************************************************
\ *	DEMO
\ ******************************************************************

INCLUDE "fx/helpers.asm"
INCLUDE "fx/sequence.asm"

\ ******************************************************************
\ *	DATA
\ ******************************************************************

.data_start

.bank0_filename EQUS "Bank0  $"
.bank1_filename EQUS "Bank1  $"

.main_fx_table
{
\\ FX initialise, update, draw and kill functions
\\ 
	EQUW do_nothing,    do_nothing,      do_nothing,    do_nothing
	EQUW kefrens_init,  kefrens_update,  kefrens_draw,  crtc_reset
	EQUW twister_init,  twister_update,  twister_draw,  crtc_reset
	EQUW boxrot_init,   boxrot_update,   boxrot_draw,   ula_pal_reset
	EQUW parallax_init, parallax_update, parallax_draw, parallax_kill
}

.main_fx_slot
{
	EQUB 4, 4, 4, 5, 5		; need something better here?
}

.data_end

\ ******************************************************************
\ *	End address to be saved
\ ******************************************************************

.end

\ ******************************************************************
\ *	Save the code
\ ******************************************************************

SAVE "JustRas", start, end

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
PRINT "VGM PLAYER size =", ~vgm_player_end-vgm_player_start
PRINT "EXOMISER size =", ~exo_end-exo_start
PRINT "DISKSYS size =", ~beeb_disksys_end-beeb_disksys_start
PRINT "PUCRUNCH size =", ~pucrunch_end-pucrunch_start
PRINT "SWR size =",~beeb_swr_end-beeb_swr_start
PRINT "SCRIPT size =",~script_end-script_start
PRINT "------"
PRINT "SEQUENCE size =",~sequence_end-sequence_start
PRINT "------"
PRINT "HIGH WATERMARK =", ~P%
PRINT "FREE =", ~screen_base_addr-P%
PRINT "------"

\ ******************************************************************
\ *	Assemble SWRAM banks
\ ******************************************************************

CLEAR 0, &FFFF
ORG &8000
GUARD &C000

.bank0_start

\ ******************************************************************
\ *	MUSIC
\ ******************************************************************

.music_data
INCBIN "audio/music/BotB 23787 djmaximum - your VGM has arrived for the Tandy 1000.raw.exo"
.music_end

\ ******************************************************************
\ *	FX
\ ******************************************************************

PAGE_ALIGN
INCLUDE "fx/kefrens.asm"
INCLUDE "fx/twister.asm"

.bank0_end

SAVE "Bank0", bank0_start, bank0_end

\ ******************************************************************
\ *	BANK 0 Info
\ ******************************************************************

PRINT "------"
PRINT "BANK 0"
PRINT "------"
PRINT "MUSIC size =", ~music_end-music_data
PRINT "------"
PRINT "KEFRENS size =", ~kefrens_end-kefrens_start
PRINT "TWISTER size =", ~twister_end-twister_start
PRINT "------"
PRINT "HIGH WATERMARK =", ~P%
PRINT "FREE =", ~&C000-P%
PRINT "------"

CLEAR 0, &FFFF
ORG &8000
GUARD &C000

.bank1_start

\ ******************************************************************
\ *	FX
\ ******************************************************************

PAGE_ALIGN
INCLUDE "fx/boxrot.asm"
INCLUDE "fx/parallax.asm"

.bank1_end

SAVE "Bank1", bank1_start, bank1_end

\ ******************************************************************
\ *	BANK 1 Info
\ ******************************************************************

PRINT "------"
PRINT "BANK 1"
PRINT "------"
PRINT "BOXROT size =",~boxrot_end-boxrot_start
PRINT "PARALLAX size =", ~parallax_end-parallax_start
PRINT "------"
PRINT "HIGH WATERMARK =", ~P%
PRINT "FREE =", ~&C000-P%
PRINT "------"
