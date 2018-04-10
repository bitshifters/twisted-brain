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
\ *	GLOBAL constants
\ ******************************************************************

SLOT_MUSIC = 4

MAIN_screen_base_addr = &3000
MAIN_screen_top_addr = &8000
MAIN_screen_size = MAIN_screen_top_addr - MAIN_screen_base_addr

MAIN_screen_num_cols = 40
MAIN_screen_bytes_per_col = 16
MAIN_screen_bytes_per_row = 640			; = MAIN_screen_bytes_per_col * MAIN_screen_num_cols

MAIN_clocks_per_scanline = 64
MAIN_scanlines_per_row = 8

; Exact time for a 50Hz frame less latch load time
FramePeriod = 312*64-2

; Calculate here the timer value to interrupt at the desired line
TimerValue = 40*64 - 2*64 - 2 - 64 - 16

\\ 40 lines for vsync
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
.main_vsync_counter		SKIP 1		; counts up with each vsync

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
GUARD MAIN_screen_base_addr			; ensure code size doesn't hit start of screen memory

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

	\\ NEED TO TURN OFF INTERLACE HERE!

	\\ Load SIDEWAYS RAM modules here

	LDA #SLOT_MUSIC
	JSR swr_select_slot
	LDA #HI(bank0_start)
	LDX #LO(bank0_filename)
	LDY #HI(bank0_filename)
	JSR disksys_load_file

	\\ Initalise system vars

	LDA #0
	STA main_vsync_counter
	
	\\ Set initial screen mode

	LDA #22:JSR oswrch
	LDA #2:JSR oswrch

	\\ Initialise FX modules here (but will be in transition later)

	JSR kefrens_init

	\\ Initialise music player

	LDX #LO(music_data)
	LDY #HI(music_data)
	JSR vgm_init_stream

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

	; Write T1 low now (the timer will not be written until you write the high byte)
    LDA #LO(TimerValue):STA &FE44
    ; Get high byte ready so we can write it as quickly as possible at the right moment
    LDX #HI(TimerValue):STX &FE45             		; start T1 counting		; 4c +1/2c 

  	; Latch T1 to interupt exactly every 50Hz frame
	LDA #LO(FramePeriod):STA &FE46
	LDA #HI(FramePeriod):STA &FE47

	\ ******************************************************************
	\ *	MAIN LOOP
	\ ******************************************************************

.main_loop

	\\  Do useful work after vsync

	INC main_vsync_counter

	\\ Service music player

	JSR vgm_poll_player

	\\ FX update callback here!

	JSR kefrens_update

	\\ Debug (are we alive?)

	IF _HEARTBEAT_CHAR
	{
		LDA main_vsync_counter		; 3c
		STA &3000
		STA &3001
		STA &3002
		STA &3003
		STA &3004
		STA &3005
		STA &3006
		STA &3007					; 8x 4c = 32c
	}
	ENDIF

	\\ Wait for first scanline

	{
		LDA #&40
		.waitTimer1
		BIT &FE4D				; 4c + 1/2c
		BEQ waitTimer1         	; poll timer1 flag
	}
	STA &FE4D             		; clear timer1 flag ; 4c +1/2c

	\\ Stablise raster!

	LDA &FE44					; 4c + 1c - will be even already?

	\\ Waste 4 or 5 cycles here

IF 0
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

	\\ FX draw callback here!

	JSR kefrens_draw

	\\ Loop as fast as possible

	JMP main_loop				; 3c

	\\ Maybe one day we'l escape the loop...

	.return

    CLI

	\\ Exit gracefully (in theory)

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

\ ******************************************************************
\ *	DATA
\ ******************************************************************

.data_start

.bank0_filename EQUS "Bank0  $"

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
PRINT "------"
PRINT "HIGH WATERMARK =", ~P%
PRINT "FREE =", ~MAIN_screen_base_addr-P%
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
INCBIN "data/Prince of Persia - 03 - Hourglass.raw.exo"
.music_end

\ ******************************************************************
\ *	FX
\ ******************************************************************

PAGE_ALIGN
INCLUDE "fx/kefrens.asm"

.bank0_end

SAVE "Bank0", bank0_start, bank0_end

\ ******************************************************************
\ *	Memory Info
\ ******************************************************************

PRINT "------"
PRINT "BANK 0"
PRINT "------"
PRINT "MUSIC size =", ~music_end-music_data
PRINT "------"
PRINT "KEFRENS size =", ~kefrens_end-kefrens_start
PRINT "------"
PRINT "HIGH WATERMARK =", ~P%
PRINT "FREE =", ~&C000-P%
PRINT "------"
