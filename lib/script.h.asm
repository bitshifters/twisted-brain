\ ******************************************************************
\ *	Script system ZP vars
\ ******************************************************************


.script_time              skip 2    ; elapsed time in 1/50th secs
.script_ptr               skip 2    ; current command ptr in the script
.script_segment_ptr       skip 2    ; ptr to the first command in the current segment that is processing
.script_segment_time      skip 2    ; elapsed time in the current segment
.script_segment_duration  skip 2    ; duration of the current segment
.script_segment_id        skip 1    ; id of the current segment (was mainly for debugging)
.script_value             skip 1    ; value passed in A to a called function

