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

.sequence_script_start

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

SCRIPT_CALLV pal_set_mode1_colour2, PAL_yellow
SEQUENCE_WAIT_SECS 3.0
SCRIPT_CALLV pal_set_mode1_colour3, PAL_white
SEQUENCE_WAIT_SECS 3.0

\\ Need some sort of fade / blackout in between?

SCRIPT_CALLV parallax_set_inc_x, &FE
SCRIPT_CALLV parallax_set_wave_f, &FE
SEQUENCE_WAIT_SECS 9.5

SCRIPT_CALLV pal_set_mode1_colour2, PAL_cyan
SCRIPT_CALLV parallax_set_inc_x, 1
SCRIPT_CALLV parallax_set_wave_f, 2
SCRIPT_CALLV parallax_set_wave_y, 3

SEQUENCE_WAIT_SECS 9.5
SCRIPT_CALLV pal_set_mode1_colour1, PAL_blue
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
