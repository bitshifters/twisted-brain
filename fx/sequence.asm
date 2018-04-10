\ ******************************************************************
\ *	Sequence of FX
\ ******************************************************************

.sequence_start

\ ******************************************************************
\ *	The fns
\ ******************************************************************

.sequence_set_fx_kefrens
{
    LDA #0
    JMP main_set_fx
}

\\ Additional fns to set params etc.

.sequence_set_fx_twister
{
    LDA #1
    JMP main_set_fx
}

\ ******************************************************************
\ *	The script
\ ******************************************************************

MACRO SEQUENCE_WAIT_SECS secs
    SCRIPT_SEGMENT_START secs
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

.sequence_script_start

; app boots into Kefrens currently

SEQUENCE_WAIT_SECS 5.0

SCRIPT_CALL sequence_set_fx_twister

SEQUENCE_WAIT_SECS 5.0

SCRIPT_CALL sequence_set_fx_kefrens

SEQUENCE_WAIT_SECS 5.0

SCRIPT_CALL sequence_set_fx_twister

SEQUENCE_WAIT_SECS 1.0

SCRIPT_CALL sequence_set_fx_kefrens

SEQUENCE_WAIT_SECS 1.0

SCRIPT_CALL sequence_set_fx_twister

SCRIPT_END

.sequence_script_end

.sequence_end
