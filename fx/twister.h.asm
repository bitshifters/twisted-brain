\ ******************************************************************
\ *	TWISTER MACROS
\ ******************************************************************

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
