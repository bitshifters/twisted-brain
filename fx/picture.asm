\ ******************************************************************
\ *	Static picture
\ ******************************************************************

.picture_start

PAGE_ALIGN
.picture_pu_data
INCBIN "data/brain.pu"

.picture_init
{
	LDX #LO(picture_pu_data)
	LDY #HI(picture_pu_data)
    LDA #HI(screen_base_addr)
    JMP PUCRUNCH_UNPACK
}

.picture_end
