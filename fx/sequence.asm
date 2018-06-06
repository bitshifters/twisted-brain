\ ******************************************************************
\ *	Sequence of FX
\ ******************************************************************

.sequence_start

.sequence_script_start

FOR n,1,100,1

    SCRIPT_CALLV main_set_fx, fx_Standard

    SCRIPT_SEGMENT_START 1
    SCRIPT_SEGMENT_END

    SCRIPT_CALLV main_set_fx, fx_Single

    SCRIPT_SEGMENT_START 1
    SCRIPT_SEGMENT_END

NEXT

    SCRIPT_END

.sequence_script_end

.sequence_end
