\ ******************************************************************
\ *	Sequence of FX
\ ******************************************************************

.sequence_start

\ ******************************************************************
\ *	The fns
\ ******************************************************************

.sequence_set_fx_kefrens
{
    LDA #fx_Kefrens
    JMP main_set_fx
}

\\ Additional fns to set params etc.

.sequence_set_fx_twister
{
    LDA #fx_Twister
    JMP main_set_fx
}

.sequence_set_fx_boxrot
{
    LDA #fx_BoxRot
    JMP main_set_fx
}

.sequence_set_fx_parallax
{
    LDA #fx_Parallax
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

SCRIPT_CALL sequence_set_fx_kefrens

SEQUENCE_WAIT_SECS 2.0

SCRIPT_CALL sequence_set_fx_boxrot

SEQUENCE_WAIT_SECS 2.0

SCRIPT_CALL sequence_set_fx_parallax

SEQUENCE_WAIT_SECS 2.0

SCRIPT_CALL sequence_set_fx_twister

SEQUENCE_WAIT_SECS 2.0

SCRIPT_CALL sequence_set_fx_kefrens

SEQUENCE_WAIT_SECS 2.0

SCRIPT_CALL sequence_set_fx_boxrot

SEQUENCE_WAIT_SECS 2.0

SCRIPT_CALL sequence_set_fx_parallax

SEQUENCE_WAIT_SECS 2.0

SCRIPT_CALL sequence_set_fx_twister

SCRIPT_END

.sequence_script_end

.sequence_end
