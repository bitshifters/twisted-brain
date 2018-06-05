\ ******************************************************************
\ *	Sequence of FX
\ ******************************************************************

.sequence_start

\ ******************************************************************
\ *	The fns
\ ******************************************************************

\ ******************************************************************
\ *	The script
\ ******************************************************************

MACRO SEQUENCE_WAIT_SECS secs
    SCRIPT_SEGMENT_START secs
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

MACRO SEQUENCE_WAIT_FRAMES frames
    SCRIPT_SEGMENT_START frames/50
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

MACRO SEQUENCE_WAIT_UNTIL frame_time
    SCRIPT_SEGMENT_UNTIL frame_time
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

MACRO SEQUENCE_FX_FOR_SECS fxenum, secs
    SCRIPT_CALLV main_set_fx, fxenum
    SCRIPT_SEGMENT_START secs
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

MACRO SEQUENCE_FX_FOR_FRAMES fxenum, frames
    SCRIPT_CALLV main_set_fx, fxenum
    SCRIPT_SEGMENT_START frames/50
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

MACRO SEQUENCE_FX_UNTIL fxenum, frame_time
    SCRIPT_CALLV main_set_fx, fxenum
    SCRIPT_SEGMENT_UNTIL frame_time
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

MACRO MODE1_SET_COLOUR c, p
IF c=1
    SCRIPT_CALLV pal_set_mode1_colour1, p
ELIF c=2
    SCRIPT_CALLV pal_set_mode1_colour2, p
ELSE
    SCRIPT_CALLV pal_set_mode1_colour3, p
ENDIF
ENDMACRO

MACRO MODE1_SET_COLOURS p1, p2, p3
    SCRIPT_CALLV pal_set_mode1_colour1, p1
    SCRIPT_CALLV pal_set_mode1_colour2, p2
    SCRIPT_CALLV pal_set_mode1_colour3, p3
ENDMACRO

MACRO TWISTER_TEMP_BLANK secs
    MODE1_SET_COLOURS PAL_black, PAL_black, PAL_black
    SEQUENCE_WAIT_SECS secs
    MODE1_SET_COLOURS PAL_red, PAL_yellow, PAL_white
ENDMACRO

MACRO TWISTER_SET_SPIN_STEP step
    SCRIPT_CALLV twister_set_spin_step_LO, LO(step * 256)
    SCRIPT_CALLV twister_set_spin_step_HI, HI(step * 256)
ENDMACRO 

MACRO TWISTER_SET_TWIST_STEP step
    SCRIPT_CALLV twister_set_twist_step_LO, LO(step * 256)
    SCRIPT_CALLV twister_set_twist_step_HI, HI(step * 256)
ENDMACRO 

MACRO TWISTER_SET_KNOT_STEP step
    SCRIPT_CALLV twister_set_knot_step_LO, LO(step * 256)
    SCRIPT_CALLV twister_set_knot_step_HI, HI(step * 256)
ENDMACRO

MACRO TWISTER_SET_KNOT_Y ystep
    SCRIPT_CALLV twister_set_knot_y_LO, LO(ystep * 256)
    SCRIPT_CALLV twister_set_knot_y_HI, HI(ystep * 256)
ENDMACRO

MACRO TWISTER_SET_SPIN_PERIOD secs
{
    IF secs = 0
    step = 0
    ELSE
    step = 256 / (secs * 50)
    ENDIF
    PRINT "STEP PERIOD: secs/table=", secs, " spin step=", step
    TWISTER_SET_SPIN_STEP step
}
ENDMACRO

MACRO TWISTER_SET_TWIST_PERIOD secs
{
    IF secs = 0
    step = 0
    ELSE
    step = 256 / (secs * 50)
    ENDIF
    PRINT "TWIST DURATION: secs/table=", secs, " frame step=", step
    TWISTER_SET_TWIST_STEP step
}
ENDMACRO

MACRO TWISTER_SET_KNOT_PERIOD secs
{
    IF secs = 0
    step = 0
    ELSE
    step = 256 / (secs * 50)
    ENDIF
    PRINT "KNOT PERIOD: secs/table=", secs, " knot step=", step
    TWISTER_SET_KNOT_STEP step
}
ENDMACRO

MACRO TWISTER_START spin, twist, knot, y
    SCRIPT_CALLV twister_set_spin_index, spin
    SCRIPT_CALLV twister_set_twist_index, twist
    SCRIPT_CALLV twister_set_knot_index, knot
    TWISTER_SET_KNOT_Y y
ENDMACRO

MACRO TWISTER_SET_PARAMS spin, twist, knot
    TWISTER_SET_SPIN_PERIOD spin
    TWISTER_SET_TWIST_PERIOD twist
    TWISTER_SET_KNOT_PERIOD knot
ENDMACRO

MACRO TWISTER_SET_NUMBER n
    SCRIPT_CALLV twister_set_displayed, n*20
ENDMACRO

.sequence_script_start

\\ Intro Pattern 1
\\ 0:00 - 0:19 = 19s
\\ BITSHIFTERS PRESENTS DEMO NAME

\\ Wait for first few bars

;SEQUENCE_WAIT_FRAMES 181

\ ******************************************************************
\\ **** TELETEXT LOGO ****
\ ******************************************************************

SEQUENCE_FX_UNTIL fx_Logo, &237

\ ******************************************************************
\\ **** WIBBLY LOGO ****
\ ******************************************************************

;SCRIPT_CALLV main_set_fx, fx_Logo
;SEQUENCE_WAIT_SECS 0.02
SCRIPT_CALLV logo_set_anim, 1
SEQUENCE_WAIT_UNTIL &3AE

\\ Intro Pattern 2
\\ 0:19 - 0:34 = 15s
\\ THINGS START TO GO RASTERY

\ ******************************************************************
\\ **** TITLE TEXT ****
\ ******************************************************************

SEQUENCE_FX_FOR_FRAMES fx_Text, 1
SCRIPT_CALLV text_set_pattern, textPattern_Spiral
SCRIPT_CALLV text_set_block, textBlock_Title    ; takes 252 frames = 5.04s
SEQUENCE_WAIT_UNTIL &4F8

\ ******************************************************************
\\ **** BRAIN DRAIN PICTURE ****
\ ******************************************************************

SEQUENCE_FX_UNTIL fx_Picture, &6C8

\\ Drums kick in 0:34 - 0:42 = 8s
\\ Drums arrive ~ frame &668
\\ KICK FX OFF WITH HIGH ENERGY

\ ******************************************************************
\\ **** CHECKERBOARD ZOOM ****
\ ******************************************************************

SEQUENCE_FX_UNTIL fx_CheckerZoom, &84D

\\ Pattern 3 0:42 - 0:57 = 15s
\\ Pattern 3 starts ~ frame &7EB
\\ SIMPLE FX ONE

\\ Pattern 4 0:57 - 1:12 = 15s
\\ SIMPLE FX TWO

\ ******************************************************************
\\ **** KEFRENS BARS ****
\ ******************************************************************

SEQUENCE_FX_UNTIL fx_Kefrens, &AEB

\\ Trigger next variation
\\ And probably another one

SEQUENCE_WAIT_UNTIL &DD3

\\ Chord change 1:12 - 1:20 = 8s

;SEQUENCE_FX_FOR_SECS fx_BoxRot, 7.8

\\ Long bit A 1:20 - 1:51 = 31s
\\ BETTER FX ONE

\ ******************************************************************
\\ **** CREDITS ****
\ ******************************************************************

SEQUENCE_FX_FOR_FRAMES fx_Text, 1
SCRIPT_CALLV text_set_pattern, textPattern_Horizontal
SCRIPT_CALLV text_set_block, textBlock_Credits
SEQUENCE_WAIT_SECS 7.0

\ ******************************************************************
\\ **** TWISTER ****
\ ******************************************************************

SEQUENCE_FX_FOR_FRAMES fx_Twister, 1

\\ PART #1
; Start spinning from rest
TWISTER_SET_PARAMS 5.12, 0, 0
SEQUENCE_WAIT_FRAMES 282
MODE1_SET_COLOUR 2, PAL_green
; keep spin constant (should be ~200 deg/sec)
; 10s to wind & unwind in one direction
TWISTER_SET_PARAMS 0, 10.0, 0
SEQUENCE_WAIT_FRAMES 251
MODE1_SET_COLOUR 2, PAL_yellow
; 10s to wind & unwind in other direction
SEQUENCE_WAIT_FRAMES 251

SEQUENCE_FX_FOR_FRAMES fx_Text, 1
SCRIPT_CALLV text_set_block, textBlock_Music
SEQUENCE_WAIT_SECS 7.0

;TWISTER_TEMP_BLANK 0.75
SEQUENCE_FX_FOR_FRAMES fx_Twister, 1

\\ PART #2
; a knot
TWISTER_SET_NUMBER 2
MODE1_SET_COLOUR 2, PAL_green
TWISTER_SET_KNOT_Y 1.0
TWISTER_SET_PARAMS 10.0, 0, 0
SCRIPT_CALLV twister_set_twist_index, 0
SEQUENCE_WAIT_SECS 5.0
; move the knot
;TWISTER_TEMP_BLANK 0.75
MODE1_SET_COLOUR 2, PAL_blue
TWISTER_SET_KNOT_PERIOD 5.0
SEQUENCE_WAIT_SECS 5.0

SEQUENCE_FX_FOR_FRAMES fx_Text, 1
SCRIPT_CALLV text_set_pattern, textPattern_Snake
SCRIPT_CALLV text_set_block, textBlock_Thanks    ; takes 252 frames = 5.04s
SEQUENCE_WAIT_SECS 6.0

;TWISTER_TEMP_BLANK 0.75
SEQUENCE_FX_FOR_FRAMES fx_Twister, 1

\\ PART #3
; go mental aka flump mode
TWISTER_SET_NUMBER 4
MODE1_SET_COLOUR 2, PAL_magenta
TWISTER_SET_KNOT_Y 2.3
TWISTER_SET_PARAMS 10, 40, 2.56

SEQUENCE_WAIT_SECS 9.0

\\ Long bit B 1:51 - 2:22 = 31s
\\ Slightly repetitive middle part so run text?

\ ******************************************************************
\\ **** THANX & GREETZ ****
\ ******************************************************************

SEQUENCE_FX_FOR_FRAMES fx_Text, 1
SCRIPT_CALLV text_set_pattern, textPattern_Snake
SCRIPT_CALLV text_set_block, textBlock_Greets    ; takes 252 frames = 5.04s
SEQUENCE_WAIT_SECS 7.0

\ ******************************************************************
\\ **** SPECS ****
\ ******************************************************************

;SEQUENCE_FX_FOR_FRAMES fx_Text, 1
SCRIPT_CALLV text_set_pattern, textPattern_Vertical
SCRIPT_CALLV text_set_block, textBlock_Specs    ; takes 252 frames = 5.04s
SEQUENCE_WAIT_SECS 7.0

\\ Put another picture here?

\\ High bit starts ~frame &1B23

\\ Drums disappear 2:22 - 3:00 = 38s
\\ Building energy here
\\ BETTER FX TWO

\ ******************************************************************
\\ **** PARALLAX ****
\ ******************************************************************

SEQUENCE_FX_FOR_SECS fx_Parallax, 3.5

MODE1_SET_COLOUR 2, PAL_yellow
SEQUENCE_WAIT_SECS 2.0
MODE1_SET_COLOUR 3, PAL_white
SEQUENCE_WAIT_SECS 2.0

\\ Need some sort of fade / blackout in between?

SCRIPT_CALLV parallax_set_inc_x, &FE
SCRIPT_CALLV parallax_set_wave_f, &FE

SEQUENCE_WAIT_SECS 9.5

MODE1_SET_COLOUR 2, PAL_cyan
SCRIPT_CALLV parallax_set_inc_x, 1
SCRIPT_CALLV parallax_set_wave_f, 2
SCRIPT_CALLV parallax_set_wave_y, 3

SEQUENCE_WAIT_SECS 9.5

MODE1_SET_COLOUR 1, PAL_blue
SCRIPT_CALLV parallax_set_inc_x, 1
SCRIPT_CALLV parallax_set_wave_f, 1
SCRIPT_CALLV parallax_set_wave_y, 15

SEQUENCE_WAIT_SECS 9.5

\\ Drums kick in again 3:00 - 3:31 = 31s
\\ Crescendo of demo - best FX!

\ ******************************************************************
\\ **** PLASMA ****
\ ******************************************************************

SEQUENCE_FX_UNTIL fx_Plasma, &2810

\\ Final chords 3:31 - 3:33 = 2s + silence
\\ Finish with wonder :)

\ ******************************************************************
\\ **** COPPER ****
\ ******************************************************************

SEQUENCE_FX_FOR_SECS fx_Copper, 10.0

SEQUENCE_FX_FOR_FRAMES fx_Text, 1
SCRIPT_CALLV text_set_block, textBlock_Return    ; takes 252 frames = 5.04s

SEQUENCE_WAIT_SECS 10.0

\ ******************************************************************
\\ **** END ****
\ ******************************************************************



\ ******************************************************************
\\ **** UNUSED ****
\ ******************************************************************

\\ Test whether all FX are keeping sync with timer
\\ AKA epilepsy mode
IF 0
FOR n,1,20,1
SEQUENCE_FX_FOR_SECS fx_Kefrens, 0.5
SEQUENCE_FX_FOR_SECS fx_VBlinds, 0.5
SEQUENCE_FX_FOR_SECS fx_CheckZoom, 0.5
SEQUENCE_FX_FOR_SECS fx_BoxRot, 0.5
SEQUENCE_FX_FOR_SECS fx_Parallax, 0.5
SEQUENCE_FX_FOR_SECS fx_Twister, 0.5
SEQUENCE_FX_FOR_SECS fx_Copper, 0.5
NEXT
ENDIF

\ ******************************************************************
\\ **** VERTICAL BLINDS ****
\ ******************************************************************
;SEQUENCE_FX_FOR_SECS fx_VBlinds, 8.0


SCRIPT_END

.sequence_script_end

.sequence_end
