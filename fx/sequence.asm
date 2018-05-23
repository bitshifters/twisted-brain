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

MACRO SEQUENCE_FX_FOR_SECS fxenum, secs
    SCRIPT_CALLV main_set_fx, fxenum
    SCRIPT_SEGMENT_START secs
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

MACRO TWISTER_SET_TWIST_FRAME_STEP step
    SCRIPT_CALLV twister_set_twist_frame_step_LO, LO(step * 256)
    SCRIPT_CALLV twister_set_twist_frame_step_HI, HI(step * 256)
ENDMACRO 

MACRO TWISTER_SET_TWIST_ROW_STEP step
    SCRIPT_CALLV twister_set_twist_row_step_LO, LO(step * 256)
    SCRIPT_CALLV twister_set_twist_row_step_HI, HI(step * 256)
ENDMACRO

MACRO TWISTER_SET_TWIST_PERIOD secs
{
    step = 256 / (secs * 50)
    PRINT "TWIST DURATION: secs/table=", secs, " frame step=", step
    TWISTER_SET_TWIST_FRAME_STEP step
}
ENDMACRO

MACRO TWISTER_SET_SPIN_PERIOD secs
{
    step = 256 / (secs * 50)
    PRINT "STEP PERIOD: secs/table=", secs, " spin step=", step
    TWISTER_SET_TWIST_SPIN_STEP step
}
ENDMACRO


MACRO TWISTER_SET_NUMBER n
    SCRIPT_CALLV twister_set_displayed, n*20
ENDMACRO

.sequence_script_start

\\ TEST TEST TEST
SEQUENCE_FX_FOR_SECS fx_Twister, 0.1

TWISTER_SET_SPIN_STEP 1.0
SEQUENCE_WAIT_SECS 5.62      ; 281 frames

MODE1_SET_COLOUR 2, PAL_green
TWISTER_SET_SPIN_STEP 0.0    ; keep spin constant (should be ~200 deg/sec)
TWISTER_SET_TWIST_PERIOD 10.0 ; 10s to cover table

SEQUENCE_WAIT_SECS 10.0

MODE1_SET_COLOUR 2, PAL_yellow
TWISTER_SET_SPIN_STEP -1.0

SEQUENCE_WAIT_SECS 5.12

MODE1_SET_COLOUR 2, PAL_blue
TWISTER_SET_TWIST_PERIOD 2.0

SEQUENCE_WAIT_SECS 10.0

TWISTER_TEMP_BLANK 0.5
TWISTER_SET_NUMBER 2
TWISTER_SET_TWIST_ROW_STEP 0.6

SEQUENCE_WAIT_SECS 10.0

MODE1_SET_COLOUR 2, PAL_magenta
TWISTER_SET_TWIST_ROW_STEP 0.75

SEQUENCE_WAIT_SECS 20.0


\\ Intro Pattern 1
\\ 0:00 - 0:19 = 19s
\\ BITSHIFTERS PRESENTS DEMO NAME

SEQUENCE_FX_FOR_SECS fx_Logo, 19.5

\\ Intro Pattern 2
\\ 0:19 - 0:34 = 15s
\\ THINGS START TO GO RASTERY

SCRIPT_CALLV logo_set_anim, 1
SEQUENCE_WAIT_SECS 15.2

\\ Drums kick in 0:34 - 0:42 = 8s
\\ KICK FX OFF WITH HIGH ENERGY

SEQUENCE_FX_FOR_SECS fx_CheckerZoom, 7.8

\\ Pattern 3 0:42 - 0:57 = 15s
\\ SIMPLE FX ONE

SEQUENCE_FX_FOR_SECS fx_VBlinds, 15.0

\\ Pattern 4 0:57 - 1:12 = 15s
\\ SIMPLE FX TWO

SEQUENCE_FX_FOR_SECS fx_Kefrens, 15.2

\\ Chord change 1:12 - 1:20 = 8s

SEQUENCE_FX_FOR_SECS fx_BoxRot, 7.8

\\ Long bit A 1:20 - 1:51 = 31s
\\ BETTER FX ONE

SEQUENCE_FX_FOR_SECS fx_Twister, 31.0

\\ Long bit B 1:51 - 2:22 = 31s
\\ Slightly repetitive middle part so run text?
\\ SPECS, CREDITS, GREETZ, THANX?

SEQUENCE_FX_FOR_SECS fx_Text, 31.0

\\ Drums disappear 2:22 - 3:00 = 38s
\\ Building energy here
\\ BETTER FX TWO

SEQUENCE_FX_FOR_SECS fx_Parallax, 3.5

MODE1_SET_COLOUR 2, PAL_yellow
SEQUENCE_WAIT_SECS 3.0
MODE1_SET_COLOUR 3, PAL_white
SEQUENCE_WAIT_SECS 3.0

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

SEQUENCE_FX_FOR_SECS fx_Plasma, 31.0

\\ Final chords 3:31 - 3:33 = 2s + silence
\\ Finish with wonder :)

SEQUENCE_FX_FOR_SECS fx_Copper, 10.0





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

SCRIPT_END

.sequence_script_end

.sequence_end
