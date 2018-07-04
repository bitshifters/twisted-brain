\ ******************************************************************
\ *	Static picture
\ ******************************************************************

picture_y = locals_start + 0
picture_dir = locals_start + 1
picture_anim = locals_start + 2
picture_pal_index = locals_start + 3
picture_pal_delay = locals_start + 4

PICTURE_DELAY = 1

.picture_start

PAGE_ALIGN
.picture_pu_data
INCBIN "data/brain-flash.pu"

.picture_shadow_data
INCBIN "data/brain-mask.pu"

\\ Special boot fn to preload SHADOW RAM to avoid large pause in demo!!

.picture_boot
{
	\ Ensure SHADOW RAM is writeable
    LDA &FE34:ORA #&4:STA &FE34

	LDX #LO(picture_shadow_data)
	LDY #HI(picture_shadow_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

	\ Ensure MAIN RAM is writeable
    LDA &FE34:AND #&FB:STA &FE34

    RTS
}

.picture_set_anim
{
    STA picture_anim
    RTS
}

.picture_set_delay
{
    STA picture_pal_delay
    RTS
}

.picture_init
{
	\ Ensure MAIN RAM is writeable
    LDA &FE34:AND #&FB:STA &FE34

	LDX #LO(picture_pu_data)
	LDY #HI(picture_pu_data)
    LDA #HI(screen_base_addr)
    JSR PUCRUNCH_UNPACK

    STZ picture_y
    STZ picture_anim

    LDA #1
    STA picture_dir

    LDA #&40
    STA picture_pal_index
    LDA #0;PICTURE_DELAY
    STA picture_pal_delay

    RTS
}

.picture_update
{
    DEC picture_pal_delay
    BNE not_yet

    IF 0
    {
        LDX picture_pal_index
        JSR picture_set_pal

        LDX picture_pal_index
        INX
        CPX #6
        BCC ok
        LDX #0
        .ok
        STX picture_pal_index

        LDA #PICTURE_DELAY
        STA picture_pal_delay
    }
    ELSE
    LDX picture_pal_index
    LDA picture_table, X
    TAX
    JSR picture_set_pal
    INC picture_pal_index
        LDA #PICTURE_DELAY
        STA picture_pal_delay
    ENDIF
    .not_yet

    LDA picture_anim
    BEQ return

    LDX picture_y
    JSR picture_copy_line_X

    JSR picture_advance_y

IF 0
    LDX picture_y
    JSR picture_copy_line_X

    JSR picture_advance_y

    LDX picture_y
    JSR picture_copy_line_X

    JSR picture_advance_y
ENDIF

    .return
    RTS
}

.picture_advance_y
{
IF 0
    LDX picture_y
    LDA picture_dir
    BMI up

    INX:INX
    BNE ok

    \\ bounce at 256
    DEX
    STX picture_dir
    BRA ok

    .up
    DEX:DEX
    CPX #&FF
    BNE ok

    INX
    STX picture_dir

    .ok
    STX picture_y
ELSE
    INC picture_y
    BNE return
    LDA #&FF
    STA picture_anim
ENDIF
    .return
    RTS
}

.picture_draw
{
	\\ R4=8 - CRTC cycle is 8 rows
	LDA #4: STA &FE00
	LDA #7: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #&FF: STA &FE01

	\\ R6=8 - 8 rows displayed
	LDA #6: STA &FE00
	LDA #8: STA &FE01		; 8 * 6c = 48c

    LDA #12: STA &FE00
    LDA #HI((&3000 + 16*640)/8):STA &FE01

    LDA #13: STA &FE00
    LDA #LO((&3000 + 16*640)/8):STA &FE01

    LDX #64
    .loop1
    JSR cycles_wait_128
    DEX
    BNE loop1

    LDA #12: STA &FE00
    LDA #HI((&3000 + 8*640)/8):STA &FE01

    LDA #13: STA &FE00
    LDA #LO((&3000 + 8*640)/8):STA &FE01

    LDX #64
    .loop2
    JSR cycles_wait_128
    DEX
    BNE loop2

    LDA #12: STA &FE00
    LDA #HI((&3000 + 0*640)/8):STA &FE01

    LDA #13: STA &FE00
    LDA #LO((&3000 + 0*640)/8):STA &FE01

    LDX #64
    .loop3
    JSR cycles_wait_128
    DEX
    BNE loop3

    LDA #12: STA &FE00
    LDA #HI((&3000 + 24*640)/8):STA &FE01

    LDA #13: STA &FE00
    LDA #LO((&3000 + 24*640)/8):STA &FE01

	\\ R4=8 - CRTC cycle is 8 rows
	LDA #4: STA &FE00
	LDA #14: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #11: STA &FE01

	\\ R6=8 - 8 rows displayed
	LDA #6: STA &FE00
	LDA #8: STA &FE01		; 8 * 6c = 48c

    RTS
}

.picture_copy_line_X
{
    JSR screen_calc_addr_lineX

	\ Ensure SHADOW RAM is writeable
    LDA &FE34:ORA #&4:STA &FE34
    
    LDX #0
    .read_loop
    {
        LDA (readptr)
        STA picture_line_buffer, X

        CLC
        LDA readptr
        ADC #8
        STA readptr
        BCC no_carry
        INC readptr+1
        .no_carry
        INX
        CPX #80
        BNE read_loop
    }

	\ Ensure MAIN RAM is writeable
    LDA &FE34:AND #&FB:STA &FE34
    
    LDX #0
    .write_loop
    {
        LDA picture_line_buffer, X
        STA (writeptr)

        CLC
        LDA writeptr
        ADC #8
        STA writeptr
        BCC no_carry
        INC writeptr+1
        .no_carry
        INX
        CPX #80
        BNE write_loop
    }

    RTS
}

.picture_set_pal
{
    LDY #0
    .loop
    LDA picture_colours, Y
    ORA picture_palette, X
    STA &FE21

    INX
    CPX #6
    BCC ok
    LDX #0
    .ok
    
    INY
    CPY #6
    BCC loop

    RTS
}

.picture_palette
{
    EQUB PAL_yellow
    EQUB PAL_red
    EQUB PAL_magenta
    EQUB PAL_blue
    EQUB PAL_cyan
    EQUB PAL_white
}

.picture_colours
{
    EQUB &80 + &30
    EQUB &80 + &10
    EQUB &80 + &50
    EQUB &80 + &40
    EQUB &80 + &60
    EQUB &80 + &70
}

PAGE_ALIGN
.picture_table
FOR n,0,255,1
v=INT(3 + 3 * SIN(n * 6 * PI / 256))
IF v>5
EQUB 5
ELSE
EQUB v
ENDIF
NEXT

.picture_end
