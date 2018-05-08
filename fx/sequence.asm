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

SEQUENCE_FX_FOR_SECS fx_BoxRot, 60.0

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

SEQUENCE_FX_FOR_SECS fx_Text, 20.0

SEQUENCE_FX_FOR_SECS fx_Logo, 2.0
SCRIPT_CALLV logo_set_anim, 1
SEQUENCE_WAIT_SECS 2.0

SEQUENCE_FX_FOR_SECS fx_Kefrens, 2.0
SEQUENCE_FX_FOR_SECS fx_VBlinds, 2.0
;SEQUENCE_FX_FOR_SECS fx_CheckZoom, 2.0
SEQUENCE_FX_FOR_SECS fx_BoxRot, 2.0
SEQUENCE_FX_FOR_SECS fx_Parallax, 2.0
SEQUENCE_FX_FOR_SECS fx_Twister, 2.0
SEQUENCE_FX_FOR_SECS fx_Copper, 2.0

IF 0
SEQUENCE_FX_FOR_SECS fx_Kefrens, 5.0
SEQUENCE_FX_FOR_SECS fx_VBlinds, 5.0
SEQUENCE_FX_FOR_SECS fx_CheckZoom, 5.0
SEQUENCE_FX_FOR_SECS fx_BoxRot, 5.0
SEQUENCE_FX_FOR_SECS fx_Parallax, 5.0
SEQUENCE_FX_FOR_SECS fx_Twister, 5.0
SEQUENCE_FX_FOR_SECS fx_Copper, 5.0

SEQUENCE_FX_FOR_SECS fx_Kefrens, 1.0
SEQUENCE_FX_FOR_SECS fx_VBlinds, 1.0
SEQUENCE_FX_FOR_SECS fx_CheckZoom, 1.0
SEQUENCE_FX_FOR_SECS fx_BoxRot, 1.0
SEQUENCE_FX_FOR_SECS fx_Parallax, 1.0
SEQUENCE_FX_FOR_SECS fx_Twister, 1.0
SEQUENCE_FX_FOR_SECS fx_Copper, 1.0
ENDIF

SEQUENCE_FX_FOR_SECS fx_Kefrens, 2.0
SEQUENCE_FX_FOR_SECS fx_VBlinds, 2.0
;SEQUENCE_FX_FOR_SECS fx_CheckZoom, 2.0
SEQUENCE_FX_FOR_SECS fx_BoxRot, 2.0
SEQUENCE_FX_FOR_SECS fx_Parallax, 2.0
SEQUENCE_FX_FOR_SECS fx_Twister, 2.0
SEQUENCE_FX_FOR_SECS fx_Copper, 2.0

SEQUENCE_FX_FOR_SECS fx_Plasma, 60.0

SCRIPT_END

.sequence_script_end

.sequence_end
