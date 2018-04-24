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

.sequence_set_fx_checkerzoom
{
    LDA #fx_CheckerZoom
    JMP main_set_fx
}

.sequence_set_fx_vblinds
{
    LDA #fx_VBlinds
    JMP main_set_fx
}

.sequence_set_fx_copper
{
    LDA #fx_Copper
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

MACRO SEQUENCE_FX_FOR_SECS fxfn, secs
    SCRIPT_CALL fxfn
    SCRIPT_SEGMENT_START secs
    ; just wait
    SCRIPT_SEGMENT_END
ENDMACRO

.sequence_script_start

\\ Test whether all FX are keeping sync with timer
\\ AKA epilepsy mode
IF 0
FOR n,1,20,1
SEQUENCE_FX_FOR_SECS sequence_set_fx_kefrens, 0.5
SEQUENCE_FX_FOR_SECS sequence_set_fx_vblinds, 0.5
SEQUENCE_FX_FOR_SECS sequence_set_fx_checkerzoom, 0.5
SEQUENCE_FX_FOR_SECS sequence_set_fx_boxrot, 0.5
SEQUENCE_FX_FOR_SECS sequence_set_fx_parallax, 0.5
SEQUENCE_FX_FOR_SECS sequence_set_fx_twister, 0.5
NEXT
ENDIF

SEQUENCE_FX_FOR_SECS sequence_set_fx_copper, 20.0

SEQUENCE_FX_FOR_SECS sequence_set_fx_kefrens, 2.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_vblinds, 2.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_checkerzoom, 2.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_boxrot, 2.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_parallax, 2.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_twister, 2.0

SEQUENCE_FX_FOR_SECS sequence_set_fx_kefrens, 5.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_vblinds, 5.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_checkerzoom, 5.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_boxrot, 5.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_parallax, 5.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_twister, 5.0

SEQUENCE_FX_FOR_SECS sequence_set_fx_kefrens, 1.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_vblinds, 1.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_checkerzoom, 1.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_boxrot, 1.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_parallax, 1.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_twister, 1.0

SEQUENCE_FX_FOR_SECS sequence_set_fx_kefrens, 10.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_vblinds, 10.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_checkerzoom, 10.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_boxrot, 10.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_parallax, 10.0
SEQUENCE_FX_FOR_SECS sequence_set_fx_twister, 10.0

SCRIPT_END

.sequence_script_end

.sequence_end
