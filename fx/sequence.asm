\ ******************************************************************
\ *	Sequence of FX
\ ******************************************************************

.sequence_start

\ ******************************************************************
\ *	SEQUENCE MACROS
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

\\ Or could query the music player..
MACRO SEQUENCE_WAIT_UNTIL_PATTERN p
    SCRIPT_SEGMENT_UNTIL (p * VGM_FRAMES_PER_PATTERN)
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

MACRO SEQUENCE_SET_FX fxenum
    SCRIPT_CALLV main_set_fx, fxenum
    SCRIPT_SEGMENT_START 1/50
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

\\ Ideally want:
\ SCRIPT_WAIT_UNTIL_NEXT_BEAT
\ SCRIPT_WAIT_UNTIL_NEXT_PATTERN

\ ******************************************************************
\ *	COLOUR MACROS
\ ******************************************************************

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

MACRO MODE0_SET_COLOURS p0,p1
    SCRIPT_CALLV pal_set_mode0_colour0, p0
    SCRIPT_CALLV pal_set_mode0_colour1, p1
ENDMACRO

\ ******************************************************************
\ *	The script
\ ******************************************************************

.sequence_script_start

\ ******************************************************************
\\ **** TELETEXT LOGO ****
\ ******************************************************************

SEQUENCE_SET_FX fx_Logo

\ ******************************************************************
\\ **** WIBBLY LOGO ****
\ ******************************************************************

; THINGS START TO GO RASTERY
SEQUENCE_WAIT_UNTIL_PATTERN 1
SCRIPT_CALLV logo_set_anim, 1
SEQUENCE_WAIT_UNTIL_PATTERN 3
SCRIPT_CALLV logo_set_anim, 0

\ ******************************************************************
\\ **** TITLE TEXT ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 5
SEQUENCE_SET_FX fx_Text
SCRIPT_CALLV text_set_pattern, textPattern_Horizontal
SCRIPT_CALLV text_set_block, textBlock_Title    ; takes 252 frames = 5.04s

\ ******************************************************************
\\ **** BRAIN DRAIN PICTURE ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 7
SEQUENCE_SET_FX fx_Picture
SEQUENCE_WAIT_UNTIL_PATTERN 7.5
SCRIPT_CALLV picture_set_anim, 1
SEQUENCE_WAIT_UNTIL_PATTERN 8
SCRIPT_CALLV picture_set_delay, 1

\ ******************************************************************
\\ **** CHECKERBOARD ZOOM ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 9
SEQUENCE_SET_FX fx_CheckerZoom

\ ******************************************************************
\\ **** VERTICAL BLINDS (FOR SIMON :) ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 11
SEQUENCE_SET_FX fx_VBlinds
;SCRIPT_CALLV kefrens_set_width, 1
;SCRIPT_CALLV kefrens_set_speed, 2
;SCRIPT_CALLV kefrens_set_add, 2

\ ******************************************************************
\\ **** KEFRENS BARS ****
\ ******************************************************************

\\ Simple wave w/ ripple
SEQUENCE_WAIT_UNTIL_PATTERN 13
SEQUENCE_SET_FX fx_Kefrens
SCRIPT_CALLV kefrens_set_speed, 1
SCRIPT_CALLV kefrens_set_add, 1
SCRIPT_CALLV kefrens_set_width, 1

\\ Wider wave
SEQUENCE_WAIT_UNTIL_PATTERN 15
;SCRIPT_CALLV kefrens_set_speed, 1
SCRIPT_CALLV kefrens_set_add, 0
;SCRIPT_CALLV kefrens_set_width, 1

\\ Most pleasing wave
SEQUENCE_WAIT_UNTIL_PATTERN 17
SCRIPT_CALLV kefrens_set_speed, 0
SCRIPT_CALLV kefrens_set_add, 0
SCRIPT_CALLV kefrens_set_width, 0

\ ******************************************************************
\\ **** CREDITS ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 19
SEQUENCE_SET_FX fx_Text
SCRIPT_CALLV text_set_pattern, textPattern_Horizontal
SCRIPT_CALLV text_set_block, textBlock_Credits

\ ******************************************************************
\\ **** TWISTER WIND/UNWIND ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 21
SEQUENCE_SET_FX fx_Twister
TWISTER_SET_NUMBER 1
TWISTER_SET_PARAMS 5.12, 0, 0
SEQUENCE_WAIT_FRAMES 153    ; 281
MODE1_SET_COLOUR 2, PAL_magenta
; keep spin constant (should be ~200 deg/sec)
; 10s to wind & unwind in one direction
TWISTER_SET_PARAMS 0, 10.0, 0
SEQUENCE_WAIT_FRAMES 251
MODE1_SET_COLOUR 2, PAL_yellow
; 10s to wind & unwind in other direction

\ ******************************************************************
\\ **** MUSIC CREDIT ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 25
SEQUENCE_SET_FX fx_Text
SCRIPT_CALLV text_set_pattern, textPattern_Horizontal
SCRIPT_CALLV text_set_block, textBlock_Music

\ ******************************************************************
\\ **** TWISTER KNOT ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 27
SEQUENCE_SET_FX fx_Twister
TWISTER_SET_NUMBER 2
MODE1_SET_COLOUR 1, PAL_blue
MODE1_SET_COLOUR 2, PAL_cyan
MODE1_SET_COLOUR 3, PAL_white
TWISTER_SET_KNOT_Y 1.0
TWISTER_SET_PARAMS 10.0, 0, 0
SCRIPT_CALLV twister_set_twist_index, 0
SEQUENCE_WAIT_UNTIL_PATTERN 28
; move the knot
;MODE1_SET_COLOUR 2, PAL_blue
TWISTER_SET_KNOT_PERIOD 5.0

\ ******************************************************************
\\ **** THANKS ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 30
SEQUENCE_SET_FX fx_Text
SCRIPT_CALLV text_set_pattern, textPattern_Snake
SCRIPT_CALLV text_set_block, textBlock_Thanks    ; takes 252 frames = 5.04s

\ ******************************************************************
\\ **** TWISTER FLUMPS ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 32
SEQUENCE_SET_FX fx_Twister
TWISTER_SET_NUMBER 4
MODE1_SET_COLOUR 1, PAL_red
MODE1_SET_COLOUR 2, PAL_magenta
MODE1_SET_COLOUR 3, PAL_white
TWISTER_SET_KNOT_Y 2.3
TWISTER_SET_PARAMS 10, 40, 2.56

\ ******************************************************************
\\ **** GREETS ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 35
SEQUENCE_SET_FX fx_Text
SCRIPT_CALLV text_set_pattern, textPattern_Snake
SCRIPT_CALLV text_set_block, textBlock_Greets    ; takes 252 frames = 5.04s

\ ******************************************************************
\\ **** COPPER ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 37
SEQUENCE_SET_FX fx_Copper
;SEQUENCE_SET_FX fx_Text
;SCRIPT_CALLV text_set_pattern, textPattern_Vertical
;SCRIPT_CALLV text_set_block, textBlock_Specs    ; takes 252 frames = 5.04s

\ ******************************************************************
\\ **** PARALLAX ****
\ ******************************************************************

; X=linear speed of top line in pixels
; F=speed of wave horizontlly (movement left/right)
; y=speed of wave vertically (how bendy)

\ Straight bars

SEQUENCE_WAIT_UNTIL_PATTERN 39 - 0.25 ; for setup

SEQUENCE_SET_FX fx_Parallax

SEQUENCE_WAIT_UNTIL_PATTERN 39.5
MODE1_SET_COLOUR 2, PAL_yellow
SEQUENCE_WAIT_UNTIL_PATTERN 40
MODE1_SET_COLOUR 3, PAL_white

\ Reverse direction!

SEQUENCE_WAIT_UNTIL_PATTERN 40.5
SCRIPT_CALLV parallax_set_inc_x, &FE
SCRIPT_CALLV parallax_set_wave_f, &FE

\ Bend bars gently

SEQUENCE_WAIT_UNTIL_PATTERN 41
MODE1_SET_COLOUR 2, PAL_cyan
SCRIPT_CALLV parallax_set_inc_x, 1
SCRIPT_CALLV parallax_set_wave_f, 1
SCRIPT_CALLV parallax_set_wave_y, 1

\ Speed up wave

SEQUENCE_WAIT_UNTIL_PATTERN 41.5
SCRIPT_CALLV parallax_set_wave_f, 2
;SCRIPT_CALLV parallax_set_wave_f, 3

\ Bend bars more

SEQUENCE_WAIT_UNTIL_PATTERN 42
MODE1_SET_COLOUR 1, PAL_green
SCRIPT_CALLV parallax_set_inc_x, &FF
SCRIPT_CALLV parallax_set_wave_f, 1
SCRIPT_CALLV parallax_set_wave_y, 2

\ Speed up wave

SEQUENCE_WAIT_UNTIL_PATTERN 43
SCRIPT_CALLV parallax_set_wave_f, 2
SEQUENCE_WAIT_UNTIL_PATTERN 43.5
SCRIPT_CALLV parallax_set_wave_f, 3

\ Bend bars even more

SEQUENCE_WAIT_UNTIL_PATTERN 44
MODE1_SET_COLOUR 1, PAL_blue
SCRIPT_CALLV parallax_set_inc_x, 1
SCRIPT_CALLV parallax_set_wave_f, 1
SCRIPT_CALLV parallax_set_wave_y, 4

\ Speed up wave

SEQUENCE_WAIT_UNTIL_PATTERN 45
SCRIPT_CALLV parallax_set_wave_f, 2

SEQUENCE_WAIT_UNTIL_PATTERN 45.5
SCRIPT_CALLV parallax_set_wave_f, 3

\ MEGA BEND!

SEQUENCE_WAIT_UNTIL_PATTERN 46
MODE1_SET_COLOUR 1, PAL_magenta
SCRIPT_CALLV parallax_set_inc_x, &FF
SCRIPT_CALLV parallax_set_wave_f, 1
SCRIPT_CALLV parallax_set_wave_y, 15

\ ******************************************************************
\\ **** PLASMA ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 47 - 0.1 ; for setup

SEQUENCE_SET_FX fx_Plasma

; X=linear speed of top line in characters
; F=speed of sine movement horizontlly (left/right)
; Y=freq of wave 1 vertically (how bendy)
; YF=speed of wave 2
; X=freq wave 2 vertically (hot extra bendy)
\\ By Hue white = red, blue, green
\\ By Hue black = magenta, cyan, yellow
\\ By Brightness white = red, blue, green, white
\\ By Brightness black = magenta, black, cyan, white

; fat & slow
MODE0_SET_COLOURS PAL_red, PAL_magenta
SCRIPT_CALLV plasma_set_x16, 2
SCRIPT_CALLV plasma_set_inc_x, 0
SCRIPT_CALLV plasma_set_wave_f, 1
SCRIPT_CALLV plasma_set_wave_y, 1
SCRIPT_CALLV plasma_set_wave_yf, &FF
SCRIPT_CALLV plasma_set_wave_x, 1

SEQUENCE_WAIT_UNTIL_PATTERN 48

; slow squeeze out
;MODE0_SET_COLOURS PAL_blue, PAL_cyan
;SCRIPT_CALLV plasma_set_x16, 20
;SCRIPT_CALLV plasma_set_inc_x, 0
;SCRIPT_CALLV plasma_set_wave_f, 1
;SCRIPT_CALLV plasma_set_wave_y, 2
;SCRIPT_CALLV plasma_set_wave_yf, 1
;SCRIPT_CALLV plasma_set_wave_x, 4

; swing from large
MODE0_SET_COLOURS PAL_green, PAL_yellow
SCRIPT_CALLV plasma_set_x16, 1
SCRIPT_CALLV plasma_set_inc_x, 1
SCRIPT_CALLV plasma_set_wave_f, 1
SCRIPT_CALLV plasma_set_wave_y, &FF
SCRIPT_CALLV plasma_set_wave_yf, 1
SCRIPT_CALLV plasma_set_wave_x, 2

SEQUENCE_WAIT_UNTIL_PATTERN 49

; nice & wibbly
MODE0_SET_COLOURS PAL_blue, PAL_cyan
SCRIPT_CALLV plasma_set_x16, 10
SCRIPT_CALLV plasma_set_inc_x, &FF
SCRIPT_CALLV plasma_set_wave_f, 0
SCRIPT_CALLV plasma_set_wave_y, &FE
SCRIPT_CALLV plasma_set_wave_yf, 3
SCRIPT_CALLV plasma_set_wave_x, 9

SEQUENCE_WAIT_UNTIL_PATTERN 50

; fast swipe from large
MODE0_SET_COLOURS PAL_white, PAL_yellow
SCRIPT_CALLV plasma_set_x16, 1
SCRIPT_CALLV plasma_set_inc_x, 1
SCRIPT_CALLV plasma_set_wave_f, 2
SCRIPT_CALLV plasma_set_wave_y, 1
SCRIPT_CALLV plasma_set_wave_yf, 0
SCRIPT_CALLV plasma_set_wave_x, 1

SEQUENCE_WAIT_UNTIL_PATTERN 51

; med bars swing
MODE0_SET_COLOURS PAL_green, PAL_cyan
SCRIPT_CALLV plasma_set_x16, 16
SCRIPT_CALLV plasma_set_inc_x, 0
SCRIPT_CALLV plasma_set_wave_f, 1
SCRIPT_CALLV plasma_set_wave_y, &FF
SCRIPT_CALLV plasma_set_wave_yf, &FF
SCRIPT_CALLV plasma_set_wave_x, &FF

SEQUENCE_WAIT_UNTIL_PATTERN 52

; fat firey wobble
MODE0_SET_COLOURS PAL_red, PAL_yellow
SCRIPT_CALLV plasma_set_x16, 8
SCRIPT_CALLV plasma_set_inc_x, &FF
SCRIPT_CALLV plasma_set_wave_f, 1
SCRIPT_CALLV plasma_set_wave_y, 2
SCRIPT_CALLV plasma_set_wave_yf, &FB
SCRIPT_CALLV plasma_set_wave_x, 6

\ ******************************************************************
\\ **** GOODBYE MESSAGE INC SPECS ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 53
SEQUENCE_SET_FX fx_Text
SCRIPT_CALLV text_set_palette, 1
SCRIPT_CALLV text_set_pattern, textPattern_Spiral
SCRIPT_CALLV text_set_block, textBlock_Return    ; takes 252 frames = 5.04s

\ ******************************************************************
\\ **** SMILEY ;) ****
\ ******************************************************************

SEQUENCE_WAIT_UNTIL_PATTERN 55
\\ Bounce!
SEQUENCE_SET_FX fx_Smiley
\\ Wipe
SEQUENCE_WAIT_UNTIL_PATTERN 56
SCRIPT_CALLV smiley_set_anim, 1

\ ******************************************************************
\\ **** END ****
\ ******************************************************************

SCRIPT_END



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
\\ **** ROTATING BOX ****
\ ******************************************************************
;SEQUENCE_FX_FOR_SECS fx_BoxRot, 7.8

.sequence_script_end

.sequence_end
